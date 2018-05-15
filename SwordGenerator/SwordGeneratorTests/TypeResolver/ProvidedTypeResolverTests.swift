//
//  ProvidedTypeResolverTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 11/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class ProvidedTypeResolverTests: XCTestCase {

    func testPrototypeReferenceWithPropertyAndConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.isOptional = true
                var provider = TypedProvider(Type(name: "FooProvider"))
                provider.type.isReference = true
                provider.type.injectionSuite.constructor = ConstructorInjection(args: [
                    FunctionInvocationArgument(name: nil, valueName: "unnamed"),
                    FunctionInvocationArgument(name: "named", valueName: "named")
                    ])
                provider.type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: provider), storage: .prototype)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.readOnlyProperties.map { return ["\($0.declaration) { ... }"] + $0.body },
            [
                [
                    "open var foo: Foo? { ... }",
                    "let fooProvider = FooProvider(unnamed, named: named)",
                    "fooProvider.x = x",
                    "return fooProvider.provide()"
                ]
            ]
        )
    }

    func testOptionalPrototypeValueWithPropertyAndConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                var provider = TypedProvider(Type(name: "FooProvider"))
                provider.type.isOptional = true
                provider.type.injectionSuite.constructor = ConstructorInjection(args: [
                    FunctionInvocationArgument(name: nil, valueName: "unnamed"),
                    FunctionInvocationArgument(name: "named", valueName: "named")
                    ])
                provider.type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: provider), storage: .prototype)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.readOnlyProperties.map { return ["\($0.declaration) { ... }"] + $0.body },
            [
                [
                    "open var foo: Foo? { ... }",
                    "var fooProvider = FooProvider(unnamed, named: named)",
                    "fooProvider?.x = x",
                    "return fooProvider?.provide()"
                ]
            ]
        )
    }

    func testOptionalCachedReferenceWithPropertyInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                var provider = TypedProvider(Type(name: "FooProvider"))
                provider.type.isReference = true
                provider.type.isOptional = true
                provider.type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: provider), storage: .cached)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            ["open let foo: Foo?"]
        )
        XCTAssertEqual(
            data.initializer.creations,
            ["let fooProvider = FooProvider()"]
        )
        XCTAssertEqual(
            data.initializer.propertyInjections,
            [
                "fooProvider?.x = x"
            ]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            [
                "self.foo = fooProvider?.provide()"
            ]
        )
    }

    func testOptionalCachedValueWithPropertyInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                var provider = TypedProvider(Type(name: "FooProvider"))
                provider.type.isOptional = true
                provider.type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: provider), storage: .cached)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            ["open let foo: Foo?"]
        )
        XCTAssertEqual(
            data.initializer.creations,
            ["var fooProvider = FooProvider()"]
        )
        XCTAssertEqual(
            data.initializer.propertyInjections,
            [
                "fooProvider?.x = x"
            ]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            [
                "self.foo = fooProvider?.provide()"
            ]
        )
    }

    func testCachedValueWithPropertyAndConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                var provider = TypedProvider(Type(name: "FooProvider"))
                provider.type.injectionSuite.constructor = ConstructorInjection(args: [
                    FunctionInvocationArgument(name: nil, valueName: "unnamed"),
                    FunctionInvocationArgument(name: "named", valueName: "named")
                    ])
                provider.type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                provider.type.injectionSuite.properties.append(PropertyInjection(name: "y", dependencyName: "y"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: provider), storage: .cached)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            ["open let foo: Foo"]
        )
        XCTAssertEqual(
            data.initializer.creations,
            ["var fooProvider = FooProvider(unnamed, named: named)"]
        )
        XCTAssertEqual(
            data.initializer.propertyInjections,
            [
                "fooProvider.x = x",
                "fooProvider.y = y"
            ]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            [
                "self.foo = fooProvider.provide()"
            ]
        )
    }

    func testCachedValue() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                let provider = TypedProvider(Type(name: "FooProvider"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: provider), storage: .cached)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            ["open let foo: Foo"]
        )
        XCTAssertEqual(
            data.initializer.creations,
            ["let fooProvider = FooProvider()"]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            ["self.foo = fooProvider.provide()"]
        )
    }
}
