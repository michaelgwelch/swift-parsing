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

public struct SequenceParser<PA:ParserType, PB:ParserType, A, B where PA.TokenType==A, PB.TokenType==B> : ParserType {
    private let parserA:PA
    private let parserB:PB
    init(parserA:PA, parserB:PB) {
        self.parserA = parserA
        self.parserB = parserB
    }
    public func parse(input: ParserContext) -> (token: (A,B), output: ParserContext)? {
        return bothTokens.parse(input)
    }

    public var firstToken:MonadicParser<A> {
        return parserA <* parserB
    }

    public var secondToken:MonadicParser<B> {
        return parserA *> parserB
    }

    public var bothTokens:MonadicParser<(A,B)> {
        return ({ x in { (x,$0) } } <§> parserA <*> parserB)
    }
}

extension Parser {
    public static func liftA2<ParserA:ParserType, ParserB:ParserType, A, B, C
        where ParserA.TokenType==A, ParserB.TokenType==B>(f:A -> B -> C)(_ a:ParserA)(_ b:ParserB) -> MonadicParser<C> {
            return f <§> a <*> b
    }

//    /// Takes a function of type `(A,B)->C` and "lifts" it to work with a 
//    /// parser for type `A` and a parser for type `B` and return a parser for type `C`
//    public static func lift<ParserA:ParserType, ParserB:ParserType, A, B, C
//        where ParserA.TokenType==A, ParserB.TokenType==B>(function f:(A,B) ->C, parserA:ParserA, parserB:ParserB) -> MonadicParser<C> {
//            return parserA.bind { a in
//                    parserB.bind { b in
//                        return Parser.success(f(a,b))
//                }
//            }
//    }

    public static func sequence<ParserA:ParserType, ParserB:ParserType, A, B where ParserA.TokenType==A, ParserB.TokenType==B>(parserA:ParserA, _ parserB:ParserB) -> SequenceParser<ParserA,ParserB,A,B> {
        return SequenceParser(parserA: parserA, parserB: parserB)
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
