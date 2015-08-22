//
//  ApplicativeParser.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation


// Like Haskell Alternative <|>
public func <|><ParserA1:ParserType, ParserA2:ParserType, A where ParserA1.TokenType==A, ParserA2.TokenType==A>(lhs:ParserA1, rhs:ParserA2) -> Parser<A> {
    return Parser { input in
        let result = lhs.parse(input)
        switch result {
        case .None: return rhs.parse(input)
        case .Some(_): return result
        }
    }
}


// Like Haskell Applicative <*>
public func <*><ParserAB:ParserType, ParserA:ParserType, A, B where ParserAB.TokenType==A->B,
    ParserA.TokenType==A>(lhs:ParserAB, rhs:ParserA) -> Parser<B> {
        return apply(lhs, rhs)
}

public func <*><A,B>(lhs:(A->B)?, rhs:A?) -> B? {
    return lhs.flatMap { rhs.map($0) }
}

// Haskell Applicative <*
public func <*<ParserA:ParserType, ParserB:ParserType, A, B where
    ParserA.TokenType==A, ParserB.TokenType==B>(lhs:ParserA, rhs:ParserB) -> Parser<A> {
        return Parse.liftA2(const)(lhs)(rhs)
}

// Haskell Applictive *>
public func *><ParserA:ParserType, ParserB:ParserType, A, B where
    ParserA.TokenType==A, ParserB.TokenType==B>(lhs:ParserA, rhs:ParserB) -> Parser<B> {
        return Parse.liftA2(const(id))(lhs)(rhs)
}

extension Parse {
    public static func liftA2<ParserA:ParserType, ParserB:ParserType, A, B, C
        where ParserA.TokenType==A, ParserB.TokenType==B>(f:A -> B -> C)(_ a:ParserA)(_ b:ParserB) -> Parser<C> {
            return f <§> a <*> b
    }
}




func apply<Parser1:ParserType, ParserA:ParserType, A, B where Parser1.TokenType==A->B,
    ParserA.TokenType==A>(tf:Parser1, _ ta:ParserA) -> Parser<B> {
        return tf.bind { f in f <§> ta }
}
