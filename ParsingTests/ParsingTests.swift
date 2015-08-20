//
//  ParsingTests.swift
//  ParsingTests
//
//  Created by Michael Welch on 8/13/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//
import Swift
import XCTest
@testable import Parsing

func AssertNil<T>(@autoclosure expression: () -> T?, message: String = "",
    file: String = __FILE__, line: UInt = __LINE__) {

        XCTAssert(expression() == nil, message, file:file, line:line);
}

func ==<T:Equatable,U:Equatable>(lhs: (T,U), rhs: (T,U)) -> Bool {
    return lhs.0 == rhs.0 && lhs.1 == rhs.1
}

func AssertEqual<T:Equatable,U:Equatable>(expression1: (T,U), _ expression2: (T,U)) {
    XCTAssert(expression1 == expression2)
}

func AssertEqual<T:Equatable,U:Equatable>(expression1: ([T],U), _ expression2: ([T],U)) {
    XCTAssertEqual(expression1.0, expression2.0)
    XCTAssertEqual(expression1.1, expression2.1)
}


class Success: XCTestCase {

    func testConsumesNoInput() {
        let expected = (5, "Hello")
        let actual = success(5).parse("Hello")!
        AssertEqual(expected, actual)
    }

    func testCanReturnWhateverIsWrapped() {
        let (token, _) = success([UInt8]()).parse("hello")!
        XCTAssertEqual(token, [UInt8]())
    }

}

class Failure: XCTestCase {
    func testAlwaysReturnsNil() {
        var result:(Int,String)? = failure().parse("")
        AssertNil(result)

        result = failure().parse("hello")
        AssertNil(result)
    }
}

class Item: XCTestCase {
    func testFailsOnEmptyString() {
        let result:(Character,String)? = item.parse("")
        AssertNil(result)
    }

    func testConsumesAndReturnsOneCharacter() {
        let expected:(Character,String) = ("i", "tem")
        let actual = item.parse("item")!
        AssertEqual(expected, actual)
    }
}

class Sat: XCTestCase {
    func testFailsIfPredicateEvaluatesToFalse() {
        let result = sat { $0 < "a" }.parse("boat")
        AssertNil(result)
    }
    func testConsumesAndReturnsOneCharacterIfPredicateEvaluatesToTrue() {
        let expected:(Character,String) = ("b", "oat")
        let actual = sat { $0 > "a" }.parse("boat")!
        AssertEqual(expected, actual)
    }
}

class Char: XCTestCase {
    func testFailsOnEmptyStringInput() {
        let result = char("a").parse("")
        AssertNil(result)
    }
    func testFailsIfCharDoesNotMatch() {
        let result = char("z").parse("chair")
        AssertNil(result)
    }
    func testConsumesAndReturnsOneCharacterIfItMatches() {
        let expected:(Character, String) = ("c", "hair")
        let actual = char("c").parse("chair")!
        AssertEqual(expected, actual)
    }
}

class Letter: XCTestCase {
    func testFailsIfEmptyStringInput() {
        let result = letter.parse("")
        AssertNil(result)
    }
    func testFailsIfFirstCharIsNotALetter() {
        let result = letter.parse("[]")
        AssertNil(result)
    }
    func testConsumesAndReturnsOneCharacterIfALetter() {
        let expected = ExpectedResult("l", "etter")
        let actual = letter.parse("letter")!
        AssertEqual(expected, actual)
    }
}

class StringParser: XCTestCase {
    func testAlwaysParsesEmptyString() {
        let expected = ("", "")
        var actual = string("").parse("")!
        AssertEqual(expected, actual)

        actual = string("").parse("hello")!
        AssertEqual(("","hello"), actual)
    }
    func testParsesSingleCharString() {
        let expected = ("l", "etter")
        let actual = string("l").parse("letter")!
        AssertEqual(expected, actual)
    }
    func testParsesString() {
        let expected = ("let","ter")
        let actual = string("let").parse("letter")!
        AssertEqual(expected, actual)
    }
}

class Number: XCTestCase {
    func testParsesANumber() {
        let expected = (123, "")
        let actual = natural.parse("123")!
        AssertEqual(expected, actual)
    }
}


// MARK: Operators


class Choice: XCTestCase {
    func testChoice() {
        // If first choice fails, return results of second
        let wrappedValue = [UInt8]()
        let expected = (wrappedValue,"hello")
        let actual = (failure() <|> success(wrappedValue)).parse("hello")!
        AssertEqual(expected, actual)
    }
}

class Many: XCTestCase {
    func testZeroMatches() {
        let expected = ("", "hello")
        let actual = String.init <§> many(char("a")).parse("hello")!
        AssertEqual(expected, actual)
    }
}

// MARK: MIsc


func ExpectedResult(c:Character, _ str:String) -> (Character, String) {
    return (c,str)
}

class ParsingTests: XCTestCase {

    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {

    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}