//
//  ExplicitTypeResolverTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 11/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class ExplicitTypeResolverTests: XCTestCase {

    func testOptionalCachedReferenceWithPropertyAndConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.isReference = true
                type.isOptional = true
                type.injectionSuite.constructor = ConstructorInjection(args: [
                    FunctionInvocationArgument(name: nil, valueName: "unnamed"),
                    FunctionInvocationArgument(name: "named", valueName: "named")
                    ])
                type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                type.injectionSuite.properties.append(PropertyInjection(name: "y", dependencyName: "y"))
                return Service(name: "foo", typeResolver: .explicit(type), storage: .cached)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            ["open let foo: Foo?"]
        )
        XCTAssertEqual(
            data.initializer.creations,
            ["let foo = Foo(unnamed, named: named)"]
        )
        XCTAssertEqual(
            data.initializer.propertyInjections,
            [
                "foo?.x = x",
                "foo?.y = y"
            ]
        )
    }

    func testOptionalCachedValueWithPropertyInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.isOptional = true
                type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                type.injectionSuite.properties.append(PropertyInjection(name: "y", dependencyName: "y"))
                return Service(name: "foo", typeResolver: .explicit(type), storage: .cached)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            ["open let foo: Foo?"]
        )
        XCTAssertEqual(
            data.initializer.creations,
            ["var foo = Foo()"]
        )
        XCTAssertEqual(
            data.initializer.propertyInjections,
            [
                "foo?.x = x",
                "foo?.y = y"
            ]
        )
    }

    func testOptionalCachedValue() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.isOptional = true
                return Service(name: "foo", typeResolver: .explicit(type), storage: .cached)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            ["open let foo: Foo?"]
        )
    }

    func testCachedValue() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                return Service(name: "foo", typeResolver: .explicit(type), storage: .cached)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            ["open let foo: Foo"]
        )
        XCTAssertEqual(
            data.initializer.creations,
            ["let foo = Foo()"]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            ["self.foo = foo"]
        )
    }

    func testCachedValueWithConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.injectionSuite.constructor = ConstructorInjection(args: [
                    FunctionInvocationArgument(name: nil, valueName: "unnamed"),
                    FunctionInvocationArgument(name: "named", valueName: "named")
                    ])
                return Service(name: "foo", typeResolver: .explicit(type), storage: .cached)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            ["open let foo: Foo"]
        )
        XCTAssertEqual(
            data.initializer.creations,
            ["let foo = Foo(unnamed, named: named)"]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            ["self.foo = foo"]
        )
    }
}
