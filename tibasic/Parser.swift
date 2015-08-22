//
//  Parser.swift
//  tibasic
//
//  Created by Michael Welch on 7/21/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation
import Swift




/////////////////////////////////////////////
// Parser struct and protocol
//////////////////

public protocol ParserType {
    typealias TokenType
    func parse(input: String) -> (token: TokenType, output:String)?
}

public struct Parser<T> : ParserType {
    private let parser:String -> (T,String)?
    public init(parser:String -> (T,String)?) {
        self.parser = parser
    }

    public func parse(input: String) -> (token: T, output: String)? {
        return parser(input)
    }
}


public struct LazyParser<TokenType, P:ParserType where P.TokenType==TokenType> : ParserType {
    private let getParser:() -> P
    // Hunch: Source of memory leaks when we get into recursive parsers later.
    public init(@autoclosure(escaping) parser:() -> P) {
        self.getParser = parser
    }
    public init(getParser:() -> P) {
        self.getParser = getParser
    }
    public func parse(input: String) -> (token: TokenType, output: String)? {
        return getParser().parse(input)
    }
}



public struct AnyParser<T> : ParserType {
    private let _parse:(String) -> (token: T, output: String)?
    public init<P: ParserType where P.TokenType == T>(_ parser: P) {
        _parse = parser.parse
    }
    public func parse(input: String) -> (token: T, output: String)? {
        return _parse(input)
    }
}



///////////////////////////////

public class Parse {
    public static func failure<T>() -> Parser<T> {
        return Parser { _ in nil }
    }

    public static func success<T>(t:T) -> Parser<T> {
        return Parser { (t, $0) }
    }

    public static let item = Parser<Character> { input in
        return input.uncons()
    }

    public static func sat(predicate:Character -> Bool) -> Parser<Character> {
        return item.bind { predicate($0) ? success($0) : failure() }
    }

    public static func char(c:Character) -> Parser<Character> {
        return sat() { c == $0 }
    }

    public static let count = 5

    public static let letter = Parse.sat § isLetter
    public static let digit = Parse.sat(isDigit)
    public static let upper = Parse.sat(isUpper)
    public static let lower = Parse.sat(isLower)
    public static let alphanum = Parse.sat(isAlphanum)

    public static func string(s:String) -> Parser<String> {
        guard (!s.isEmpty) else {
            return success("")
        }

        let c = s[s.startIndex]
        let cs = s.substringFromIndex(s.startIndex.successor())

        return char(c) *> string(cs) *> success(s)
    }

    public static let isSpace:Character -> Bool = { (c:Character) -> Bool in
        c == " " || c == "\n" || c == "\r" || c == "\t" }

    public static let space:Parser<()> = Parse.sat(isSpace)* *> Parse.success(())

    public static let ident:Parser<String> = String.init <§> (cons <§> letter <*> alphanum*)
    public static let int:String -> Int = { Int($0)!} // Construct an int out of a string of digits

    public static let nat:Parser<Int> = int <§> (String.init <§> (cons <§> digit <*> digit*))
    public static let identifier = ident.token()

    public static let natural = nat.token()

    public static let symbol:String -> Parser<String> = { (Parse.string § $0).token() }

    //* Wrap a parser so that it is evaluated lazily
    public static func lazy<TokenType, P:ParserType where P.TokenType==TokenType>(@autoclosure(escaping) getParser:() -> P) -> LazyParser<TokenType, P> {
        return LazyParser { getParser() }
    }

}


let isLetter:Character -> Bool = { c in isUpper(c) || isLower(c) }
let isDigit:Character -> Bool = { c in (c >= "0" && c <= "9") }
let isUpper:Character -> Bool = { c in (c >= "A" && c <= "Z") }
let isLower:Character -> Bool = { c in (c >= "a" && c <= "z") }
let isAlphanum:Character -> Bool = { isLetter($0) || isDigit($0) }


// MARK: ParserType extension

extension ParserType {
    func repeatMany() -> Parser<List<TokenType>> {
        return Parse.lazy(self.repeatOneOrMany()) <|> Parse.success(List<TokenType>.Nil)
    }
    func repeatOneOrMany() -> Parser<List<TokenType>> {
        return cons <§> self <*> self.repeatMany()
    }
    func token() -> Parser<TokenType> {
        return Parse.space *> self <* Parse.space
    }
    func void() -> Parser<()> {
        return (self) *> Parse.success(())
    }
}

public postfix func *<PT:ParserType, T where PT.TokenType==T>(p:PT) -> Parser<List<T>> {
    return p.repeatMany()
}

public postfix func +<PT:ParserType, T where PT.TokenType==T>(p:PT) -> Parser<List<T>> {
    return p.repeatOneOrMany()
}




