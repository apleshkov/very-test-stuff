//
//  ExtensionParserTests.swift
//  ParserTests
//
//  Created by andrey.pleshkov on 28/05/2018.
//

import XCTest
@testable import Parser
import SourceKittenFramework

class ExtensionParserTests: XCTestCase {
    
    func testClass() {
        XCTAssertEqual(
            parse(contents:
                """
                class Foo {}
                extension Foo {}
                """
            ),
            [ParsedExtension(typeName: "Foo")]
        )
        XCTAssertEqual(
            parse(contents:
                """
                class Foo {}
                extension Foo: Bar, Baz {}
                """
            ),
            [
                ParsedExtension(
                    typeName: "Foo",
                    inheritedFrom: [
                        ParsedTypeUsage(name: "Bar"),
                        ParsedTypeUsage(name: "Baz")
                    ]
                )
            ]
        )
    }

    func testStruct() {
        XCTAssertEqual(
            parse(contents:
                """
                struct Foo {}
                extension Foo {}
                """
            ),
            [ParsedExtension(typeName: "Foo")]
        )
        XCTAssertEqual(
            parse(contents:
                """
                struct Foo {}
                extension Foo: Bar {}
                extension Foo: Baz {}
                """
            ),
            [
                ParsedExtension(
                    typeName: "Foo",
                    inheritedFrom: [
                        ParsedTypeUsage(name: "Bar")
                    ]
                ),
                ParsedExtension(
                    typeName: "Foo",
                    inheritedFrom: [
                        ParsedTypeUsage(name: "Baz")
                    ]
                )
            ]
        )
    }

    func testEnum() {
        XCTAssertEqual(
            parse(contents:
                """
                enum Foo {}
                extension Foo {}
                """
            ),
            [ParsedExtension(typeName: "Foo")]
        )
        XCTAssertEqual(
            parse(contents:
                """
                enum Foo {}
                extension Foo: Bar, Baz {}
                """
            ),
            [
                ParsedExtension(
                    typeName: "Foo",
                    inheritedFrom: [
                        ParsedTypeUsage(name: "Bar"),
                        ParsedTypeUsage(name: "Baz")
                    ]
                )
            ]
        )
    }

    func testProtocol() {
        XCTAssertEqual(
            parse(contents:
                """
                protocol Foo {}
                extension Foo {}
                """
            ),
            [ParsedExtension(typeName: "Foo")]
        )
    }
}

private func parse(contents: String) -> [ParsedExtension] {
    let structure = try! Structure(file: File(contents: contents))
    return structure.dictionary.swiftSubstructures!.compactMap {
        return ExtensionParser.parse($0)
    }
}
