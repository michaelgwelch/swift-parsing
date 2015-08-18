//: Playground - noun: a place where people can play

import Cocoa
import Parsing


print("qu", appendNewline: false)

var rrkd = natural.tokenize("23")

var result = (NumExpression.NumberLiteral <§> number).tokenize("234 ")
result = (NumExpression.Id <§> identifier).tokenize("abd")
result = ((NumExpression.Id <§> identifier) <|> (NumExpression.NumberLiteral <§> number)).tokenize("abc")

let lparen = char("(")
let rparen = char(")")

result = (lparen *> (NumExpression.NumberLiteral <§> number) <* rparen).tokenize("(23)")

result = exp_operand.tokenize("1")


var h = NumExpression.NumberLiteral(345)




//
//print("hi")
//
//var result:(Int,String)? = failure().tokenize("hello")
//result = success(55).tokenize("hello")
//let r2 = item.tokenize("hello")
//var r3 = (item *> item *> item).tokenize("hello")
//r3 = char("h").tokenize("hello")
//r3 = char("i").tokenize("hello")
//r3 = char("i").tokenize("")
//
//
//var l = cons(3)(cons(5)(.Nil))
//
//
//
//let const2:(String,Int)->String = uncurry(const)
//
