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

let letter:Parser<Character> = sat !< isLetter
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



infix operator +++ { associativity left precedence 150 }
func +++<TA>(t1:Parser<TA>, t2:Parser<TA>) -> Parser<TA> {
    return Parser { input in
        let parseResult = t1.tokenize(input)
        switch parseResult {
        case .None: return t2.tokenize(input)
        case .Some(_): return parseResult
        }
    }
}

func many<T>(t:Parser<T>) -> Parser<List<T>> {
    return many(t) +++ success(List<T>.Nil)
}

func manystack1<T>(t:Parser<T>) -> Parser<List<T>> {
    return t |>>= { v in
        many(t) |>>= { vs in
            return success(List<T>.Cons(h: v, t: vs))
        }
    }
}

let isSpace:Character -> Bool = { (c:Character) -> Bool in
    c == " " || c == "\n" || c == "\r" || c == "\t" }

let space:Parser<()> = many(sat(isSpace)) |>> success(())
let ident:Parser<String> = letter |>>= { c in
    many(alphanum) |>>= { cs in
        var list = List<Character>.Cons(h: c, t: cs)
        return success(String(list))
    }
}

let nat:Parser<Int> = digit |>>= { d in
    many(digit) |>>= { ds in
        var list = List<Character>.Cons(h: d, t: ds)
        return success(Int(String(list))!) // Oops, could have some overflow or exception
    }
}

func token<T>(t:Parser<T>) -> Parser<T> {
    return space |>> t |>>= { v in
        space |>> success(v)
    }
}


let identifier = token(ident)
let natural = token(nat)
func symbol(xs:String) -> Parser<String> {
    return token(string(xs))
}

func fmap<A,B>(f:A->B, _ t:Parser<A>) -> Parser<B> {
    return t |>>= { v in
        return success(f(v))
    }
}



func apply<A,B>(tf:Parser<A -> B>, _ ta:Parser<A>) -> Parser<B> {
    return tf.bind { f in
        fmap(f, ta)
    }
}
