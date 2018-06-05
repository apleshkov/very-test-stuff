//
//  TypeRepoResolverTests.swift
//  SaberTests
//
//  Created by Andrew Pleshkov on 04/06/2018.
//

import XCTest
@testable import Saber

class TypeRepoResolverTests: XCTestCase {
    
    func testExplicit() {
        let parsedData: ParsedData = {
            let factory = ParsedDataFactory()
            try! FileParser(contents:
                """
                // @saber.container(App)
                // @saber.scope(Singleton)
                protocol AppConfig {}

                // @saber.scope(Singleton)
                struct Foo {}
                """
                ).parse(to: factory)
            return factory.make()
        }()
        let repo = try! TypeRepository(parsedData: parsedData)
        XCTAssertEqual(
            repo.resolver(for: .name("Foo"), scopeKey: .name("Singleton")),
            .explicit(.name("Foo"))
        )
        XCTAssertEqual(
            repo.resolver(for: .name("Bar"), scopeKey: .name("Singleton")),
            nil
        )
    }
    
    func testExternal() {
        let parsedData: ParsedData = {
            let factory = ParsedDataFactory()
            try! FileParser(contents:
                """
                // @saber.container(App)
                // @saber.scope(Singleton)
                // @saber.externals(AppExternal)
                protocol AppConfig {}

                struct AppExternal {
                    var foo: Foo
                    func bar() -> Bar {}
                }
                """
                ).parse(to: factory)
            return factory.make()
        }()
        let repo = try! TypeRepository(parsedData: parsedData)
        XCTAssertEqual(
            repo.resolver(for: .name("Foo"), scopeKey: .name("Singleton")),
            .external(
                member: .property(
                    from: .name("AppExternal"),
                    name: "foo",
                    key: .name("Foo")
                )
            )
        )
        XCTAssertEqual(
            repo.resolver(for: .name("Bar"), scopeKey: .name("Singleton")),
            .external(
                member: TypeRepository.ExternalMember.method(
                    from: .name("AppExternal"),
                    parsed: ParsedMethod(
                        name: "bar",
                        args: [],
                        returnType: ParsedTypeUsage(name: "Bar"),
                        isStatic: false,
                        annotations: []
                    ),
                    key: .name("Bar")
                )
            )
        )
    }
    
    func testProvided1() {
        let parsedData: ParsedData = {
            let factory = ParsedDataFactory()
            try! FileParser(contents:
                """
                // @saber.container(App)
                // @saber.scope(Singleton)
                protocol AppConfig {}

                struct Foo {} // known type

                // @saber.scope(Singleton)
                class FooProvider {
                    // @saber.provider
                    func provide() -> Foo {}
                }

                // @saber.scope(Singleton)
                class BarProvider {
                    // @saber.provider
                    func provide() -> Bar {} // returns unknown type
                }
                """
                ).parse(to: factory)
            return factory.make()
        }()
        let repo = try! TypeRepository(parsedData: parsedData)
        XCTAssertEqual(
            repo.resolver(for: .name("Foo"), scopeKey: .name("Singleton")),
            .provided(.name("Foo"))
        )
        XCTAssertEqual(
            repo.resolver(for: .name("Bar"), scopeKey: .name("Singleton")),
            .provided(.name("Bar"))
        )
    }
    
    func testProvided2() {
        let parsedData: ParsedData = {
            let factory = ParsedDataFactory()
            try! FileParser(contents:
                """
                // @saber.container(App)
                // @saber.scope(Singleton)
                protocol AppConfig {}

                struct Foo {
                    // @saber.provider
                    static func provide() -> Foo {} // returns known type
                }

                class BarFactory {
                    // @saber.provider
                    static func make() -> Bar {} // returns unknown type
                }
                """
                ).parse(to: factory)
            return factory.make()
        }()
        let repo = try! TypeRepository(parsedData: parsedData)
        XCTAssertEqual(
            repo.resolver(for: .name("Foo"), scopeKey: .name("Singleton")),
            .provided(.name("Foo"))
        )
        XCTAssertEqual(
            repo.resolver(for: .name("Bar"), scopeKey: .name("Singleton")),
            .provided(.name("Bar"))
        )
    }
    
    func testProvided3() {
        let parsedData: ParsedData = {
            let factory = ParsedDataFactory()
            try! FileParser(contents:
                """
                // @saber.container(App)
                // @saber.scope(Singleton)
                protocol AppConfig {}

                protocol Foo {}

                // @saber.scope(Singleton)
                class FooProvider {
                    // @saber.provider
                    func provide() -> Foo {}
                }
                """
                ).parse(to: factory)
            return factory.make()
        }()
        let repo = try! TypeRepository(parsedData: parsedData)
        XCTAssertEqual(
            repo.resolver(for: .name("Foo"), scopeKey: .name("Singleton")),
            .provided(.name("Foo"))
        )
    }
    
    func testBound() {
        let parsedData: ParsedData = {
            let factory = ParsedDataFactory()
            try! FileParser(contents:
                """
                // @saber.container(App)
                // @saber.scope(Singleton)
                protocol AppConfig {}

                protocol FooProtocol {}

                // @saber.scope(Singleton)
                // @saber.bindTo(FooProtocol)
                struct Foo {}

                // @saber.scope(Singleton)
                // @saber.bindTo(BarProtocol)
                struct Bar {}
                """
                ).parse(to: factory)
            return factory.make()
        }()
        let repo = try! TypeRepository(parsedData: parsedData)
        XCTAssertEqual(
            repo.resolver(for: .name("FooProtocol"), scopeKey: .name("Singleton")),
            .bound(.name("FooProtocol"), to: .name("Foo"))
        )
        XCTAssertEqual(
            repo.resolver(for: .name("BarProtocol"), scopeKey: .name("Singleton")),
            .bound(.name("BarProtocol"), to: .name("Bar"))
        )
    }
}
