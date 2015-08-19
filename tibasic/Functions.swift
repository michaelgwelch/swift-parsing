//
//  Functions.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation

public func const<A,B>(a:A)(b:B) -> A {
    return a
}

public func id<A>(a:A) -> A {
    return a
}

// Like Haskell $
public func §<A,B>(lhs:A->B, rhs:A) -> B {
    return lhs(rhs)
}

public func •<A,B,C>(f:B->C, g:A->B)(_ a:A) -> C {
    return f § g § a // === f(g(a))
}

public func curry<A,B,C>(f:(A,B)->C)(_ a:A)(_ b:B) -> C {
    return f(a,b)
}

public func uncurry<A,B,C>(f:A->B->C)(_ a:A,_ b:B) -> C {
    return f(a)(b)
}

extension String {
    /// A tuple compromised of the first character and the remaining characters of
    /// self if self is not empty. Else nil.
    public func uncons() -> (head:Character, tail:String)? {
        return uncons(id)
    }
    public func uncons<T>(f:(head:Character, tail:String) -> T) -> T? {
        guard (!self.isEmpty) else {
            return nil
        }
        let index0 = self.startIndex
        return f(head: self[index0], tail: self.substringFromIndex(index0.successor()))
    }
}
