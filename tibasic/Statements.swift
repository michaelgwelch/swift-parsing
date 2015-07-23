//
//  Statements.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation
enum PrintItem {
    case StringExpr(str:String) // should take expression
    case NumericExpr(num:Int) // should take expression
}

func parsePrintStringExpr() -> Parser<PrintItem> {
    return PrintItem.StringExpr <§> identifier
}

func parsePrintNumericExpr() -> Parser<PrintItem> {
    return PrintItem.NumericExpr <§> nat
}

func parsePrintItem() -> Parser<PrintItem> {
    return parsePrintStringExpr()
        <|> parsePrintNumericExpr()
}

enum PrintSeparator {
    case Comma
    case Colon
    case Semicolon
    case Multiple(seperators: [PrintSeparator])
}
