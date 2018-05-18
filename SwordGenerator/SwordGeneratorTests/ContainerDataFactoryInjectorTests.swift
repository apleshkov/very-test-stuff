//
//  ContainerDataFactoryCreationTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 17/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class ContainerDataFactoryInjectorTests: XCTestCase {
    
    func testValueInjections() {
        var type = Type(name: "Foo")
        type.memberInjections = [
            MemberInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar")))
        ]
        let injector = ContainerDataFactory().injector(for: type)
        XCTAssertEqual(
            injector,
            [
                "open func inject(to injectee: inout Foo) {",
                "    injectee.bar = self.bar",
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
        let injector = ContainerDataFactory().injector(for: type)
        XCTAssertEqual(
            injector,
            [
                "open func inject(to injectee: inout Foo) {",
                "    injectee.bar = self.bar",
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
        let injector = ContainerDataFactory().injector(for: type)
        XCTAssertEqual(
            injector,
            [
                "open func inject(to injectee: Foo) {",
                "    injectee.bar = self.bar",
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
        let injector = ContainerDataFactory().injector(for: type)
        XCTAssertEqual(
            injector,
            [
                "open func inject(to injectee: Foo) {",
                "    injectee.bar = self.bar",
                "}"
            ]
        )
    }
}
