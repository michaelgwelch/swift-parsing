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

struct Parser<T> {
    private let parse:String -> (T,String)?
    init(parse:String -> (T,String)?) {
        self.parse = parse
    }

    func tokenize(input: String) -> (token: T, output: String)? {
        return parse(input)
    }
}


///////////////////////////////



// Functions that return Tokenizers

func failure<T>() -> Parser<T> {
    return Parser { _ in nil }
}

func success<T>(t:T) -> Parser<T> {
    return Parser { input in (t, input) }
}

func sat(predicate:Character -> Bool) -> Parser<Character> {

    return item |>>= { c in
        return predicate(c) ? success(c) : failure()
    }
}

func char(c:Character) -> Parser<Character> {
    return sat() { x in c == x }
}

// Parser primitives

let item:Parser<Character> = Parser<Character> { input in
    guard (input.characters.count > 0) else {
        return nil
    }
    return (input[input.startIndex], input.substringFromIndex(input.startIndex.successor()))
}

let isLetter:Character -> Bool = { c in isUpper(c) || isLower(c) }
let isDigit:Character -> Bool = { c in (c >= "0" && c <= "9") }
let isUpper:Character -> Bool = { c in (c >= "A" && c <= "Z") }
let isLower:Character -> Bool = { c in (c >= "a" && c <= "z") }
let isAlphanum:Character -> Bool = { isLetter($0) || isDigit($0) }

let letter:Parser<Character> = sat § isLetter
let digit:Parser<Character> = sat(isDigit)
let upper:Parser<Character> = sat(isUpper)
let lower:Parser<Character> = sat(isLower)
let alphanum:Parser<Character> = sat(isAlphanum)



extension Parser {
    func bind<TB>(f:T -> Parser<TB>) -> Parser<TB> {
        return bind2(self, f)
    }
}

func bind2<TA, TB>(ma:Parser<TA>, _ f:TA -> Parser<TB>) -> Parser<TB> {
    return Parser { input in
        switch ma.tokenize(input) {
        case .None: return nil
        case .Some((let a, let output)): return f(a).tokenize(output)
        }
    }
}




func string(s:String) -> Parser<String> {
    if s.isEmpty { return success("") }
    let c = s[s.startIndex]
    let cs = s.substringFromIndex(s.startIndex.successor())
    return char(c) |>> string(cs) |>> success(s)
}


func many<T>(t:Parser<T>) -> Parser<List<T>> {
    return many1(t) <|> success(List<T>.Nil)
}

func many1<T>(t:Parser<T>) -> Parser<List<T>> {
    return cons <§> t <*> many(t)
}

let isSpace:Character -> Bool = { (c:Character) -> Bool in
    c == " " || c == "\n" || c == "\r" || c == "\t" }

let space:Parser<()> = many(sat(isSpace)) |>> success(())

let ident:Parser<String> = String.init <§> (cons <§> letter <*> many(alphanum))

let int:String -> Int = { (s:String) in Int(s)!}

let nat:Parser<Int> = int <§> (String.init <§> (cons <§> digit <*> many(digit)))

func token<T>(t:Parser<T>) -> Parser<T> { return (space *> t) <* space }


let identifier = token(ident)
let natural = token(nat)
func symbol(xs:String) -> Parser<String> {
    return token(string(xs))
}




