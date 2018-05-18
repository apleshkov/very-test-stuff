//
//  ContainerDataFactoryMakerTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 18/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class ContainerDataFactoryMakerTests: XCTestCase {

    func testOptionalAndNoArgs() {
        let type = Type(name: "Foo").set(isOptional: true)
        let maker = ContainerDataFactory().maker(for: type)
        XCTAssertEqual(
            maker,
            [
                "private func make() -> Foo? {",
                "    return Foo()",
                "}"
            ]
        )
    }

    func testAllNamedArgs() {
        var type = Type(name: "Foo")
        type.constructorInjections = [
            ConstructorInjection(name: "bar", typeResolver: .explicit(Type(name: "Bar"))),
            ConstructorInjection(name: "baz", typeResolver: .explicit(Type(name: "Baz")))
        ]
        let maker = ContainerDataFactory().maker(for: type)
        XCTAssertEqual(
            maker,
            [
                "private func make() -> Foo {",
                "    return Foo(bar: self.bar, baz: self.baz)",
                "}"
            ]
        )
    }

    func testNotAllNamedArgs() {
        var type = Type(name: "Foo")
        type.constructorInjections = [
            ConstructorInjection(name: nil, typeResolver: .explicit(Type(name: "Bar"))),
            ConstructorInjection(name: "baz", typeResolver: .explicit(Type(name: "Baz")))
        ]
        let maker = ContainerDataFactory().maker(for: type)
        XCTAssertEqual(
            maker,
            [
                "private func make() -> Foo {",
                "    return Foo(self.bar, baz: self.baz)",
                "}"
            ]
        )
    }
}
