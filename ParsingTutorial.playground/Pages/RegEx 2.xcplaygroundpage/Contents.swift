//: [Previous](@previous)

import Foundation
import SwiftParsing

//: **Figure 1: The grammar for regular expressions**
//:
//:
//:     reg_expr         ::= term term_tail
//:     term_tail        ::= { | term term_tail } • ε
//:     term             ::= factor factor_tail
//:     factor_tail      ::= { term } • ε
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
//: has cases for each production in the grammar. We could eliminated cases for
//: term_tail, factor_tail, basic_expr_tail, paren_expr and basic.
//: term_tail can be eliminated because it's results can be stored in an Expr or Epsilon
//: Likewise, factor_tail, can be stored as a Term or Epsilon.
//: basic_expr_tail can be stored as a Repeat or Epsilon
//: basic can be stored as a Paren or Char
//: paren_expr can just return whatever reg_expr returns.

print("I ran")

indirect enum RegEx {
    case expr(RegEx, RegEx)
    case term(RegEx, RegEx)
    case factor(RegEx, RegEx)
    case rept
    case paren(RegEx)
    case char(Character)
    case epsilon()
}



//: Concatenate the strings and return the result
//: For example:
//:
//:     join(["foo", "bar", "baz"]) // "foobarbaz"
func join<S:Sequence>(strings:S) -> String where S.Iterator.Element==String {
    return strings.joined(separator: "")
}
//: A curried function that accepts two String values, concatenates them
//: together and returns the result. For example:
//:
//:     concat("foo")("bar") // "foobar"
let concat:(String)-> (String) -> String = { x in { x + $0 }}


let createExpr = curry(RegEx.expr)
let createTerm = curry(RegEx.term)
let createFactor = curry(RegEx.factor)


let or = Parser.char("|").void()
let star = Parser.char("*") *> Parser.success(RegEx.rept)
let lparen = Parser.char("(").void()
let rparen = Parser.char(")").void()
let epsilon = Parser.success(RegEx.epsilon())

let regchar = Parser.satisfy { (c:Character) in
    c != "(" && c != ")" && c != "*" && c != "|"
}

var reg_expr:ParserOf<RegEx>! = nil
let expr=Parser.lazy(reg_expr)

let char_expr = RegEx.char <§> regchar
let paren_expr = RegEx.paren <§> (lparen *> expr) <* rparen
let basic_expr = paren_expr <|> char_expr
let basic_expr_tail = star <|> epsilon
let factor = createFactor <§> basic_expr <*> basic_expr_tail
let factor_tail:ParserOf<RegEx>
var term:ParserOf<RegEx>! = nil

factor_tail = Parser.lazy(term) <|> epsilon
term = createTerm <§> factor <*> factor_tail
var term_tail:ParserOf<RegEx>! = nil
term_tail = createExpr <§> (or *> term) <*> Parser.lazy(term_tail) <|> epsilon
reg_expr = createExpr <§> term <*> term_tail

extension RegEx {
    var isStar:Bool {
        switch self {
        case .rept: return true
        default: return false
        }
    }
    var isEpsilon:Bool {
        if case .epsilon() = self {
            return true
        }
        return false
    }

    func compile() -> ParserOf<String> {
        switch self {
        case .expr(let r1, let r2):
            let r1Parser = r1.compile()
            return r2.isEpsilon ?  r1Parser : r1Parser <|> r2.compile()
        case .term(let r1, let r2):
            return concat <§> r1.compile() <*> r2.compile()
        case .factor(let r1, let r2):
            let r1Parser = r1.compile()
            return r2.isStar ? join <§> r1Parser.repeatMany() : r1Parser
        case .rept: return Parser.failure() // shouldn't be reached
        case .paren(let r): return r.compile()
        case .char(let c): return Parser.char(c).map { String.init($0) }
        case .epsilon: return Parser.success("")
        }
    }

    var description:String {
        switch self {
        case .expr(let r1, let r2): return r1.description + (r2.isEpsilon ? "" : "|\(r2.description)")
        case .term(let r1, let r2): return r1.description + r2.description
        case .factor(let r1, let r2): return r1.description + r2.description
        case .rept: return "*"
        case .paren(let r): return "(\(r.description))"
        case .char(let c): return String(c)
        case .epsilon(): return ""
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
    return {s in p.parse(s)!.token}
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


