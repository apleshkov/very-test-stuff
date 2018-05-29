//
//  ParserTests.swift
//  ParserTests
//
//  Created by andrey.pleshkov on 08/05/2018.
//

import XCTest
@testable import Saber
import SourceKittenFramework

class TypeParserTests: XCTestCase {

    func testSimpleDecl() {
        XCTAssertEqual(
            parse(contents: "class Foo {}"),
            [ParsedType(name: "Foo", isReference: true)]
        )
        XCTAssertEqual(
            parse(contents: "struct Foo {}"),
            [ParsedType(name: "Foo")]
        )
    }

    func testGenericDecl() {
        XCTAssertEqual(
            parse(contents: "struct Foo<T> {}"),
            [ParsedType(name: "Foo")]
        )
    }
    
    func testInheritedDecl() {
        XCTAssertEqual(
            parse(contents: "struct Foo: Bar {}"),
            [ParsedType(name: "Foo").add(inheritedFrom: ParsedTypeUsage(name: "Bar"))]
        )
    }
    
    func testTypeAnnotations() {
        XCTAssertEqual(
            parse(contents:
                """
                struct Foo {}
                // текст на русском
                // @saber.cached
                // @saber.bindTo(Baz)
                struct Bar {}
                """
            ),
            [
                ParsedType(name: "Foo"),
                ParsedType(name: "Bar")
                    .add(annotation: .bound(to: ParsedTypeUsage(name: "Baz")))
                    .add(annotation: .cached)
            ]
        )
    }

    func testNested() {
        XCTAssertEqual(
            parse(contents:
                """
                class Foo {
                    struct Bar {}
                    extension Baz {}
                }
                """
                ).map { $0.nested },
            [
                [
                    .type(ParsedType(name: "Bar")),
                    .extension(ParsedExtension(typeName: "Baz"))
                ]
            ]
        )
    }
}

private func parse(contents: String) -> [ParsedType] {
    let structure = try! Structure(file: File(contents: contents))
    let rawAnnotations = RawAnnotations(contents: contents)
    return structure.dictionary.swiftSubstructures!.compactMap {
        return TypeParser.parse($0, rawAnnotations: rawAnnotations)
    }
}
