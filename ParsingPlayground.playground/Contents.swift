//: Playground - noun: a place where people can play

import Cocoa
import Parsing

//: # The Primitives
//: The `Parse` class provides many parser primitives. Every parser
//: takes a string as an input and returns an optional tuple that
//: contains the token that was parsed and the remaining string.
//:
//: `Parse.failure()` This parser fails to parse anything and always returns `nil`
let intParser:Parser<Int> = Parse.failure()
intParser.parse("any input")

//: `Parse.item` This parser fails if the input string is the empty string.
//: It returns the first character of any non-empty string.
Parse.item.parse("")
Parse.item.parse("abcde")!.token   // parses "a" as the token
Parse.item.parse("abcde")!.output  // what's left is "bcde"

//: `Parse.satisfy` This parser succeeds whenever the predicate returns
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


//: # Combining parsers
//: It's great to be able to parse primitives but often we
//: want to combine them to parse a larger input. There
//: are two ways to do this using the map operator `<§>`, and the
//: applicative operators:
//: `<*>`, `<*` and `*>` or using the monadic `bind` function.
//: The second option is more powerful but also slightly more
//: complex to write and read.
//: ## Applicative parsing
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

let sum:Int -> Int -> Int = { a in { a + $0 }}
let parser = sum <§> Parse.natural <*> (Parse.char("+") *> Parse.natural)
let evaluate = parser.parse("    225 + 432   ")!.token
let failToParse = parser.parse("    225 - 432 ")

//: ## Monadic parsing





