//
//  Functions.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation

func const<A,B>(a:A)(b:B) -> A {
    return a
}

func id<A>(a:A) -> A {
    return a
}

// Like Haskell $
func §<A,B>(lhs:A->B, rhs:A) -> B {
    return lhs(rhs)
}

func •<A,B,C>(f:B->C, g:A->B)(a:A) -> C {
    return f § g § a // === f(g(a))
}
