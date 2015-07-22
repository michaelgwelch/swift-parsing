//
//  Token.swift
//  tibasic
//
//  Created by Michael Welch on 7/18/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation

enum Token {
    case Colon
    case EOF
    case EOL
    case Error
//    Colon       = ':',
//    Comma       = ',',
//    Exponent    = '^',
//    LessThan    = '<',
//    GreaterThan = '>',
//    Concatenate = '&',
//    Equals      = '=',
//    LeftParen   = '(',
//    RightParen  = ')',
//    Plus        = '+',
//    Minus       = '-',
//    Times       = '*',
//    Divides     = '/',
//    Semicolon   = ';',
//    And         = 256,
//    Base,
//    Call,
//    Data,
//    Dim,
//    Else,
//    End, // used for keywords END and STOP
//    EndOfLine,
//    EOF, // end of file
//    Error,
//    Float,
//    For,
//    Function,
//    Go, // As part of GO SUB
//    Goto,
//    Gosub,
//    GreaterThanEqual,
//    If,
//    Input,
//    LessThanEqual,
//    Let,
//    Next,
//    Not,
//    NotEquals,
//    Number,
//    On,
//    Or,
//    Option,
//    Print,
//    Randomize,
//    Read,
//    Remark, // technically not a token, and should never be returned. Used internally by lexer only.
//    Restore,
//    Return,
//    String,
//    Sub,        // The key word "SUB"
//    Subroutine, // A built in subroutine like clear, or print.
//    Tab,
//    Then,
//    To,
//    Variable
}