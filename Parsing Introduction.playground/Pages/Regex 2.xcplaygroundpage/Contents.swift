//: [Previous](@previous)

import Foundation
import Parsing

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


let or = Parser.char("|").void()
let star = Parser.char("*") *> Parser.success(RegEx.Repeat)
let lparen = Parser.char("(").void()
let rparen = Parser.char(")").void()
let epsilon = Parser.success(RegEx.Epsilon())

let regchar = Parser.satisfy { (c:Character) in
    c != "(" && c != ")" && c != "*" && c != "|"
}

let reg_expr:MonadicParser<RegEx>
let expr=Parser.lazy(reg_expr)

let char_expr = RegEx.Char <§> regchar
let paren_expr = RegEx.Paren <§> (lparen *> expr) <* rparen
let basic_expr = paren_expr <|> char_expr
let basic_expr_tail = star <|> epsilon
let factor = createFactor <§> basic_expr <*> basic_expr_tail
let factor_tail:MonadicParser<RegEx>
let term:MonadicParser<RegEx>
factor_tail = Parser.lazy(term) <|> epsilon
term = createTerm <§> factor <*> factor_tail
let term_tail:MonadicParser<RegEx>
term_tail = createExpr <§> (or *> term) <*> Parser.lazy(term_tail) <|> epsilon
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

    func compile() -> MonadicParser<String> {
        switch self {
        case .Expr(let r1, let r2):
            let r1Parser = r1.compile()
            return r2.isEpsilon ?  r1Parser : r1Parser <|> r2.compile()
        case .Term(let r1, let r2):
            return concat <§> r1.compile() <*> r2.compile()
        case .Factor(let r1, let r2):
            let r1Parser = r1.compile()
            return r2.isStar ? join <§> r1Parser.repeatMany() : r1Parser
        case .Repeat: return Parser.failure() // shouldn't be reached
        case .Paren(let r): return r.compile()
        case .Char(let c): return Parser.char(c).map { String.init($0) }
        case .Epsilon: return Parser.success("")
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

// paren expr
p = compile("(c)")
p.parse("cd")

// repeat expr
p = compile("a*")
p.parse("aaaa")

// repeat paren
p = compile("(a)*")
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
p.parse("abbbg")?.token

// or
let r = reg_expr.parse("a|b")!.token
p = compile("a|b")
p.parse("b")

reg_expr.parse("ab*|b*")!.token.description


//: [Next](@next)
