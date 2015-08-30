//: [Previous](@previous)

import Foundation
import Parsing

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

}


let reg_expr:MonadicParser<RegEx>
let expr = Parser.lazy(reg_expr)

let reg_char = Parser.satisfy { (c:Character) in
    c != "(" && c != ")" && c != "*" && c != "|"
}

let char_expr = reg_char.map(RegEx.Char)

let paren_expr_sequence = Parser.char("(").sequence(expr).secondToken.sequence(Parser.char(")")).firstToken

let paren_expr = paren_expr_sequence.map(RegEx.Paren)

let basic_expr = (paren_expr <|> char_expr).map(RegEx.Basic)
let basic_star = Parser.char("*").sequence(Parser.success(RegEx.BasicStar())).secondToken
let basic_epsilon = Parser.success(RegEx.BasicEpsilon())
let basic_expr_tail = basic_star.orElse(basic_epsilon)

let factor_sequence = basic_expr.sequence(basic_expr_tail).bothTokens
let factor = factor_sequence.map(RegEx.Factor)

let factor_tail:MonadicParser<RegEx>
let factor_tail_sequence = factor.sequence(Parser.lazy(factor_tail)).bothTokens
let factor_tail_continue = factor_tail_sequence.map(RegEx.FactorTailContinue)
let factor_tail_epsilon = Parser.success(RegEx.FactorTailEpsilon())
factor_tail = factor_tail_continue.orElse(factor_tail_epsilon)

let term_sequence = factor.sequence(factor_tail).bothTokens
let term = term_sequence.map(RegEx.Term)
let term_tail:MonadicParser<RegEx>
let term_tail_sequence = Parser.char("|").sequence(term).secondToken.sequence(Parser.lazy(term_tail)).bothTokens
let term_tail_continue = term_tail_sequence.map(RegEx.TermTailContinue)
let term_tail_epsilon = Parser.success(RegEx.TermTailEpsilon())
term_tail = term_tail_continue.orElse(term_tail_epsilon)

let reg_expr_sequence = term.sequence(term_tail).bothTokens
reg_expr = reg_expr_sequence.map(RegEx.Expr)


extension RegEx {

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

        case .FactorTailContinue(let r1, let r2):
            return r2.compileTail(withPrefix: r1.compile())

        case .FactorTailEpsilon():
            fatalError("f eps shouldn't be called")

        case .Factor(let r1, let r2):
            return r2.compileTail(withPrefix: r1.compile())

        case .BasicStar():
            fatalError("* is not a valid regular expression")

        case .BasicEpsilon(): fatalError("shouldn't be called")
        case .Basic(let r): return r.compile()
        case .Paren(let r): return r.compile()
        case .Char(let c): return Parser.string(String(c))

        }
    }

    func compileTail(withPrefix prefix:MonadicParser<String>) -> MonadicParser<String> {
        let concat:(String,String) -> String = { $0 + $1 }

        switch self {
        case .TermTailContinue(let r1, let r2):
            return prefix.orElse(r2.compileTail(withPrefix: r1.compile()))

        case .FactorTailContinue(let r1, let r2):
            let sequence = prefix.sequence(r2.compileTail(withPrefix: r1.compile())).bothTokens
            return sequence.map(concat)
            
        case .BasicStar():
            return prefix.repeatMany().join()
            
        case .BasicEpsilon(), .FactorTailEpsilon(), .TermTailEpsilon(): return prefix
            
        default:
            fatalError()
        }
    }

}


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
term.parse("a")!.token.compile().parse("a")

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


//: [Next](@next)
