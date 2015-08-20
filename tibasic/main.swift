//
//  main.swift
//  tibasic
//
//  Created by Michael Welch on 7/18/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation



print("Hello, World!")

let result = num_expression.parse("2^3*5")



print(result?.token.eval( ["a":7, "b":3 ] ))



