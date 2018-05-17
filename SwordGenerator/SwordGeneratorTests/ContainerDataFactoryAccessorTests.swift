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
        let resolver = TypeResolver.provided(Type(name: "Foo"), by: TypedProvider(Type(name: "FooProvider")))
        XCTAssertEqual(
            ContainerDataFactory().accessor(of: resolver, owner: "self"),
            "self.foo"
        )
    }

    func testProvidedByStaticMethod() {
        let resolver = TypeResolver.provided(Type(name: "Foo"), by: StaticMethodProvider(receiverName: "Foo", methodName: "provide", args: []))
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
