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
                extension Bar {
                    // @saber.inject
                    func set() {}
                }
            }
            extension Foo.Bar.Baz {
                // @saber.inject
                func set() {}
            }
            """
        ).parse(to: factory)
        try! FileParser(contents:
            """
            struct Foo {
                struct Bar {
                    // @saber.cached
                    struct Baz {}
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
    }
}
