//
//  Tokenizer.swift
//  tibasic
//
//  Created by Michael Welch on 7/21/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//

import Foundation


func const<A,B>(a:A)(b:B) -> A {
    return a
}

func id<A>(a:A) -> A {
    return a
}

func liftA2<A,B,C>(f:A -> B -> C)(_ a:Tokenizer<A>)(_ b:Tokenizer<B>) -> Tokenizer<C> {
    return f <~> a <*> b
}


// Like Haskell fmap, <$>
infix operator <~> { associativity left precedence 120 }
func <~><A,B>(lhs:A->B, rhs:Tokenizer<A>) -> Tokenizer<B> {
    return fmap(lhs, rhs)
}

// Like Haskell Alternative <|>
infix operator <|> { associativity left precedence 110 }
func <|><A>(lhs:Tokenizer<A>, rhs:Tokenizer<A>) -> Tokenizer<A> {
    return Tokenizer { input in
        let result = lhs.tokenize(input)
        switch lhs.tokenize(input) {
        case .None: return rhs.tokenize(input)
        case .Some(_): return result
        }
    }
}


// Like Haskell Applicative <*>
infix operator <*> { associativity left precedence 120 }
func <*><A,B>(lhs:Tokenizer<A -> B>, rhs:Tokenizer<A>) -> Tokenizer<B> {
    return apply(lhs, rhs)
}

// Haskell Applicative <*
infix operator <* { associativity left precedence 120 }
func <*<A,B>(lhs:Tokenizer<A>, rhs:Tokenizer<B>) -> Tokenizer<A> {
    return liftA2(const)(lhs)(rhs)
}

// Haskell Applictive *>
infix operator *> { associativity left precedence 120 }
func *><A,B>(lhs:Tokenizer<A>, rhs:Tokenizer<B>) -> Tokenizer<B> {
    return liftA2(const(id))(lhs)(rhs)
}



// Like Haskell >>=, bind
infix operator |>>= { associativity left precedence 100 }
func |>>=<T1, T2>(lhs:Tokenizer<T1>, rhs:T1 -> Tokenizer<T2>) -> Tokenizer<T2> {
    return lhs.bind(rhs)
}

// Like Haskell >>
infix operator |>> { associativity left precedence 100 }
func |>><T1,T2>(lhs:Tokenizer<T1>, rhs:Tokenizer<T2>) -> Tokenizer<T2> {
    return lhs.bind { _ in rhs }
}

// Like Haskell $
infix operator !< { associativity right precedence 50 }
func !<<A,B>(lhs:A->B, rhs:A) -> B {
    return lhs(rhs)
}



/////////////////////////////////////////////
// Tokenizer struct and protocol
//////////////////

struct Tokenizer<T> : TokenizerType {
    let tokenizer:String -> (T,String)?
    init(tokenizer:String -> (T,String)?) {
        self.tokenizer = tokenizer
    }

    func tokenize(input: String) -> (token: T, output: String)? {
        return tokenizer(input)
    }
}

protocol TokenizerType {
    typealias T
    func tokenize(input: String) -> (token: T, output: String)?
}

///////////////////////////////




// Functions that return Tokenizers

func failure<T>() -> Tokenizer<T> {
    return Tokenizer { _ in nil }
}

func success<T>(t:T) -> Tokenizer<T> {
    return Tokenizer { input in (t, input) }
}

func sat(predicate:Character -> Bool) -> Tokenizer<Character> {
    return item |>>= { c in
        return predicate(c) ? success(c) : failure()
    }
}

func char(c:Character) -> Tokenizer<Character> {
    return sat() { x in c == x }
}

// Tokenizer primitives

let item:Tokenizer<Character> = Tokenizer<Character> { input in
    guard (input.characters.count > 0) else {
        return nil
    }
    return (input[input.startIndex], input.substringFromIndex(input.startIndex.successor()))
}

let isLetter:Character -> Bool = { c in isUpper(c) || isLower(c) }
let isDigit:Character -> Bool = { c in (c >= "0" && c <= "9") }
let isUpper:Character -> Bool = { c in (c >= "A" && c <= "Z") }
let isLower:Character -> Bool = { c in (c >= "a" && c <= "z") }
let isAlphanum:Character -> Bool = { isLetter($0) || isDigit($0) }

let letter:Tokenizer<Character> = sat !< isLetter
let digit:Tokenizer<Character> = sat(isDigit)
let upper:Tokenizer<Character> = sat(isUpper)
let lower:Tokenizer<Character> = sat(isLower)
let alphanum:Tokenizer<Character> = sat(isAlphanum)



extension Tokenizer {
    func bind<TB>(f:T -> Tokenizer<TB>) -> Tokenizer<TB> {
        return bind2(self, f)
    }

}

func bind2<TA, TB>(ma:Tokenizer<TA>, _ f:TA -> Tokenizer<TB>) -> Tokenizer<TB> {
    return Tokenizer { input in
        switch ma.tokenize(input) {
        case .None: return nil
        case .Some((let a, let output)): return f(a).tokenize(output)
        }
    }
}




func string(s:String) -> Tokenizer<String> {
    if s.isEmpty { return success("") }
    let c = s[s.startIndex]
    let cs = s.substringFromIndex(s.startIndex.successor())
    return char(c) |>> string(cs) |>> success(s)
}



