//
//  ParserTests.swift
//  ParserTests
//
//  Created by andrey.pleshkov on 08/05/2018.
//

import XCTest
@testable import Parser
import SourceKittenFramework

class TypeParserTests: XCTestCase {

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

    func testSource1() {
        XCTAssertEqual(
            parse(contents: "class Foo {}"),
            [ParsedType(name: "Foo", isReference: true)]
        )
        XCTAssertEqual(
            parse(contents: "struct Foo {}"),
            [ParsedType(name: "Foo")]
        )
    }

    func testSource2() {
        XCTAssertEqual(
            parse(contents: "struct Foo<T> {}"),
            [ParsedType(name: "Foo").add(generic: ParsedType(name: "T"))]
        )
    }
}

private func parse(contents: String) -> [ParsedType] {
    let structure = try! Structure(file: File(contents: contents))
    return structure.dictionary.swiftSubstructures!.compactMap {
        return TypeParser().parse($0, contents: contents)
    }
}
