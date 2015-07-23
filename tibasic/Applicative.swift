//
//  ApplicativeParser.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation


public func pure<A>(a:A) -> Parser<A> {
    return success(a)
}

// Like Haskell Alternative <|>
public func <|><A>(lhs:Parser<A>, rhs:Parser<A>) -> Parser<A> {
    return Parser { input in
        let result = lhs.tokenize(input)
        switch lhs.tokenize(input) {
        case .None: return rhs.tokenize(input)
        case .Some(_): return result
        }
    }
}


// Like Haskell Applicative <*>
public func <*><A,B>(lhs:Parser<A -> B>, rhs:Parser<A>) -> Parser<B> {
    return apply(lhs, rhs)
}

// Haskell Applicative <*
public func <*<A,B>(lhs:Parser<A>, rhs:Parser<B>) -> Parser<A> {
    return liftA2(const)(lhs)(rhs)
}

// Haskell Applictive *>
public func *><A,B>(lhs:Parser<A>, rhs:Parser<B>) -> Parser<B> {
    return liftA2(const(id))(lhs)(rhs)
}

public func liftA2<A,B,C>(f:A -> B -> C)(_ a:Parser<A>)(_ b:Parser<B>) -> Parser<C> {
    return f <§> a <*> b
}


public func apply<A,B>(tf:Parser<A -> B>, _ ta:Parser<A>) -> Parser<B> {
    return tf.bind { f in
        fmap(f, ta)
    }
}