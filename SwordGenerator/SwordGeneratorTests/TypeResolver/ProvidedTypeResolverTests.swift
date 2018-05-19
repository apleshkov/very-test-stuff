//
//  ProvidedTypeResolverTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 11/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class ProvidedTypeResolverTests: XCTestCase {

    func testTypedProvider() {
        var type = Type(name: "FooBar")
        type.memberInjections = [MemberInjection(name: "baz", typeResolver: .explicit(Type(name: "Baz")))]
        let resolver = TypeResolver.provided(
            type,
            by: .typed(
                TypedProvider(
                    type: Type(name: "CoolProvider"),
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
                    "    var fooBar = self.makeFooBar()",
                    "    self.injectTo(fooBar: &fooBar)",
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
            [
                [
                    "private func injectTo(fooBar: inout FooBar) {",
                    "    fooBar.baz = self.baz",
                    "}"
                ]
            ]
        )
    }
    
    func testCachedTypedProvider() {
        let type = Type(name: "FooBar")
        let resolver = TypeResolver.provided(
            type,
            by: .typed(
                TypedProvider(
                    type: Type(name: "CoolProvider")
                        .set(initializer: .some(args: [
                            ConstructorInjection(
                                name: "quux",
                                typeResolver: .explicit(Type(name: "Quux"))
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
                ["private var cached_fooBar: FooBar?"]
            ]
        )
        XCTAssertEqual(
            data.getters,
            [
                [
                    "open var fooBar: FooBar {",
                    "    if let cached = self.cached_fooBar { return cached }",
                    "    let fooBar = self.makeFooBar()",
                    "    self.cached_fooBar = fooBar",
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
        var type = Type(name: "FooBar")
        type.memberInjections = [MemberInjection(name: "baz", typeResolver: .explicit(Type(name: "Baz")))]
        let resolver = TypeResolver.provided(
            type,
            by: .staticMethod(
                StaticMethodProvider(
                    receiverName: "FooBar",
                    methodName: "provide",
                    args: [
                        FunctionInvocationArgument(name: "quux", typeResolver: .explicit(Type(name: "Quux")))
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
                    "    return FooBar.provide(quux: self.quux)",
                    "}"
                ]
            ]
        )
        XCTAssertEqual(
            data.injectors,
            [
                [
                    "private func injectTo(fooBar: inout FooBar) {",
                    "    fooBar.baz = self.baz",
                    "}"
                ]
            ]
        )
    }
}
