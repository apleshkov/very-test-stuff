//
//  ContainerParserTests.swift
//  ParserTests
//
//  Created by andrey.pleshkov on 25/05/2018.
//

import XCTest
@testable import Saber
import SourceKittenFramework

class ContainerParserTests: XCTestCase {

    func testSimple() {
        XCTAssertEqual(
            parse(contents:
                """
                // @saber.container(FooContainer)
                // @saber.scope(FooScope)
                protocol FooContaining {}
                """
            ),
            [
                ParsedContainer(
                    name: "FooContainer",
                    scopeName: "FooScope",
                    protocolName: "FooContaining"
                )
            ]
        )
    }

    func testNoName() {
        XCTAssertEqual(
            parse(contents:
                """
                // @saber.scope(FooScope)
                protocol FooContaining {}
                """
            ),
            []
        )
    }

    func testNoScope() {
        XCTAssertEqual(
            parse(contents:
                """
                // @saber.container(FooContainer)
                protocol FooContaining {}
                """
            ),
            []
        )
    }

    func testNonProtocol() {
        XCTAssertEqual(
            parse(contents:
                """
                // @saber.container(FooContainer)
                struct FooContaining {}
                """
            ),
            []
        )
    }

    func test() {
        XCTAssertEqual(
            parse(contents:
                """
                // @saber.container(FooContainer)
                // @saber.scope(FooScope)
                // @saber.dependsOn(BarContainer, BazContainer)
                // @saber.dependsOn(QuuxContainer)
                // @saber.externals(FooExternals2, FooExternals3)
                // @saber.externals(FooExternals1)
                protocol FooContaining {}
                """
            ),
            [
                ParsedContainer(
                    name: "FooContainer",
                    scopeName: "FooScope",
                    protocolName: "FooContaining",
                    dependencies: [
                        ParsedTypeUsage(name: "QuuxContainer"),
                        ParsedTypeUsage(name: "BarContainer"),
                        ParsedTypeUsage(name: "BazContainer")
                    ],
                    externals: [
                        ParsedTypeUsage(name: "FooExternals1"),
                        ParsedTypeUsage(name: "FooExternals2"),
                        ParsedTypeUsage(name: "FooExternals3")
                    ]
                )
            ]
        )
    }
}

private func parse(contents: String) -> [ParsedContainer] {
    let structure = try! Structure(file: File(contents: contents))
    let rawData = RawData(contents: contents)
    return structure.dictionary.swiftSubstructures!.compactMap {
        return ContainerParser.parse($0, rawData: rawData)
    }
}
