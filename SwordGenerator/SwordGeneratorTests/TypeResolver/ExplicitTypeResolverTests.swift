//
//  ExplicitTypeResolverTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 11/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class ExplicitTypeResolverTests: XCTestCase {

    func testValue() {
        let type = Type(name: "FooBar")
        let resolver = TypeResolver.explicit(type)
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
                    "open var fooBar: FooBar {",
                    "    let fooBar = self.makeFooBar()",
                    "    return fooBar",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.makers,
            [
                [
                    "private func makeFooBar() -> FooBar {",
                    "    return FooBar()",
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
        var type = Type(name: "FooBar")
        type.memberInjections = [MemberInjection(name: "quux", typeResolver: .explicit(Type(name: "Quux")))]
        let resolver = TypeResolver.explicit(type)
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
                    "open var fooBar: FooBar {",
                    "    var fooBar = self.makeFooBar()",
                    "    self.injectTo(fooBar: &fooBar)",
                    "    return fooBar",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.makers,
            [
                [
                    "private func makeFooBar() -> FooBar {",
                    "    return FooBar()",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.injectors,
            [
                [
                    "private func injectTo(fooBar: inout FooBar) {",
                    "    fooBar.quux = self.quux",
                    "}"
                ]
            ]
        )
    }
    
    func testNoInitializer() {
        var type = Type(name: "FooBar").set(initializer: .none)
        type.memberInjections = [MemberInjection(name: "quux", typeResolver: .explicit(Type(name: "Quux")))]
        let resolver = TypeResolver.explicit(type)
        let service = Service(typeResolver: resolver, storage: .none)
        let container = Container(name: "Test").add(service: service)
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties,
            []
        )
        XCTAssertEqual(
            data.getters,
            []
        )
        XCTAssertEqual(
            data.makers,
            []
        )
        XCTAssertEqual(
            data.injectors,
            [
                [
                    "open func injectTo(fooBar: inout FooBar) {",
                    "    fooBar.quux = self.quux",
                    "}"
                ]
            ]
        )
    }
}
