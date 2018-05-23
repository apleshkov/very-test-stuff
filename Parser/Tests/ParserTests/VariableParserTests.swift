//
//  VariableParserTests.swift
//  ParserTests
//
//  Created by andrey.pleshkov on 23/05/2018.
//

import XCTest
@testable import Parser
import SourceKittenFramework

class VariableParserTests: XCTestCase {

    func testLet() {
        XCTAssertEqual(
            parse(contents: [
                "struct Foo {",
                "let bar: Bar",
                "}"
                ]),
            [ParsedVariable(name: "bar", type: ParsedType(name: "Bar"))]
        )
    }

    func testVar() {
        XCTAssertEqual(
            parse(contents: [
                "struct Foo {",
                "var bar: Bar",
                "}"
                ]),
            [ParsedVariable(name: "bar", type: ParsedType(name: "Bar"))]
        )
    }
}

private func parse(contents: [String]) -> [ParsedVariable] {
    let text = contents.joined()
    let structure = try! Structure(file: File(contents: text))
    let substructure = structure.dictionary.swiftSubstructures![0]
    let type = TypeParser.parse(substructure, contents: text)
    return type!.variables
}
