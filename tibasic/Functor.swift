//
//  Functor.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation

func fmap<ParserA:ParserType, A, B where ParserA.TokenType==A>(f:A->B, _ t:ParserA) -> Parser<B> {
    return t.bind { success(f($0)) }
}

// Like Haskell fmap, <$>
public func <§><ParserA:ParserType, A, B where ParserA.TokenType==A>(lhs:A->B, rhs:ParserA) -> Parser<B> {
    return fmap(lhs, rhs)
}

public func <§><A,B>(lhs:A->B, rhs:A?) -> B? {
    return rhs.map(lhs)
}


// Tuple Functor on rhs
public func <§><A,B,C>(lhs:A->B, rhs:(A,C)) -> (B,C) {
    return (lhs(rhs.0), rhs.1)
}