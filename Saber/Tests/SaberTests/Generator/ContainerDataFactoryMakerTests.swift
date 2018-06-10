//
//  ContainerDataFactoryMakerTests.swift
//  SaberTests
//
//  Created by andrey.pleshkov on 18/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import Saber

class ContainerDataFactoryMakerTests: XCTestCase {

    func testNoInitializer() {
        let decl = TypeDeclaration(name: "Foo").set(initializer: .none)
        let maker = ContainerDataFactory().maker(for: decl)
        XCTAssertEqual(maker, nil)
    }
    
    func testOptionalAndNoArgs() {
        let decl = TypeDeclaration(name: "Foo").set(isOptional: true)
        let maker = ContainerDataFactory().maker(for: decl)
        XCTAssertEqual(
            maker,
            [
                "private func makeFoo() -> Foo? {",
                "    return Foo()",
                "}"
            ]
        )
    }

    func testAllNamedArgs() {
        var decl = TypeDeclaration(name: "Foo")
        decl.initializer = .some(args: [
            ConstructorInjection(name: "bar", typeResolver: .explicit(TypeUsage(name: "Bar"))),
            ConstructorInjection(name: "baz", typeResolver: .explicit(TypeUsage(name: "Baz")))
            ])
        let maker = ContainerDataFactory().maker(for: decl)
        XCTAssertEqual(
            maker,
            [
                "private func makeFoo() -> Foo {",
                "    return Foo(bar: self.bar, baz: self.baz)",
                "}"
            ]
        )
    }

    func testNotAllNamedArgs() {
        var decl = TypeDeclaration(name: "Foo")
        decl.initializer = .some(args: [
            ConstructorInjection(name: nil, typeResolver: .explicit(TypeUsage(name: "Bar"))),
            ConstructorInjection(name: "baz", typeResolver: .explicit(TypeUsage(name: "Baz")))
            ])
        let maker = ContainerDataFactory().maker(for: decl)
        XCTAssertEqual(
            maker,
            [
                "private func makeFoo() -> Foo {",
                "    return Foo(self.bar, baz: self.baz)",
                "}"
            ]
        )
    }
}
