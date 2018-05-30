//
//  FileParserTests.swift
//  SaberTests
//
//  Created by Andrew Pleshkov on 29/05/2018.
//

import XCTest
@testable import Saber

class FileParserTests: XCTestCase {
    
    func testNestedDecls() {
        let factory = ParsedDataFactory()
        try! FileParser(contents:
            """
            extension Foo {
                typealias FooInt = Int

                extension Bar {
                    // @saber.inject
                    func set() {}
                }
            }
            extension Foo.Bar.Baz {
                // @saber.inject
                func set() {}

                typealias BazInt = Int
            }
            """
        ).parse(to: factory)
        try! FileParser(contents:
            """
            struct Foo {
                struct Bar {
                    // @saber.cached
                    struct Baz {}

                    typealias BarInt = Int
                }
            }
            """
        ).parse(to: factory)
        let data = factory.make()
        XCTAssertEqual(data.types.count, 3)
        XCTAssertEqual(
            data.types["Foo"]?.name,
            "Foo"
        )
        XCTAssertEqual(
            data.types["Foo.Bar"]?.methods,
            [ParsedMethod(name: "set", annotations: [.inject])]
        )
        XCTAssertEqual(
            data.types["Foo.Bar.Baz"]?.annotations,
            [.cached]
        )
        XCTAssertEqual(
            data.types["Foo.Bar.Baz"]?.methods,
            [ParsedMethod(name: "set", annotations: [.inject])]
        )
        XCTAssertEqual(
            data.aliases["Foo.FooInt"]?.type,
            ParsedTypeUsage(name: "Int")
        )
        XCTAssertEqual(
            data.aliases["Foo.Bar.BarInt"]?.type,
            ParsedTypeUsage(name: "Int")
        )
        XCTAssertEqual(
            data.aliases["Foo.Bar.Baz.BazInt"]?.type,
            ParsedTypeUsage(name: "Int")
        )
    }

    func testModuleName() {
        let factory = ParsedDataFactory()
        try! FileParser(contents:
            """
            class Foo {}
            typealias Bar = Foo
            """, moduleName: "A"
            ).parse(to: factory)
        let data = factory.make()
        XCTAssertEqual(
            data.types["Foo"]?.moduleName,
            "A"
        )
        XCTAssertEqual(
            data.aliases["Bar"]?.moduleName,
            "A"
        )
    }
    
    func testContainer() {
        let factory = ParsedDataFactory()
        try! FileParser(contents:
            """
            // @saber.container(Foo)
            // @saber.scope(Singleton)
            protocol FooConfig {}
            """
            ).parse(to: factory)
        let data = factory.make()
        XCTAssertEqual(
            data.containers["Foo"]?.scopeName,
            "Singleton"
        )
    }
}
