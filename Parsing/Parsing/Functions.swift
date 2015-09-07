//
//  Functions.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation

@warn_unused_result
public func const<A,B>(a:A)(b:B) -> A {
    return a
}

@warn_unused_result
public func id<A>(a:A) -> A {
    return a
}

@warn_unused_result
public func flip<TA, TB, TC>(f:TA -> TB -> TC)(_ b:TB)(_ a:TA) -> TC {
    return f(a)(b)
}

// Like Haskell $
@warn_unused_result
public func §<A,B>(lhs:A->B, rhs:A) -> B {
    return lhs(rhs)
}

@warn_unused_result
public func •<A,B,C>(f:B->C, g:A->B)(_ a:A) -> C {
    return f § g § a // === f(g(a))
}

@warn_unused_result
public func curry<A,B,C>(f:(A,B)->C)(_ a:A)(_ b:B) -> C {
    return f(a,b)
}

@warn_unused_result
public func uncurry<A,B,C>(f:A->B->C)(_ a:A,_ b:B) -> C {
    return f(a)(b)
}

extension String {
    /// A tuple compromised of the first character and the remaining characters of
    /// self if self is not empty. Else nil.
    @warn_unused_result
    public func uncons() -> (head:Character, tail:String)? {
        return uncons(id)
    }
    @warn_unused_result
    public func uncons<T>(f:(head:Character, tail:String) -> T) -> T? {
        guard (!self.isEmpty) else {
            return nil
        }
        let index0 = self.startIndex
        return f(head: self[index0], tail: self.substringFromIndex(index0.successor()))
    }
}
