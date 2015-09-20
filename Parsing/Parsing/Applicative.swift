//
//  ApplicativeParser.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation


// MARK: ParserType Applicative

/// Create a new parser that is composed of two parsers.
/// If the first one fails to parse anything then the second run is run.
///
/// Like Haskell Alternative <|>
@warn_unused_result
public func <|><ParserA1:ParserType, ParserA2:ParserType, A where ParserA1.TokenType==A, ParserA2.TokenType==A>(lhs:ParserA1, rhs:ParserA2) -> ParserOf<A> {
    return ParserOf { input in
        if let result = lhs.parse(input) {
            return result
        } else {
            return rhs.parse(input)
        }
    }
}

///
// Like Haskell Applicative <*>
@warn_unused_result
public func <*><ParserAB:ParserType, ParserA:ParserType, A, B where ParserAB.TokenType==A->B,
    ParserA.TokenType==A>(lhs:ParserAB, rhs:ParserA) -> ParserOf<B> {
        return apply(lhs, rhs)
}

// Haskell Applicative <*
@warn_unused_result
public func <*<ParserA:ParserType, ParserB:ParserType, A, B where
    ParserA.TokenType==A, ParserB.TokenType==B>(lhs:ParserA, rhs:ParserB) -> ParserOf<A> {

        return Parsers.sequence(lhs, rhs) { $0.0 }
}

// Haskell Applictive *>
@warn_unused_result
public func *><ParserA:ParserType, ParserB:ParserType, A, B where
    ParserA.TokenType==A, ParserB.TokenType==B>(lhs:ParserA, rhs:ParserB) -> ParserOf<B> {
        
        return Parsers.sequence(lhs, rhs) { $0.1 }
}

public struct SequenceParserOf<PA:ParserType, PB:ParserType, A, B where PA.TokenType==A, PB.TokenType==B> : ParserType {
    private let parserA:PA
    private let parserB:PB
    init(parserA:PA, parserB:PB) {
        self.parserA = parserA
        self.parserB = parserB
    }
    @warn_unused_result
    public func parse(input: ParserContext) -> (token: (A,B), output: ParserContext)? {
        return bothTokens.parse(input)
    }

    public var firstToken:ParserOf<A> {
        return parserA <* parserB
    }

    public var secondToken:ParserOf<B> {
        return parserA *> parserB
    }

    public var bothTokens:ParserOf<(A,B)> {
        return { x in { (x,$0) } } <§> parserA <*> parserB
    }
}



extension Parsers {

    /// Create a new parser that sequences two parsers and passes their
    /// tokens through the function `f`.
    @warn_unused_result
    public static func sequence<PA:ParserType, PB:ParserType, A, B, C where
        PA.TokenType==A, PB.TokenType==B>(parserA:PA, _ parserB:PB,  _ f:(A,B)->C) -> ParserOf<C> {
            return { a in { b in f(a,b) } } <§> parserA <*> parserB
    }

    /// Creates a new parser that sequences three parsers and passes their
    /// results throught the function `f`.
    @warn_unused_result
    public static func sequence<PA:ParserType, PB:ParserType, PC:ParserType, A, B, C, D
        where PA.TokenType==A, PB.TokenType==B, PC.TokenType==C>(pa:PA, _ pb:PB, _ pc:PC,
        _ f:(A,B,C)->D) -> ParserOf<D> {
            return { a in { b in { c in f(a,b,c) } } } <§> pa <*> pb <*> pc
    }

}

extension ParserType {

//    public func sequence<P:ParserType, A where P.TokenType==A>(parser:P) -> SequenceParserOf<Self, P, TokenType, A> {
//        return SequenceParser(parserA: self, parserB: parser)
//    }

}

@warn_unused_result
func apply<Parser1:ParserType, ParserA:ParserType, A, B where Parser1.TokenType==A->B,
    ParserA.TokenType==A>(tf:Parser1, _ ta:ParserA) -> ParserOf<B> {
        return tf.bind { f in f <§> ta }
}


// MARK: Optional Applicative

@warn_unused_result
public func <*><A,B>(lhs:(A->B)?, rhs:A?) -> B? {
    return lhs.flatMap { rhs.map($0) }
}


@warn_unused_result
public func *><A,B>(lhs:A?, rhs:B?) -> B? {
    if lhs == nil { return nil }
    return rhs
}

@warn_unused_result
public func <*<A,B>(lhs:A?, rhs:B?) -> A? {
    return rhs *> lhs
}



