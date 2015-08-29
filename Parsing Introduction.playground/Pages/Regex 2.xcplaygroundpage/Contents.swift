//: [Previous](@previous)

import Foundation
import Parsing

//: **Figure 1: The grammar for regular expressions**
//:
//:     regexpr    ::= orexpr
//:     orexpr     ::= concatexpr { { | orexpr } • ε }
//:     concatexpr ::= repeatexpr { concatexpr • ε}
//:     repeatexpr ::= basicexpr { * • ε }
//:     basicexpr  ::= parenexpr • charexpr
//:     parenexpr  ::= ( regexpr )
//:     charexpr   ::= regchar
//:     regchar    ::= "any character except {'|','(',')','*'}"
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

indirect enum RegEx {
    case Expr(RegEx, RegEx)
    case TermTail(RegEx, RegEx) // Used only for the | case, else it's Epsilon
    case Term(RegEx, RegEx)
    // No case for FactorTail. It's either a Factor or Epsilon
    case Factor(RegEx, RegEx)
    // No case for basic expr tail. It's either a Repeat or Epsilon
    // No case for basic. It's either a paren expr or a char expr
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
let createTermTail = curry(RegEx.TermTail)
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
factor_tail = createFactor <§> factor <*> Parser.lazy(factor_tail) <|> epsilon
let term = createTerm <§> factor <*> factor_tail
let term_tail:MonadicParser<RegEx>
term_tail = createTermTail <§> (or *> term) <*> Parser.lazy(term_tail) <|> epsilon
reg_expr = createExpr <§> term <*> term_tail

extension RegEx {
    var isStar:Bool {
        switch self {
        case .Repeat: return true
        default: return false
        }
    }
    var isTermTail:Bool {
        switch self {
        case .TermTail(_): return true
        default: return false
        }
    }
    func compile() -> MonadicParser<String> {
        switch self {
        case .Expr(let r1, let r2):
            let r1Parser = r1.compile()
            return r2.isTermTail ? r1Parser <|> r2.compile() : r1Parser
        case .TermTail(let r1, let r2):
            let r1Parser = r1.compile()
            return r2.isTermTail ? r1Parser <|> r2.compile() : r1Parser
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
p.parse("abbbbg")?.token

// or
let r = reg_expr.parse("a|b")!.token
print(r)
p = compile("a|b")
p.parse("b")

print(epsilon.parse("b")!.token)

//: [Next](@next)
