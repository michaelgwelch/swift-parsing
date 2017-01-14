//: [Previous](@previous)


//: A regular expression can be parsed as a ParserOf<ParserOf<String>>
//: or ParserOf<ParserOf<Character>>Parser


import Foundation
import SwiftParsing

//: # Using Swift Parsing For a Reg Ex Library
//: Regular expressions are character patterns that describe a set of strings.
//: In this exercise we will write a library that allows us to test whether a given
//: string is “accepted” by a regular expression. (Alternatively, it can be said that
//: we will be testing whether a regular expression *matches* a string.)

//: ## Grammar of Regex
//: Describing this grammar gets confusing, because we use parentheses and ‘|’
//: both in describing the grammar and in the grammar. So rather than use ‘|’
//: like the book does for choices I’m going to use `•`. And rather than use parentheses
//: for grouping I’m going to use curly braces. So, for example, if you look at
//: figure 1 you will see *orexpr* is defined to be a *concatexpr* followed by a choice.
//: The first choice is a ‘|’ followed by an *orexpr*. The second choice is the empty
//: string (denoted by the symbol ε).
//:
//: A regular expression is built up of characters and operators. The most basic
//: regular expressions only use 3 operations: concatenation, alternation (option),
//: and repetition. Concatenation is denoted by just writing two regular expressions
//: side by side (as in `ab`). Alternation is denoted by the "|" symbol and means either
//: the first regex or the second (as in `a|b`). Repetition is denoted by "*" and means
//: 0 or more of the preceding regular expression (as in `a*`).
//:
//: See table 1 for some examples of regular expressions:
//:
//: **Figure 1: The grammar for regular expressions**
//:
//:     regexpr    ::= orexpr
//:     orexpr     ::= concatexpr { | orexpr • ε }
//:     concatexpr ::= repeatexpr { concatexpr • ε}
//:     repeatexpr ::= basicexpr { * • ε }
//:     basicexpr  ::= parenexpr • charexpr
//:     parenexpr  ::= ( regexpr )
//:     charexpr   ::= regchar
//:     regchar    ::= "any character except {'|','(',')','*'}"
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

print("I ran")
//: Some helper functions we'll be using later.
typealias P = Parser
let satisfy = P.satisfy
let char = P.char


//: Concatenate the strings and return the result
//: For example:
//:
//:     join(["foo", "bar", "baz"]) // "foobarbaz"
func join<S:Sequence>(strings:S) -> String where S.Iterator.Element==String{
    return strings.joined(separator: "")
}

//: A curried function that accepts two String values, concatenates them
//: together and returns the result. For example:
//:
//:     concat("foo")("bar") // "foobar"
let concat:(String) -> (String) -> String = { x in { x + $0 }}

//: Create a `String` from a `Character`
let charToString:(Character) -> String = { String.init($0) }


//: A parser that parses any character except the special chars '|', '*', '(', and ')'
let regChar:ParserOf<Character> = satisfy { (c:Character) -> Bool in
    c != "|" && c != "*" && c != "(" && c != ")"
}

//: A forward reference for `orExpr`
var orExpr:ParserOf<ParserOf<String>>! = nil

//: Use lazy in next line because `orExpr` is not yet assigned.
//: It's a *forward reference* because Playgrounds apparently can't refer
//: to something that has not yet been defined (unlike normal source files)
//: It can't be defined yet because it's circular. This safely breaks the circular
//: reference
let regExpr = P.lazy(orExpr)

//: Parses a parenexpr. Note that the `*>` operator parses two expressions
//: and returns the right hand side. The `<*` operator parses two expressions
//: and returns the left hand side. So the following parser parses a "(", a
//: regExpr and a ")" but only returns the the results of regExpr.
let parenExpr = char("(") *> regExpr <* char(")")

let charExpr = regChar |>>= { return P.success(charToString <§> char($0)) }

let basicExpr = parenExpr <|> charExpr

let repeatExpr = basicExpr |>>= { be in
    char("*") *> P.success(join <§> be*) <|> P.success(be)
}

var concatExpr:ParserOf<ParserOf<String>>! = nil
concatExpr = repeatExpr |>>= { re in
    (concatExpr |>>= { ce in return P.success(concat <§> re <*> ce) }) <|> P.success(re)
}

orExpr = concatExpr |>>= { ce in
    (char("|") *> orExpr |>>= { oe in return P.success(ce <|> oe) }) <|> P.success(ce)
}

var parseAna = regExpr.parse("a")!.token
parseAna.parse("ab")
parseAna.parse("b")

parseAna = regExpr.parse("(a)")!.token
parseAna.parse("ab")
parseAna.parse("b")

var parseAs = repeatExpr.parse("a*")!.token
parseAs.parse("")!.token
parseAs.parse("aaaaab")!

var parseAOrB = regExpr.parse("a|b*")!.token
parseAOrB.parse("a")!.token
parseAOrB.parse("bb")!.token

var parseAsOrBs = regExpr.parse("a*|(b*)")!.token
parseAsOrBs.parse("aaaaaaab")!.token
parseAsOrBs.parse("b")!.token

func compile(_ regex:String) -> ParserOf<String> {
    return regExpr.parse(regex)!.token
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
