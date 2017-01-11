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
    public fileprivate(set) var row:Int
    public fileprivate(set) var col:Int
    private var iterator:IndexingIterator<String.CharacterView>

    init(string:String) {
        row = 1
        col = 1
        iterator = string.characters.makeIterator()
    }

    mutating func advance() -> Character? {
        guard let currentChar = iterator.next() else {
            return nil;
        }

        if currentChar == "\n" {
            row += 1
            col = 1
        } else {
            col += 1
        }

        return currentChar
    }
}

/*
extension ParserContext:Equatable {

}

@warn_unused_result
public func ==(lhs:ParserContext, rhs:ParserContext) -> Bool {
    return lhs.col == rhs.col
    && lhs.row == rhs.row
    && lhs.string == rhs.string
}
*/






public protocol ParserType {
    associatedtype TokenType
    
    func parse(_ input: ParserContext) -> (token: TokenType, output: ParserContext)?
}


/*
public extension ParserType {
    /// For backward compatiblity with prewritten tests.
    @warn_unused_result
    func parse(input: String) -> (token: Self.TokenType, output: String)? {
        let context = ParserContext(string: input)
        let result = self.parse(context)
        return result.map { ($0.token, $0.output.string) }
    }
}
*/




public struct ParserOf<T> : ParserType {
    private let parser:(ParserContext) -> (T,ParserContext)?

    init(parser:@escaping (ParserContext) -> (T,ParserContext)?) {
        self.parser = parser
    }

    public func parse(_ input: ParserContext) -> (token: T, output: ParserContext)? {
        return parser(input)
    }

}


public struct LazyParserOf<TokenType, P:ParserType> : ParserType where P.TokenType==TokenType {

    private let getParser:() -> P
    // Hunch: Source of memory leaks when we get into recursive parsers later.
    public init(parser: @escaping () -> P) {
        self.getParser = parser
    }

    public func parse(_ input: ParserContext) ->
        (token: TokenType, output: ParserContext)? {
        return getParser().parse(input)
    }
}



public struct AnyParserOf<T> : ParserType {

    private let _parse:(ParserContext) -> (token: T, output: ParserContext)?
    public init<P: ParserType>(_ parser: P) where P.TokenType == T {
        _parse = parser.parse
    }
    
    public func parse(_ input: ParserContext) -> (token: T, output: ParserContext)? {
        return _parse(input)
    }
}



///////////////////////////////

public class Parser {

    public static func failure<T>() -> ParserOf<T> {
        return ParserOf { _ in nil }
    }

    public static func success<T>(_ t:T) -> ParserOf<T> {
        return ParserOf { (t, $0) }
    }

    public static let item = ParserOf<Character> { (input) in
        var input = input
        let currentChar = input.advance()
        return currentChar.map { ($0, input) }
    }


    public static let satisfy = { (predicate:@escaping (Character)->Bool) in
        return item.bind { predicate($0) ? Parser.success($0) : Parser.failure() }
    }

    public static let char = { (c:Character) in
        return satisfy() { c == $0 }
    }


    public static let letter = satisfy(isLetter)
    public static let digit = satisfy(isDigit)
    public static let upper = satisfy(isUpper)
    public static let lower = satisfy(isLower)
    public static let alphanum = satisfy(isAlphanum)


    public static func string(_ s:String) -> ParserOf<String> {
        guard (!s.isEmpty) else {
            return success("")
        }

        let c = s[s.startIndex]
        let cs = s.substring(from: s.index(after: s.startIndex))

        //return char(c) *> string(cs) *> success(s)

        return char(c).bind { _ in
            return string(cs).bind { _ in
                return success(s)
            }
        }
    }

    public static let isSpace:(Character) -> Bool = { (c:Character) -> Bool in
        c == " " || c == "\n" || c == "\r" || c == "\t" }

    public static let space:ParserOf<()> = Parser.satisfy(isSpace)* *> Parser.success(())


    public static let ident:ParserOf<String> = Parser.sequence(letter, alphanum*, cons).map { String($0) }
    public static let int:(String) -> Int = { Int($0)!} // Construct an int out of a string of digits

    public static let nat:ParserOf<Int> = Parser.sequence(digit, digit*, cons).map {String($0)}.map(int)
    public static let identifier = ident.token()

    public static let natural = nat.token()

    public static let symbol:(String) -> ParserOf<String> = { (Parser.string($0) ).token() }

    /// Wrap a parser so that it is evaluated lazily
    
    public static func lazy<TokenType, P:ParserType>(_ getParser:@autoclosure @escaping () -> P) -> LazyParserOf<TokenType, P> where P.TokenType==TokenType {
        return LazyParserOf { getParser() }
    }

    public static let currentRow:ParserOf<Int> = ParserOf { ($0.row, $0) }

    public static let currentCol:ParserOf<Int> = ParserOf { ($0.col, $0) }

    public static let currentLocation:ParserOf<Location> = Parser.sequence(currentRow, currentCol) {($0,$1)}

}


public typealias Location = (row:Int, col:Int)


let isLetter:(Character) -> Bool = { c in isUpper(c) || isLower(c) }
let isDigit:(Character) -> Bool = { c in (c >= "0" && c <= "9") }
let isUpper:(Character) -> Bool = { c in (c >= "A" && c <= "Z") }
let isLower:(Character) -> Bool = { c in (c >= "a" && c <= "z") }
let isAlphanum:(Character) -> Bool = { isLetter($0) || isDigit($0) }


 
// MARK: ParserType extension
extension ParserType where TokenType==String {

    public func optional() -> ParserOf<String> {
        return self <|> Parser.success("")
    }
}


extension ParserType {

    public func repeatMany() -> ParserOf<List<TokenType>> {
        return Parser.lazy(self.repeatOneOrMore()) <|> Parser.success(.empty)
    }

    
    public func repeatOneOrMore() -> ParserOf<List<TokenType>> {
        return Parser.sequence(self, self.repeatMany(), cons)
    }


    
    public func token() -> ParserOf<TokenType> {
        return Parser.space *> self <* Parser.space
    }

    
    public func void() -> ParserOf<()> {
        return (self) *> Parser.success(())
    }

    
    public func optional(defaultVal:TokenType) -> ParserOf<TokenType> {
        return self <|> Parser.success(defaultVal)
    }

    public var discardToken:ParserOf<()> {
        return Parser.success(()) <* self
    }

    
    public func orElse<P:ParserType>(p:P) -> ParserOf<TokenType> where P.TokenType==TokenType {
        return self <|> p
    }

    // How can I avoid doing the start and end location for each parsing expression. How about
    // something like this:

    
    func withLocation() -> ParserOf<(TokenType,Location,Location)> {
        return Parser.sequence(Parser.currentLocation, self, Parser.currentLocation) { ($1, $0, $2) }
    }

    
}
/*
extension ParserType where TokenType==List<String> {
    @warn_unused_result
    public func join() -> ParserOf<String> {
        let join = flip(List<String>.joinWithSeparator)("")
        return join <§> self
    }
}
*/

public postfix func *<PT:ParserType, T>(p:PT) -> ParserOf<List<T>> where PT.TokenType==T {
    return p.repeatMany()
}


public postfix func +<PT:ParserType, T>(p:PT) -> ParserOf<List<T>> where PT.TokenType==T {
    return p.repeatOneOrMore()
}





