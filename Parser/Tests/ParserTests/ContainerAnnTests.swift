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
            ContainerAnnotationParser().parse("name(Foo)"),
            ContainerAnnotation.name("Foo")
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("name(  Bar )"),
            ContainerAnnotation.name("Bar")
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("name()"),
            nil
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("name( )"),
            nil
        )
    }

    func testScope() {
        XCTAssertEqual(
            ContainerAnnotationParser().parse("scope(Foo)"),
            ContainerAnnotation.scope("Foo")
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("scope(  Bar )"),
            ContainerAnnotation.scope("Bar")
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("scope()"),
            nil
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("scope( )"),
            nil
        )
    }

    func testDependencies() {
        XCTAssertEqual(
            ContainerAnnotationParser().parse("dependsOn()"),
            ContainerAnnotation.dependsOn([])
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("dependsOn(Foo)"),
            ContainerAnnotation.dependsOn([
                ParsedType(name: "Foo")
                ])
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("dependsOn(Foo, Bar)"),
            ContainerAnnotation.dependsOn([
                ParsedType(name: "Foo"),
                ParsedType(name: "Bar")
                ])
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("dependsOn(,Foo,)"),
            ContainerAnnotation.dependsOn([
                ParsedType(name: "Foo")
                ])
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("dependsOn(Foo?, Bar!)"),
            ContainerAnnotation.dependsOn([
                ParsedType(name: "Foo", isOptional: true),
                ParsedType(name: "Bar", isUnwrapped: true)
                ])
        )
    }

    func testExternals() {
        XCTAssertEqual(
            ContainerAnnotationParser().parse("externals()"),
            ContainerAnnotation.externals([])
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("externals(Foo)"),
            ContainerAnnotation.externals([
                ParsedType(name: "Foo")
                ])
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("externals(Foo, Bar)"),
            ContainerAnnotation.externals([
                ParsedType(name: "Foo"),
                ParsedType(name: "Bar")
                ])
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("externals(,Foo,)"),
            ContainerAnnotation.externals([
                ParsedType(name: "Foo")
                ])
        )
        XCTAssertEqual(
            ContainerAnnotationParser().parse("externals(Foo?, Bar!)"),
            ContainerAnnotation.externals([
                ParsedType(name: "Foo", isOptional: true),
                ParsedType(name: "Bar", isUnwrapped: true)
                ])
        )
    }
}
