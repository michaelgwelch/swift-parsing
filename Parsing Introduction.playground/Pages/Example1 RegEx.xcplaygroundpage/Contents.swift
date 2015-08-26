//: [Previous](@previous)

import Foundation
import Parsing

//: # Using Swift Parsing For a Reg Ex Library
//: A regular expression can be parsed as a Parser<Parser<String>>
//: or Parser<Parser<Character>>Parser

let regChar:Parser<Character> = Parse.satisfy { (c:Character) -> Bool in
    c != "|" && c != "*" && c != "(" && c != ")"
}

let repeatExpr:Parser<Parser<String>>
let regExpr = Parse.lazy(repeatExpr)

let parenExpr:Parser<Parser<String>> = Parse.char("(") *> regExpr <* Parse.char(")")

func charToString(c:Character) -> String { return String(c) }
let charExpr:Parser<Parser<String>> = regChar |>>= { return Parse.success(charToString <§> Parse.char($0)) }

let basicExpr = parenExpr <|> charExpr

func concat<S:SequenceType where S.Generator.Element==String>(strings:S) -> String {
    return strings.joinWithSeparator("")
}



repeatExpr = basicExpr |>>= { be in
    (Parse.char("*") |>> (Parse.success § concat <§> be.repeatMany()))
    <|> Parse.success(be)
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
//: [Next](@next)
