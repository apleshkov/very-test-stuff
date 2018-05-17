//
//  ParentContainerTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 11/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class ParentContainerTests: XCTestCase {

    func testParentContainerDependencies() {
        var parentContainer = Container(name: "Parent")
        parentContainer.services.append(
            {
                let type = Type(name: "Foo")
                return Service(typeResolver: .explicit(type), storage: .cached)
            }()
        )
        var container = Container(name: "Test", parent: parentContainer)
        container.services.append(
            {
                var type = Type(name: "Bar")
                type.constructorInjections = [
                    ConstructorInjection(name: "foo", typeResolver: .explicit(Type(name: "Foo")))
                ]
                return Service(typeResolver: .explicit(type), storage: .cached)
            }()
        )
        container.services.append(
            {
                var type = Type(name: "Baz")
                type.constructorInjections = [
                    ConstructorInjection(name: "foo", typeResolver: .explicit(Type(name: "Foo")))
                ]
                return Service(typeResolver: .explicit(type), storage: .none)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.initializer.args.map { "\($0.name): \($0.typeName)" },
            ["parentContainer: ParentContainer"]
        )
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            [
                "open unowned let parentContainer: ParentContainer",
                "open let bar: Bar"
            ]
        )
        XCTAssertEqual(
            data.initializer.creations,
            [
                "let bar = Bar(foo: parentContainer.foo)"
            ]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            [
                "self.parentContainer = parentContainer",
                "self.bar = bar"
            ]
        )
        XCTAssertEqual(
            data.readOnlyProperties.map { "\($0.declaration) { \($0.body.joined(separator: "; ")) }" },
            [
                "open var foo: Foo { return self.parentContainer.foo }",
                "open var baz: Baz { let baz = Baz(foo: parentContainer.foo); return baz }"
            ]
        )
    }

    func testParentContainer() {
        var parentContainer = Container(name: "Parent")
        parentContainer.services.append(
            {
                let type = Type(name: "Foo")
                return Service(typeResolver: .explicit(type), storage: .cached)
            }()
        )
        parentContainer.services.append(
            {
                var type = Type(name: "Foo")
                type.isOptional = true
                return Service(typeResolver: .explicit(type), storage: .cached)
            }()
        )
        parentContainer.services.append(
            {
                let type = Type(name: "Bar")
                let provider = TypedProvider(Type(name: "BarProvider"))
                return Service(typeResolver: .provided(type, by: provider), storage: .cached)
            }()
        )
        parentContainer.services.append(
            {
                let type = Type(name: "Baz")
                var provider = TypedProvider(Type(name: "BazProvider"))
                provider.type.isOptional = true
                return Service(typeResolver: .provided(type, by: provider), storage: .cached)
            }()
        )
        parentContainer.services.append(
            {
                var type = Type(name: "Quux")
                type.isOptional = true
                let provider = TypedProvider(Type(name: "QuuxProvider"))
                return Service(typeResolver: .provided(type, by: provider), storage: .cached)
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
        parentContainer.services.append(
            {
                let type = Type(name: "Foo")
                return Service(typeResolver: .explicit(type), storage: .cached)
            }()
        )
        parentContainer.services.append(
            {
                let type = Type(name: "Bar")
                return Service(typeResolver: .explicit(type), storage: .cached)
            }()
        )
        var container = Container(name: "Test", parent: parentContainer)
        container.services.append(
            {
                let type = Type(name: "ReplacedFoo")
                return Service(typeResolver: .explicit(type), storage: .cached)
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
            container.services.append(
                {
                    let type = Type(name: "AFoo")
                    return Service(typeResolver: .explicit(type), storage: .cached)
                }()
            )
            container.services.append(
                {
                    let type = Type(name: "ABar")
                    return Service(typeResolver: .explicit(type), storage: .cached)
                }()
            )
            return container
        }()
        let containerB: Container = {
            var container = Container(name: "B", parent: containerA)
            container.services.append(
                {
                    let type = Type(name: "BReplacedBar")
                    return Service(typeResolver: .explicit(type), storage: .cached)
                }()
            )
            container.services.append(
                {
                    let type = Type(name: "BBaz")
                    return Service(typeResolver: .explicit(type), storage: .cached)
                }()
            )
            return container
        }()
        let containerC: Container = {
            var container = Container(name: "C", parent: containerB)
            container.services.append(
                {
                    let type = Type(name: "CReplacedBaz")
                    return Service(typeResolver: .explicit(type), storage: .cached)
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
}
