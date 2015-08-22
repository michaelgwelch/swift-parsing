//
//  NumberExpression.swift
//  tibasic
//
//  Created by Michael Welch on 8/11/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation
import Darwin

public indirect enum NumExpression {
    case Id(String)
    case Expr(NumExpression, NumExpression)
    case NumberLiteral(Int)
    case Term(NumExpression, NumExpression)
    case TermTailPlus(NumExpression, NumExpression)
    case TermTailSub(NumExpression, NumExpression)
    case Paren(NumExpression)
    case Factor(NumExpression, NumExpression)
    case FactTailMult(NumExpression, NumExpression)
    case FactTailDiv(NumExpression, NumExpression)
    case Negate(NumExpression)
    case Epsilon
    case Exp(NumExpression, NumExpression)
//    case Negate(NumericExpression)
//    case Multiply(NumericExpression, NumericExpression)
//    case Divide(NumericExpression, NumericExpression)
//    case Add(NumericExpression, NumericExpression)
//    case Subtract(NumericExpression, NumericExpression)

    static let CreateExpr = curry(Expr)
    static let CreateExp = curry(Exp)
    static let CreateMult = curry(FactTailMult)
    static let CreateDiv = curry(FactTailDiv)
    static let CreateTerm = curry(Term)
    static let CreatePlus = curry(TermTailPlus)
    static let CreateSub = curry(TermTailSub)
    static let CreateFact = curry(Factor)
//    static let CreateAdd = curry(Add)
//    static let CreateSub = curry(Subtract)
}

extension NumExpression : CustomStringConvertible {
    public var description:String {
        switch self {
        case .Id(let s): return s
        case .NumberLiteral(let i): return String(i)
        case .Epsilon: return ""
        case .Negate(let n): return "-" + n.description
        case .Factor(let e1, let e2): return e1.description + e2.description
        case .FactTailMult(let e1, let e2): return "*" + e1.description + e2.description
        case .FactTailDiv(let e1, let e2): return "/" + e1.description + e2.description
        case .Term(let e1, let e2): return e1.description + e2.description
        case .TermTailPlus(let e1, let e2): return "+" + e1.description + e2.description
        case .TermTailSub(let e1, let e2): return "-" + e1.description + e2.description
        case .Exp(let e1, let e2): return "^" + e1.description + e2.description
        case .Expr(let e1, let e2): return e1.description + e2.description
        case .Paren(let e): return "(" + e.description + ")"
        }
    }
}

extension NumExpression {
    var identifiers:[String] {
        switch self {
        case .Id(let s): return [s]
        case .Negate(let n): return n.identifiers
        case .Factor(let e1, let e2): return e1.identifiers + e2.identifiers
        case .FactTailMult(let e1, let e2): return e1.identifiers + e2.identifiers
        case .FactTailDiv(let e1, let e2): return e1.identifiers + e2.identifiers
        case .Term(let e1, let e2): return e1.identifiers + e2.identifiers
        case .TermTailPlus(let e1, let e2): return e1.identifiers + e2.identifiers
        case .TermTailSub(let e1, let e2): return e1.identifiers + e2.identifiers
        case .Exp(let e1, let e2): return e1.identifiers + e2.identifiers
        case .Expr(let e1, let e2): return e1.identifiers + e2.identifiers
        case .Paren(let e): return e.identifiers
        default: return []
        }
    }
}

extension NumExpression {
    var isEpsilon:Bool {
        switch self {
        case .Epsilon: return true
        default: return false
        }
    }
}

func intPow(lhs:Int, _ rhs:Int) -> Int {
    return Int(pow(Double(lhs), Double(rhs)))
}
let mult:Int -> Int -> Int = { lhs in { lhs * $0 }}
let plus:Int -> Int -> Int = { lhs in { lhs + $0 }}
let div:Int -> Int -> Int = { lhs in { lhs / $0 }}
let sub:Int -> Int -> Int = { lhs in { lhs - $0 }}
let exp:Int -> Int -> Int = { lhs in { intPow(lhs, $0) }}

