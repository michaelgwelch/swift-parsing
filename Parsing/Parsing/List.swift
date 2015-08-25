//
//  List.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation

import Swift

public indirect enum List<T> {
    case Nil
    case Cons(h:T, t:List<T>)
    public func insert(h:T) -> List<T> {
        return Cons(h: h, t: self)
    }
}

public func cons<T>(head:T)(_ tail:List<T>) -> List<T> {
    return List<T>.Cons(h: head, t: tail)
}

extension List : SequenceType {
    public func generate() -> AnyGenerator<T> {
        var list = self
        return anyGenerator {
            switch list {
            case .Nil: return nil
            case .Cons(let h, let t):
                list = t
                return h
            }
        }
    }
}

