//
//  Monoid.swift
//  tibasic
//
//  Created by Michael Welch on 8/19/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation

protocol Monoid {
    typealias Type
    var identity:Type { get }
    func operation(lhs: Type, _ rhs: Type) -> Type
}

protocol Group : Monoid {
    func inverse(value: Type) -> Type
}

protocol AlmostGroup : Monoid {
    func nullableInverse(value:Type) -> Type?
}

struct SumInt {
    let identity = 0
    func operation(lhs: Int, _ rhs: Int) -> Int {
        return lhs + rhs
    }
}

extension SumInt : Monoid {
    
}

extension SumInt : Group {
    func inverse(value: Int) -> Int {
        return -value
    }
}

struct MultiplicationInt {
    let identity = 1
    func operation(lhs: Int, _ rhs: Int) -> Int {
        return lhs * rhs
    }
}

extension MultiplicationInt : Monoid {

}

struct NonZeroDouble {
    private let _value:Double
    init?(value:Double) {
        guard value != 0 else {
            return nil
        }
        _value = value
    }
}

extension NonZeroDouble : FloatLiteralConvertible {
    init(floatLiteral value: Double) {
        guard value != 0 else {
            fatalError("Cannot instatiate NonZeroDouble with 0 value")
        }
        _value = value
    }
}

struct MultiplicationNonZeroDouble {
    let identity:NonZeroDouble = 1.0
    func operation(lhs: NonZeroDouble, _ rhs: NonZeroDouble) -> NonZeroDouble {
        return NonZeroDouble(floatLiteral: lhs._value * rhs._value)
    }
}

extension MultiplicationNonZeroDouble : Monoid {

}

extension MultiplicationNonZeroDouble : Group {
    func inverse(nonZeroDouble: NonZeroDouble) -> NonZeroDouble {
        return NonZeroDouble(floatLiteral: 1/nonZeroDouble._value)
    }
}

struct SumDouble : Monoid, Group {
    let identity:Double = 0
    func operation(lhs: Double, _ rhs: Double) -> Double {
        return lhs + rhs
    }
    func inverse(doubleValue: Double) -> Double {
        return -doubleValue
    }
}

struct MultiplyDouble {
    let identity:Double = 1
    func operation(lhs: Double, _ rhs:Double) -> Double {
        return lhs * rhs
    }
    func nullableInverse(doubleValue:Double) -> Double? {
        guard (doubleValue != 0) else {
            return nil
        }
        return 1/doubleValue
    }
}

extension MultiplyDouble : Monoid, AlmostGroup {
    
}

