//
//  Functions.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//


import Foundation


//public func const<A,B>(a:A, b:B) -> A {
//    return a
//}


public func id<A>(a:A) -> A {
    return a
}


//public func flip<TA, TB, TC>(f:TA -> TB -> TC)(_ b:TB)(_ a:TA) -> TC {
//    return f(a)(b)
//}

// Like Haskell $

public func §<A,B>(lhs:(A)->B, rhs:A) -> B {
    return lhs(rhs)
}


public func •<A,B,C>(f:@escaping (B)->C, g:@escaping (A)->B) -> ((A) -> C) {
    return { f § g § $0 } // === f(g(a))
}


//public func curry<A,B,C>(f:(A,B)->C)(_ a:A)(_ b:B) -> C {
//    return f(a,b)
//}


//public func uncurry<A,B,C>(f:A->B->C)(_ a:A,_ b:B) -> C {
//    return f(a)(b)
//}

extension String {
    /// A tuple compromised of the first character and the remaining characters of
    /// self if self is not empty. Else nil.
    
    public func uncons() -> (head:Character, tail:String)? {
        return uncons(id)
    }

    public func uncons<T>(_ f:(_ head:Character, _ tail:String) -> T) -> T? {
        guard (!self.isEmpty) else {
            return nil
        }
        let index0 = self.startIndex
        return f(self[index0], self.substring(from: self.index(after: index0)))
    }
}


