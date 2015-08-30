//
//  TestRegex.swift
//  Parsing
//
//  Created by Michael Welch on 8/29/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation
import XCTest

//: [Previous](@previous)

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
//: has cases for each production in the grammar. We could eliminated cases for
//: term_tail, factor_tail, basic_expr_tail, paren_expr and basic.
//: term_tail can be eliminated because it's results can be stored in an Expr or Epsilon
//: Likewise, factor_tail, can be stored as a Term or Epsilon.
//: basic_expr_tail can be stored as a Repeat or Epsilon
//: basic can be stored as a Paren or Char
//: paren_expr can just return whatever reg_expr returns.

func join<S:SequenceType where S.Generator.Element==String>(strings:S) -> String {
    return strings.joinWithSeparator("")
}

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

    var isStar:Bool {
        if case BasicStar = self {
            return true
        }
        return false;
    }


    func compile() -> MonadicParser<String> {
        let epsilon = Parser.success("")
        let concat = { (s1:String) in { s1 + $0 } }

        switch self {
        case .Expr(let r1, let r2):
            return r1.compile() <|> r2.compile()
        case .TermTailContinue(let r1, let r2): return r1.compile() <|> r2.compile()
        case .TermTailEpsilon(): return epsilon
        case .Term(let r1, let r2): return concat <§> r1.compile() <*> r2.compile()
        case .FactorTailContinue(let r1, let r2): return concat <§> r1.compile() <*> r2.compile()
        case .FactorTailEpsilon(): return epsilon
        case .Factor(let r1, let r2):
            return r2.isStar ? join <§> r1.compile().repeatMany() : r1.compile()
        case .BasicStar(): fatalError("* is not a valid regular expression")
        case .BasicEpsilon(): return epsilon
        case .Basic(let r): return r.compile()
        case .Paren(let r): return r.compile()
        case .Char(let c): return Parser.string(String(c))

        }
    }

    var compileExpression:String {
        let epsilon = "epsilon"
        let concat = "concat"

        switch self {
        case.Expr(let r1, let r2):
            return "(\(r1.compileExpression)) <|> (\(r2.compileExpression))"
        case .TermTailContinue(let r1, let r2):
            return "(\(r1.compileExpression)) <|> (\(r2.compileExpression))"
        case .TermTailEpsilon(): return epsilon
        case .Term(let r1, let r2):
            return "(\(concat) <§> (\(r1.compileExpression)) <*> (\(r2.compileExpression)))"
        case .FactorTailContinue(let r1, let r2):
            return "(\(concat) <§> (\(r1.compileExpression)) <*> (\(r2.compileExpression)))"
        case .FactorTailEpsilon():
            return epsilon
        case .Factor(let r1, let r2):
            if r2.isStar {
                return "(join <§> \(r1.compileExpression).repeatMany())"
            } else {
                return (r1.compileExpression)
            }
        case .BasicStar(): fatalError("* is not a valid regular expression")
        case .BasicEpsilon():
            return epsilon
        case .Basic(let r):
            return (r.compileExpression)
        case .Paren(let r):
            return (r.compileExpression)
        case .Char(let c):
            return "Parser.string(String(\(c)))"
        }
    }

}

class TestRegEx :XCTestCase {



    static let reg_expr:MonadicParser<RegEx> = term//RegEx.createExpr <§> term <*> term_tail
    //let term:MonadicParser<RegEx>
    static let expr = Parser.lazy(reg_expr)

    static let reg_char = Parser.satisfy { (c:Character) in
        c != "(" && c != ")" && c != "*" && c != "|"
    }


    static let char_expr = RegEx.Char <§> reg_char

    static let paren_expr = RegEx.Paren <§> (Parser.char("(") *> expr <* Parser.char(")"))

    static let basic_expr = RegEx.Basic <§> (paren_expr <|> char_expr)
    static let basic_star = Parser.char("*") *> Parser.success(RegEx.BasicStar())
    static let basic_epsilon = Parser.success(RegEx.BasicEpsilon())
    static let basic_expr_tail = basic_star <|> basic_epsilon


    static let factor = RegEx.createFactor <§> basic_expr <*> basic_expr_tail
    static let factor_tail:MonadicParser<RegEx> = factor_tail_continue <|> factor_tail_epsilon
    static let factor_tail_continue = RegEx.createFactorTailContinue <§> factor <*> Parser.lazy(factor_tail)
    static let factor_tail_epsilon = Parser.success(RegEx.FactorTailEpsilon())


    static let term = RegEx.createTerm <§> factor <*> factor_tail
    static let term_tail:MonadicParser<RegEx>  = term_tail_continue <|> term_tail_epsilon
    static let term_tail_continue = RegEx.createTermTailContinue <§> (Parser.char("|") *> term) <*>
        Parser.lazy(term_tail)
    static let term_tail_epsilon = Parser.success(RegEx.TermTailEpsilon())


    //reg_expr = RegEx.createExpr <§> term <*> term_tail



    static func compile(s:String)->MonadicParser<String> {
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

    func testIt() {

        // char expr
        var p = TestRegEx.compile("a")
        runParser(p)("a")
        p.parse("b")


        // repeat paren
        p = TestRegEx.compile("(a)*")
        print(TestRegEx.reg_expr.parse("(a)*")!.token)

        let expression = TestRegEx.reg_expr.parse("(a)*")!.token.compileExpression
        print(expression)
        p.parse("aaaa")
        p.parse("bbbcd")

        // concat expr
        p = TestRegEx.compile("ab")
        p.parse("a")
        p.parse("ab")

        // paren expr
        p = TestRegEx.compile("(c)")
        p.parse("cd")

        // repeat expr
        p = TestRegEx.compile("a*")
        p.parse("aaaa")

        // repeat paren
        p = TestRegEx.compile("(a)*")
        print(TestRegEx.reg_expr.parse("(a)*")!.token)
        
        p.parse("aaaa")
        p.parse("bbbcd")
        
        // regex 7
        p = TestRegEx.compile("a(b)*a")
        p.parse("aa")
        p.parse("aba")
        p.parse("abbbbac")
        
        // regex 8
        p = TestRegEx.compile("a|b|c")
        p.parse("abc")
        p.parse("cd")
        p.parse("ba")
        
        // repeat again
        p = TestRegEx.compile("ab*|b*")
        p.parse("abbbbg")?.token
        
        // or
      //  let r = TestRegEx.reg_expr.parse("a|b")!.token
        p = TestRegEx.compile("a|b")
        p.parse("b")
    }
    //reg_expr.parse("ab*|b*")!.token.description
    
}


//: [Next](@next)
