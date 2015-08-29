//: [Previous](@previous)

import Foundation
import Parsing
import Darwin

//: # Parsing and evaluating expressions
//:
//: For this example we'll parse the following grammar
//:
//:     
//:     expr             ::= term term_tail
//:     term_tail        ::= plus_op expr 
//:                        | sub_op expr
//:                        | epsilon
//:     term             ::= factor factor_tail
//:     factor_tail      ::= mult_op term 
//:                        | div_op term
//:                        | epsilon
//:     factor           ::= exp_operand exp_operand_tail
//:     exp_operand_tail ::= exp_op factor 
//:                        | epsilon
//:     exp_operand      ::= ( expr ) 
//:                        | id
//:                        | literal
//:                        | sub_op expr
//:                        | plus_op expr
//:     plus_op          ::= +
//:     sub_op           ::= -
//:     mult_op          ::= *
//:     div_op           ::= /
//:     exp_op           ::= ^
//:     epsilon          ::= 𝜖 (Empty string)


//: [Next](@next)


//: Declare an enum that can store the results of our parsing

indirect enum NumericExpression {
    case Expression(NumericExpression, NumericExpression)
    case AddTermTail(NumericExpression)
    case SubtactTermTail(NumericExpression)
    case Term(NumericExpression, NumericExpression)
    case MultiplyFactorTail(NumericExpression)
    case DivideFactorTail(NumericExpression)
    case Factor(NumericExpression, NumericExpression)
    case ExponentOperandTail(NumericExpression)
    case Identifier(String)
    case Literal(Int)
    case Negate(NumericExpression)
    case Epsilon
}

//: Declare curried functions for creating NumericExpressions as these work best
//: with the applicative operators we'll be using

let createExpression = curry(NumericExpression.Expression)
let createTerm = curry(NumericExpression.Term)
let createFactor = curry(NumericExpression.Factor)

let num_expr:MonadicParser<NumericExpression>
let expr = Parser.lazy(num_expr)


//: Now just start defining parsers for each line of the grammar starting at the bottom

let epsilon = Parser.success(NumericExpression.Epsilon)
let exp_op = Parser.char("^")
let div_op = Parser.char("/")
let mult_op = Parser.char("*")
let sub_op = Parser.char("-")
let plus_op = Parser.char("+")
let lparen = Parser.char("(")
let rparen = Parser.char(")")



let unaryPlus = plus_op *> expr
let unaryNegate = NumericExpression.Negate <§> (sub_op *> expr)
let literal = NumericExpression.Literal <§> Parser.natural
let identifier = NumericExpression.Identifier <§> Parser.identifier
let paren_expr = lparen *> expr <* rparen
let exp_operand = paren_expr <|> identifier <|> literal <|> unaryNegate <|> unaryPlus
let factor:MonadicParser<NumericExpression>
let exp_operand_tail = NumericExpression.ExponentOperandTail <§> (exp_op *> Parser.lazy(factor)) <|> epsilon
factor = createFactor <§> exp_operand <*> exp_operand_tail
let term:MonadicParser<NumericExpression>
let factor_tail = NumericExpression.MultiplyFactorTail <§> (mult_op *> Parser.lazy(term))
    <|> NumericExpression.DivideFactorTail <§> (div_op *> Parser.lazy(term))
    <|> epsilon
term = createTerm <§> factor <*> factor_tail
let term_tail = NumericExpression.AddTermTail <§> (plus_op *> expr)
    <|> NumericExpression.SubtactTermTail <§> (sub_op *> expr)
    <|> epsilon
num_expr = createExpression <§> term <*> term_tail




extension NumericExpression {
    func eval(withMemory store:[String:Int]) -> Int? {

        func combineExpressions(expr1:NumericExpression, _ expr2:NumericExpression) -> Int? {
            let e1 = expr1.eval(withMemory:store)
            return expr2.eval(withLeftHandSide:e1, andMemory:store)
        }

        switch self {
        case .Expression(let expr1, let expr2):
            return combineExpressions(expr1, expr2)

        case .Term(let expr1, let expr2):
            return combineExpressions(expr1, expr2)

        case .Factor(let expr1, let expr2):
            return combineExpressions(expr1, expr2)

        case .Identifier(let id):
            return store[id]

        case .Literal(let num):
            return num

        case .Negate(let expr):
            return { -$0 } <§> expr.eval(withMemory: store)


        case .AddTermTail(_), .SubtactTermTail(_), .MultiplyFactorTail(_), .DivideFactorTail(_),
        .ExponentOperandTail(_), .Epsilon:
            return nil

        }
    }
    func eval(withLeftHandSide accumulator:Int?, andMemory store:[String:Int]) -> Int? {
        func combineThreeExpressions(accumulator:Int?, _ expr1:NumericExpression, _ expr2:NumericExpression) -> Int? {
            return expr2.eval(withLeftHandSide: expr1.eval(withLeftHandSide: accumulator, andMemory: store), andMemory: store)
        }
        switch self {

        case .Identifier, .Literal, .Negate:
            return nil

        case .Expression(let expr1, let expr2):
            return combineThreeExpressions(accumulator, expr1, expr2)

        case .Term(let expr1, let expr2):
            return combineThreeExpressions(accumulator, expr1, expr2)

        case .Factor(let expr1, let expr2):
            return combineThreeExpressions(accumulator, expr1, expr2)


        case .AddTermTail(let expr):
            let sum:Int -> Int -> Int = { x in { y in x + y } }
            return sum <§> accumulator <*> expr.eval(withMemory: store)

        case .SubtactTermTail(let expr):
            let diff:Int -> Int -> Int = { x in { y in x - y } }
            return diff <§> accumulator <*> expr.eval(withMemory: store)

        case .MultiplyFactorTail(let expr):
            let product:Int -> Int -> Int = { x in { y in x * y } }
            return product <§> accumulator <*> expr.eval(withMemory: store)

        case .DivideFactorTail(let expr):
            let quotient:Int -> Int -> Int = { x in { y in x / y } }
            return quotient <§> accumulator <*> expr.eval(withMemory: store)

        case .ExponentOperandTail(let expr):
            let exp:Int -> Int -> Int = { x in { y in Int(pow(Double(x), Double(y))) } }
            return exp <§> accumulator <*> expr.eval(withMemory: store)

        case .Epsilon:
            return accumulator


        }
    }
}


let parsedExpression = num_expr.parse("(3 + 52) * 4 ")?.token

NumericExpression.eval <§> parsedExpression <*> [String:Int]()

