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
            parse(contents: [
                "struct Foo {",
                "func foo() {}",
                "func bar<T>(x: Int) {}",
                "}"
                ]).map { $0.name },
            ["foo", "bar"]
        )
    }

    func testVoid() {
        XCTAssertEqual(
            parse(contents: [
                "struct Foo {",
                "func foo() {}",
                "func bar() -> Void {}",
                "func baz() -> Swift.Void {}",
                "func quux() -> () {}",
                "}"
                ]).map { $0.returnType },
            [
                nil,
                ParsedType(name: "Void"),
                ParsedType(name: "Swift.Void"),
                nil
            ]
        )
    }

    func testArgs() {
        XCTAssertEqual(
            parse(contents: [
                "struct Foo {",
                "func bar(_ x: Int!, baz: Baz, quux: Quux?, promise: Promise<String>) {}",
                "}"
                ]).map { $0.args },
            [
                [
                    ParsedArgument(
                        name: nil,
                        type: ParsedType(name: "Int", isUnwrapped: true)
                    ),
                    ParsedArgument(
                        name: "baz",
                        type: ParsedType(name: "Baz")
                    ),
                    ParsedArgument(
                        name: "quux",
                        type: ParsedType(name: "Quux", isOptional: true)
                    ),
                    ParsedArgument(
                        name: "promise",
                        type: ParsedType(name: "Promise")
                            .add(generic: ParsedType(name: "String"))
                    )
                ]
            ]
        )
    }

    func testTuple() {
        XCTAssertEqual(
            parse(contents: [
                "struct Foo {",
                "func foo() -> (x: Int, y: Int, Dictionary<String, String>) {}",
                "}"
                ]).map { $0.returnType },
            [
                nil
            ]
        )
    }

    func testLambda() {
        XCTAssertEqual(
            parse(contents: [
                "struct Foo {",
                "func foo() -> (x: Int) -> () {}",
                "}"
                ]).map { $0.returnType },
            [
                nil
            ]
        )
    }

    func testStatic() {
        XCTAssertEqual(
            parse(contents: [
                "class Foo {",
                "static func foo() {}",
                "class func bar() {}",
                "}"
                ]),
            [
                ParsedMethod(name: "foo", args: [], returnType: nil, isStatic: true),
                ParsedMethod(name: "bar", args: [], returnType: nil, isStatic: true)
            ]
        )
    }
}

private func parse(contents: [String]) -> [ParsedMethod] {
    let text = contents.joined()
    let structure = try! Structure(file: File(contents: text))
    let substructure = structure.dictionary.swiftSubstructures![0]
    let type = TypeParser.parse(substructure, contents: text)
    return type!.methods
}
