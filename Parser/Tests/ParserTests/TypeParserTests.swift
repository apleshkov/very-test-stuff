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
            TypeParser.parse("Foo"),
            ParsedType(name: "Foo")
        )
        XCTAssertEqual(
            TypeParser.parse("(Foo)"),
            ParsedType(name: "Foo")
        )
        XCTAssertEqual(
            TypeParser.parse("( Foo  )"),
            ParsedType(name: "Foo")
        )
        XCTAssertEqual(
            TypeParser.parse("( (Foo )  )"),
            ParsedType(name: "Foo")
        )
    }

    func testOptional() {
        XCTAssertEqual(
            TypeParser.parse("Foo?"),
            ParsedType(name: "Foo", isOptional: true)
        )
    }

    func testUnwrapped() {
        XCTAssertEqual(
            TypeParser.parse("Foo!"),
            ParsedType(name: "Foo", isUnwrapped: true)
        )
    }

    func testGenrics() {
        XCTAssertEqual(
            TypeParser.parse("Foo<Bar, Baz?>"),
            ParsedType(name: "Foo")
                .add(generic: ParsedType(name: "Bar"))
                .add(generic: ParsedType(name: "Baz", isOptional: true))
        )
    }

    func testNested() {
        XCTAssertEqual(
            TypeParser.parse("Foo.Bar.Baz"),
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
    
    func testTypeAnnotations() {
        XCTAssertEqual(
            parse(contents: [
                "struct Foo {}",
                "// текст на русском",
                "// @saber.cached",
                "// @saber.bindTo(Baz)",
                "struct Bar {}"
                ]),
            [
                ParsedType(name: "Foo"),
                ParsedType(name: "Bar")
                    .add(typeAnnotation: .bound(to: ParsedType(name: "Baz")))
                    .add(typeAnnotation: .cached)
            ]
        )
    }
    
    func testContainerAnnotations() {
        XCTAssertEqual(
            parse(contents: [
                "// @saber.name(FooContainer)",
                "// @saber.scope(FooScope)",
                "// @saber.dependsOn(BarContainer, BazContainer)",
                "// @saber.externals(FooExternals1, FooExternals2)",
                "private struct FooContainerConfiguration {}"
                ]),
            [
                ParsedType(name: "FooContainerConfiguration")
                    .add(containerAnnotation: .externals([
                        ParsedType(name: "FooExternals1"),
                        ParsedType(name: "FooExternals2")
                        ]))
                    .add(containerAnnotation: .dependsOn([
                        ParsedType(name: "BarContainer"),
                        ParsedType(name: "BazContainer")
                        ]))
                    .add(containerAnnotation: .scope("FooScope"))
                    .add(containerAnnotation: .name("FooContainer"))
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

private func parse(contents: [String]) -> [ParsedType] {
    return parse(contents: contents.joined(separator: "\n"))
}
