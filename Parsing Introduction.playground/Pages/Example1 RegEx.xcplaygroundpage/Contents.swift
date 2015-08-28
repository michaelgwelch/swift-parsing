//: [Previous](@previous)


//: A regular expression can be parsed as a Parser<Parser<String>>
//: or Parser<Parser<Character>>Parser


import Foundation
import Parsing

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


//: Some helper functions

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


let regChar:Parser<Character> = Parse.satisfy { (c:Character) -> Bool in
    c != "|" && c != "*" && c != "(" && c != ")"
}

let orExpr:Parser<Parser<String>>

//: Use lazy in next line because `orExpr` is not yet assigned.
//: It's a *forward reference* because Playgrounds apparently can't refer
//: to something that has not yet been defined (unlike normal source files)
//: It can't be defined yet because it's circular. This safely breaks the circular
//: reference
let regExpr = Parse.lazy(orExpr)

let parenExpr = Parse.char("(") *> regExpr <* Parse.char(")")

let charToString:Character -> String = { String.init($0) }


let charExpr = regChar |>>= { return Parse.success(charToString <§> Parse.char($0)) }

let basicExpr = parenExpr <|> charExpr



let repeatExpr = basicExpr |>>= { be in
    (Parse.char("*") |>> (Parse.success(join <§> be.repeatMany())))
    <|> Parse.success(be)
}


func concatExprF() -> Parser<Parser<String>> {
    return repeatExpr |>>= { re in
        (concatExprF() |>>= { ce in
            return Parse.success(concat <§> re <*> ce)
            }) <|> Parse.success(re)
    }

}

let concatExpr = concatExprF()

orExpr = concatExpr |>>= { (ce:Parser<String>) in
    (
        Parse.char("|") |>> orExpr |>>= { oe in
            return Parse.success(ce <|> oe)
        }
    ) <|> Parse.success(ce)
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

func compile(regex:String) -> Parser<String> {
    return regExpr.parse(regex)!.token
}

func runParser(p:Parser<String>)(_ s:String) -> String {
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
p.parse("abb")



//: [Next](@next)
