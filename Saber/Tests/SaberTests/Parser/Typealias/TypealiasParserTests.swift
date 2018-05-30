//
//  TypealiasParserTests.swift
//  SaberTests
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import XCTest
@testable import Saber
import SourceKittenFramework

class TypealiasParserTests: XCTestCase {
    
    func testSimple() {
        XCTAssertEqual(
            parse(contents: "typealias Foo = Bar"),
            [ParsedTypealias(name: "Foo", type: ParsedTypeUsage(name: "Bar"))]
        )
    }

    func testGeneric() {
        XCTAssertEqual(
            parse(contents: "typealias Foo = Bar<Int>"),
            [
                ParsedTypealias(
                    name: "Foo",
                    type: ParsedTypeUsage(name: "Bar")
                        .add(generic: ParsedTypeUsage(name: "Int"))
                )
            ]
        )
    }
}

private func parse(contents: String) -> [ParsedTypealias] {
    let rawAnnotations = RawAnnotations(contents: contents)
    let structure = try! Structure(file: File(contents: contents)).dictionary
    return structure.swiftSubstructures!.compactMap {
        return TypealiasParser.parse($0, rawAnnotations: rawAnnotations)
    }
}
