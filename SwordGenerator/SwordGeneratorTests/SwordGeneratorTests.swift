//
//  SwordGeneratorTests.swift
//  SwordGeneratorTests
//
//  Created by Andrew Pleshkov on 30/04/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class SwordGeneratorTests: XCTestCase {

    func testPrototypeStaticMethodProvider() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                let provider = StaticMethodProvider(receiverName: "Foo", methodName: "makeFoo", args: [])
                return Dependency(name: "foo", typeResolver: .provided(type, by: provider), storage: .prototype)
            }()
        )
        container.dependencies.append(
            {
                var type = Type(name: "Bar")
                type.isOptional = true
                let provider = StaticMethodProvider(receiverName: "Bar", methodName: "makeBar", args: [
                    FunctionInvocationArgument(name: "foo", valueName: "foo")
                    ])
                return Dependency(name: "bar", typeResolver: .provided(type, by: provider), storage: .prototype)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            []
        )
        XCTAssertEqual(
            data.initializer.creations,
            []
        )
        XCTAssertEqual(
            data.initializer.propertyInjections,
            []
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            []
        )
        XCTAssertEqual(
            data.readOnlyProperties.map { return "\($0.declaration) { \($0.body.joined()) }" },
            [
                "open var foo: Foo { return Foo.makeFoo() }",
                "open var bar: Bar? { return Bar.makeBar(foo: foo) }"
            ]
        )
    }
    
    func testCachedStaticMethodProvider() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                let provider = StaticMethodProvider(recieverName: "Foo", methodName: "makeFoo", args: [])
                return Dependency(name: "foo", typeResolver: .provided(type, by: provider), storage: .cached)
            }()
        )
        container.dependencies.append(
            {
                var type = Type(name: "Bar")
                type.isOptional = true
                let provider = StaticMethodProvider(receiverName: "Bar", methodName: "makeBar", args: [
                    FunctionInvocationArgument(name: "foo", valueName: "foo")
                    ])
                return Dependency(name: "bar", typeResolver: .provided(type, by: provider), storage: .cached)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            [
                "open let foo: Foo",
                "open let bar: Bar?"
            ]
        )
        XCTAssertEqual(
            data.initializer.creations,
            [
                "let foo = Foo.makeFoo()",
                "let bar = Bar.makeBar(foo: foo)"
            ]
        )
        XCTAssertEqual(
            data.initializer.propertyInjections,
            []
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            [
                "self.foo = foo",
                "self.bar = bar"
            ]
        )
        XCTAssertEqual(
            data.readOnlyProperties.map { return ["\($0.declaration) { ... }"] + $0.body },
            []
        )
    }
    
    func testOptionalPrototypeReferenceWithPropertyInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.isReference = true
                type.isOptional = true
                type.injectionSuite.constructor = ConstructorInjection(args: [])
                type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                type.injectionSuite.properties.append(PropertyInjection(name: "y", dependencyName: "y"))
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .prototype)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.readOnlyProperties.map { $0.body },
            [
                [
                    "let foo = Foo()",
                    "foo?.x = x",
                    "foo?.y = y",
                    "return foo"
                ]
            ]
        )
    }
    
    func testPrototypeReferenceWithPropertyAndConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.isReference = true
                type.injectionSuite.constructor = ConstructorInjection(args: [
                    FunctionInvocationArgument(name: nil, valueName: "unnamed"),
                    FunctionInvocationArgument(name: "named", valueName: "named")
                    ])
                type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                type.injectionSuite.properties.append(PropertyInjection(name: "y", dependencyName: "y"))
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .prototype)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.readOnlyProperties.map { $0.body },
            [
                [
                    "let foo = Foo(unnamed, named: named)",
                    "foo.x = x",
                    "foo.y = y",
                    "return foo"
                ]
            ]
        )
    }
    
    func testOptionalPrototypeValueWithPropertyInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.isOptional = true
                type.injectionSuite.constructor = ConstructorInjection(args: [])
                type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                type.injectionSuite.properties.append(PropertyInjection(name: "y", dependencyName: "y"))
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .prototype)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.readOnlyProperties.map { $0.body },
            [
                [
                    "var foo = Foo()",
                    "foo?.x = x",
                    "foo?.y = y",
                    "return foo"
                ]
            ]
        )
    }
    
    func testPrototypeValueWithPropertyAndConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.injectionSuite.constructor = ConstructorInjection(args: [
                    FunctionInvocationArgument(name: nil, valueName: "unnamed"),
                    FunctionInvocationArgument(name: "named", valueName: "named")
                    ])
                type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                type.injectionSuite.properties.append(PropertyInjection(name: "y", dependencyName: "y"))
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .prototype)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.readOnlyProperties.map { $0.body },
            [
                [
                    "var foo = Foo(unnamed, named: named)",
                    "foo.x = x",
                    "foo.y = y",
                    "return foo"
                ]
            ]
        )
    }
    
    func testPrototypeValueWithConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.injectionSuite.constructor = ConstructorInjection(args: [
                    FunctionInvocationArgument(name: nil, valueName: "unnamed"),
                    FunctionInvocationArgument(name: "named", valueName: "named")
                    ])
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .prototype)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.readOnlyProperties.map { $0.body },
            [
                [
                    "let foo = Foo(unnamed, named: named)",
                    "return foo"
                ]
            ]
        )
    }
    
    func testPrototypeValue() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .prototype)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.readOnlyProperties.map { ["\($0.declaration) { ... }"] + $0.body },
            [
                [
                    "open var foo: Foo { ... }",
                    "let foo = Foo()",
                    "return foo"
                ]
            ]
        )
    }
    
    func testInitArguments() {
        var container = Container(name: "Test")
        container.args.append(ContainerArgument(name: "foo", typeName: "String", isStoredProperty: false))
        container.args.append(ContainerArgument(name: "bar", typeName: "Int?", isStoredProperty: true))
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.initializer.args.map { "\($0.name): \($0.typeName)" },
            ["foo: String", "bar: Int?"]
        )
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            ["open let bar: Int?"]
        )
        XCTAssertEqual(data.initializer.storedProperties, ["self.bar = bar"])
    }
    
    func testName() {
        let container = Container(name: "Test")
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(data.name, "TestContainer")
    }
}
