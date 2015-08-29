//
//  ApplicativeParser.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation


// Like Haskell Alternative <|>
public func <|><ParserA1:ParserType, ParserA2:ParserType, A where ParserA1.TokenType==A, ParserA2.TokenType==A>(lhs:ParserA1, rhs:ParserA2) -> MonadicParser<A> {
    return MonadicParser { input in
        if let result = lhs.parse(input) {
            return result
        } else {
            return rhs.parse(input)
        }
    }
}


// Like Haskell Applicative <*>
public func <*><ParserAB:ParserType, ParserA:ParserType, A, B where ParserAB.TokenType==A->B,
    ParserA.TokenType==A>(lhs:ParserAB, rhs:ParserA) -> MonadicParser<B> {
        return apply(lhs, rhs)
}

public func <*><A,B>(lhs:(A->B)?, rhs:A?) -> B? {
    return lhs.flatMap { rhs.map($0) }
}

// Haskell Applicative <*
public func <*<ParserA:ParserType, ParserB:ParserType, A, B where
    ParserA.TokenType==A, ParserB.TokenType==B>(lhs:ParserA, rhs:ParserB) -> MonadicParser<A> {
        //return Parse.liftA2(const)(lhs)(rhs)
        return lhs.liftA2(rhs)(const)
}

// Haskell Applictive *>
public func *><ParserA:ParserType, ParserB:ParserType, A, B where
    ParserA.TokenType==A, ParserB.TokenType==B>(lhs:ParserA, rhs:ParserB) -> MonadicParser<B> {
        //return Parse.liftA2(const(id))(lhs)(rhs)
        return lhs.liftA2(rhs)(const(id))
}

extension Parser {
    public static func liftA2<ParserA:ParserType, ParserB:ParserType, A, B, C
        where ParserA.TokenType==A, ParserB.TokenType==B>(f:A -> B -> C)(_ a:ParserA)(_ b:ParserB) -> MonadicParser<C> {
            return f <§> a <*> b
    }
}

extension ParserType {
    public func liftA2<ParserT:ParserType, T, U where ParserT.TokenType==T>(t:ParserT)(_ f:TokenType -> T -> U) -> MonadicParser<U> {
        return f <§> self <*> t
    }
}




func apply<Parser1:ParserType, ParserA:ParserType, A, B where Parser1.TokenType==A->B,
    ParserA.TokenType==A>(tf:Parser1, _ ta:ParserA) -> MonadicParser<B> {
        return tf.bind { f in f <§> ta }
}
