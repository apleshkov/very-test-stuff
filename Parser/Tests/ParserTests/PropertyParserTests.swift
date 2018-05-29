//
//  PropertyParserTests.swift
//  ParserTests
//
//  Created by andrey.pleshkov on 23/05/2018.
//

import XCTest
@testable import Parser
import SourceKittenFramework

class PropertyParserTests: XCTestCase {

    func testLet() {
        XCTAssertEqual(
            parse(contents:
                """
                struct Foo {
                let bar: Bar
                }
                """
                ),
            [ParsedProperty(name: "bar", type: ParsedTypeUsage(name: "Bar"))]
        )
    }

    func testVar() {
        XCTAssertEqual(
            parse(contents:
                """
                struct Foo {
                var bar: Bar
                }
                """
                ),
            [ParsedProperty(name: "bar", type: ParsedTypeUsage(name: "Bar"))]
        )
    }

    func testAnnotations() {
        XCTAssertEqual(
            parse(contents:
                """
                struct Foo {
                // @saber.inject
                var bar: Bar
                }
                """
            ),
            [
                ParsedProperty(
                    name: "bar",
                    type: ParsedTypeUsage(name: "Bar"),
                    annotations: [.inject]
                )
            ]
        )
    }
}

private func parse(contents: String) -> [ParsedProperty] {
    let rawAnnotations = RawAnnotations(contents: contents)
    let structure = try! Structure(file: File(contents: contents))
    let substructure = structure.dictionary.swiftSubstructures![0]
    let type = TypeParser.parse(substructure, rawAnnotations: rawAnnotations)
    return type!.properties
}
