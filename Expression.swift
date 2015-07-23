//
//  Expression.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation

public enum Expression {
    case Numeric(NumericExpression)
    case String(StringExpression)
    case Relational(RelationalExpression)
}

public let expression = Expression.Numeric <§> numeric_expression
    <|> Expression.Relational <§> relational_expression
    <|> Expression.String <§> string_expression