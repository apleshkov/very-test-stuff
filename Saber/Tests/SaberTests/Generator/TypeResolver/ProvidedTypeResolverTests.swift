//
//  ProvidedTypeResolverTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 11/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import Saber

class ProvidedTypeResolverTests: XCTestCase {

    func testTypedProvider() {
        var decl = TypeDeclaration(name: "FooBar")
        decl.memberInjections = [MemberInjection(name: "baz", typeResolver: .explicit(TypeUsage(name: "Baz")))]
        let resolver = TypeResolver<TypeDeclaration>.provided(
            TypeUsage(name: decl.name),
            by: .typed(
                TypedProvider(
                    decl: TypeDeclaration(name: "CoolProvider"),
                    methodName: "provide"
                )
            )
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
                    "open var fooBar: FooBar {",
                    "    let fooBar = self.makeFooBar()",
                    "    return fooBar",
                    "}"
                ],
                [
                    "private var coolProvider: CoolProvider {",
                    "    let coolProvider = self.makeCoolProvider()",
                    "    return coolProvider",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.makers,
            [
                [
                    "private func makeFooBar() -> FooBar {",
                    "    let provider = self.coolProvider",
                    "    return provider.provide()",
                    "}"
                ],
                [
                    "private func makeCoolProvider() -> CoolProvider {",
                    "    return CoolProvider()",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.injectors,
            []
        )
    }
    
    func testCachedTypedProvider() {
        let decl = TypeDeclaration(name: "FooBar")
        let resolver = TypeResolver<TypeDeclaration>.provided(
            TypeUsage(name: decl.name),
            by: .typed(
                TypedProvider(
                    decl: TypeDeclaration(name: "CoolProvider")
                        .set(initializer: .some(args: [
                            ConstructorInjection(
                                name: "quux",
                                typeResolver: .explicit(TypeUsage(name: "Quux"))
                            )
                            ])),
                    methodName: "provide"
                )
            )
        )
        let service = Service(typeResolver: resolver, storage: .cached)
        let container = Container(name: "Test").add(service: service)
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.storedProperties,
            [
                ["private var cached_coolProvider: CoolProvider?"]
            ]
        )
        XCTAssertEqual(
            data.getters,
            [
                [
                    "open var fooBar: FooBar {",
                    "    let fooBar = self.makeFooBar()",
                    "    return fooBar",
                    "}"
                ],
                [
                    "private var coolProvider: CoolProvider {",
                    "    if let cached = self.cached_coolProvider { return cached }",
                    "    let coolProvider = self.makeCoolProvider()",
                    "    self.cached_coolProvider = coolProvider",
                    "    return coolProvider",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.makers,
            [
                [
                    "private func makeFooBar() -> FooBar {",
                    "    let provider = self.coolProvider",
                    "    return provider.provide()",
                    "}"
                ],
                [
                    "private func makeCoolProvider() -> CoolProvider {",
                    "    return CoolProvider(quux: self.quux)",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.injectors,
            []
        )
    }
    
    func testStaticMethodProvider() {
        var decl = TypeDeclaration(name: "FooBar")
        decl.memberInjections = [MemberInjection(name: "baz", typeResolver: .explicit(TypeUsage(name: "Baz")))]
        let resolver = TypeResolver<TypeDeclaration>.provided(
            TypeUsage(name: decl.name),
            by: .staticMethod(
                StaticMethodProvider(
                    receiverName: "FooBar",
                    methodName: "provide",
                    args: [
                        FunctionInvocationArgument(name: "quux", typeResolver: .explicit(TypeUsage(name: "Quux")))
                    ]
                )
            )
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
                    "    return FooBar.provide(quux: self.quux)",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.injectors,
            []
        )
    }
}
