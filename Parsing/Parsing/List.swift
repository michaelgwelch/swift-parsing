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
    case empty
    case cons(h:T, t:List<T>)

    public func insert(h:T) -> List<T> {
        return .cons(h: h, t: self)
    }
}

public func cons<T>(_ head:T) -> ((List<T>) -> List<T>) {
    return { List<T>.cons(h: head, t: $0) }
}

extension List : IteratorProtocol, Sequence {
    mutating public func next() -> T? {
        switch self {
        case .empty: return nil
        case .cons(let h, let t):
            defer { self = t }
            return h
        }
    }
}
/*
extension List : Sequence {
    public func makeIterator() -> AnyIterator<T> {
        var list = self
        return AnyIterator {
            switch list {
            case .empty: return nil
            case .cons(let h, let t):
                list = t
                return h
            }
        }
    }
}
*/


//extension List {
//    public func bind<U>(f:T -> List<U>) -> List<U> {
//        return .Nil
//    }
//}
//
//extension List where T : SequenceType {
//    public func concat() -> List<T.Generator.Element> {
//        return self.bind(id)
//    }
//}


