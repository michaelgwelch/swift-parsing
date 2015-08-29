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
//:     term_tail        ::= plus_op term term_tail
//:                        | sub_op term term_tail
//:                        | epsilon
//:     term             ::= factor factor_tail
//:     factor_tail      ::= mult_op factor factor_tail
//:                        | div_op factor factor_tail
//:                        | epsilon
//:     factor           ::= basic basic_tail
//:     basic_tail       ::= exp_op basic basic_tail
//:                        | epsilon
//:     basic            ::= ( expr )
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
    case AddTermTail(NumericExpression, NumericExpression)
    case SubtractTermTail(NumericExpression, NumericExpression)
    case Term(NumericExpression, NumericExpression)
    case MultiplyFactorTail(NumericExpression, NumericExpression)
    case DivideFactorTail(NumericExpression, NumericExpression)
    case Factor(NumericExpression, NumericExpression)
    case BasicTail(NumericExpression, NumericExpression)
    case Paren(NumericExpression)
    case Identifier(String)
    case Literal(Int)
    case Negate(NumericExpression)
    case Epsilon
}

//: Declare curried functions for creating NumericExpressions as these work best
//: with the applicative operators we'll be using

let createExpression = curry(NumericExpression.Expression)
let createAdd = curry(NumericExpression.AddTermTail)
let createSub = curry(NumericExpression.SubtractTermTail)
let createTerm = curry(NumericExpression.Term)
let createMult = curry(NumericExpression.MultiplyFactorTail)
let createDiv = curry(NumericExpression.DivideFactorTail)
let createFactor = curry(NumericExpression.Factor)
let createBasic = curry(NumericExpression.BasicTail)

let num_expr:MonadicParser<NumericExpression>
let expr = Parser.lazy(num_expr)


//: Now just start defining parsers for each line of the grammar starting at the bottom

let epsilon = Parser.success(NumericExpression.Epsilon)
let exp_op = Parser.char("^").token()
let div_op = Parser.char("/").token()
let mult_op = Parser.char("*").token()
let sub_op = Parser.char("-").token()
let plus_op = Parser.char("+").token()
let lparen = Parser.char("(").token()
let rparen = Parser.char(")").token()



let unaryPlus = plus_op *> expr
let unaryNegate = NumericExpression.Negate <§> (sub_op *> expr)
let literal = NumericExpression.Literal <§> Parser.natural
let identifier = NumericExpression.Identifier <§> Parser.identifier
let paren_expr = NumericExpression.Paren <§> (lparen *> expr) <* rparen
let basic = paren_expr <|> identifier <|> literal <|> unaryNegate <|> unaryPlus
let basic_tail:MonadicParser<NumericExpression>
basic_tail = createBasic <§> (exp_op *> basic) <*> Parser.lazy(basic_tail) <|> epsilon
let factor = createFactor <§> basic <*> basic_tail
let factor_tail:MonadicParser<NumericExpression>
factor_tail = createMult <§> (mult_op *> factor) <*> Parser.lazy(factor_tail)
    <|> createDiv <§> (div_op *> factor) <*> Parser.lazy(factor_tail)
    <|> epsilon
let term = createTerm <§> factor <*> factor_tail
let term_tail:MonadicParser<NumericExpression>
term_tail = createAdd <§> (plus_op *> term) <*> Parser.lazy(term_tail)
    <|> createSub <§> (sub_op *> term) <*> Parser.lazy(term_tail)
    <|> epsilon
num_expr = createExpression <§> term <*> term_tail




extension NumericExpression {
    static func eval(expr1:NumericExpression, inExpression expr2:NumericExpression, withStore store:[String:Int]) -> Int? {
        let e1 = expr1.eval(withMemory:store)
        return expr2.eval(withLeftHandSide:e1, andMemory:store)
    }

    func eval(withMemory store:[String:Int]) -> Int? {

        switch self {
        case .Expression(let expr1, let expr2):
            return NumericExpression.eval(expr1, inExpression: expr2, withStore:store)

        case .Term(let expr1, let expr2):
            return NumericExpression.eval(expr1, inExpression: expr2, withStore:store)

        case .Factor(let expr1, let expr2):
            return NumericExpression.eval(expr1, inExpression: expr2, withStore:store)

        case .Paren(let e):
            return e.eval(withMemory: store)

        case .Identifier(let id):
            return store[id]

        case .Literal(let num):
            return num

        case .Negate(let expr):
            return { -$0 } <§> expr.eval(withMemory: store)


        case .AddTermTail(_), .SubtractTermTail(_), .MultiplyFactorTail(_), .DivideFactorTail(_),
        .BasicTail(_), .Epsilon:
            return nil

        }
    }

