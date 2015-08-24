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
    public private(set) var index:String.Index
    public let string:String

    mutating func advance() -> Character? {
        guard (index != string.endIndex) else {
            return nil
        }

        let currentChar = string[index]
        index = index.successor()
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

extension ParserContext : GeneratorType {
    public mutating func next() -> Character? {
        return advance()
    }
}

extension ParserContext : SequenceType {
    public func generate() -> ParserContext {
        return self
    }
}

public func ==(lhs:ParserContext, rhs:ParserContext) -> Bool {
    return lhs.col == rhs.col
    && lhs.row == rhs.row
    && lhs.index == rhs.index
    && lhs.string == rhs.string
}

extension ParserContext {
    init(string:String) {
        row = 1
        col = 1
        index = string.startIndex
        self.string = string
    }
}



public protocol ParserType {
    typealias TokenType
    func parse(input: ParserContext) -> (token: Self.TokenType, output: ParserContext)?
}

public extension ParserType {
    /// For backward compatiblity with prewritten tests.
    func parse(input: String) -> (token: Self.TokenType, output: String)? {
        let context = ParserContext(string: input)
        return self.parse(context).map { ($0.token, $0.output.string.substringFromIndex($0.output.index)) }
    }
}

public struct Parser<T> : ParserType {
    private let parser:ParserContext -> (T,ParserContext)?
    init(parser:ParserContext -> (T,ParserContext)?) {
        self.parser = parser
    }

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
    public func parse(input: ParserContext) -> (token: TokenType, output: ParserContext)? {
        return getParser().parse(input)
    }
}



public struct AnyParser<T> : ParserType {
    private let _parse:(ParserContext) -> (token: T, output: ParserContext)?
    public init<P: ParserType where P.TokenType == T>(_ parser: P) {
        _parse = parser.parse
    }
    public func parse(input: ParserContext) -> (token: T, output: ParserContext)? {
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

    public static let item = Parser<Character> { (var input) in
        let currentChar = input.next()
        return currentChar.map { ($0, input) }
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

    static func currentRow() -> Parser<Int> {
        return Parser { ($0.row, $0) }
    }

    static func currentCol() -> Parser<Int> {
        return Parser { ($0.col, $0) }
    }

    public static func currentLocation() -> Parser<Location> {
        func tuple(row:Int)(_ col:Int) -> Location {
            return (row, col)
        }
        return tuple <§> currentRow() <*> currentCol()
    }
}
public typealias Location = (row:Int, col:Int)


let isLetter:Character -> Bool = { c in isUpper(c) || isLower(c) }
let isDigit:Character -> Bool = { c in (c >= "0" && c <= "9") }
let isUpper:Character -> Bool = { c in (c >= "A" && c <= "Z") }
let isLower:Character -> Bool = { c in (c >= "a" && c <= "z") }
let isAlphanum:Character -> Bool = { isLetter($0) || isDigit($0) }


// MARK: ParserType extension

func tuple3<T1,T2,T3>(t1:T1)(_ t2:T2)(_ t3:T3) -> (T1,T2,T3) {
    return (t1, t2, t3)
}

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

    // How can I avoid doing the start and end location for each parsing expression. How about
    // something like this:

    func withLocation() -> Parser<(TokenType,Location,Location)> {
        func reorderTuple(startLoc:Location)(_ token:TokenType)(_ endLoc:Location) -> (TokenType,Location,Location) {
            return (token, startLoc, endLoc)
        }
        return reorderTuple <§> Parse.currentLocation() <*> self <*> Parse.currentLocation()
    }
}

public postfix func *<PT:ParserType, T where PT.TokenType==T>(p:PT) -> Parser<List<T>> {
    return p.repeatMany()
}

public postfix func +<PT:ParserType, T where PT.TokenType==T>(p:PT) -> Parser<List<T>> {
    return p.repeatOneOrMany()
}





