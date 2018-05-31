//
//  TypeAnnTests.swift
//  ParserTests
//
//  Created by andrey.pleshkov on 22/05/2018.
//

import XCTest
@testable import Saber

class TypeAnnTests: XCTestCase {
    
    func testBound() {
        XCTAssertEqual(
            TypeAnnotationParser.parse("bindTo()"),
            nil
        )
        XCTAssertEqual(
            TypeAnnotationParser.parse("bindTo(Foo)"),
            TypeAnnotation.bound(
                to: ParsedTypeUsage(name: "Foo")
            )
        )
        XCTAssertEqual(
            TypeAnnotationParser.parse("bindTo(Foo?)"),
            TypeAnnotation.bound(
                to: ParsedTypeUsage(name: "Foo", isOptional: true)
            )
        )
    }

    func testCached() {
        XCTAssertEqual(
            TypeAnnotationParser.parse("cached()"),
            nil
        )
        XCTAssertEqual(
            TypeAnnotationParser.parse("cached"),
            TypeAnnotation.cached
        )
    }

    func testInjectOnly() {
        XCTAssertEqual(
            TypeAnnotationParser.parse("injectOnly()"),
            nil
        )
        XCTAssertEqual(
            TypeAnnotationParser.parse("injectOnly"),
            TypeAnnotation.injectOnly
        )
    }
}
