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
