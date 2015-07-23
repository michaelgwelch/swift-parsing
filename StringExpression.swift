//
//  StringExpression.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation

public enum StringExpression {
    case Literal(s:String)
}

public let string_expression = StringExpression.Literal <§> string("")