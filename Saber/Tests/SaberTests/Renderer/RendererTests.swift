//
//  RendererTests.swift
//  SaberTests
//
//  Created by andrey.pleshkov on 28/06/2018.
//

import XCTest
@testable import Saber

class RendererTests: XCTestCase {
    
    func testEmptyInitializer() {
        let container = Container(name: "Foo")
        let data = ContainerDataFactory().make(from: container)
        let out = Renderer(data: data).render()
        XCTAssertEqual(
            out,
            """
            import Foundation

            class Foo: FooProtocol {

                open init() {
                }
            }
            """
        )
    }

    func testComplexInitializer() {
        var initializer = ContainerData.Initializer()
        initializer.args = [("bar", "Bar"), ("baz", "Baz")]
        initializer.creations = ["let quux = Quux()"]
        initializer.storedProperties = ["self.quux = quux"]
        let data = ContainerData(name: "Foo", initializer: initializer)
        let out = Renderer(data: data).render()
        XCTAssertEqual(
            out,
            """
            class Foo {

                open init(bar: Bar, baz: Baz) {
                    let quux = Quux()
                    self.quux = quux
                }
            }
            """
        )
    }

    func testInheritanceAndImports() {
        var data = ContainerData(name: "Foo", initializer: ContainerData.Initializer())
        data.imports = ["Foundation", "UIKit"]
        data.inheritedFrom = ["Bar", "Baz"]
        let out = Renderer(data: data).render()
        XCTAssertEqual(
            out,
            """
            import Foundation
            import UIKit

            class Foo: Bar, Baz {

                open init() {
                }
            }
            """
        )
    }

    func testStoredProperties() {
        var data = ContainerData(name: "Foo", initializer: ContainerData.Initializer())
        data.storedProperties = [
            ["private let bar: Bar"],
            ["private let baz: Baz"]
        ]
        let out = Renderer(data: data).render()
        XCTAssertEqual(
            out,
            """
            class Foo {

                private let bar: Bar

                private let baz: Baz

                open init() {
                }
            }
            """
        )
    }

    func testGettersMakersInjectors() {
        var data = ContainerData(name: "Foo", initializer: ContainerData.Initializer())
        data.getters = [
            [
                "var bar: Bar? {",
                "    return nil",
                "}"
            ],
            [
                "var baz: Baz {",
                "    return Baz()",
                "}"
            ]
        ]
        let out = Renderer(data: data).render()
        XCTAssertEqual(
            out,
            """
            class Foo {

                private let bar: Bar

                private let baz: Baz

                open init() {
                }
            }
            """
        )
    }
}
