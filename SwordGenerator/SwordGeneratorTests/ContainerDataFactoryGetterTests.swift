//
//  ContainerDataFactoryGetterTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 18/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class ContainerDataFactoryGetterTests: XCTestCase {
    
    func testValueWithoutMemberInjections() {
        let type = Type(name: "Foo")
        let getter = ContainerDataFactory().getter(of: type, named: "foo")
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    let foo: Foo = self.make()",
                "    return foo",
                "}"
            ]
        )
    }

    func testReferenceWithoutMemberInjections() {
        var type = Type(name: "Foo")
        type.isReference = true
        let getter = ContainerDataFactory().getter(of: type, named: "foo")
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    let foo: Foo = self.make()",
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
        let getter = ContainerDataFactory().getter(of: type, named: "foo")
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    var foo: Foo = self.make()",
                "    self.inject(to: &foo)",
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
        let getter = ContainerDataFactory().getter(of: type, named: "foo")
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    let foo: Foo = self.make()",
                "    self.inject(to: foo)",
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
        let getter = ContainerDataFactory().getter(of: type, named: "foo")
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo? {",
                "    var foo: Foo? = self.make()",
                "    if var foo = foo { self.inject(to: &foo) }",
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
        let getter = ContainerDataFactory().getter(of: type, named: "foo")
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo? {",
                "    let foo: Foo? = self.make()",
                "    if let foo = foo { self.inject(to: foo) }",
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
        let getter = ContainerDataFactory().getter(of: type, named: "foo", cached: ("cachedFoo", false))
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    if let cached = self.cachedFoo { return cached }",
                "    var foo: Foo = self.make()",
                "    self.inject(to: &foo)",
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
        let getter = ContainerDataFactory().getter(of: type, named: "foo", cached: ("cachedFoo", false))
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    if let cached = self.cachedFoo { return cached }",
                "    let foo: Foo = self.make()",
                "    self.inject(to: foo)",
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
        let getter = ContainerDataFactory().getter(of: type, named: "foo", cached: ("cachedFoo", true))
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    self.lock.lock()",
                "    defer { self.lock.unlock() }",
                "    if let cached = self.cachedFoo { return cached }",
                "    var foo: Foo = self.make()",
                "    self.inject(to: &foo)",
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
        let getter = ContainerDataFactory().getter(of: type, named: "foo", cached: ("cachedFoo", true))
        XCTAssertEqual(
            getter,
            [
                "open var foo: Foo {",
                "    self.lock.lock()",
                "    defer { self.lock.unlock() }",
                "    if let cached = self.cachedFoo { return cached }",
                "    let foo: Foo = self.make()",
                "    self.inject(to: foo)",
                "    self.cachedFoo = foo",
                "    return foo",
                "}"
            ]
        )
    }
}
