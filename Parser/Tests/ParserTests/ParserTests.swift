//
//  ParserTests.swift
//  ParserTests
//
//  Created by andrey.pleshkov on 08/05/2018.
//

import XCTest
@testable import Parser

class ParserTests: XCTestCase {

    func testSimple() {
        XCTAssertEqual(
            TypeParser().parse("Foo"),
            ParsedType(name: "Foo")
        )
    }

    func testOptional() {
        XCTAssertEqual(
            TypeParser().parse("Foo?"),
            ParsedType(name: "Foo", isOptional: true)
        )
    }

    func testUnwrapped() {
        XCTAssertEqual(
            TypeParser().parse("Foo!"),
            ParsedType(name: "Foo", isUnwrapped: true)
        )
    }

    func testGenrics() {
        XCTAssertEqual(
            TypeParser().parse("Foo<Bar, Baz?>"),
            ParsedType(name: "Foo")
                .add(generic: ParsedType(name: "Bar"))
                .add(generic: ParsedType(name: "Baz", isOptional: true))
        )
    }

    func testNested() {
        XCTAssertEqual(
            TypeParser().parse("Foo.Bar.Baz"),
            ParsedType(name: "Foo.Bar.Baz")
        )
    }
}
