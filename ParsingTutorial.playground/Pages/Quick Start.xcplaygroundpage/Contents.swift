//: # Parsing Introduction

import Cocoa
import SwiftParsing

var x = 234

//: # Quick Example
//: Parse an expression of the form  `x + z` and evaluate it.

let parseExpression = Parser.natural.bind { x in
    Parser.char("+").bind { c in
        Parser.natural.bind { y in
            return Parser.success(x + y)
        }
    }
}

parseExpression.parse(" 3 + 5 ")!.token

//: We can simplify slightly by using the `|>>` operator to avoid the
//: unused variable `c`.
(Parser.natural |>>= { x in
    Parser.char("+") |>> Parser.natural |>>= {
        return Parser.success(x + $0)
    }
    }).parse("    12  + 23  ")!.token

//: Alternatively we could do this without the lambda expressions
//: But first we need a curried version of addition
let sumFunny:(Int) -> (Character) -> (Int) -> Int = { x in { _ in { x + $0 } } }



//: `parseExpression2` is functionally equivalent to `parseExpression` and arguable
//: simpler once you learn the funny operators: `<§>` , `<*>` and `*>`
let parseExpression2 = sumFunny <§> Parser.natural <*> Parser.char("+") <*> Parser.natural
parseExpression2.parse(" 19 + 24 ")!.token

//: While this works you might notice that we defined `sumFunny` to take an `Int`, a `Character`,
//: and another `Int`. This is because these are the three things we parsed. But we don't
//: really want to pass the `+` to the `sumFunny` function. To parse the `+` and
//: "throw it away" we can use the `*>` operator like this:

let sum:(Int) -> (Int) -> Int = { x in { y in x + y } }
(sum <§> Parser.natural <*> (Parser.char("+") *> Parser.natural)).parse(" 19 + 24 ")!.token

//: ## The Primitives
//: The `Parser` class provides many parser primitives. A parser
//: is any type that conforms to `ParserType`. Most of the primitives
//: return a parser of type `ParserOf<T>` where `T` depends on what is
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
//: `Parser.failure<T>() -> ParserOf<T>` This parser fails to parse anything and always returns `nil`
let intParser:ParserOf<Int> = Parser.failure()
intParser.parse("any input")

//: Note that since `failure` is generic in it's return type you need a type
//: annotation to specify the type `T`.
//:
//:     // fails to compile because `T` cannot be inferred
//:     Parser().parse("input string")
//:
//: This isn't normally an issue as the context will allow the
//: compiler to infer the type. Also, you are not likely to need
//: to use this method. (Note: consider moving this primitive to the
//: bottom since it's unlikely to be used much.)
//:

//: `Parser.success<T>(t:T) -> ParserOf<T>` This parser always succeeds and returns
//: the token `t`. It never consumer any of the input string.
//: The following example always "parses" the array `[2,3,4]` but consumes
//: none of the string.
Parser.success([2,3,4]).parse("Hello")


//: `Parser.item:ParserOf<Character>` This parser fails if the input string is the empty string.
//: It parses the first character of any non-empty string.
Parser.item.parse("")
Parser.item.parse("abcde")!.token   // parses "a" as the token
Parser.item.parse("abcde")!.output  // what's left is "bcde"

//: `Parser.satisfy(Character -> Bool) -> ParserOf<Character>` This parser succeeds
//: whenever the predicate returns
//: `true`. It fails when the predicate returns `false`
Parser.satisfy { $0 >= "a" }.parse("Apple")        // returns nil
Parser.satisfy { $0 >= "a" }.parse("apple")!.token // parses "a"

//: Parse the letter "c". The result is `Some ("c","hair")`
Parser.char("c").parse("chair")


//: Fail to parse because the first letter of "hello" is not a "c"
let letter_c_failure = Parser.char("c").parse("hello") //: returns nil

//: Parse an integer: 234
var integerValue = Parser.nat.parse("234")!.token

//: Parse an integer including the white space before and after
//: (ignoring all the whitespace)
integerValue = Parser.natural.parse("   234   ")!.token

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
let result1 = Parser.natural.parse(inputString)!
let result2 = Parser.char("+").parse(result1.output)!
let result3 = Parser.natural.parse(result2.output)!
let evaluateSum = result1.token + result3.token

//: This works but has several draw backs. The first is that it is
//: rather long to write. The next is that it doesn't handle errors.
//: It assumes that we will have no problems with our input. Finally
//: it requires a lot of intermediate values to be stored. In particular
//: it requires that we correctly "thread" the output string from each
//: parsing operation to the input of the next.
//: Here's a better example:

let parser = sum <§> Parser.natural <*> (Parser.char("+") *> Parser.natural)
let evaluate = parser.parse("    225 + 432   ")!.token
let failToParse = parser.parse("    225 - 432 ")

//: ### Monadic parsing
