//
//  ContainerDataFactoryGetterTests.swift
//  SaberTests
//
//  Created by andrey.pleshkov on 18/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import Saber

class ContainerDataFactoryGetterTests: XCTestCase {
    
    func testValueWithoutMemberInjections() {
        let type = Type(name: "Foo")
        let getter = ContainerDataFactory().getter(of: type, accessLevel: "open")
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    let foo = self.makeFoo()",
                "    return foo",
                "}"
            ]
        )
    }

    func testReferenceWithoutMemberInjections() {
        var type = Type(name: "Foo")
        type.isReference = true
        let getter = ContainerDataFactory().getter(of: type, accessLevel: "open")
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    let foo = self.makeFoo()",
                "    return foo",
                "}"
            ]
        )
    }

    func testValueInjections() {
        var type = Type(name: "Foo")
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let getter = ContainerDataFactory().getter(of: type, accessLevel: "open")
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    var foo = self.makeFoo()",
                "    self.injectTo(foo: &foo)",
                "    return foo",
                "}"
            ]
        )
    }

    func testReferenceInjections() {
        var type = Type(name: "Foo")
        type.isReference = true
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let getter = ContainerDataFactory().getter(of: type, accessLevel: "open")
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    let foo = self.makeFoo()",
                "    self.injectTo(foo: foo)",
                "    return foo",
                "}"
            ]
        )
    }

    func testOptionalValueInjections() {
        var type = Type(name: "Foo")
        type.isOptional = true
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let getter = ContainerDataFactory().getter(of: type, accessLevel: "open")
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo? {",
                "    var foo = self.makeFoo()",
                "    if var foo = foo { self.injectTo(foo: &foo) }",
                "    return foo",
                "}"
            ]
        )
    }

    func testOptionalReferenceInjections() {
        var type = Type(name: "Foo")
        type.isReference = true
        type.isOptional = true
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let getter = ContainerDataFactory().getter(of: type, accessLevel: "open")
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo? {",
                "    let foo = self.makeFoo()",
                "    if let foo = foo { self.injectTo(foo: foo) }",
                "    return foo",
                "}"
            ]
        )
    }

    func testCachedValueInjections() {
        var type = Type(name: "Foo")
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let getter = ContainerDataFactory().getter(of: type, accessLevel: "open", cached: ("cachedFoo", false))
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    if let cached = self.cachedFoo { return cached }",
                "    var foo = self.makeFoo()",
                "    self.injectTo(foo: &foo)",
                "    self.cachedFoo = foo",
                "    return foo",
                "}"
            ]
        )
    }

    func testCachedReferenceInjections() {
        var type = Type(name: "Foo")
        type.isReference = true
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let getter = ContainerDataFactory().getter(of: type, accessLevel: "open", cached: ("cachedFoo", false))
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    if let cached = self.cachedFoo { return cached }",
                "    let foo = self.makeFoo()",
                "    self.injectTo(foo: foo)",
                "    self.cachedFoo = foo",
                "    return foo",
                "}"
            ]
        )
    }

    func testThreadSafeCachedValueInjections() {
        var type = Type(name: "Foo")
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let getter = ContainerDataFactory().getter(of: type, accessLevel: "open", cached: ("cachedFoo", true))
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    self.lock.lock()",
                "    defer { self.lock.unlock() }",
                "    if let cached = self.cachedFoo { return cached }",
                "    var foo = self.makeFoo()",
                "    self.injectTo(foo: &foo)",
                "    self.cachedFoo = foo",
                "    return foo",
                "}"
            ]
        )
    }

    func testThreadSafeCachedReferenceInjections() {
        var type = Type(name: "Foo")
        type.isReference = true
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let getter = ContainerDataFactory().getter(of: type, accessLevel: "open", cached: ("cachedFoo", true))
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    self.lock.lock()",
                "    defer { self.lock.unlock() }",
                "    if let cached = self.cachedFoo { return cached }",
                "    let foo = self.makeFoo()",
                "    self.injectTo(foo: foo)",
                "    self.cachedFoo = foo",
                "    return foo",
                "}"
            ]
        )
    }
}
