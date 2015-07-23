//
//  RelationalExpression.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation

indirect enum RelationalExpression {
    case LessThan(RelationalExpression, RelationalExpression)
    case True
    case False
}

let relational_expression = success(RelationalExpression.True)