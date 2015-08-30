//: [Previous](@previous)

import Foundation
import SwiftParsing

//: **Figure 1: The grammar for regular expressions**
//:
//:
//:     reg_expr         ::= term term_tail
//:     term_tail        ::= { | term term_tail } • ε
//:     term             ::= factor factor_tail
//:     factor_tail      ::= { factor factor_tail } • ε
//:     factor           ::= basic_expr basic_expr_tail
//:     basic_expr_tail  ::= * • ε
//:     basic_expr       ::= paren_expr • char_expr
//:     paren_expr       ::= ( reg_expr )
//:     char_expr        ::= "any charater except {'|','(',')','*'}"
//:
//: **Table 1: Examples of regular expressions and strings that they match.**
//:
//:     Pattern  Strings                              Notes
//:     -----------------------------------------------------------------------
//:     a        { a }                                Matches only "a"
//:     b        { b }                                Matches only "b"
//:     ab       { ab }                               Matches only "ab"
//:     a|b      { a, b }                             Matches "a" or "b"
//:     a*       { ε, a, aa, aaa, ... }               Matches an infinite set
//:     a(bc*)*d {ad, abd, abbd, abcd, abbcd, ... }   Matches an infinite set

//: We want a tree we can parse our results into. The RegEx enum
//: has cases for each production in the grammar.


indirect enum RegEx {
    case Expr(RegEx, RegEx)
    case TermTailContinue(RegEx, RegEx)
    case TermTailEpsilon()
    case Term(RegEx, RegEx)
    case FactorTailContinue(RegEx, RegEx)
    case FactorTailEpsilon()
    case Factor(RegEx, RegEx)
    case BasicStar()
    case BasicEpsilon()
    case Basic(RegEx)
    case Paren(RegEx)
    case Char(Character)

    static let createExpr = curry(Expr)
    static let createTermTailContinue = curry(TermTailContinue)
    static let createTerm = curry(Term)
    static let createFactorTailContinue = curry(FactorTailContinue)
    static let createFactor = curry(Factor)


    func compile() -> MonadicParser<String> {

        switch self {
        case .Expr(let r1, let r2):
            return r2.compileTail(withPrefix: r1.compile())

        case .TermTailContinue(let r1, let r2):
            return r2.compileTail(withPrefix: r1.compile())

        case .TermTailEpsilon():
            fatalError("t eps shouldn't be called")

        case .Term(let r1, let r2):
            return r2.compileTail(withPrefix: r1.compile())
            //return r2.isEpsilon ? r1.compile() : concat <§> r1.compile() <*> r2.compile()

        case .FactorTailContinue(let r1, let r2):
            return r2.compileTail(withPrefix: r1.compile())
            //return r2.isEpsilon ? r1.compile() : concat <§> r1.compile() <*> r2.compile()

        case .FactorTailEpsilon():
            fatalError("f eps shouldn't be called")

        case .Factor(let r1, let r2):
            return r2.compileTail(withPrefix: r1.compile())
            //return r2.isStar ? join <§> r1.compile().repeatMany() : r1.compile()

        case .BasicStar():
            fatalError("* is not a valid regular expression")

        case .BasicEpsilon(): fatalError("shouldn't be called")
        case .Basic(let r): return r.compile()
        case .Paren(let r): return r.compile()
        case .Char(let c): return Parser.string(String(c))

        }
    }

    func compileTail(withPrefix prefix:MonadicParser<String>) -> MonadicParser<String> {
        let concat = { (s1:String) in { s1 + $0 } }

        switch self {
        case .TermTailContinue(let r1, let r2):
            return prefix <|> r2.compileTail(withPrefix: r1.compile())

        case .FactorTailContinue(let r1, let r2):
            return concat <§> prefix <*> r2.compileTail(withPrefix: r1.compile())

        case .BasicStar():
            return prefix.repeatMany().join()

        case .BasicEpsilon(), .FactorTailEpsilon(), .TermTailEpsilon(): return prefix

        default:
            fatalError()
        }
    }


}


let reg_expr:MonadicParser<RegEx>
//let term:MonadicParser<RegEx>
let expr = Parser.lazy(reg_expr)

let reg_char = Parser.satisfy { (c:Character) in
    c != "(" && c != ")" && c != "*" && c != "|"
}


let char_expr = RegEx.Char <§> reg_char

let paren_expr = RegEx.Paren <§> (Parser.char("(") *> expr <* Parser.char(")"))

let basic_expr = RegEx.Basic <§> (paren_expr <|> char_expr)
let basic_star = Parser.char("*") *> Parser.success(RegEx.BasicStar())
let basic_epsilon = Parser.success(RegEx.BasicEpsilon())
let basic_expr_tail = basic_star <|> basic_epsilon


let factor = RegEx.createFactor <§> basic_expr <*> basic_expr_tail
let factor_tail:MonadicParser<RegEx>
let factor_tail_continue = RegEx.createFactorTailContinue <§> factor <*> Parser.lazy(factor_tail)
let factor_tail_epsilon = Parser.success(RegEx.FactorTailEpsilon())
factor_tail = factor_tail_continue <|> factor_tail_epsilon

let term = RegEx.createTerm <§> factor <*> factor_tail
let term_tail:MonadicParser<RegEx>
let term_tail_continue = RegEx.createTermTailContinue <§> (Parser.char("|") *> term) <*>
    Parser.lazy(term_tail)
let term_tail_epsilon = Parser.success(RegEx.TermTailEpsilon())
term_tail = term_tail_continue <|> term_tail_epsilon

reg_expr = RegEx.createExpr <§> term <*> term_tail



func compile(s:String)->MonadicParser<String> {
    let regex = reg_expr.parse(s)?.token
    if let regex = regex {
        return regex.compile()
    } else {
        return Parser.failure()
    }
}

func runParser(p:MonadicParser<String>)(_ s:String) -> String {
    return p.parse(s)!.token
}


// char expr
var p = compile("a")
runParser(p)("a")
p.parse("b")

// concat expr
p = compile("ab")
p.parse("a")
p.parse("ab")

// paren expr
p = compile("(c)")
p.parse("cd")

// repeat expr
p = compile("a*")
p.parse("aaaa")

// repeat paren
p = compile("(a)*")
print(reg_expr.parse("(a)*")!.token)

p.parse("aaaa")
p.parse("bbbcd")

// regex 7
p = compile("a(b)*a")
p.parse("aa")
p.parse("aba")
p.parse("abbbbac")

// regex 8
p = compile("a|b|c")
p.parse("abc")
p.parse("cd")
p.parse("ba")

// repeat again
p = compile("ab*|b*")
p.parse("abbbbg")?.token

// or
let r = reg_expr.parse("a|b")!.token
p = compile("a|b")
p.parse("b")

//reg_expr.parse("ab*|b*")!.token.description




//: [Next](@next)
