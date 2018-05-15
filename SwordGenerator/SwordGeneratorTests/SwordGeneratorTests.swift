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
                let provider = TypedProvider(Type(name: "BarProvider"))
                return Dependency(name: "bar", typeResolver: .provided(type, by: provider), storage: .singleton)
            }()
        )
        parentContainer.dependencies.append(
            {
                let type = Type(name: "Baz")
                var provider = TypedProvider(Type(name: "BazProvider"))
                provider.type.isOptional = true
                return Dependency(name: "baz", typeResolver: .provided(type, by: provider), storage: .singleton)
            }()
        )
        parentContainer.dependencies.append(
            {
                var type = Type(name: "Quux")
                type.isOptional = true
                let provider = TypedProvider(Type(name: "QuuxProvider"))
                return Dependency(name: "quux", typeResolver: .provided(type, by: provider), storage: .singleton)
            }()
        )
        let container = Container(name: "Test", parent: parentContainer)
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.initializer.args.map { "\($0.name): \($0.typeName)" },
            ["parentContainer: ParentContainer"]
        )
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            ["open unowned let parentContainer: ParentContainer"]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            ["self.parentContainer = parentContainer"]
        )
        XCTAssertEqual(
            data.readOnlyProperties.map { "\($0.declaration) { \($0.body.joined()) }" },
            [
                "open var foo1: Foo { return self.parentContainer.foo1 }",
                "open var foo2: Foo? { return self.parentContainer.foo2 }",
                "open var bar: Bar { return self.parentContainer.bar }",
                "open var baz: Baz? { return self.parentContainer.baz }",
                "open var quux: Quux? { return self.parentContainer.quux }"
            ]
        )
    }
    
    func testParentContainerCollisions() {
        var parentContainer = Container(name: "Parent")
        parentContainer.dependencies.append(
            {
                let type = Type(name: "Foo")
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .singleton)
            }()
        )
        parentContainer.dependencies.append(
            {
                let type = Type(name: "Bar")
                return Dependency(name: "bar", typeResolver: .explicit(type), storage: .singleton)
            }()
        )
        var container = Container(name: "Test", parent: parentContainer)
        container.dependencies.append(
            {
                let type = Type(name: "ReplacedFoo")
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .singleton)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            [
                "open unowned let parentContainer: ParentContainer",
                "open let foo: ReplacedFoo"
            ]
        )
        XCTAssertEqual(
            data.initializer.creations,
            ["let foo = ReplacedFoo()"]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            [
                "self.parentContainer = parentContainer",
                "self.foo = foo"
            ]
        )
        XCTAssertEqual(
            data.readOnlyProperties.map { "\($0.declaration) { \($0.body.joined()) }" },
            [
                "open var bar: Bar { return self.parentContainer.bar }"
            ]
        )
    }
    
    func testMultipleChildContainers() {
        let containerA: Container = {
            var container = Container(name: "A")
            container.dependencies.append(
                {
                    let type = Type(name: "AFoo")
                    return Dependency(name: "foo", typeResolver: .explicit(type), storage: .singleton)
                }()
            )
            container.dependencies.append(
                {
                    let type = Type(name: "ABar")
                    return Dependency(name: "bar", typeResolver: .explicit(type), storage: .singleton)
                }()
            )
            return container
        }()
        let containerB: Container = {
            var container = Container(name: "B", parent: containerA)
            container.dependencies.append(
                {
                    let type = Type(name: "BReplacedBar")
                    return Dependency(name: "bar", typeResolver: .explicit(type), storage: .singleton)
                }()
            )
            container.dependencies.append(
                {
                    let type = Type(name: "BBaz")
                    return Dependency(name: "baz", typeResolver: .explicit(type), storage: .singleton)
                }()
            )
            return container
        }()
        let containerC: Container = {
            var container = Container(name: "C", parent: containerB)
            container.dependencies.append(
                {
                    let type = Type(name: "CReplacedBaz")
                    return Dependency(name: "baz", typeResolver: .explicit(type), storage: .singleton)
                }()
            )
            return container
        }()
        let dataB = ContainerDataFactory().make(from: containerB)
        XCTAssertEqual(
            dataB.storedProperties.map { $0.declaration },
            [
                "open unowned let parentContainer: AContainer",
                "open let bar: BReplacedBar",
                "open let baz: BBaz"
            ]
        )
        XCTAssertEqual(
            dataB.initializer.creations,
            [
                "let bar = BReplacedBar()",
                "let baz = BBaz()"
            ]
        )
        XCTAssertEqual(
            dataB.initializer.storedProperties,
            [
                "self.parentContainer = parentContainer",
                "self.bar = bar",
                "self.baz = baz"
            ]
        )
        XCTAssertEqual(
            dataB.readOnlyProperties.map { "\($0.declaration) { \($0.body.joined()) }" },
            [
                "open var foo: AFoo { return self.parentContainer.foo }"
            ]
        )
        let dataC = ContainerDataFactory().make(from: containerC)
        XCTAssertEqual(
            dataC.storedProperties.map { $0.declaration },
            [
                "open unowned let parentContainer: BContainer",
                "open let baz: CReplacedBaz"
            ]
        )
        XCTAssertEqual(
            dataC.initializer.creations,
            ["let baz = CReplacedBaz()"]
        )
        XCTAssertEqual(
            dataC.initializer.storedProperties,
            [
                "self.parentContainer = parentContainer",
                "self.baz = baz"
            ]
        )
        XCTAssertEqual(
            dataC.readOnlyProperties.map { "\($0.declaration) { \($0.body.joined()) }" },
            [
                "open var bar: BReplacedBar { return self.parentContainer.bar }",
                "open var foo: AFoo { return self.parentContainer.foo }"
            ]
        )
    }
    
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
    
    func testSingletonStaticMethodProvider() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                let provider = StaticMethodProvider(receiverName: "Foo", methodName: "makeFoo", args: [])
                return Dependency(name: "foo", typeResolver: .provided(type, by: provider), storage: .singleton)
            }()
        )
        container.dependencies.append(
            {
                var type = Type(name: "Bar")
                type.isOptional = true
                let provider = StaticMethodProvider(receiverName: "Bar", methodName: "makeBar", args: [
                    FunctionInvocationArgument(name: "foo", valueName: "foo")
                    ])
                return Dependency(name: "bar", typeResolver: .provided(type, by: provider), storage: .singleton)
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
    
    func testPrototypeTypedProviderReferenceWithPropertyAndConstructorInjections() {
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
    
    func testOptionalPrototypeTypedProviderValueWithPropertyAndConstructorInjections() {
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
    
    func testOptionalSingletonTypedProviderReferenceWithPropertyInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                var provider = TypedProvider(Type(name: "FooProvider"))
                provider.type.isReference = true
                provider.type.isOptional = true
                provider.type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: provider), storage: .singleton)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
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
            data.readOnlyProperties.map { return ["\($0.declaration) { ... }"] + $0.body },
            [
                [
                    "open var foo: Foo? { ... }",
                    "return fooProvider?.provide()"
                ]
            ]
        )
    }
    
    func testOptionalSingletonTypedProviderValueWithPropertyInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                var provider = TypedProvider(Type(name: "FooProvider"))
                provider.type.isOptional = true
                provider.type.injectionSuite.properties.append(PropertyInjection(name: "x", dependencyName: "x"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: provider), storage: .singleton)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
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
            data.readOnlyProperties.map { return ["\($0.declaration) { ... }"] + $0.body },
            [
                [
                    "open var foo: Foo? { ... }",
                    "return fooProvider?.provide()"
                ]
            ]
        )
    }
    
    func testSingletonTypedProviderValueWithPropertyAndConstructorInjections() {
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
                return Dependency(name: "foo", typeResolver: .provided(type, by: provider), storage: .singleton)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
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
            data.readOnlyProperties.map { return ["\($0.declaration) { ... }"] + $0.body },
            [
                [
                    "open var foo: Foo { ... }",
                    "return fooProvider.provide()"
                ]
            ]
        )
    }
    
    func testProvidedSingletonValue() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                let type = Type(name: "Foo")
                let provider = TypedProvider(Type(name: "FooProvider"))
                return Dependency(name: "foo", typeResolver: .provided(type, by: provider), storage: .singleton)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
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
            data.readOnlyProperties.map { return ["\($0.declaration) { ... }"] + $0.body },
            [
                [
                    "open var foo: Foo { ... }",
                    "return fooProvider.provide()"
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
    
    func testExplicitOptionalSingletonReferenceWithPropertyAndConstructorInjections() {
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
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .singleton)
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
    
    func testExplicitOptionalSingletonValue() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.isOptional = true
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .singleton)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
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
    
    func testExplicitSingletonValueWithConstructorInjections() {
        var container = Container(name: "Test")
        container.dependencies.append(
            {
                var type = Type(name: "Foo")
                type.injectionSuite.constructor = ConstructorInjection(args: [
                    FunctionInvocationArgument(name: nil, valueName: "unnamed"),
                    FunctionInvocationArgument(name: "named", valueName: "named")
                    ])
                return Dependency(name: "foo", typeResolver: .explicit(type), storage: .singleton)
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
