//
//  ParsingTests.swift
//  ParsingTests
//
//  Created by Michael Welch on 8/13/15.
//  Copyright © 2015 Michael Welch. All rights reserved.
//
import Swift
import XCTest
@testable import SwiftParsing

typealias P=Parser
//func AssertNil<T>(_ expression: @autoclosure () -> T?, message: String = "",
//    file: String = #file, line: UInt = #line) {
//
//        XCTAssert(expression() == nil, message, file:file, line:line);
//}

func ==<T:Equatable,U:Equatable>(lhs: (T,U), rhs: (T,U)) -> Bool {
    return lhs.0 == rhs.0 && lhs.1 == rhs.1
}

//func AssertEqual<T:Equatable,U:Equatable>(_ expression1: (T,U), _ expression2: (T,U)) {
//    XCTAssert(expression1 == expression2)
//}

//func AssertEqual<T:Equatable,U:Equatable>(_ expression1: ([T],U), _ expression2: ([T],U)) {
//    XCTAssertEqual(expression1.0, expression2.0)
//    XCTAssertEqual(expression1.1, expression2.1)
//}


class Success: XCTestCase {

    func testConsumesNoInput() {
        let expected = (5, "Hello")
        let actual = P.success(5).parse("Hello")!
        AssertEqual(expected, actual)
    }

    func testCanReturnWhateverIsWrapped() {
        let (token, _) = P.success([UInt8]()).parse("hello")!
        XCTAssertEqual(token, [UInt8]())
    }

    func testContextDoesNotChange() {
        // Arrange
        let string = "watch television"
        let expected = ParserContext(row: 1, col:6, string:string)
        // Act
        let (_, actual) = P.success(24).parse(expected)!

        // Assert
        XCTAssertEqual(expected, actual)
    }

}

class Failure: XCTestCase {
    func testAlwaysReturnsNil() {
        var result:(Int,String)? = P.failure().parse("")
        AssertNil(result)

        result = P.failure().parse("hello")
        AssertNil(result)
    }
}

class Item: XCTestCase {
    func testFailsOnEmptyString() {
        let result:(Character,String)? = P.item.parse("")
        AssertNil(result)
    }

    func testConsumesAndReturnsOneCharacter() {
        let expected:(Character,String) = ("i", "tem")
        let actual = P.item.parse("item")!
        AssertEqual(expected, actual)
    }

    func testOnSameLineColumnIncreases() {
        // Arrange
        let string = "alphabet"
        let context = ParserContext(row: 1, col: 3, string: string)
        let expected = ParserContext(row: 1, col: 4, string: "lphabet")
        // Act
        let (_, actual) = P.item.parse(context)!
        // Assert
        XCTAssertEqual(expected, actual)
    }

    func testWhenNewLineParsedRowIncreasesColumnSetToOne() {
        let string = "\nMichael"
        let context = ParserContext(row: 1, col: 6, string: string)
        let expected = ParserContext(row: 2, col: 1, string: "Michael")

        // Act
        let (_, actual) = P.item.parse(context)!
        // Assert
        XCTAssertEqual(expected, actual)

    }
}

class Sat: XCTestCase {
    func testFailsIfPredicateEvaluatesToFalse() {
        let result = P.satisfy { $0 < "a" }.parse("boat")
        AssertNil(result)
    }
    func testConsumesAndReturnsOneCharacterIfPredicateEvaluatesToTrue() {
        let expected:(Character,String) = ("b", "oat")
        let actual = P.satisfy { $0 > "a" }.parse("boat")!
        AssertEqual(expected, actual)
    }
}

class Char: XCTestCase {
    func testFailsOnEmptyStringInput() {
        let result = P.char("a").parse("")
        AssertNil(result)
    }
    func testFailsIfCharDoesNotMatch() {
        let result = P.char("z").parse("chair")
        AssertNil(result)
    }
    func testConsumesAndReturnsOneCharacterIfItMatches() {
        let expected:(Character, String) = ("c", "hair")
        let parser = P.char("c")
        let actual = parser.parse("chair")
        AssertEqual(expected, actual!)
    }
}

class Letter: XCTestCase {
    func testFailsIfEmptyStringInput() {
        let result = P.letter.parse("")
        AssertNil(result)
    }
    func testFailsIfFirstCharIsNotALetter() {
        let result = P.letter.parse("[]")
        AssertNil(result)
    }
    func testConsumesAndReturnsOneCharacterIfALetter() {
        let expected = ExpectedResult("l", "etter")
        let actual = P.letter.parse("letter")!
        AssertEqual(expected, actual)
    }
}

class StringParser: XCTestCase {
    func testAlwaysParsesEmptyString() {
        let expected = ("", "")
        var actual = P.string("").parse("")!
        AssertEqual(expected, actual)

        actual = P.string("").parse("hello")!
        AssertEqual(("","hello"), actual)
    }
    func testParsesSingleCharString() {
        let expected = ("l", "etter")
        let actual = P.string("l").parse("letter")!
        AssertEqual(expected, actual)
    }
    func testParsesString() {
        let expected = ("let","ter")
        let actual = P.string("let").parse("letter")!
        AssertEqual(expected, actual)
    }
    func testFailsIfNoMatch() {
        AssertNil(P.string("hello").parse("goodbye"))
    }
    func testColumnIncreasesByNumberOfCharactersInString() {
        let string = "\nMichael"
        let context = ParserContext(row: 1, col: 6, string: string)
        let expected = ParserContext(row: 2, col: 8, string: "")

        // Act
        let (_, actual) = P.string("\nMichael").parse(context)!
        // Assert
        XCTAssertEqual(expected, actual)
    }
}

class Number: XCTestCase {
    func testParsesANumber() {
        let expected = (123, "")
        let actual = P.natural.parse("123")!
        AssertEqual(expected, actual)
    }
}


// MARK: Operators


class Choice: XCTestCase {
    func testChoice() {
        // If first choice fails, return results of second
        let wrappedValue = [UInt8]()
        let expected = (wrappedValue,"hello")
        let actual = (P.failure() <|> P.success(wrappedValue)).parse("hello")!
        AssertEqual(expected, actual)
    }
}

class Many: XCTestCase {
    func testZeroMatches() {
        let expected = ("", "hello")
        let actual = String.init <§> P.char("a").repeatMany().parse("hello")!
        AssertEqual(expected, actual)
    }
}

// MARK: MIsc


func ExpectedResult(_ c:Character, _ str:String) -> (Character, String) {
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
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