    func eval(withLeftHandSide accumulator:Int?, andMemory store:[String:Int]) -> Int? {

        switch self {

        case .Expression(_), .Term(_), .Factor(_), .Paren(_), .Identifier, .Literal, .Negate:
            return nil

        case .AddTermTail(let expr1, let expr2):
            let sum:Int -> Int -> Int = { x in { y in x + y } }
            return sum <§> accumulator <*> NumericExpression.eval(expr1, inExpression: expr2, withStore: store)

        case .SubtractTermTail(let expr1, let expr2):
            let diff:Int -> Int -> Int = { x in { y in x - y } }
            return diff <§> accumulator <*> NumericExpression.eval(expr1, inExpression: expr2, withStore: store)

        case .MultiplyFactorTail(let expr1, let expr2):
            let product:Int -> Int -> Int = { x in { y in x * y } }
            return product <§> accumulator <*> NumericExpression.eval(expr1, inExpression: expr2, withStore: store)

        case .DivideFactorTail(let expr1, let expr2):
            let quotient:Int -> Int -> Int = { x in { y in x / y } }
            return quotient <§> accumulator <*> NumericExpression.eval(expr1, inExpression: expr2, withStore: store)

        case .BasicTail(let expr1, let expr2):
            let exp:Int -> Int -> Int = { x in { y in Int(pow(Double(x), Double(y))) } }
            return exp <§> accumulator <*> NumericExpression.eval(expr1, inExpression: expr2, withStore: store)

        case .Epsilon:
            return accumulator


        }
    }

    var graph : String {
        switch self {
        case .Expression(let e1, let e2): return "Expression(\(e1.graph), \(e2.graph))"
        case .AddTermTail(let e1, let e2): return "AddTermTail(\(e1.graph), \(e2.graph))"
        case .SubtractTermTail(let e1, let e2): return "SubtractTermTail(\(e1.graph), \(e2.graph))"
        case .Term(let e1, let e2): return "Term(\(e1.graph), \(e2.graph))"
        case .MultiplyFactorTail(let e1, let e2): return "MultiplyFactorTail(\(e1.graph), \(e2.graph))"
        case .DivideFactorTail(let e1, let e2): return "DivideFactorTail(\(e1.graph), \(e2.graph))"
        case .Factor(let e1, let e2): return "Factor(\(e1.graph), \(e2.graph))"
        case .BasicTail(let e1, let e2): return "ExponentOperandTail(\(e1.graph), \(e2.graph))"
        case .Paren(let e): return "Paren(\(e.graph))"
        case .Identifier(let s): return "\"\(s)\""
        case .Literal(let n): return String(n)
        case .Negate(let n): return "Negate(\(n))"
        case .Epsilon: return "𝜖"

        }
    }


    var description : String {
        switch self {
        case .Expression(let e1, let e2): return e1.description + e2.description
        case .AddTermTail(let e1, let e2): return "+" + e1.description + e2.description
        case .SubtractTermTail(let e1, let e2): return "-" + e1.description + e2.description
        case .Term(let e1, let e2): return e1.description + e2.description
        case .MultiplyFactorTail(let e1, let e2): return "*" + e1.description + e2.description
        case .DivideFactorTail(let e1, let e2): return "/" + e1.description + e2.description
        case .Factor(let e1, let e2): return e1.description + e2.description
        case .BasicTail(let e1, let e2): return "^" + e1.description + e2.description
        case .Paren(let e): return "(\(e.description))"
        case .Identifier(let s): return s
        case .Literal(let n): return n.description
        case .Negate(let e): return "-" + e.description
        case .Epsilon: return ""
        }
    }
}


let result = num_expr.parse("(8 + 4) * 12")!
let parsedExpression = result.token
print(parsedExpression.description)
print(result.output)

print(parsedExpression.graph)

NumericExpression.eval <§> parsedExpression <*> [String:Int]()