extension NumExpression {
    public func eval() -> Int? {
        var store = [String:Int]()
        store = identifiers.reduce(store) { (var currentStore, let key) -> [String:Int] in
            currentStore[key] = 1
            return currentStore
        }
        return eval(store)
    }
    public func eval(store: [String:Int]) -> Int? {
        switch self {

        case .Id(let s): return store[s] ?? 0
        case .NumberLiteral(let i): return i
        case .Epsilon: return nil
        case .Negate(let e): return e.eval(store).map { -$0 }
        case .Factor(let e1, let e2): return e2.eval(store, initialValue: e1.eval(store))
        case .FactTailMult(let e1, let e2): return e2.eval(store, initialValue: e1.eval(store))
        case .FactTailDiv(let e1, let e2): return e2.eval(store, initialValue: e1.eval(store))
        case .Term(let e1, let e2): return e2.eval(store, initialValue: e1.eval(store))
        case .TermTailPlus(let e1, let e2): return e2.eval(store, initialValue: e1.eval(store))
        case .TermTailSub(let e1, let e2): return e2.eval(store, initialValue: e1.eval(store))
        case .Exp(let e1, let e2): return e2.eval(store, initialValue: e1.eval(store))
        case .Expr(let e1, let e2): return e2.eval(store, initialValue:e1.eval(store))
        case .Paren(let e): return e.eval(store)
            
        }
    }
    func eval(store: [String:Int], initialValue value: Int?) -> Int? {
        switch self {
        case .FactTailMult(let e1, let e2): return mult <§> value <*> e2.eval(store, initialValue: e1.eval(store))
        case .FactTailDiv(let e1, let e2): return div <§> value <*> e2.eval(store, initialValue: e1.eval(store))
        case .TermTailPlus(let e1, let e2): return plus <§> value <*> e2.eval(store, initialValue: e1.eval(store))
        case .TermTailSub(let e1, let e2): return sub <§> value <*> e2.eval(store, initialValue: e1.eval(store))
        case .Exp(let e1, let e2): return exp <§> value <*> e2.eval(store, initialValue: e1.eval(store))
        case .Epsilon: return value
        default: fatalError("What sort of expression is this")
        }
    }
}

extension NumExpression : CustomDebugStringConvertible {
    public var debugDescription:String { return description }
}


let lparen = Parse.char("(")
let rparen = Parse.char(")")

let multop = Parse.char("*")
let divop = Parse.char("/")
let plusop = Parse.char("+")
let subop = Parse.char("-")
let expop = Parse.char("^")
public let number = Parse.nat


public let num_expression:Parser<NumExpression> = NumExpression.CreateExpr <§> term <*> term_tail()
//public let num_expression:Parser<NumExpression> = term
let lazy_num_expression = Parse.lazy(num_expression)

func term_tail() -> Parser<NumExpression> {
    return NumExpression.CreatePlus <§> (plusop *> term) <*> lazy_term_tail
      <|> NumExpression.CreateSub <§> (subop *> term) <*> lazy_term_tail
      <|> epsilon
}
let lazy_term_tail = Parse.lazy(term_tail())


let term = NumExpression.CreateTerm <§> factor <*> factor_tail()

func factor_tail() -> Parser<NumExpression> {
    return NumExpression.CreateMult <§> (multop *> factor) <*> lazy_factor_tail
      <|> NumExpression.CreateDiv <§> (divop *> factor) <*> lazy_factor_tail
      <|> epsilon
}
let lazy_factor_tail = Parse.lazy(factor_tail())

let factor = NumExpression.CreateFact <§> exp_operand <*> exp_operand_tail()

func exp_operand_tail() -> Parser<NumExpression> {
    return NumExpression.CreateExp <§> (expop *> exp_operand) <*> Parse.lazy(exp_operand_tail())
      <|> epsilon
}

public let exp_operand = (lparen *> lazy_num_expression <* rparen)
  <|> NumExpression.NumberLiteral <§> number
  <|> NumExpression.Id <§> Parse.identifier
  <|> (plusop *> lazy_num_expression)
  <|> NumExpression.Negate <§> (subop *> lazy_num_expression)

let epsilon = Parse.success(NumExpression.Epsilon)
