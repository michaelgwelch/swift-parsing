//
//  List.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation


indirect enum List<T> {
    case Nil
    case Cons(h:T, t:List<T>)
}

class ListGenerator<T> : AnyGenerator<T> {

    private(set) var list:List<Element>
    init(_ list:List<Element>) {
        self.list = list
    }
    override func next() -> Element? {
        switch list {
        case .Nil: return nil
        case .Cons(let h, let t):
            list = t
            return h
        }
    }
}

extension List : SequenceType {
    func generate() -> AnyGenerator<T> {
        return ListGenerator(self)
    }
}
