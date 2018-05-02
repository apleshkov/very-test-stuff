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
    
    func testParentContainer() {
        var parentContainer = Container(name: "Parent")
        parentContainer.dependencies.append(
            {
                let type = Type(name: "Foo")
                return Dependency(name: "foo1", typeResolver: .explicit(type), storage: .singleton)
            }()
        )
        parentContainer.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.isOptional = true
                return Dependency(name: "foo2", typeResolver: .explicit(type), storage: .singleton)
            }()
        )
        parentContainer.dependencies.append(
            {
                let type = Type(name: "Bar")
                let providerType = Type(name: "BarProvider")
                return Dependency(name: "bar", typeResolver: .provided(type, by: providerType), storage: .singleton)
            }()
        )
        parentContainer.dependencies.append(
            {
                let type = Type(name: "Baz")
                var providerType = Type(name: "BazProvider")
                providerType.isOptional = true
                return Dependency(name: "baz", typeResolver: .provided(type, by: providerType), storage: .singleton)
            }()
        )
        parentContainer.dependencies.append(
            {
                var type = Type(name: "Quux")
                type.isOptional = true
                let providerType = Type(name: "QuuxProvider")
                return Dependency(name: "quux", typeResolver: .provided(type, by: providerType), storage: .singleton)
            }()
        )
        let container = Container(name: "Test")
        let data = ContainerData.make(from: container, parent: parentContainer)
        XCTAssertEqual(
            data.initializer.args.map { "\($0.name): \($0.typeName)" },
            ["parentContainer: ParentContainer"]
        )
        XCTAssertEqual(
            data.properties.map { $0.declaration },
            ["open unowned let parentContainer: ParentContainer"]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            ["self.parentContainer = parentContainer"]
        )
        XCTAssertEqual(
            data.getters.map { "var \($0.name): \($0.typeName) { \($0.body.joined()) }" },
            [
                "var foo1: Foo { return self.parentContainer.foo1 }",
                "var foo2: Foo? { return self.parentContainer.foo2 }",
                "var bar: Bar { return self.parentContainer.bar }",
                "var baz: Baz? { return self.parentContainer.baz }",
                "var quux: Quux? { return self.parentContainer.quux }"
            ]
        )
    }
    
    func testPrototypeProviderReferenceWithPropertyAndConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.isOptional = true
                var providerType = Type(name: "FooProvider")
                providerType.isReference = true
                providerType.injectionSuite.constructor = ConstructorInjection(args: [])
                providerType.injectionSuite.constructor?.args.append((name: nil, dependencyName: "unnamed"))
                providerType.injectionSuite.constructor?.args.append((name: "named", dependencyName: "named"))
                providerType.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: providerType), storage: .prototype)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.getters.map { return ["var \($0.name): \($0.typeName) {}"] + $0.body },
            [
                [
                    "var foo: Foo? {}",
                    "let fooProvider = FooProvider(unnamed, named: named)",
                    "fooProvider.x = x",
                    "return fooProvider.get()"
                ]
            ]
        )
    }
    
    func testOptionalPrototypeProviderValueWithPropertyAndConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                var providerType = Type(name: "FooProvider")
                providerType.isOptional = true
                providerType.injectionSuite.constructor = ConstructorInjection(args: [])
                providerType.injectionSuite.constructor?.args.append((name: nil, dependencyName: "unnamed"))
                providerType.injectionSuite.constructor?.args.append((name: "named", dependencyName: "named"))
                providerType.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: providerType), storage: .prototype)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.getters.map { return ["var \($0.name): \($0.typeName) {}"] + $0.body },
            [
                [
                    "var foo: Foo? {}",
                    "var fooProvider = FooProvider(unnamed, named: named)",
                    "fooProvider?.x = x",
                    "return fooProvider?.get()"
                ]
            ]
        )
    }
    
    func testOptionalSingletonProviderReferenceWithPropertyInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                var providerType = Type(name: "FooProvider")
                providerType.isReference = true
                providerType.isOptional = true
                providerType.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: providerType), storage: .singleton)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.properties.map { $0.declaration },
            ["open let fooProvider: FooProvider?"]
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
            data.getters.map { return ["var \($0.name): \($0.typeName) {}"] + $0.body },
            [
                [
                    "var foo: Foo? {}",
                    "return fooProvider?.get()"
                ]
            ]
        )
    }
    
    func testOptionalSingletonProviderValueWithPropertyInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                var providerType = Type(name: "FooProvider")
                providerType.isOptional = true
                providerType.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: providerType), storage: .singleton)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.properties.map { $0.declaration },
            ["open let fooProvider: FooProvider?"]
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
            data.getters.map { return ["var \($0.name): \($0.typeName) {}"] + $0.body },
            [
                [
                    "var foo: Foo? {}",
                    "return fooProvider?.get()"
                ]
            ]
        )
    }
    
    func testSingletonProviderValueWithPropertyAndConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                var providerType = Type(name: "FooProvider")
                providerType.injectionSuite.constructor = ConstructorInjection(args: [])
                providerType.injectionSuite.constructor?.args.append((name: nil, dependencyName: "unnamed"))
                providerType.injectionSuite.constructor?.args.append((name: "named", dependencyName: "named"))
                providerType.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                providerType.injectionSuite.properties.append(PropertyInjection(name: "y", dependencyName: "y"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: providerType), storage: .singleton)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.properties.map { $0.declaration },
            ["open let fooProvider: FooProvider"]
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
            data.getters.map { return ["var \($0.name): \($0.typeName) {}"] + $0.body },
            [
                [
                    "var foo: Foo {}",
                    "return fooProvider.get()"
                ]
            ]
        )
    }
    
    func testProvidedSingletonValue() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                let providerType = Type(name: "FooProvider")
                return Dependency(name: "foo", typeResolver: .provided(type, by: providerType), storage: .singleton)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.properties.map { $0.declaration },
            ["open let fooProvider: FooProvider"]
        )
        XCTAssertEqual(
            data.initializer.creations,
            ["let fooProvider = FooProvider()"]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            ["self.fooProvider = fooProvider"]
        )
        XCTAssertEqual(
            data.getters.map { return ["var \($0.name): \($0.typeName) {}"] + $0.body },
            [
                [
                    "var foo: Foo {}",
                    "return fooProvider.get()"
                ]
            ]
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
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.getters.map { $0.body },
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
                type.injectionSuite.constructor = ConstructorInjection(args: [])
                type.injectionSuite.constructor?.args.append((name: nil, dependencyName: "unnamed"))
                type.injectionSuite.constructor?.args.append((name: "named", dependencyName: "named"))
                type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                type.injectionSuite.properties.append(PropertyInjection(name: "y", dependencyName: "y"))
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .prototype)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.getters.map { $0.body },
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
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.getters.map { $0.body },
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
                type.injectionSuite.constructor = ConstructorInjection(args: [])
                type.injectionSuite.constructor?.args.append((name: nil, dependencyName: "unnamed"))
                type.injectionSuite.constructor?.args.append((name: "named", dependencyName: "named"))
                type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                type.injectionSuite.properties.append(PropertyInjection(name: "y", dependencyName: "y"))
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .prototype)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.getters.map { $0.body },
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
                type.injectionSuite.constructor = ConstructorInjection(args: [])
                type.injectionSuite.constructor?.args.append((name: nil, dependencyName: "unnamed"))
                type.injectionSuite.constructor?.args.append((name: "named", dependencyName: "named"))
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .prototype)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.getters.map { $0.body },
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
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.getters.map { ["var \($0.name): \($0.typeName) {}"] + $0.body },
            [
                [
                    "var foo: Foo {}",
                    "let foo = Foo()",
                    "return foo"
                ]
            ]
        )
    }
    
    func testExplicitOptionalSingletonReferenceWithPropertyAndConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.isReference = true
                type.isOptional = true
                type.injectionSuite.constructor = ConstructorInjection(args: [])
                type.injectionSuite.constructor?.args.append((name: nil, dependencyName: "unnamed"))
                type.injectionSuite.constructor?.args.append((name: "named", dependencyName: "named"))
                type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                type.injectionSuite.properties.append(PropertyInjection(name: "y", dependencyName: "y"))
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .singleton)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.properties.map { $0.declaration },
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
    
    func testExplicitOptionalSingletonValueWithPropertyInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.isOptional = true
                type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                type.injectionSuite.properties.append(PropertyInjection(name: "y", dependencyName: "y"))
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .singleton)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.properties.map { $0.declaration },
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
    
    func testExplicitOptionalSingletonValue() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.isOptional = true
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .singleton)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.properties.map { $0.declaration },
            ["open let foo: Foo?"]
        )
    }
    
    func testExplicitSingletonValue() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .singleton)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.properties.map { $0.declaration },
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
    
    func testExplicitSingletonValueWithConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.injectionSuite.constructor = ConstructorInjection(args: [])
                type.injectionSuite.constructor?.args.append((name: nil, dependencyName: "unnamed"))
                type.injectionSuite.constructor?.args.append((name: "named", dependencyName: "named"))
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .singleton)
            }()
        )
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.properties.map { $0.declaration },
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
    
    func testInitArguments() {
        var container = Container(name: "Test")
        container.args.append((name: "foo", typeName: "String", isStoredProperty: false))
        container.args.append((name: "bar", typeName: "Int?", isStoredProperty: true))
        let data = ContainerData.make(from: container)
        XCTAssertEqual(
            data.initializer.args.map { "\($0.name): \($0.typeName)" },
            ["foo: String", "bar: Int?"]
        )
        XCTAssertEqual(
            data.properties.map { $0.declaration },
            ["open let bar: Int?"]
        )
        XCTAssertEqual(data.initializer.storedProperties, ["self.bar = bar"])
    }
    
    func testName() {
        let container = Container(name: "Test")
        let data = ContainerData.make(from: container)
        XCTAssertEqual(data.name, "TestContainer")
    }
}
