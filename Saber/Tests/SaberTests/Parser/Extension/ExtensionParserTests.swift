//
//  ExtensionParserTests.swift
//  ParserTests
//
//  Created by andrey.pleshkov on 28/05/2018.
//

import XCTest
@testable import Saber
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

    func testNested() {
        XCTAssertEqual(
            parse(contents:
                """
                extension Foo {
                    struct Bar {}
                    extension Baz {}
                    typealias Quux = Int
                }
                """
                ).map { $0.nested },
            [
                [
                    .type(ParsedType(name: "Bar")),
                    .extension(ParsedExtension(typeName: "Baz")),
                    .typealias(
                        ParsedTypealias(
                            name: "Quux",
                            target: .type(ParsedTypeUsage(name: "Int"))
                        )
                    )
                ]
            ]
        )
    }
    
    func testMembers() {
        XCTAssertEqual(
            parse(contents:
                """
                extension Foo {
                    // @saber.inject
                    func foo() {}
                    // @saber.inject
                    var bar: Int {
                        get {}
                        set {}
                    }
                }
                """
            ),
            [
                ParsedExtension(typeName: "Foo")
                    .add(method: ParsedMethod(name: "foo", annotations: [.inject]))
                    .add(property: ParsedProperty(name: "bar", type: ParsedTypeUsage(name: "Int"), annotations: [.inject]))
            ]
        )
        
    }
}

private func parse(contents: String) -> [ParsedExtension] {
    let structure = try! Structure(file: File(contents: contents))
    let rawData = RawData(contents: contents)
    return structure.dictionary.swiftSubstructures!.compactMap {
        return ExtensionParser.parse($0, rawData: rawData)
    }
}
