//
//  ApplicativeParser.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation


// Like Haskell Alternative <|>
public func <|><ParserA1:ParserType, ParserA2:ParserType, A where ParserA1.ParsedType==A, ParserA2.ParsedType==A>(lhs:ParserA1, rhs:ParserA2) -> Parser<A> {
    return Parser { input in
        let result = lhs.tokenize(input)
        switch result {
        case .None: return rhs.tokenize(input)
        case .Some(_): return result
        }
    }
}


// Like Haskell Applicative <*>
public func <*><ParserAB:ParserType, ParserA:ParserType, A, B where ParserAB.ParsedType==A->B,
    ParserA.ParsedType==A>(lhs:ParserAB, rhs:ParserA) -> Parser<B> {
        return apply(lhs, rhs)
}

// Haskell Applicative <*
public func <*<ParserA:ParserType, ParserB:ParserType, A, B where
    ParserA.ParsedType==A, ParserB.ParsedType==B>(lhs:ParserA, rhs:ParserB) -> Parser<A> {
        return liftA2(const)(lhs)(rhs)
}

// Haskell Applictive *>
public func *><ParserA:ParserType, ParserB:ParserType, A, B where
    ParserA.ParsedType==A, ParserB.ParsedType==B>(lhs:ParserA, rhs:ParserB) -> Parser<B> {
        return liftA2(const(id))(lhs)(rhs)
}

public func liftA2<ParserA:ParserType, ParserB:ParserType, A, B, C
    where ParserA.ParsedType==A, ParserB.ParsedType==B>(f:A -> B -> C)(_ a:ParserA)(_ b:ParserB) -> Parser<C> {
        return f <§> a <*> b
}


func apply<Parser1:ParserType, ParserA:ParserType, A, B where Parser1.ParsedType==A->B,
    ParserA.ParsedType==A>(tf:Parser1, _ ta:ParserA) -> Parser<B> {
        return tf.bind { f in fmap(f, ta) }
}
