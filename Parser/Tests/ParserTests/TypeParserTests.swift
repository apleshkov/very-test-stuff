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
            [ParsedType(name: "Foo").add(inheritedFrom: ParsedType(name: "Bar"))]
        )
    }
    
    func testMethodDecl() {
        let barFun: ParsedFunction = {
            let args: [ParsedArgument] = [
                ParsedArgument(
                    name: nil,
                    type: ParsedType(name: "Int")
                ),
                ParsedArgument(
                    name: "baz",
                    type: ParsedType(name: "Baz")
                ),
                ParsedArgument(
                    name: "quux",
                    type: ParsedType(name: "Quux", isOptional: true)
                )
            ]
            return ParsedFunction(
                name: "bar",
                args: args,
                returnType: ParsedType(name: "Bar", isUnwrapped: true)
            )
        }()
        let bazFun = ParsedFunction(
            name: "baz",
            args: [],
            returnType: nil
        )
        XCTAssertEqual(
            parse(contents: [
                "struct Foo {",
                "func bar(_ x: Int, baz: Baz, quux: Quux?) -> Bar! {}",
                "func baz<T>() {}",
                "}"
                ].joined()),
            [ParsedType(name: "Foo").add(function: barFun).add(function: bazFun)]
        )
    }
}

private func parse(contents: String) -> [ParsedType] {
    let structure = try! Structure(file: File(contents: contents))
    return structure.dictionary.swiftSubstructures!.compactMap {
        return TypeParser().parse($0, contents: contents)
    }
}
