//
//  Operators.swift
//  tibasic
//
//  Created by Michael Welch on 7/22/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//


/*
 Haskell Precdence
 . 9 r (function composition)
 * 7 l
 + 6 l
 
 *>  4 l
 <*  4 l
 <*> 4 l
 <$> 4 l
 == 4 none
 <|> 3 l
 && 3 r
 || 2 r
 >>  1 l
 >>= 1 l
 $ 0 r
 */


import Foundation

// §
precedencegroup ApplicationPrecedence {
    higherThan: AssignmentPrecedence, TernaryPrecedence
    associativity: right
}

precedencegroup MonadicBindPrecedence {
    higherThan: ApplicationPrecedence
    associativity: left
}

precedencegroup AlternativePrecedence {
    higherThan: MonadicBindPrecedence
    associativity: left
}


precedencegroup ApplicativePrecedence {
    higherThan: AlternativePrecedence
    associativity: left
}

precedencegroup FunctionCompositionPrecedence {
    higherThan: ApplicativePrecedence
    associativity: right
}




 // Like Haskell . (compose)
infix operator • : FunctionCompositionPrecedence

// Like Haskell fmap, <$>
infix operator <§> : ApplicativePrecedence



// Like Haskell Applicative <*>
infix operator <*> : ApplicativePrecedence //{ associativity left precedence 120 }

// Haskell Applicative <*
infix operator <* : ApplicativePrecedence //{ associativity left precedence 120 }


// Haskell Applictive *>
//infix operator *> { associativity left precedence 120 }
infix operator *> : ApplicativePrecedence

// Like Haskell Alternative <|>
infix operator <|> : AlternativePrecedence



// Like Haskell >>=, bind
infix operator |>>= : MonadicBindPrecedence

// Like Haskell >> (sequence and throw away the value on the left)
infix operator |>> : MonadicBindPrecedence

// Like Haskell $
infix operator § : ApplicationPrecedence


// repeatMany
postfix operator *
postfix operator +



