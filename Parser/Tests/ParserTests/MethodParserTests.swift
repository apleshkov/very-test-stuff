//
//  MethodParserTests.swift
//  ParserTests
//
//  Created by andrey.pleshkov on 23/05/2018.
//

import XCTest
@testable import Parser
import SourceKittenFramework

class MethodParserTests: XCTestCase {

    func testName() {
        XCTAssertEqual(
            parse(contents:
                """
                struct Foo {
                func foo() {}
                func bar<T>(x: Int) {}
                }
                """
                ).map { $0.name },
            ["foo", "bar"]
        )
    }

    func testVoid() {
        XCTAssertEqual(
            parse(contents:
                """
                struct Foo {
                func foo() {}
                func bar() -> Void {}
                func baz() -> Swift.Void {}
                func quux() -> () {}
                }
                """
                ).map { $0.returnType },
            [
                nil,
                ParsedTypeUsage(name: "Void"),
                ParsedTypeUsage(name: "Swift.Void"),
                nil
            ]
        )
    }

    func testArgs() {
        XCTAssertEqual(
            parse(contents:
                """
                struct Foo {
                func bar(_ x: Int!, baz: Baz, quux: Quux?, promise: Promise<String>) {}
                }
                """
                ).map { $0.args },
            [
                [
                    ParsedArgument(
                        name: nil,
                        type: ParsedTypeUsage(name: "Int", isUnwrapped: true)
                    ),
                    ParsedArgument(
                        name: "baz",
                        type: ParsedTypeUsage(name: "Baz")
                    ),
                    ParsedArgument(
                        name: "quux",
                        type: ParsedTypeUsage(name: "Quux", isOptional: true)
                    ),
                    ParsedArgument(
                        name: "promise",
                        type: ParsedTypeUsage(name: "Promise")
                            .add(generic: ParsedTypeUsage(name: "String"))
                    )
                ]
            ]
        )
    }

    func testTuple() {
        XCTAssertEqual(
            parse(contents:
                """
                struct Foo {
                func foo() -> (x: Int, y: Int, Dictionary<String, String>) {}
                }
                """
                ).map { $0.returnType },
            [
                nil
            ]
        )
    }

    func testLambda() {
        XCTAssertEqual(
            parse(contents:
                """
                struct Foo {
                func foo() -> (x: Int) -> () {}
                }
                """
                ).map { $0.returnType },
            [
                nil
            ]
        )
    }

    func testStatic() {
        XCTAssertEqual(
            parse(contents:
                """
                class Foo {
                static func foo() {}
                class func bar() {}
                }
                """
            ),
            [
                ParsedMethod(name: "foo", args: [], returnType: nil, isStatic: true),
                ParsedMethod(name: "bar", args: [], returnType: nil, isStatic: true)
            ]
        )
    }

    func testAnnotated() {
        XCTAssertEqual(
            parse(contents:
                """
                class Foo {
                // @saber.inject
                func set(bar: Bar, baz: Baz) {}
                // @saber.provider
                static func provide() -> Foo {}
                }
                """
            ),
            [
                ParsedMethod(
                    name: "set",
                    args: [
                        ParsedArgument(name: "bar", type: ParsedTypeUsage(name: "Bar")),
                        ParsedArgument(name: "baz", type: ParsedTypeUsage(name: "Baz"))
                    ],
                    annotations: [.inject]
                ),
                ParsedMethod(
                    name: "provide",
                    returnType: ParsedTypeUsage(name: "Foo"),
                    isStatic: true,
                    annotations: [.provider]
                )
            ]
        )
    }
}

private func parse(contents: String) -> [ParsedMethod] {
    let rawAnnotations = RawAnnotations(contents: contents)
    let structure = try! Structure(file: File(contents: contents))
    let substructure = structure.dictionary.swiftSubstructures![0]
    let type = TypeParser.parse(substructure, rawAnnotations: rawAnnotations)
    return type!.methods
}
