//
//  BoundTypeResolverTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 11/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import Saber

class BoundTypeResolverTests: XCTestCase {

    func testOptional() {
        let resolver = TypeResolver.bound(
            Type(name: "FooProtocol").set(isOptional: true),
            to: Type(name: "Foo").set(isOptional: true)
        )
        let service = Service(typeResolver: resolver, storage: .none)
        let container = Container(name: "Test").add(service: service)
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties,
            []
        )
        XCTAssertEqual(
            data.getters,
            [
                [
                    "open var fooProtocol: FooProtocol? {",
                    "    return self.foo",
                    "}"
                ],
                [
                    "private var foo: Foo? {",
                    "    let foo = self.makeFoo()",
                    "    return foo",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.makers,
            [
                [
                    "private func makeFoo() -> Foo? {",
                    "    return Foo()",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.injectors,
            []
        )
    }

    func testValueWithMemberInjections() {
        var type = Type(name: "Foo")
        type.memberInjections = [MemberInjection(name: "quux", typeResolver: .explicit(Type(name: "Quux")))]
        let resolver = TypeResolver.bound(
            Type(name: "FooProtocol"),
            to: type
        )
        let service = Service(typeResolver: resolver, storage: .none)
        let container = Container(name: "Test").add(service: service)
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties,
            []
        )
        XCTAssertEqual(
            data.getters,
            [
                [
                    "open var fooProtocol: FooProtocol {",
                    "    return self.foo",
                    "}"
                ],
                [
                    "private var foo: Foo {",
                    "    var foo = self.makeFoo()",
                    "    self.injectTo(foo: &foo)",
                    "    return foo",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.makers,
            [
                [
                    "private func makeFoo() -> Foo {",
                    "    return Foo()",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.injectors,
            [
                [
                    "private func injectTo(foo: inout Foo) {",
                    "    foo.quux = self.quux",
                    "}"
                ]
            ]
        )
    }
}
