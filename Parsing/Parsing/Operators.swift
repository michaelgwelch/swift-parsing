//
//  Operators.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation


// Like Haskell fmap, <$>
infix operator <§> { associativity left precedence 140 }

// Like Haskell Applicative <*>
infix operator <*> { associativity left precedence 120 }

// Haskell Applicative <*
infix operator <* { associativity left precedence 120 }

// Haskell Applictive *>
infix operator *> { associativity left precedence 120 }

// Like Haskell Alternative <|>
infix operator <|> { associativity left precedence 110 }


// Like Haskell >>=, bind
infix operator |>>= { associativity left precedence 100 }

// Like Haskell >> (sequence and throw away the value on the left)
infix operator |>> { associativity left precedence 100 }

// Like Haskell $
infix operator § { associativity right precedence 50 }

// Like Haskell . (compose)
infix operator • { associativity right precedence 190 }

// repeatMany
postfix operator * {}
postfix operator + {}

