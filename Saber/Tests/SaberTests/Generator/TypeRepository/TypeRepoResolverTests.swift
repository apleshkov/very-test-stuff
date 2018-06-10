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
            repo.resolver(for: .name("Foo"), scopeName: "Singleton"),
            .explicit
        )
        XCTAssertEqual(
            repo.resolver(for: .name("Bar"), scopeName: "Singleton"),
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
            repo.resolver(for: .name("Foo"), scopeName: "Singleton"),
            .external(
                member: .property(
                    from: .name("AppExternal"),
                    name: "foo"
                )
            )
        )
        XCTAssertEqual(
            repo.resolver(for: .name("Bar"), scopeName: "Singleton"),
            .external(
                member: TypeRepository.ExternalMember.method(
                    from: .name("AppExternal"),
                    parsed: ParsedMethod(
                        name: "bar",
                        args: [],
                        returnType: ParsedTypeUsage(name: "Bar"),
                        isStatic: false,
                        annotations: []
                    )
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
            repo.resolver(for: .name("Foo"), scopeName: "Singleton"),
            .provider(.name("FooProvider"))
        )
        XCTAssertEqual(
            repo.resolver(for: .name("Bar"), scopeName: "Singleton"),
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
            repo.resolver(for: .name("Foo"), scopeName: "Singleton"),
            .provider(.name("Foo"))
        )
        XCTAssertEqual(
            repo.resolver(for: .name("Bar"), scopeName: "Singleton"),
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
            repo.resolver(for: .name("Foo"), scopeName: "Singleton"),
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
            repo.resolver(for: .name("FooProtocol"), scopeName: "Singleton"),
            .binder(.name("Foo"))
        )
        XCTAssertEqual(
            repo.resolver(for: .name("BarProtocol"), scopeName: "Singleton"),
            .binder(.name("Bar"))
        )
    }

    func testDerived() {
        let parsedData: ParsedData = {
            let factory = ParsedDataFactory()
            try! FileParser(contents:
                """
                // @saber.container(App)
                // @saber.scope(Singleton)
                // @saber.externals(AppExternal)
                protocol AppConfig {}

                // @saber.scope(Singleton)
                // @saber.bindTo(FooProtocol)
                struct Foo {}

                // @saber.scope(Singleton)
                class BarProvider {
                    // @saber.provider
                    func provide() -> Bar {}
                }

                struct AppExternal {
                    var baz: Baz
                }

                // @saber.scope(Singleton)
                class Quux {}

                // @saber.container(SessionContainer)
                // @saber.scope(Session)
                // @saber.dependsOn(App)
                protocol SessionConfig {}
                """
                ).parse(to: factory)
            return factory.make()
        }()
        let repo = try! TypeRepository(parsedData: parsedData)
        XCTAssertEqual(
            repo.resolver(for: .name("FooProtocol"), scopeName: "Session"),
            .derived(
                from: "Singleton",
                resolver: .binder(.name("Foo"))
            )
        )
        XCTAssertEqual(
            repo.resolver(for: .name("Bar"), scopeName: "Session"),
            .derived(
                from: "Singleton",
                resolver: .provider(.name("BarProvider"))
            )
        )
        XCTAssertEqual(
            repo.resolver(for: .name("Baz"), scopeName: "Session"),
            .derived(
                from: "Singleton",
                resolver: .external(
                    member: .property(from: .name("AppExternal"), name: "baz")
                )
            )
        )
        XCTAssertEqual(
            repo.resolver(for: .name("Quux"), scopeName: "Session"),
            .derived(
                from: "Singleton",
                resolver: .explicit
            )
        )
    }
}
