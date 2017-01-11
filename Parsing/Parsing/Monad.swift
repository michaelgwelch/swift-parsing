//
//  Monad.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//


import Foundation


// Like Haskell >>=, bind

public func |>>=<T1, T2>(lhs:ParserOf<T1>, rhs:@escaping (T1) -> ParserOf<T2>) -> ParserOf<T2> {
    return lhs.bind(rhs)
}

// Like Haskell >>

public func |>><T1,T2>(lhs:ParserOf<T1>, rhs:ParserOf<T2>) -> ParserOf<T2> {
    return lhs.bind { _ in rhs }
}



extension ParserType {

    public func bind<TB, PB:ParserType>(_ f:@escaping (TokenType) -> PB)
        -> ParserOf<TB> where PB.TokenType == TB {
        return ParserOf { input in

            return self.parse(input).flatMap { (a,output)
                    in f(a).parse(output)
            }

        }
    }
}


