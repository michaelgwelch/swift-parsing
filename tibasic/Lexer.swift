//
//  Lexer.swift
//  tibasic
//
//  Created by Michael Welch on 7/18/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation

import Swift

struct Lexeme {
    let token:Token
    let value:TokenValue
    init(_ token:Token) {
        // gurad that token is not number or string
        self.init(token, withValue: TokenValue.None)
    }
    init(_ token:Token, withValue value:TokenValue) {
        // guard that token is one of number or string
        self.token = token
        self.value = value
    }
}
extension Lexeme : Equatable {
    
}
func ==(lhs:Lexeme, rhs:Lexeme) -> Bool {
    return true
}

func !=(lhs:Lexeme, rhs:Lexeme) -> Bool {
    return false
}


enum TokenValue {
    case None
    case StringValue(s:String)
    case FloatingPointValue(d:Double)
    case IntegerValue(i:Int)
}

class Lexer {
    private let s:String
    private var pos:String.CharacterView.Index
    private(set) var col:Int = 1
    private(set) var line:Int = 1
    private var tokenValue:TokenValue

    init(s:String) {
        self.s = s
        pos = s.startIndex
        tokenValue = TokenValue.None
    }

    func next() -> Lexeme {
        skipWhiteSpace()
        guard (pos < s.endIndex) else {
            return Lexeme(Token.EOF)
        }

        let char = advance()
        if (char == "\r") {
            return Lexeme(Token.EOL)
        }

        return Lexeme(Token.Error)
    }

    private func advance() -> Character {
        skipWhiteSpace()
        let char = s[pos]
        pos = pos.successor()
        return char
    }

    private func skipWhiteSpace() {
        var char = s[pos]
        while (char == "\n" || char == " " || char == "\t" || char == "\r") && pos < s.endIndex {
            pos == pos.successor()
            char = s[pos]
        }
    }

}

struct Tokenizer<T> : Tokenizes {
    let tokenizer:String -> (T,String)?
    init(tokenizer:String -> (T,String)?) {
        self.tokenizer = tokenizer
    }

    func tokenize(input: String) -> (token: T, output: String)? {
        return tokenizer(input)
    }
}

protocol Tokenizes {
    typealias T
    func tokenize(input: String) -> (token: T, output: String)?
}



func failure<T>() -> Tokenizer<T> {
    return Tokenizer { _ in nil }
}

func success<T>(t:T) -> Tokenizer<T> {
    return Tokenizer { input in (t, input) }
}

let item:Tokenizer<Character> = Tokenizer<Character> { input in
        guard (input.characters.count > 0) else {
            return nil
        }
        return (input[input.startIndex], input.substringFromIndex(input.startIndex.successor()))
    }


func sat(predicate:Character -> Bool) -> Tokenizer<Character> {
    return item |>>= { c in
        return predicate(c) ? success(c) : failure()
    }
}

func char(c:Character) -> Tokenizer<Character> {
    return sat() { x in c == x }
}

extension Tokenizer {
    func bind<TB>(f:T -> Tokenizer<TB>) -> Tokenizer<TB> {
        return bind2(self, f)
    }
}

infix operator |>>= { associativity left precedence 160 }
func |>>=<T1, T2>(lhs:Tokenizer<T1>, rhs:T1 -> Tokenizer<T2>) -> Tokenizer<T2> {
    return lhs.bind(rhs)
}

infix operator |>> { associativity left precedence 160 }
func |>><T1,T2>(lhs:Tokenizer<T1>, rhs:Tokenizer<T2>) -> Tokenizer<T2> {
    return lhs.bind { _ in rhs }
}

let isLetter:Character -> Bool = { c in isUpper(c) || isLower(c) }
let isDigit:Character -> Bool = { c in (c >= "0" && c <= "9") }
let isUpper:Character -> Bool = { c in (c >= "A" && c <= "Z") }
let isLower:Character -> Bool = { c in (c >= "a" && c <= "z") }
let isAlphanum:Character -> Bool = { isLetter($0) || isDigit($0) }

