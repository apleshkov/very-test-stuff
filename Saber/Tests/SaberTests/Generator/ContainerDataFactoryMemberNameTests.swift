//
//  ContainerDataFactoryMemberNameTests.swift
//  SaberTests
//
//  Created by Andrew Pleshkov on 19/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import Saber

class ContainerDataFactoryMemberNameTests: XCTestCase {
    
    func testSimple() {
        XCTAssertEqual(
            ContainerDataFactory().memberName(of: Type(name: "Foo")),
            "foo"
        )
    }
    
    func testCamelCase() {
        XCTAssertEqual(
            ContainerDataFactory().memberName(of: Type(name: "FooBarQuux")),
            "fooBarQuux"
        )
    }
    
    func testNested() {
        XCTAssertEqual(
            ContainerDataFactory().memberName(of: Type(name: "Foo.Bar.Quux")),
            "fooBarQuux"
        )
    }
    
    func testGeneric() {
        var type = Type(name: "Array")
        type.generics.append(Type(name: "Int"))
        XCTAssertEqual(
            ContainerDataFactory().memberName(of: type),
            "arrayWithInt"
        )
    }
    
    func testOptionalGeneric() {
        var type = Type(name: "Array")
        type.generics.append(Type(name: "Int").set(isOptional: true))
        XCTAssertEqual(
            ContainerDataFactory().memberName(of: type),
            "arrayWithInt"
        )
    }
    
    func testTwoGenerics() {
        var type = Type(name: "Dictionary")
        type.generics.append(Type(name: "String"))
        type.generics.append(Type(name: "Foo.Bar").set(isOptional: true))
        XCTAssertEqual(
            ContainerDataFactory().memberName(of: type),
            "dictionaryWithStringAndFooBar"
        )
    }
}
