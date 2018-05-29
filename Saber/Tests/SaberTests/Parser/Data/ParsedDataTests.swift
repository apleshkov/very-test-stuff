//
//  ParsedDataTests.swift
//  SaberTests
//
//  Created by Andrew Pleshkov on 29/05/2018.
//

import XCTest
@testable import Saber

class ParsedDataTests: XCTestCase {
    
    func testPostponed() {
        let type: ParsedType = {
            var type = ParsedType(name: "Foo")
            type.inheritedFrom = [ParsedTypeUsage(name: "ParentFoo")]
            type.properties = [
                ParsedProperty(name: "x", type: ParsedTypeUsage(name: "Float"))
            ]
            type.methods = [
                ParsedMethod(name: "init")
            ]
            type.annotations = [.cached]
            type.isReference = true
            type.nested = [.type(ParsedType(name: "Bar"))]
            return type
        }()
        let ext: ParsedExtension = {
            var ext = ParsedExtension(typeName: "Foo")
            ext.inheritedFrom = [ParsedTypeUsage(name: "Hashable")]
            ext.properties = [
                ParsedProperty(name: "y", type: ParsedTypeUsage(name: "Float"))
            ]
            ext.methods = [
                ParsedMethod(name: "hashValue")
            ]
            ext.nested = [.type(ParsedType(name: "Baz"))]
            return ext
        }()
        let factory = ParsedDataFactory()
        factory.register(ext)
        factory.register(type)
        let madeType = factory.make().types[type.name]
        XCTAssertEqual(
            madeType?.inheritedFrom,
            type.inheritedFrom + ext.inheritedFrom
        )
        XCTAssertEqual(
            madeType?.properties,
            type.properties + ext.properties
        )
        XCTAssertEqual(
            madeType?.methods,
            type.methods + ext.methods
        )
        XCTAssertEqual(
            madeType?.annotations,
            type.annotations
        )
        XCTAssertEqual(
            madeType?.isReference,
            type.isReference
        )
        XCTAssertEqual(
            madeType?.nested,
            type.nested + ext.nested
        )
    }
}