infix operator +++ { associativity left precedence 150 }
func +++<TA>(t1:Tokenizer<TA>, t2:Tokenizer<TA>) -> Tokenizer<TA> {
    return Tokenizer { input in
        let parseResult = t1.tokenize(input)
        switch parseResult {
        case .None: return t2.tokenize(input)
        case .Some(_): return parseResult
        }
    }
}

func many<T>(t:Tokenizer<T>) -> Tokenizer<List<T>> {
    return many(t) +++ success(List<T>.Nil)
}

func manystack1<T>(t:Tokenizer<T>) -> Tokenizer<List<T>> {
    return t |>>= { v in
        many(t) |>>= { vs in
            return success(List<T>.Cons(h: v, t: vs))
        }
    }
}

let isSpace:Character -> Bool = { (c:Character) -> Bool in
    c == " " || c == "\n" || c == "\r" || c == "\t" }

let space:Tokenizer<()> = many(sat(isSpace)) |>> success(())
let ident:Tokenizer<String> = letter |>>= { c in
    many(alphanum) |>>= { cs in
        var list = List<Character>.Cons(h: c, t: cs)
        return success(String(list))
    }
}

let nat:Tokenizer<Int> = digit |>>= { d in
    many(digit) |>>= { ds in
        var list = List<Character>.Cons(h: d, t: ds)
        return success(Int(String(list))!) // Oops, could have some overflow or exception
    }
}

func token<T>(t:Tokenizer<T>) -> Tokenizer<T> {
    return space |>> t |>>= { v in
        space |>> success(v)
    }
}


let identifier = token(ident)
let natural = token(nat)
func symbol(xs:String) -> Tokenizer<String> {
    return token(string(xs))
}

func fmap<A,B>(f:A->B, _ t:Tokenizer<A>) -> Tokenizer<B> {
    return t |>>= { v in
        return success(f(v))
    }
}



func apply<A,B>(tf:Tokenizer<A -> B>, _ ta:Tokenizer<A>) -> Tokenizer<B> {
    return tf.bind { f in
        fmap(f, ta)
    }
}

indirect enum List<T> {
    case Nil
    case Cons(h:T, t:List<T>)
}

class ListGenerator<T> : AnyGenerator<T> {

    private(set) var list:List<Element>
    init(_ list:List<Element>) {
        self.list = list
    }
    override func next() -> Element? {
        switch list {
        case .Nil: return nil
        case .Cons(let h, let t):
            list = t
            return h
        }
    }
}

extension List : SequenceType {
    func generate() -> AnyGenerator<T> {
        return ListGenerator(self)
    }
}

struct Number {

}


enum PrintItem {
    case StringExpr(str:String) // should take expression
    case NumericExpr(num:Int) // should take expression
}

func parsePrintStringExpr() -> Tokenizer<PrintItem> {
    return PrintItem.StringExpr <~> identifier
}

func parsePrintNumericExpr() -> Tokenizer<PrintItem> {
    return PrintItem.NumericExpr <~> nat
}

func parsePrintItem() -> Tokenizer<PrintItem> {
    return parsePrintStringExpr()
    <|> parsePrintNumericExpr()
}

enum PrintSeparator {
    case Comma
    case Colon
    case Semicolon
    case Multiple(seperators: [PrintSeparator])
}



enum Expression {
    case NumericExpr
    case StringExpr
    case Relationalexpr
}

indirect enum NumericExpression {
    case NumberLiteral(Int)
    case Paren(NumericExpression)
    case Exp(NumericExpression, NumericExpression)
    case Negate(NumericExpression)
    case Multiply(NumericExpression, NumericExpression)
    case Divide(NumericExpression, NumericExpression)
    case Add(NumericExpression, NumericExpression)
    case Subtract(NumericExpression, NumericExpression)
}
func curry<A,B,C>(f:(A,B)->C)(_ a:A)(_ b:B) -> C {
    return f(a,b)
}

let left_paren = char("(")
let right_paren = char(")")
let exponent_op = char("^")
let mult_op = char("*")
let divide_op = char("/")
let plus_op = char("+")
let subtract_op = char("-")
let number = nat

let numeric_expression:Tokenizer<NumericExpression> = add_expression

let number_literal_expr = NumericExpression.NumberLiteral <~> number

let paren_expression = number_literal_expr
  <|> NumericExpression.Paren <~> (left_paren *> numeric_expression <* right_paren)

let exponent_expresion = paren_expression
  <|> curry(NumericExpression.Exp) <~> (numeric_expression <* exponent_op) <*> numeric_expression

let prefix_expression = exponent_expresion
  <|> plus_op *> numeric_expression
  <|> NumericExpression.Negate <~> (subtract_op *> numeric_expression)

let multiply_expression = prefix_expression
  <|> curry(NumericExpression.Multiply) <~> (numeric_expression <* mult_op) <*> numeric_expression
  <|> curry(NumericExpression.Divide) <~> (numeric_expression <* divide_op) <*> numeric_expression

let add_expression = multiply_expression
  <|> curry(NumericExpression.Add) <~> (numeric_expression <* plus_op) <*> numeric_expression
  <|> curry(NumericExpression.Subtract) <~> (numeric_expression <* subtract_op) <*> numeric_expression
