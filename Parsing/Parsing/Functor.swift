//
//  Functor.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation

extension ParserType {
    public func map<B>(f:TokenType -> B) -> MonadicParser<B> {
        return self.bind { Parser.success(f($0)) }
    }
}

extension Parser {
    /// Lifts a function of type `A-B` to work with a parser for type `A` and
    /// return a parser for type `B`
    public static func map<ParserA:ParserType, A, B where ParserA.TokenType==A>(function f:A->B, forUseOn parser:ParserA)
        -> MonadicParser<B> {
            return f <§> parser
    }
}

// Like Haskell fmap, <$>
public func <§><ParserA:ParserType, A, B where ParserA.TokenType==A>(lhs:A->B, rhs:ParserA) -> MonadicParser<B> {
    return rhs.map(lhs)
}

public func <§><A,B>(lhs:A->B, rhs:A?) -> B? {
    return rhs.map(lhs)
}

public func <§><A,B>(lhs:A->B, rhs:[A]) -> [B] {
    return rhs.map(lhs)
}


// Tuple Functor on rhs
public func <§><A,B,C>(lhs:A->B, rhs:(A,C)) -> (B,C) {
    return (lhs(rhs.0), rhs.1)
}

public func <§><A,B>(lhs:A->B, rhs:List<A>) -> List<B> {
    return (rhs.map(lhs))
}


extension List {
    public func map<B>(f:T->B) -> List<B> {
        return self.reduce(List<B>.Nil, combine: {List<B>.Cons(h: f($1), t: $0)})
    }
}