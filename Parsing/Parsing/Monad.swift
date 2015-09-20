//
//  Monad.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation


// Like Haskell >>=, bind
@warn_unused_result
public func |>>=<T1, T2>(lhs:ParserOf<T1>, rhs:T1 -> ParserOf<T2>) -> ParserOf<T2> {
    return lhs.bind(rhs)
}

// Like Haskell >>
@warn_unused_result
public func |>><T1,T2>(lhs:ParserOf<T1>, rhs:ParserOf<T2>) -> ParserOf<T2> {
    return lhs.bind { _ in rhs }
}



extension ParserType {
    @warn_unused_result
    public func bind<TB, PB:ParserType where PB.TokenType == TB>(f:TokenType -> PB) -> ParserOf<TB> {
        return ParserOf { input in
            if case let .Some(a, output) = self.parse(input) {
                return f(a).parse(output)
            }
            return nil

        }
    }
}

