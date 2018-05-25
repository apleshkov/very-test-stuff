//
//  ContainerAnnTests.swift
//  ParserTests
//
//  Created by andrey.pleshkov on 22/05/2018.
//

import XCTest
@testable import Parser

class ContainerAnnTests: XCTestCase {
    
    func testName() {
        XCTAssertEqual(
            ContainerAnnotationParser.parse("container(Foo)"),
            ContainerAnnotation.name("Foo")
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("container(  Bar )"),
            ContainerAnnotation.name("Bar")
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("container()"),
            nil
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("container( )"),
            nil
        )
    }

    func testScope() {
        XCTAssertEqual(
            ContainerAnnotationParser.parse("scope(Foo)"),
            ContainerAnnotation.scope("Foo")
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("scope(  Bar )"),
            ContainerAnnotation.scope("Bar")
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("scope()"),
            nil
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("scope( )"),
            nil
        )
    }

    func testDependencies() {
        XCTAssertEqual(
            ContainerAnnotationParser.parse("dependsOn()"),
            ContainerAnnotation.dependencies([])
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("dependsOn(Foo)"),
            ContainerAnnotation.dependencies([
                ParsedType(name: "Foo")
                ])
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("dependsOn(Foo, Bar)"),
            ContainerAnnotation.dependencies([
                ParsedType(name: "Foo"),
                ParsedType(name: "Bar")
                ])
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("dependsOn(,Foo,)"),
            ContainerAnnotation.dependencies([
                ParsedType(name: "Foo")
                ])
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("dependsOn(Foo?, Bar!)"),
            ContainerAnnotation.dependencies([
                ParsedType(name: "Foo", isOptional: true),
                ParsedType(name: "Bar", isUnwrapped: true)
                ])
        )
    }

    func testExternals() {
        XCTAssertEqual(
            ContainerAnnotationParser.parse("externals()"),
            ContainerAnnotation.externals([])
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("externals(Foo)"),
            ContainerAnnotation.externals([
                ParsedType(name: "Foo")
                ])
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("externals(Foo, Bar)"),
            ContainerAnnotation.externals([
                ParsedType(name: "Foo"),
                ParsedType(name: "Bar")
                ])
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("externals(,Foo,)"),
            ContainerAnnotation.externals([
                ParsedType(name: "Foo")
                ])
        )
        XCTAssertEqual(
            ContainerAnnotationParser.parse("externals(Foo?, Bar!)"),
            ContainerAnnotation.externals([
                ParsedType(name: "Foo", isOptional: true),
                ParsedType(name: "Bar", isUnwrapped: true)
                ])
        )
    }
}
