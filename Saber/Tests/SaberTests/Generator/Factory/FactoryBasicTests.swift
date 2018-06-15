//
//  FactoryBasicTests.swift
//  SaberTests
//
//  Created by Andrew Pleshkov on 15/06/2018.
//

import XCTest
@testable import Saber

class FactoryBasicTests: XCTestCase {
    
    func testSimple() {
        let parsedFactory = ParsedDataFactory()
        try! FileParser(contents:
            """
            // @saber.container(App)
            // @saber.scope(Singleton)
            protocol AppConfig {}
            """
            ).parse(to: parsedFactory)
        let repo = try! TypeRepository(parsedData: parsedFactory.make())
        let containers = try! ContainerFactory(repo: repo).make()
        XCTAssertEqual(
            containers,
            [
                Container(
                    name: "App",
                    protocolName: "AppConfig"
                )
            ]
        )
    }
    
    func testImportsAndThreadSafe() {
        let parsedFactory = ParsedDataFactory()
        try! FileParser(contents:
            """
            // @saber.container(App)
            // @saber.scope(Singleton)
            // @saber.imports(UIKit, SomeModule)
            // @saber.threadSafe
            protocol AppConfig {}
            """
            ).parse(to: parsedFactory)
        let repo = try! TypeRepository(parsedData: parsedFactory.make())
        let containers = try! ContainerFactory(repo: repo).make()
        XCTAssertEqual(
            containers,
            [
                Container(
                    name: "App",
                    protocolName: "AppConfig",
                    isThreadSafe: true,
                    imports: ["UIKit", "SomeModule"]
                )
            ]
        )
    }
    
    func testCyclicDependencies() {
        let parsedFactory = ParsedDataFactory()
        try! FileParser(contents:
            """
            // @saber.scope(Singleton)
            struct Foo {
                init(bar: Bar) {}
            }

            // @saber.scope(Singleton)
            struct Bar {
                init(foo: Foo) {}
            }

            // @saber.container(App)
            // @saber.scope(Singleton)
            protocol AppConfig {}
            """
            ).parse(to: parsedFactory)
        let repo = try! TypeRepository(parsedData: parsedFactory.make())
        XCTAssertThrowsError(try ContainerFactory(repo: repo).make())
    }
}
