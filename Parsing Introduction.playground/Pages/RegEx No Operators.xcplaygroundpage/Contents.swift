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

}

typealias P = Parser

let reg_expr:ParserOf<RegEx>
let expr = Parser.lazy(reg_expr)

let reg_char = Parser.satisfy { (c:Character) in
    c != "(" && c != ")" && c != "*" && c != "|"
}

let char_expr = reg_char.map(RegEx.Char)

let paren_expr_sequence = P.sequence(P.char("("), expr, P.char(")")) { $0.1 }

let paren_expr = paren_expr_sequence.map(RegEx.Paren)

let basic_expr = (paren_expr <|> char_expr).map(RegEx.Basic)
let basic_star = P.sequence(P.char("*"), P.success(RegEx.BasicStar())) { $0.1 }
let basic_epsilon = Parser.success(RegEx.BasicEpsilon())
let basic_expr_tail = basic_star.orElse(basic_epsilon)

let factor_sequence = P.sequence(basic_expr, basic_expr_tail) { ($0,$1) }
let factor = factor_sequence.map(RegEx.Factor)

let factor_tail:ParserOf<RegEx>
let factor_tail_sequence = P.sequence(factor, P.lazy(factor_tail)) { ($0, $1) }
let factor_tail_continue = factor_tail_sequence.map(RegEx.FactorTailContinue)
let factor_tail_epsilon = Parser.success(RegEx.FactorTailEpsilon())
factor_tail = factor_tail_continue.orElse(factor_tail_epsilon)

let term_sequence = P.sequence(factor, factor_tail) { ($0,$1) }
let term = term_sequence.map(RegEx.Term)
let term_tail:ParserOf<RegEx>
let term_tail_sequence = P.sequence(P.char("|"), term, P.lazy(term_tail)) { ($1, $2) }
let term_tail_continue = term_tail_sequence.map(RegEx.TermTailContinue)
let term_tail_epsilon = Parser.success(RegEx.TermTailEpsilon())
term_tail = term_tail_continue.orElse(term_tail_epsilon)

let reg_expr_sequence = P.sequence(term, term_tail) { ($0,$1) }
reg_expr = reg_expr_sequence.map(RegEx.Expr)


extension RegEx {

    func compile() -> ParserOf<String> {

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

    func compileTail(withPrefix prefix:ParserOf<String>) -> ParserOf<String> {

        switch self {
        case .TermTailContinue(let r1, let r2):
            return prefix.orElse(r2.compileTail(withPrefix: r1.compile()))

        case .FactorTailContinue(let r1, let r2):
            let sequence = P.sequence(prefix, r2.compileTail(withPrefix: r1.compile())) {
                ($0,$1)
            }
            return sequence.map(+)
            
        case .BasicStar():
            return prefix.repeatMany().join()
            
        case .BasicEpsilon(), .FactorTailEpsilon(), .TermTailEpsilon(): return prefix
            
        default:
            fatalError()
        }
    }

}


func compile(s:String)->ParserOf<String> {
    let regex = reg_expr.parse(s)?.token
    if let regex = regex {
        return regex.compile()
    } else {
        return Parser.failure()
    }
}

func runParser(p:ParserOf<String>)(_ s:String) -> String {
    return p.parse(s)!.token
}


func ==<A,B where A:Equatable, B:Equatable>(lhs:(A,B), rhs:(A,B)) -> Bool {
    return lhs.0 == rhs.0 && lhs.1 == rhs.1
}

func assertEqual(@autoclosure result:() -> (String,String)?, _ expected:(String,String)?,
    file: String = __FILE__, line: UInt = __LINE__) -> (String,String)? {
        let actual = result()
        let equal:(String,String)->(String,String)->Bool = { lhs in { lhs == $0 } }

        if (actual == nil && expected == nil) {
            return actual
        }

        let comparison = equal <§> actual <*> expected
        if let areEqual = comparison where areEqual {
            return actual
        }

        print("Error: \(actual) != \(expected) on line:\(line)")
        return actual
}

// char expr
var p = compile("a")
runParser(p)("a")
assertEqual(p.parse("a"), ("a",""))
assertEqual(p.parse("abc"), ("a","bc"))
assertEqual(p.parse("b"), nil)

// concat expr
p = compile("ab")
assertEqual(p.parse("a"), nil)
assertEqual(p.parse("ab"), ("ab",""))

// paren expr
p = compile("(c)")
assertEqual(p.parse("cd"), ("c","d"))

// repeat expr
p = compile("a*")
assertEqual(p.parse("aaaa"), ("aaaa",""))

// repeat paren
p = compile("(a)*")
assertEqual(p.parse("aaaa"), ("aaaa",""))
assertEqual(p.parse("bbbcd"), ("","bbbcd"))

// regex 7
p = compile("a(b)*a")
assertEqual(p.parse("aa"), ("aa",""))
assertEqual(p.parse("aba"), ("aba",""))
assertEqual(p.parse("abbbbac"), ("abbbba","c"))

p = compile("a(bc*)*a")
assertEqual(p.parse("aa"), ("aa",""))
assertEqual(p.parse("aba"), ("aba",""))
assertEqual(p.parse("abbbbccccbcba"), ("abbbbccccbcba",""))

// regex 8
p = compile("a|b|c")
assertEqual(p.parse("abc"), ("a","bc"))
assertEqual(p.parse("cd"), ("c","d"))
assertEqual(p.parse("ba"), ("b","a"))

// repeat again
p = compile("ab*|b*")
assertEqual(p.parse("abbbg"), ("abbb","g"))



//: [Next](@next)
