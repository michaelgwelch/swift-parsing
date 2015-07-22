//
//  tibasic_unit_test.swift
//  tibasic-unit-test
//
//  Created by Michael Welch on 7/19/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import XCTest



class LexerTest: XCTestCase {

    
    func testEOF() {
        let s = ""
        let result = lex(s)

        let expected:Lexeme = Lexeme(Token.EOF)

        XCTAssertEqual([expected], result)

        let lexer:Lexer = Lexer(s: "")

        let t = lexer.next()

        XCTAssertEqual(Token.EOF, t.token)
    }

    func testEOL() {


        let actual = lex("\r ")
        let expected = [Token.EOL, Token.EOF].map() { Lexeme($0) }



        XCTAssertEqual(actual, expected)
    }



    func lex(s:String) -> [Lexeme] {
        let lexer = Lexer(s:s)
        var lexemes = [Lexeme]()

        var lexeme = lexer.next()
        repeat {
            lexemes.append(lexeme)
            lexeme = lexer.next()

        } while lexeme.token != Token.EOF

        return lexemes

    }
    
}
