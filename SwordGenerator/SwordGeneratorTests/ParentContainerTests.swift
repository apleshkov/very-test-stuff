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
        let fooType = Type(name: "Foo")
        var parentContainer = Container(name: "ParentContainer")
        parentContainer.services.append(
            {
                return Service(typeResolver: .explicit(fooType), storage: .none)
            }()
        )
        let parentType = Type(name: parentContainer.name)
        var container = Container(name: "TestContainer").add(dependency: parentType)
        container.services.append(
            {
                var type = Type(name: "Bar")
                type.initializer = .some(args: [
                    ConstructorInjection(
                        name: "foo",
                        typeResolver: .derived(from: parentType, typeResolver: .explicit(fooType))
                    )
                    ])
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
                    "open var bar: Bar {",
                    "    let bar = self.makeBar()",
                    "    return bar",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.makers,
            [
                [
                    "private func makeBar() -> Bar {",
                    "    return Bar(foo: self.parentContainer.foo)",
                    "}"
                ]
            ]
        )
    }

    func testMultipleChildContainers() {
        let aDependency = Type(name: "ContainerA")
        let bDependency = Type(name: "ContainerB")
        let container: Container = {
            var container = Container(name: "ContainerC")
                .add(dependency: aDependency)
                .add(dependency: bDependency)
            container.services.append(
                {
                    var type = Type(name: "Baz")
                    type.memberInjections = [
                        MemberInjection(
                            name: "foo",
                            typeResolver: .derived(
                                from: aDependency,
                                typeResolver: .explicit(Type(name: "Foo"))
                            )
                        ),
                        MemberInjection(
                            name: "bar",
                            typeResolver: .derived(
                                from: bDependency,
                                typeResolver: .explicit(Type(name: "Bar"))
                            )
                        ),
                        MemberInjection(
                            name: "quux",
                            typeResolver: .derived(
                                from: bDependency,
                                typeResolver: .derived(
                                    from: aDependency,
                                    typeResolver: .explicit(Type(name: "Quux"))
                                )
                            )
                        )
                    ]
                    return Service(typeResolver: .explicit(type), storage: .none)
                }()
            )
            return container
        }()
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties,
            [
                ["open unowned let containerA: ContainerA"],
                ["open unowned let containerB: ContainerB"]
            ]
        )
        XCTAssertEqual(
            data.getters,
            [
                [
                    "open var baz: Baz {",
                    "    var baz = self.makeBaz()",
                    "    self.injectTo(baz: &baz)",
                    "    return baz",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.makers,
            [
                [
                    "private func makeBaz() -> Baz {",
                    "    return Baz()",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.injectors,
            [
                [
                    "private func injectTo(baz: inout Baz) {",
                    "    baz.foo = self.containerA.foo",
                    "    baz.bar = self.containerB.bar",
                    "    baz.quux = self.containerB.containerA.quux",
                    "}"
                ]
            ]
        )
    }
}
