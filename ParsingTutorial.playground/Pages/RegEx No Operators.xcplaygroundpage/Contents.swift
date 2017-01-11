//: [Previous](@previous)

import Cocoa
import SwiftParsing

print("hello")

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
    case expr(RegEx, RegEx)
    case termTailContinue(RegEx, RegEx)
    case termTailEpsilon()
    case term(RegEx, RegEx)
    case factorTailContinue(RegEx, RegEx)
    case factorTailEpsilon()
    case factor(RegEx, RegEx)
    case basicStar()
    case basicEpsilon()
    case basic(RegEx)
    case paren(RegEx)
    case char(Character)
}

typealias P = Parser

var reg_expr:ParserOf<RegEx>! = nil
let expr = Parser.lazy(reg_expr)

let reg_char = Parser.satisfy { (c:Character) in
    c != "(" && c != ")" && c != "*" && c != "|"
}

let char_expr = reg_char.map(RegEx.char)

let paren_expr_sequence = P.sequence(P.char("("), expr, P.char(")")) { $0.1 }

let paren_expr = paren_expr_sequence.map(RegEx.paren)

let basic_expr = (paren_expr <|> char_expr).map(RegEx.basic)
let basic_star = P.sequence(P.char("*"), P.success(RegEx.basicStar())) { $0.1 }
let basic_epsilon = Parser.success(RegEx.basicEpsilon())
let basic_expr_tail = basic_star.orElse(basic_epsilon)

let factor_sequence = P.sequence(basic_expr, basic_expr_tail) { ($0,$1) }
let factor = factor_sequence.map(RegEx.factor)

var factor_tail:ParserOf<RegEx>! = nil
let factor_tail_sequence = P.sequence(factor, P.lazy(factor_tail)) { ($0, $1) }
let factor_tail_continue = factor_tail_sequence.map(RegEx.factorTailContinue)
let factor_tail_epsilon = Parser.success(RegEx.factorTailEpsilon())
factor_tail = factor_tail_continue.orElse(factor_tail_epsilon)

let term_sequence = P.sequence(factor, factor_tail) { ($0,$1) }
let term = term_sequence.map(RegEx.term)
var term_tail:ParserOf<RegEx>! = nil
let term_tail_sequence = P.sequence(P.char("|"), term, P.lazy(term_tail)) { ($1, $2) }
let term_tail_continue = term_tail_sequence.map(RegEx.termTailContinue)
let term_tail_epsilon = Parser.success(RegEx.termTailEpsilon())
term_tail = term_tail_continue.orElse(term_tail_epsilon)

let reg_expr_sequence = P.sequence(term, term_tail) { ($0,$1) }
reg_expr = reg_expr_sequence.map(RegEx.expr)

extension RegEx {
    func compile() -> ParserOf<String> {

        switch self {
        case .expr(let r1, let r2):
            return r2.compileTail(withPrefix: r1.compile())

        case .termTailContinue(let r1, let r2):
            return r2.compileTail(withPrefix: r1.compile())

        case .termTailEpsilon():
            fatalError("t eps shouldn't be called")

        case .term(let r1, let r2):
            return r2.compileTail(withPrefix: r1.compile())

        case .factorTailContinue(let r1, let r2):
            return r2.compileTail(withPrefix: r1.compile())

        case .factorTailEpsilon():
            fatalError("f eps shouldn't be called")

        case .factor(let r1, let r2):
            return r2.compileTail(withPrefix: r1.compile())

        case .basicStar():
            fatalError("* is not a valid regular expression")

        case .basicEpsilon(): fatalError("shouldn't be called")
        case .basic(let r): return r.compile()
        case .paren(let r): return r.compile()
        case .char(let c): return Parser.string(String(c))
            
        }
    }

    func compileTail(withPrefix prefix:ParserOf<String>) -> ParserOf<String> {

        switch self {
        case .termTailContinue(let r1, let r2):
            return prefix.orElse(r2.compileTail(withPrefix: r1.compile()))

        case .factorTailContinue(let r1, let r2):
            let sequence = P.sequence(prefix, r2.compileTail(withPrefix: r1.compile())) {
                ($0,$1)
            }
            return sequence.map(+)

        case .basicStar():
            return prefix.repeatMany().join()

        case .basicEpsilon(), .factorTailEpsilon(), .termTailEpsilon(): return prefix

        default:
            fatalError()
        }
    }
}

func compile(_ s:String)->ParserOf<String> {
    let regex = reg_expr.parse(s)?.token
    if let regex = regex {
        return regex.compile()
    } else {
        return Parser.failure()
    }
}

func runParser(_ p:ParserOf<String>) -> ((String) -> String) {
    return { s in p.parse(s)!.token }
}

//: Asserts equality but also prints the error to the console
func assertEqual(_ result:@autoclosure() -> (String,String)?, _ expected:(String,String)?,
                 file: StaticString = #file, line: UInt = #line) -> (String,String)? {
    let actual = result()
    let equal:(String,String)->(String,String)->Bool = { lhs in { rhs in lhs == rhs } }
    if (actual == nil && expected == nil) {
        return actual
    }
    let comparison = equal <§> actual <*> expected

    if let areEqual = comparison, areEqual  {
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

