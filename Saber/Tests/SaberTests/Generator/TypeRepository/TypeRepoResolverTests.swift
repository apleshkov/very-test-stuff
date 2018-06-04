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

                struct Foo: Singleton {}
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

                class FooProvider: Singleton {
                    // @saber.provider
                    func provide() -> Foo {}
                }

                class BarProvider: Singleton {
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
}
