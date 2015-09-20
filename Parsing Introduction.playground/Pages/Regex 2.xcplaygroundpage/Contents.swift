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

indirect enum RegEx {
    case Expr(RegEx, RegEx)
    case Term(RegEx, RegEx)
    case Factor(RegEx, RegEx)
    case Repeat
    case Paren(RegEx)
    case Char(Character)
    case Epsilon()
}


//: Concatenate the strings and return the result
//: For example:
//:
//:     join(["foo", "bar", "baz"]) // "foobarbaz"
func join<S:SequenceType where S.Generator.Element==String>(strings:S) -> String {
    return strings.joinWithSeparator("")
}
//: A curried function that accepts two String values, concatenates them
//: together and returns the result. For example:
//:
//:     concat("foo")("bar") // "foobar"
let concat:String -> String -> String = { x in { x + $0 }}


let createExpr = curry(RegEx.Expr)
let createTerm = curry(RegEx.Term)
let createFactor = curry(RegEx.Factor)


let or = Parsers.char("|").void()
let star = Parsers.char("*") *> Parsers.success(RegEx.Repeat)
let lparen = Parsers.char("(").void()
let rparen = Parsers.char(")").void()
let epsilon = Parsers.success(RegEx.Epsilon())

let regchar = Parsers.satisfy { (c:Character) in
    c != "(" && c != ")" && c != "*" && c != "|"
}

let reg_expr:ParserOf<RegEx>
let expr=Parsers.lazy(reg_expr)

let char_expr = RegEx.Char <§> regchar
let paren_expr = RegEx.Paren <§> (lparen *> expr) <* rparen
let basic_expr = paren_expr <|> char_expr
let basic_expr_tail = star <|> epsilon
let factor = createFactor <§> basic_expr <*> basic_expr_tail
let factor_tail:ParserOf<RegEx>
let term:ParserOf<RegEx>
factor_tail = Parsers.lazy(term) <|> epsilon
term = createTerm <§> factor <*> factor_tail
let term_tail:ParserOf<RegEx>
term_tail = createExpr <§> (or *> term) <*> Parsers.lazy(term_tail) <|> epsilon
reg_expr = createExpr <§> term <*> term_tail

extension RegEx {
    var isStar:Bool {
        switch self {
        case .Repeat: return true
        default: return false
        }
    }
    var isEpsilon:Bool {
        if case Epsilon() = self {
            return true
        }
        return false
    }

    func compile() -> ParserOf<String> {
        switch self {
        case .Expr(let r1, let r2):
            let r1Parser = r1.compile()
            return r2.isEpsilon ?  r1Parser : r1Parser <|> r2.compile()
        case .Term(let r1, let r2):
            return concat <§> r1.compile() <*> r2.compile()
        case .Factor(let r1, let r2):
            let r1Parser = r1.compile()
            return r2.isStar ? join <§> r1Parser.repeatMany() : r1Parser
        case .Repeat: return Parsers.failure() // shouldn't be reached
        case .Paren(let r): return r.compile()
        case .Char(let c): return Parsers.char(c).map { String.init($0) }
        case .Epsilon: return Parsers.success("")
        }
    }

    var description:String {
        switch self {
        case .Expr(let r1, let r2): return r1.description + (r2.isEpsilon ? "" : "|\(r2.description)")
        case .Term(let r1, let r2): return r1.description + r2.description
        case .Factor(let r1, let r2): return r1.description + r2.description
        case .Repeat: return "*"
        case .Paren(let r): return "(\(r.description))"
        case .Char(let c): return String(c)
        case .Epsilon(): return ""
        }
    }
}

func compile(s:String)->ParserOf<String> {
    let regex = reg_expr.parse(s)?.token
    if let regex = regex {
        return regex.compile()
    } else {
        return Parsers.failure()
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