let letter:Tokenizer<Character> = sat(isLetter)
let digit:Tokenizer<Character> = sat(isDigit)
let upper:Tokenizer<Character> = sat(isUpper)
let lower:Tokenizer<Character> = sat(isLower)
let alphanum:Tokenizer<Character> = sat(isAlphanum)

func string(s:String) -> Tokenizer<String> {
    if s.isEmpty { return success("") }
    let c = s[s.startIndex]
    let cs = s.substringFromIndex(s.startIndex.successor())
    return char(c) |>> string(cs) |>> success(s)
}

func bind2<TA, TB>(ma:Tokenizer<TA>, _ f:TA -> Tokenizer<TB>) -> Tokenizer<TB> {
    return Tokenizer { input in
        switch ma.tokenize(input) {
        case .None: return nil
        case .Some((let a, let output)): return f(a).tokenize(output)
        }
    }
}

infix operator +++ { associativity left precedence 150 }
func +++<TA>(t1:Tokenizer<TA>, t2:Tokenizer<TA>) -> Tokenizer<TA> {
    return Tokenizer { input in
        let parseResult = t1.tokenize(input)
        switch parseResult {
        case .None: return t2.tokenize(input)
        case .Some(_): return parseResult
        }
    }
}

func many<T>(t:Tokenizer<T>) -> Tokenizer<List<T>> {
    return many(t) +++ success(List<T>.Nil)
}

func manystack1<T>(t:Tokenizer<T>) -> Tokenizer<List<T>> {
    return t |>>= { v in
        many(t) |>>= { vs in
            return success(List<T>.Cons(h: v, t: Box(vs)))
        }
    }
}

let isSpace:Character -> Bool = { (c:Character) -> Bool in
    c == " " || c == "\n" || c == "\r" || c == "\t" }

let space:Tokenizer<()> = many(sat(isSpace)) |>> success(())
let ident:Tokenizer<String> = letter |>>= { c in
    many(alphanum) |>>= { cs in
        var list = List<Character>.Cons(h: c, t: Box(cs))
        return success(String(list))
    }
}

let nat:Tokenizer<Int> = digit |>>= { d in
    many(digit) |>>= { ds in
        var list = List<Character>.Cons(h: d, t: Box(ds))
        return success(Int(String(list))!) // Oops, could have some overflow or exception
    }
}

func token<T>(t:Tokenizer<T>) -> Tokenizer<T> {
    return space |>> t |>>= { v in
        space |>> success(v)
    }
}


let identifier = token(ident)
let natural = token(nat)
func symbol(xs:String) -> Tokenizer<String> {
    return token(string(xs))
}

func fmap<A,B>(f:A->B, _ t:Tokenizer<A>) -> Tokenizer<B> {
    return t |>>= { v in
        return success(f(v))
    }
}

infix operator <|> { }
func <|><A,B>(lhs:A->B, rhs:Tokenizer<A>) -> Tokenizer<B> {
    return fmap(lhs, rhs)
}

func apply<A,B>(tf:Tokenizer<A -> B>, _ ta:Tokenizer<A>) -> Tokenizer<B> {
    return tf.bind { f in
        f <|> ta
    }
}

infix operator <*> { associativity left precedence 160 }
func <*><A,B>(lhs:Tokenizer<A -> B>, rhs:Tokenizer<A>) -> Tokenizer<B> {
    return apply(lhs, rhs)
}

class Box<T> {
    private(set) var value:T
    init(_ value:T) {
        self.value = value
    }
}

enum List<T> {
    case Nil
    case Cons(h:T, t:Box<List<T>>)
}

class ListGenerator<T> : AnyGenerator<T> {

    private(set) var list:List<Element>
    init(_ list:List<Element>) {
        self.list = list
    }
    override func next() -> Element? {
        switch list {
        case .Nil: return nil
        case .Cons(let h, let box):
            list = box.value
            return h
        }
    }
}

extension List : SequenceType {
    func generate() -> AnyGenerator<T> {
        return ListGenerator(self)
    }
}
