//
//  ContainerDataFactoryAccessorTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 17/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class ContainerDataFactoryAccessorTests: XCTestCase {
    
    func testType() {
        XCTAssertEqual(
            ContainerDataFactory().accessor(of: Type(name: "FooBarQuux"), owner: "self"),
            "self.fooBarQuux"
        )
    }

    func testExplicit() {
        let resolver = TypeResolver.explicit(Type(name: "FooBarQuux"))
        XCTAssertEqual(
            ContainerDataFactory().accessor(of: resolver, owner: "self"),
            "self.fooBarQuux"
        )
    }

    func testProvidedByType() {
        let provider = TypedProvider(type: Type(name: "FooProvider"), methodName: "provide")
        let resolver = TypeResolver.provided(Type(name: "Foo"), by: .typed(provider))
        XCTAssertEqual(
            ContainerDataFactory().accessor(of: resolver, owner: "self"),
            "self.foo"
        )
    }

    func testProvidedByStaticMethod() {
        let provider = StaticMethodProvider(receiverName: "Foo", methodName: "provide", args: [])
        let resolver = TypeResolver.provided(Type(name: "Foo"), by: .staticMethod(provider))
        XCTAssertEqual(
            ContainerDataFactory().accessor(of: resolver, owner: "self"),
            "self.foo"
        )
    }

    func testBound() {
        let resolver = TypeResolver.bound(Type(name: "FooProtocol"), to: Type(name: "Foo"))
        XCTAssertEqual(
            ContainerDataFactory().accessor(of: resolver, owner: "self"),
            "self.fooProtocol"
        )
    }
}
