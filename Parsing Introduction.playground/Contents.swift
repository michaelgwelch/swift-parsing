//: # Parsing Introduction

import Cocoa
import Parsing

//: # Quick Example
//: Parse an expression of the form  `x + z` and evaluate it.

let parseExpression = Parse.natural.bind { x in
    Parse.char("+").bind { c in
        Parse.natural.bind { y in
            return Parse.success(x + y)
        }
    }
}

parseExpression.parse(" 3 + 5 ")!.token

//: Alternatively we could do this without the lambda expressions
//: But first we need a curried version of addition
let sum:Int -> Int -> Int = { x in { x + $0 } }

//: `parseExpression2` is functionally equivalent to `parseExpression` and arguable
//: simpler once you learn the funny operators: `<§>` , `<*>` and `*>`
let parseExpression2 = sum <§> Parse.natural <*> (Parse.char("+") *> Parse.natural)
parseExpression2.parse(" 19 + 24 ")!.token
//: ## The Primitives
//: The `Parse` class provides many parser primitives. A parser
//: is any type that conforms to `ParserType`. Most of the primitives
//: return a parser of type `Parser<T>` where `T` depends on what is
//: to be parsed.
//:
//: The extension method `parse` is defined for all instances of `ParserType`.
//:
//: `func parse(String) -> (T, String)?`
//:
//: It attempts to parse something from the input string and returns `nil` if it
//: fails, else it returns a tuple with the data that was parsed as well as the
//: remaining input string.
//:

//:
//: `Parse.failure<T>() -> Parser<T>` This parser fails to parse anything and always returns `nil`
let intParser:Parser<Int> = Parse.failure()
intParser.parse("any input")

//: Note that since `failure` is generic in it's return type you need a type
//: annotation to specify the type `T`.
//:
//:     // fails to compile because `T` cannot be inferred
//:     Parse().parse("input string")
//:
//: This isn't normally an issue as the context will allow the
//: compiler to infer the type. Also, you are not likely to need
//: to use this method. (Note: consider moving this primitive to the
//: bottom since it's unlikely to be used much.)
//:

//: `Parse.success<T>(t:T) -> Parser<T>` This parser always succeeds and returns
//: the token `t`. It never consumer any of the input string.
//: The following example always "parses" the array `[2,3,4]` but consumes
//: none of the string.
Parse.success([2,3,4]).parse("Hello")


//: `Parse.item:Parser<Character>` This parser fails if the input string is the empty string.
//: It parses the first character of any non-empty string.
Parse.item.parse("")
Parse.item.parse("abcde")!.token   // parses "a" as the token
Parse.item.parse("abcde")!.output  // what's left is "bcde"

//: `Parse.satisfy(Character -> Bool) -> Parser<Character>` This parser succeeds 
//: whenever the predicate returns
//: `true`. It fails when the predicate returns `false`
Parse.satisfy { $0 >= "a" }.parse("Apple")        // returns nil
Parse.satisfy { $0 >= "a" }.parse("apple")!.token // parses "a"

//: Parse the letter "c". The result is `Some ("c","hair")`
Parse.char("c").parse("chair")

//: Fail to parse because the first letter of "hello" is not a "c"
let letter_c_failure = Parse.char("c").parse("hello") //: returns nil

//: Parse an integer: 234
var integerValue = Parse.nat.parse("234")!.token

//: Parse an integer including the white space before and after 
//: (ignoring all the whitespace)
integerValue = Parse.natural.parse("   234   ")!.token


//: ## Combining parsers
//: It's great to be able to parse primitives but often we
//: want to combine them to parse a larger input. There
//: are two ways to do this using the map operator `<§>`, and the
//: applicative operators:
//: `<*>`, `<*` and `*>` or using the monadic `bind` function.
//: The second option is more powerful but also slightly more
//: complex to write and read.
//:
//: ### Applicative parsing
//: Let's assume we want to parse an expression of the form
//: 
//:     a + b
//:
//: where `a` and `b` are any two natural numbers and 
//: we evaluate the result
//:
//: Here's are first, rather long, example:

let inputString = " 225 + 432 "
let result1 = Parse.natural.parse(inputString)!
let result2 = Parse.char("+").parse(result1.output)!
let result3 = Parse.natural.parse(result2.output)!
let evaluateSum = result1.token + result3.token

//: This works but has several draw backs. The first is that it is
//: rather long to write. The next is that it doesn't handle errors.
//: It assumes that we will have no problems with our input. Finally
//: it requires a lot of intermediate values to be stored. In particular
//: it requires that we correctly "thread" the output string from each
//: parsing operation to the input of the next.
//: Here's a better example:

let parser = sum <§> Parse.natural <*> (Parse.char("+") *> Parse.natural)
let evaluate = parser.parse("    225 + 432   ")!.token
let failToParse = parser.parse("    225 - 432 ")

//: ### Monadic parsing





