//
//  Monad.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation


// Like Haskell >>=, bind
public func |>>=<T1, T2>(lhs:Parser<T1>, rhs:T1 -> Parser<T2>) -> Parser<T2> {
    return lhs.bind(rhs)
}

// Like Haskell >>
public func |>><T1,T2>(lhs:Parser<T1>, rhs:Parser<T2>) -> Parser<T2> {
    return lhs.bind { _ in rhs }
}



extension ParserType {
    public func bind<TB, PB:ParserType where PB.TokenType == TB>(f:TokenType -> PB) -> Parser<TB> {
        return Parser { input in
            if case let Optional.Some(a, output) = self.parse(input) {
                return f(a).parse(output)
            }
            return nil

        }
    }
}

