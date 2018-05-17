//
//  ContainerDataFactoryCreationTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 17/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class ContainerDataFactoryCreationTests: XCTestCase {
    
    func testCreation() {
        let fooType = Type(name: "Foo")
        let createdFoo = ContainerDataFactory().create(type: fooType, named: "foo")
        XCTAssertEqual(createdFoo.creation, "let foo = Foo()")
        XCTAssertEqual(createdFoo.injections, [])

        let barType: Type = {
            var type = Type(name: "Bar")
            type.constructorInjections = [
                ConstructorInjection(name: nil, typeResolver: .explicit(fooType)),
                ConstructorInjection(name: "foo", typeResolver: .explicit(fooType))
            ]
            return type
        }()
        let createdBar = ContainerDataFactory().create(type: barType, named: "bar")
        XCTAssertEqual(createdBar.creation, "let bar = Bar(self.foo, foo: self.foo)")
        XCTAssertEqual(createdBar.injections, [])
    }

    func testValueInjections() {
        var type = Type(name: "Foo")
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let created = ContainerDataFactory().create(type: type, named: "foo")
        XCTAssertEqual(created.creation, "var foo = Foo()")
        XCTAssertEqual(created.injections, ["foo.bar = self.bar"])
    }

    func testOptionalValueInjections() {
        var type = Type(name: "Foo")
        type.isOptional = true
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let created = ContainerDataFactory().create(type: type, named: "foo")
        XCTAssertEqual(created.creation, "var foo = Foo()")
        XCTAssertEqual(created.injections, ["foo?.bar = self.bar"])
    }

    func testReferenceInjections() {
        var type = Type(name: "Foo")
        type.isReference = true
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let created = ContainerDataFactory().create(type: type, named: "foo")
        XCTAssertEqual(created.creation, "let foo = Foo()")
        XCTAssertEqual(created.injections, ["foo.bar = self.bar"])
    }

    func testOptionalReferenceInjections() {
        var type = Type(name: "Foo")
        type.isReference = true
        type.isOptional = true
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let created = ContainerDataFactory().create(type: type, named: "foo")
        XCTAssertEqual(created.creation, "let foo = Foo()")
        XCTAssertEqual(created.injections, ["foo?.bar = self.bar"])
    }
}
