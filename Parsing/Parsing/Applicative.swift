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

public func <|><ParserA1:ParserType, ParserA2:ParserType, A>(lhs:ParserA1, rhs:ParserA2) -> ParserOf<A> where ParserA1.TokenType==A, ParserA2.TokenType==A {
    return ParserOf { input in

        return lhs.parse(input) ?? rhs.parse(input)
        
    }
}



///
// Like Haskell Applicative <*>

public func <*><ParserAB:ParserType, ParserA:ParserType, A, B>(lhs:ParserAB, rhs:ParserA) -> ParserOf<B> where ParserAB.TokenType==(A)->B,
    ParserA.TokenType==A {
        return apply(lhs, rhs)
}


// Haskell Applicative <*

public func <*<ParserA:ParserType, ParserB:ParserType, A, B>(lhs:ParserA, rhs:ParserB) -> ParserOf<A> where
    ParserA.TokenType==A, ParserB.TokenType==B {

        return Parser.sequence(lhs, rhs) { $0.0 }
}

// Haskell Applictive *>

public func *><ParserA:ParserType, ParserB:ParserType, A, B>(lhs:ParserA, rhs:ParserB) -> ParserOf<B> where
    ParserA.TokenType==A, ParserB.TokenType==B {
        
        return Parser.sequence(lhs, rhs) { $0.1 }
}

/*

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

*/

extension Parser {

    /// Create a new parser that sequences two parsers and passes their
    /// tokens through the function `f`.
    
    public static func sequence<PA:ParserType, PB:ParserType, A, B, C>(_ parserA:PA, _ parserB:PB,  _ f:@escaping (A,B)->C) -> ParserOf<C> where
        PA.TokenType==A, PB.TokenType==B {
            return { a in { b in f(a,b) } } <§> parserA <*> parserB
    }

    /// Creates a new parser that sequences three parsers and passes their
    /// results throught the function `f`.
    
    public static func sequence<PA:ParserType, PB:ParserType, PC:ParserType, A, B, C, D>(_ pa:PA, _ pb:PB, _ pc:PC,
                                _ f:@escaping (A,B,C)->D) -> ParserOf<D>
        where PA.TokenType==A, PB.TokenType==B, PC.TokenType==C {
            return { a in { b in { c in f(a,b,c) } } } <§> pa <*> pb <*> pc
    }

}

/*
extension ParserType {

//    public func sequence<P:ParserType, A where P.TokenType==A>(parser:P) -> SequenceParserOf<Self, P, TokenType, A> {
//        return SequenceParser(parserA: self, parserB: parser)
//    }

}
 */


func apply<Parser1:ParserType, ParserA:ParserType, A, B>(_ tf:Parser1, _ ta:ParserA) -> ParserOf<B> where Parser1.TokenType==(A)->B,
    ParserA.TokenType==A {
        return tf.bind { f in ta.map(f) }
}


// MARK: Optional Applicative


public func <*><A,B>(lhs:((A)->B)?, rhs:A?) -> B? {
    return lhs.flatMap { rhs.map($0) }
}



public func *><A,B>(lhs:A?, rhs:B?) -> B? {
    if lhs == nil { return nil }
    return rhs
}


public func <*<A,B>(lhs:A?, rhs:B?) -> A? {
    return rhs *> lhs
}



