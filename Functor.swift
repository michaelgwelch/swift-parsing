//
//  Functor.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation

func fmap<A,B>(f:A->B, _ t:Parser<A>) -> Parser<B> {
    return t |>>= { v in
        return success(f(v))
    }
}

// Like Haskell fmap, <$>
func <§><A,B>(lhs:A->B, rhs:Parser<A>) -> Parser<B> {
    return fmap(lhs, rhs)
}