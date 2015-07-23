//
//  BasicParser.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation


struct Number {

}

indirect enum NumericExpression {
    case NumberLiteral(Int)
    case Paren(NumericExpression)
    case Exp(NumericExpression, NumericExpression)
    case Negate(NumericExpression)
    case Multiply(NumericExpression, NumericExpression)
    case Divide(NumericExpression, NumericExpression)
    case Add(NumericExpression, NumericExpression)
    case Subtract(NumericExpression, NumericExpression)

    static let CreateExp = curry(Exp)
    static let CreateMult = curry(Multiply)
    static let CreateDiv = curry(Divide)
    static let CreateAdd = curry(Add)
    static let CreateSub = curry(Subtract)
}


let left_paren = char("(")
let right_paren = char(")")
let exponent_op = char("^")
let mult_op = char("*")
let divide_op = char("/")
let plus_op = char("+")
let subtract_op = char("-")
let number = nat

// TODO: This algorithm requires a bit of backtracking -- can rewrite to avoid that.
// Example: 3 + 5, the number 3 is parsed several times before we back track up to the add_expression
// I think, that is the case anyway. I should brush up on the parsing of Expressions.

let numeric_expression:Parser<NumericExpression> = add_expression

let number_literal_expr = NumericExpression.NumberLiteral <§> number

let paren_expression = number_literal_expr
    <|> NumericExpression.Paren <§> (left_paren *> numeric_expression <* right_paren)

let exponent_expresion = paren_expression
    <|> NumericExpression.CreateExp <§> (numeric_expression <* exponent_op) <*> numeric_expression

let prefix_expression = exponent_expresion
    <|> plus_op *> numeric_expression
    <|> NumericExpression.Negate <§> (subtract_op *> numeric_expression)

let multiply_expression = prefix_expression
    <|> NumericExpression.CreateMult <§> (numeric_expression <* mult_op) <*> numeric_expression
    <|> NumericExpression.CreateDiv <§> (numeric_expression <* divide_op) <*> numeric_expression

let add_expression = multiply_expression
    <|> NumericExpression.CreateAdd <§> (numeric_expression <* plus_op) <*> numeric_expression
    <|> NumericExpression.CreateSub <§> (numeric_expression <* subtract_op) <*> numeric_expression
