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
                return Service(typeResolver: .explicit(type), storage: .none)
            }()
        )
        var container = Container(name: "Test", parent: parentContainer)
        container.services.append(
            {
                let type = Type(name: "Bar")
                return Service(typeResolver: .explicit(type), storage: .none)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.initializer.args.map { "\($0.name): \($0.typeName)" },
            ["parentContainer: ParentContainer"]
        )
        XCTAssertEqual(
            data.storedProperties,
            [
                ["open unowned let parentContainer: ParentContainer"]
            ]
        )
        XCTAssertEqual(
            data.initializer.creations,
            []
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            [
                "self.parentContainer = parentContainer"
            ]
        )
        XCTAssertEqual(
            data.getters,
            [
                [
                    "private var foo: Foo {",
                    "    return self.parentContainer.foo",
                    "}"
                ],
                [
                    "open var bar: Bar {",
                    "    let bar = self.makeBar()",
                    "    return bar",
                    "}"
                ]
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
        let container = Container(name: "Test", parent: parentContainer)
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.initializer.args.map { "\($0.name): \($0.typeName)" },
            ["parentContainer: ParentContainer"]
        )
        XCTAssertEqual(
            data.storedProperties,
            [
                ["open unowned let parentContainer: ParentContainer"]
            ]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            ["self.parentContainer = parentContainer"]
        )
        XCTAssertEqual(
            data.getters,
            [
                [
                    "private var foo: Foo {",
                    "    return self.parentContainer.foo",
                    "}"
                ]
            ]
        )
    }

    func testParentContainerCollisions() {
        var parentContainer = Container(name: "Parent")
        parentContainer.services.append(
            {
                let type = Type(name: "Foo")
                return Service(typeResolver: .explicit(type), storage: .none)
            }()
        )
        var container = Container(name: "Test", parent: parentContainer)
        container.services.append(
            {
                let type = Type(name: "Foo")
                return Service(typeResolver: .explicit(type), storage: .none)
            }()
        )
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.getters,
            [
                [
                    "private var foo: Foo {",
                    "    return self.parentContainer.foo",
                    "}"
                ],
                [
                    "open var foo: Foo {",
                    "    let foo = self.makeFoo()",
                    "    return foo",
                    "}"
                ]
            ]
        )
    }

    func testMultipleChildContainers() {
        let containerA: Container = {
            var container = Container(name: "A")
            container.services.append(
                {
                    let type = Type(name: "AFoo")
                    return Service(typeResolver: .explicit(type), storage: .none)
                }()
            )
            return container
        }()
        let containerB: Container = {
            var container = Container(name: "B", parent: containerA)
            container.services.append(
                {
                    let type = Type(name: "BBar")
                    return Service(typeResolver: .explicit(type), storage: .none)
                }()
            )
            return container
        }()
        let containerC: Container = {
            var container = Container(name: "C", parent: containerB)
            container.services.append(
                {
                    let type = Type(name: "CBaz")
                    return Service(typeResolver: .explicit(type), storage: .none)
                }()
            )
            return container
        }()
        let dataB = ContainerDataFactory().make(from: containerB)
        XCTAssertEqual(
            dataB.getters,
            [
                [
                    "private var aFoo: AFoo {",
                    "    return self.parentContainer.aFoo",
                    "}"
                ],
                [
                    "open var bBar: BBar {",
                    "    let bBar = self.makeBBar()",
                    "    return bBar",
                    "}"
                ]
            ]
        )
        let dataC = ContainerDataFactory().make(from: containerC)
        XCTAssertEqual(
            dataC.getters,
            [
                [
                    "private var bBar: BBar {",
                    "    return self.parentContainer.bBar",
                    "}"
                ],
                [
                    "private var aFoo: AFoo {",
                    "    return self.parentContainer.aFoo",
                    "}"
                ],
                [
                    "open var cBaz: CBaz {",
                    "    let cBaz = self.makeCBaz()",
                    "    return cBaz",
                    "}"
                ]
            ]
        )
    }
}
