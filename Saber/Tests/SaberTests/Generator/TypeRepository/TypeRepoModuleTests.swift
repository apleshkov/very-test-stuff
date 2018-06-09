//
//  TypeRepoModuleTests.swift
//  SaberTests
//
//  Created by andrey.pleshkov on 09/06/2018.
//

import XCTest
@testable import Saber

class TypeRepoModuleTests: XCTestCase {
    
    func testType() {
        let parsedData: ParsedData = {
            let factory = ParsedDataFactory()
            try! FileParser(contents:
                """
                // @saber.scope(Singleton)
                struct Foo {}
                """, moduleName: "A"
                ).parse(to: factory)
            try! FileParser(contents:
                """
                // @saber.container(App)
                // @saber.scope(Singleton)
                protocol AppConfig {}
                """, moduleName: "B"
                ).parse(to: factory)
            return factory.make()
        }()
        let repo = try! TypeRepository(parsedData: parsedData)
        XCTAssertEqual(
            try? repo.find(by: .modular(module: "A", name: "Foo")).key,
            .modular(module: "A", name: "Foo")
        )
        XCTAssertEqual(
            try? repo.find(by: .name("Foo")).key,
            .modular(module: "A", name: "Foo")
        )
        XCTAssertEqual(
            repo.find(by: "Foo")?.key,
            .modular(module: "A", name: "Foo")
        )
        XCTAssertEqual(
            repo.find(by: "A.Foo")?.key,
            .modular(module: "A", name: "Foo")
        )
        XCTAssertEqual(
            try? repo.find(by: .name("Bar")).key,
            nil
        )
    }

    func testTypeCollisions() {
        let parsedData: ParsedData = {
            let factory = ParsedDataFactory()
            try! FileParser(contents:
                """
                // @saber.scope(Singleton)
                struct Foo {}
                """, moduleName: "A"
                ).parse(to: factory)
            try! FileParser(contents:
                """
                // @saber.container(App)
                // @saber.scope(Singleton)
                protocol AppConfig {}

                // @saber.scope(Singleton)
                struct Foo {}
                """, moduleName: "B"
                ).parse(to: factory)
            return factory.make()
        }()
        let repo = try! TypeRepository(parsedData: parsedData)
        XCTAssertThrowsError(try repo.find(by: .name("Foo")).key, ".name()", {
            XCTAssertEqual(
                $0 as? Throwable,
                Throwable.declCollision(name: "Foo", modules: ["A", "B"])
            )
        })
    }
}
