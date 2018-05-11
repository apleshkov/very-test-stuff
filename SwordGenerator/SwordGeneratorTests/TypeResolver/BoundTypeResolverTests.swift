//
//  BoundTypeResolverTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 11/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class BoundTypeResolverTests: XCTestCase {

    func testCachedValue() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let mimicType = Type(name: "FooProtocol")
                var type = Type(name: "Foo")
                type.injectionSuite.constructor = ConstructorInjection(args: [
                    FunctionInvocationArgument(name: "bar", valueName: "bar")
                    ])
                type.injectionSuite.properties.append(PropertyInjection(name: "baz", dependencyName: "baz"))
                return Dependency(name: "foo", typeResolver: .bound(mimicType, to: type), storage: .cached)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            [
                "open let foo: FooProtocol"
            ]
        )
        XCTAssertEqual(
            data.initializer.creations,
            [
                "var foo = Foo(bar: bar)"
            ]
        )
        XCTAssertEqual(
            data.initializer.propertyInjections,
            [
                "foo.baz = baz"
            ]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            [
                "self.foo = foo"
            ]
        )
    }

    func testPrototypeValue() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let mimicType = Type(name: "FooProtocol")
                var type = Type(name: "Foo")
                type.injectionSuite.constructor = ConstructorInjection(args: [
                    FunctionInvocationArgument(name: "bar", valueName: "bar")
                    ])
                type.injectionSuite.properties.append(PropertyInjection(name: "baz", dependencyName: "baz"))
                return Dependency(name: "foo", typeResolver: .bound(mimicType, to: type), storage: .prototype)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.readOnlyProperties.map { [$0.declaration] + $0.body },
            [
                [
                    "open var foo: FooProtocol",
                    "var foo = Foo(bar: bar)",
                    "foo.baz = baz",
                    "return foo"
                ]
            ]
        )
    }
}
