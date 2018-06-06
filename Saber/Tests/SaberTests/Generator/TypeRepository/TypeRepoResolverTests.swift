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
            .explicit
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
            .provider(.name("FooProvider"))
        )
        XCTAssertEqual(
            repo.resolver(for: .name("Bar"), scopeKey: .name("Singleton")),
            .provider(.name("BarProvider"))
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

                // @saber.scope(Singleton)
                struct Foo {
                    // @saber.provider
                    static func provide() -> Foo {} // returns known type
                }

                // @saber.scope(Singleton)
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
            .provider(.name("Foo"))
        )
        XCTAssertEqual(
            repo.resolver(for: .name("Bar"), scopeKey: .name("Singleton")),
            .provider(.name("BarFactory"))
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
            .provider(.name("FooProvider"))
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
            .binder(.name("Foo"))
        )
        XCTAssertEqual(
            repo.resolver(for: .name("BarProtocol"), scopeKey: .name("Singleton")),
            .binder(.name("Bar"))
        )
    }

    func testDerived1() {
        let parsedData: ParsedData = {
            let factory = ParsedDataFactory()
            try! FileParser(contents:
                """
                // @saber.container(App)
                // @saber.scope(Singleton)
                protocol AppConfig {}

                // @saber.container(SessionContainer)
                // @saber.scope(Session)
                // @saber.dependsOn(App)
                protocol SessionConfig {}

                // @saber.scope(Singleton)
                // @saber.bindTo(FooProtocol)
                struct Foo {}
                """
                ).parse(to: factory)
            return factory.make()
        }()
        let repo = try! TypeRepository(parsedData: parsedData)
        XCTAssertEqual(
            repo.resolver(for: .name("FooProtocol"), scopeKey: .name("Session")),
            .derived(
                from: .name("Singleton"),
                resolver: .binder(.name("Foo"))
            )
        )
    }
}
