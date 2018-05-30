//
//  ContainerDataFactoryCreationTests.swift
//  SaberTests
//
//  Created by andrey.pleshkov on 17/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import Saber

class ContainerDataFactoryInjectorTests: XCTestCase {
    
    func testNoInjections() {
        let type = Type(name: "Foo")
        let injector = ContainerDataFactory().injector(for: type, accessLevel: "open")
        XCTAssertEqual(injector, nil)
    }
    
    func testValueInjections() {
        var type = Type(name: "Foo")
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let injector = ContainerDataFactory().injector(for: type, accessLevel: "open")
        XCTAssertEqual(
            injector,
            [
                "open func injectTo(foo: inout Foo) {",
                "    foo.bar = self.bar",
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
        let injector = ContainerDataFactory().injector(for: type, accessLevel: "open")
        XCTAssertEqual(
            injector,
            [
                "open func injectTo(foo: inout Foo) {",
                "    foo.bar = self.bar",
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
        let injector = ContainerDataFactory().injector(for: type, accessLevel: "open")
        XCTAssertEqual(
            injector,
            [
                "open func injectTo(foo: Foo) {",
                "    foo.bar = self.bar",
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
        let injector = ContainerDataFactory().injector(for: type, accessLevel: "open")
        XCTAssertEqual(
            injector,
            [
                "open func injectTo(foo: Foo) {",
                "    foo.bar = self.bar",
                "}"
            ]
        )
    }
    
    func testMethodInjections() {
        var type = Type(name: "Foo")
        type.methodInjections = [
            InstanceMethodInjection(methodName: "set", args: [
                FunctionInvocationArgument(name: "baz", typeResolver: .explicit(Type(name: "Baz")))
                ]),
            InstanceMethodInjection(methodName: "set", args: [
                FunctionInvocationArgument(name: "quux", typeResolver: .explicit(Type(name: "Quux")))
                ])
        ]
        let injector = ContainerDataFactory().injector(for: type, accessLevel: "open")
        XCTAssertEqual(
            injector,
            [
                "open func injectTo(foo: inout Foo) {",
                "    foo.set(baz: self.baz)",
                "    foo.set(quux: self.quux)",
                "}"
            ]
        )
    }
    
    func testMemberAndMethodInjections() {
        var type = Type(name: "Foo")
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        type.methodInjections = [
            InstanceMethodInjection(methodName: "set", args: [
                FunctionInvocationArgument(name: nil, typeResolver: .explicit(Type(name: "Baz"))),
                FunctionInvocationArgument(name: "quux", typeResolver: .explicit(Type(name: "Quux")))
                ])
        ]
        let injector = ContainerDataFactory().injector(for: type, accessLevel: "open")
        XCTAssertEqual(
            injector,
            [
                "open func injectTo(foo: inout Foo) {",
                "    foo.bar = self.bar",
                "    foo.set(self.baz, quux: self.quux)",
                "}"
            ]
        )
    }

    func testDidInjectHandler() {
        var type = Type(name: "Foo")
        type.didInjectHandlerName = "postInit"
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        type.methodInjections = [
            InstanceMethodInjection(methodName: "set", args: [
                FunctionInvocationArgument(name: nil, typeResolver: .explicit(Type(name: "Baz"))),
                FunctionInvocationArgument(name: "quux", typeResolver: .explicit(Type(name: "Quux")))
                ])
        ]
        let injector = ContainerDataFactory().injector(for: type, accessLevel: "open")
        XCTAssertEqual(
            injector,
            [
                "open func injectTo(foo: inout Foo) {",
                "    foo.bar = self.bar",
                "    foo.set(self.baz, quux: self.quux)",
                "    foo.postInit()",
                "}"
            ]
        )
    }
}
