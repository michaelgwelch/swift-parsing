//: [Previous](@previous)

import Foundation
import SwiftParsing

let string_literal_contents = ((Parser.string("\"\"") <|> (Parser.satisfy { $0 != "\"" }).map {String($0)})).repeatMany().join()
let string_literal = Parser.sequence(Parser.string("\""), string_literal_contents, Parser.string("\"")) {
    (_,s,_) in s
}

//: [Next](@next)

let simpleString = "\"abcdef\""

string_literal.parse(simpleString)

let stringWithEmbeddedQuotes = "\"He \"\"said\"\" \""//\"\""//Hello\"\""
string_literal.parse(stringWithEmbeddedQuotes)

let anotherExample = "\" He said \"\"Hello\"\" \""
string_literal.parse(anotherExample)

let identifier_first_char = Parser.letter <|> Parser.char("@")
    <|> Parser.char("[") <|> Parser.char("]") <|> Parser.char("_") <|> Parser.char("\\")
let identifier_char = Parser.alphanum <|> Parser.char("@") <|> Parser.char("_")
let identifier_string = Parser.sequence(identifier_first_char, identifier_char.repeatMany()) { (c,s) in
    String(c) + String(s)
}
let identifier = Parser.sequence(identifier_string, Parser.string("$").optional("")) { (s1,s2) in
    (s1+s2)
}

identifier.parse("A$")
identifier.parse("]BC34_")


let digitsOptional = Parser.digit.repeatMany().map {String($0)}
let digits = Parser.digit.repeatOneOrMany().map {String($0)}
let fractional = Parser.sequence(Parser.string("."), digits.optional("0"), {$0 + $1}).optional("")
let exponent_char = Parser.string("e").orElse(Parser.string("E"))
let exponent_sign = (Parser.string("+").orElse(Parser.string("-"))).optional("")
let exponent = Parser.sequence(exponent_char, exponent_sign, digits) { (c,s,d) in c + s + d }
let significand = Parser.sequence(digits, fractional) {$0+$1}
let number_literal = Parser.sequence(significand, exponent) { (s,e) in s+e }

digitsOptional.parse("")
digits.parse("12")
significand.parse("123.15")
exponent.parse("e-123")
number_literal.parse("123.15e+19")

let nsnum = NSDecimalNumber(string: "1b")

let testString = Parser.string("hello")
testString.optional().parse("hello")
testString.optional().parse("hellb")

