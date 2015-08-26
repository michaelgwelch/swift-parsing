//: [Previous](@previous)

import Foundation
import Parsing

//: # Using Swift Parsing For a Reg Ex Library
//: A regular expression can be parsed as a Parser<Parser<String>>
//: or Parser<Parser<Character>>Parser

let regChar:Parser<Character> = Parse.satisfy { (c:Character) -> Bool in
    c != "|" && c != "*" && c != "(" && c != ")"
}

let basicExpr:Parser<Parser<String>>
let regExpr = Parse.lazy(basicExpr)

let parenExpr:Parser<Parser<String>> = Parse.char("(") *> regExpr <* Parse.char(")")

func charToString(c:Character) -> String { return String(c) }
let charExpr:Parser<Parser<String>> = regChar |>>= { return Parse.success(charToString <§> Parse.char($0)) }

basicExpr = parenExpr <|> charExpr




var parseAna = regExpr.parse("a")!.token
parseAna.parse("ab")
parseAna.parse("b")


parseAna = regExpr.parse("(a)")!.token
parseAna.parse("ab")
parseAna.parse("b")

//: [Next](@next)
