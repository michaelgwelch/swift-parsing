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
public func <|><ParserA1:ParserType, ParserA2:ParserType, A where ParserA1.TokenType==A, ParserA2.TokenType==A>(lhs:ParserA1, rhs:ParserA2) -> Parser<A> {
    return Parser { input in
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
    ParserA.TokenType==A>(lhs:ParserAB, rhs:ParserA) -> Parser<B> {
        return apply(lhs, rhs)
}

// Haskell Applicative <*
@warn_unused_result
public func <*<ParserA:ParserType, ParserB:ParserType, A, B where
    ParserA.TokenType==A, ParserB.TokenType==B>(lhs:ParserA, rhs:ParserB) -> Parser<A> {
        let first:(A,B) -> A = { $0.0 }
        return Parsers.lift(first, lhs, rhs)
}

// Haskell Applictive *>
@warn_unused_result
public func *><ParserA:ParserType, ParserB:ParserType, A, B where
    ParserA.TokenType==A, ParserB.TokenType==B>(lhs:ParserA, rhs:ParserB) -> Parser<B> {
        let second:(A,B) -> B = { $0.1 }
        return Parsers.lift(second, lhs, rhs)
}

public struct SequenceParser<PA:ParserType, PB:ParserType, A, B where PA.TokenType==A, PB.TokenType==B> : ParserType {
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

    public var firstToken:Parser<A> {
        return parserA <* parserB
    }

    public var secondToken:Parser<B> {
        return parserA *> parserB
    }

    public var bothTokens:Parser<(A,B)> {
        return { x in { (x,$0) } } <§> parserA <*> parserB
    }
}



extension Parsers {

    /// Takes a function of type `(A,B)->C` and "lifts" it to work with a
    /// parser for type `A` and a parser for type `B` and return a parser for type `C`
    public static func lift<ParserA:ParserType, ParserB:ParserType, A, B, C
        where ParserA.TokenType==A, ParserB.TokenType==B>(f:(A,B) ->C, _ parserA:ParserA, _ parserB:ParserB) -> Parser<C> {
            return parserA.bind { a in
                parserB.bind { b in
                    return Parsers.success(f(a,b))
                }
            }
    }
}

extension ParserType {

    public func sequence<P:ParserType, A where P.TokenType==A>(parser:P) -> SequenceParser<Self, P, TokenType, A> {
        return SequenceParser(parserA: self, parserB: parser)
    }
    
}

@warn_unused_result
func apply<Parser1:ParserType, ParserA:ParserType, A, B where Parser1.TokenType==A->B,
    ParserA.TokenType==A>(tf:Parser1, _ ta:ParserA) -> Parser<B> {
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



