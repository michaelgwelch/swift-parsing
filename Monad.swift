//
//  Monad.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation


// Like Haskell >>=, bind
func |>>=<T1, T2>(lhs:Parser<T1>, rhs:T1 -> Parser<T2>) -> Parser<T2> {
    return lhs.bind(rhs)
}

// Like Haskell >>
func |>><T1,T2>(lhs:Parser<T1>, rhs:Parser<T2>) -> Parser<T2> {
    return lhs.bind { _ in rhs }
}