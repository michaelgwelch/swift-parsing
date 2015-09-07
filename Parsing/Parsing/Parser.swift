//
//  Parser.swift
//  tibasic
//
//  Created by Michael Welch on 7/21/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation



/////////////////////////////////////////////
// Parser struct and protocol
//////////////////

public struct ParserContext {
    public private(set) var row:Int
    public private(set) var col:Int
    public private(set) var string:String

    mutating func advance() -> Character? {
        guard (!string.isEmpty) else {
            return nil
        }

        let currentChar = string[string.startIndex]
        string = string[string.startIndex.successor()..<string.endIndex]
        if currentChar == "\n" {
            row++
            col = 1
        } else {
            col++
        }

        return currentChar
    }
}

extension ParserContext:Equatable {

}

@warn_unused_result
public func ==(lhs:ParserContext, rhs:ParserContext) -> Bool {
    return lhs.col == rhs.col
    && lhs.row == rhs.row
    && lhs.string == rhs.string
}

extension ParserContext {
    init(string:String) {
        row = 1
        col = 1
        self.string = string
    }
}



public protocol ParserType {
    typealias TokenType
    @warn_unused_result
    func parse(input: ParserContext) -> (token: TokenType, output: ParserContext)?
}

public extension ParserType {
    /// For backward compatiblity with prewritten tests.
    @warn_unused_result
    func parse(input: String) -> (token: Self.TokenType, output: String)? {
        let context = ParserContext(string: input)
        let result = self.parse(context)
        return result.map { ($0.token, $0.output.string) }
    }
}

public struct Parser<T> : ParserType {
    private let parser:ParserContext -> (T,ParserContext)?
    init(parser:ParserContext -> (T,ParserContext)?) {
        self.parser = parser
    }

    @warn_unused_result
    public func parse(input: ParserContext) -> (token: T, output: ParserContext)? {
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
    @warn_unused_result
    public func parse(input: ParserContext) -> (token: TokenType, output: ParserContext)? {
        return getParser().parse(input)
    }
}



public struct AnyParser<T> : ParserType {
    private let _parse:(ParserContext) -> (token: T, output: ParserContext)?
    public init<P: ParserType where P.TokenType == T>(_ parser: P) {
        _parse = parser.parse
    }
    @warn_unused_result
    public func parse(input: ParserContext) -> (token: T, output: ParserContext)? {
        return _parse(input)
    }
}



///////////////////////////////

public class Parsers {
    @warn_unused_result
    public static func failure<T>() -> Parser<T> {
        return Parser { _ in nil }
    }

    @warn_unused_result
    public static func success<T>(t:T) -> Parser<T> {
        return Parser { (t, $0) }
    }

    public static let item = Parser<Character> { (var input) in
        let currentChar = input.advance()
        return currentChar.map { ($0, input) }
    }

    public static let satisfy = { (predicate:Character->Bool) in
        return item.bind { predicate($0) ? Parsers.success($0) : Parsers.failure() }
    }

    public static let char = { (c:Character) in
        return satisfy() { c == $0 }
    }

    public static let letter = satisfy § isLetter
    public static let digit = satisfy(isDigit)
    public static let upper = satisfy(isUpper)
    public static let lower = satisfy(isLower)
    public static let alphanum = satisfy(isAlphanum)

    @warn_unused_result
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

    public static let space:Parser<()> = Parsers.satisfy(isSpace)* *> Parsers.success(())

    public static let ident:Parser<String> = String.init <§> (cons <§> letter <*> alphanum*)
    public static let int:String -> Int = { Int($0)!} // Construct an int out of a string of digits

    public static let nat:Parser<Int> = int <§> (String.init <§> (cons <§> digit <*> digit*))
    public static let identifier = ident.token()

    public static let natural = nat.token()

    public static let symbol:String -> Parser<String> = { (Parsers.string § $0).token() }

    /// Wrap a parser so that it is evaluated lazily
    @warn_unused_result
    public static func lazy<TokenType, P:ParserType where P.TokenType==TokenType>(@autoclosure(escaping) getParser:() -> P) -> LazyParser<TokenType, P> {
        return LazyParser { getParser() }
    }

    public static let currentRow:Parser<Int> = Parser { ($0.row, $0) }

    public static let currentCol:Parser<Int> = Parser { ($0.col, $0) }

    public static let currentLocation:Parser<Location> = Parsers.sequence(currentRow, currentCol) {($0,$1)}

}
public typealias Location = (row:Int, col:Int)


let isLetter:Character -> Bool = { c in isUpper(c) || isLower(c) }
let isDigit:Character -> Bool = { c in (c >= "0" && c <= "9") }
let isUpper:Character -> Bool = { c in (c >= "A" && c <= "Z") }
let isLower:Character -> Bool = { c in (c >= "a" && c <= "z") }
let isAlphanum:Character -> Bool = { isLetter($0) || isDigit($0) }


// MARK: ParserType extension

extension ParserType {
    @warn_unused_result
    public func repeatMany() -> Parser<List<TokenType>> {
        return Parsers.lazy(self.repeatOneOrMany()) <|> Parsers.success(.Nil)
    }
    @warn_unused_result
    func repeatOneOrMany() -> Parser<List<TokenType>> {
        return cons <§> self <*> self.repeatMany()
    }
    public func token() -> Parser<TokenType> {
        return Parsers.space *> self <* Parsers.space
    }
    @warn_unused_result
    public func void() -> Parser<()> {
        return (self) *> Parsers.success(())
    }

    public var discardToken:Parser<()> {
        return Parsers.success(()) <* self
    }

    @warn_unused_result
    public func orElse<P:ParserType where P.TokenType==TokenType>(p:P) -> Parser<TokenType> {
        return self <|> p
    }

    // How can I avoid doing the start and end location for each parsing expression. How about
    // something like this:

    @warn_unused_result
    func withLocation() -> Parser<(TokenType,Location,Location)> {
        return Parsers.sequence(Parsers.currentLocation, self, Parsers.currentLocation) { ($1, $0, $2) }
    }
}

extension ParserType where TokenType==List<String> {
    @warn_unused_result
    public func join() -> Parser<String> {
        let join = flip(List<String>.joinWithSeparator)("")
        return join <§> self
    }
}

@warn_unused_result
public postfix func *<PT:ParserType, T where PT.TokenType==T>(p:PT) -> Parser<List<T>> {
    return p.repeatMany()
}

@warn_unused_result
public postfix func +<PT:ParserType, T where PT.TokenType==T>(p:PT) -> Parser<List<T>> {
    return p.repeatOneOrMany()
}





