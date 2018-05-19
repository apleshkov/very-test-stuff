//
//  ContainerDataFactoryInvokedTests.swift
//  SwordGeneratorTests
//
//  Created by andrey.pleshkov on 18/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class ContainerDataFactoryInvokedTests: XCTestCase {
    
    func testWithoutArgs() {
        let invoked = ContainerDataFactory().invoked("foo", isOptional: false, with: "bar", args: [])
        XCTAssertEqual(
            invoked,
            "foo.bar()"
        )
    }

    func testAllNamedArgs() {
        let args: [FunctionInvocationArgument] = [
            FunctionInvocationArgument(name: "baz", typeResolver: .explicit(Type(name: "Baz"))),
            FunctionInvocationArgument(name: "quux", typeResolver: .explicit(Type(name: "Quux")))
        ]
        let invoked = ContainerDataFactory().invoked("foo", isOptional: false, with: "bar", args: args)
        XCTAssertEqual(
            invoked,
            "foo.bar(baz: self.baz, quux: self.quux)"
        )
    }

    func testNotAllNamedArgs() {
        let args: [FunctionInvocationArgument] = [
            FunctionInvocationArgument(name: nil, typeResolver: .explicit(Type(name: "Baz"))),
            FunctionInvocationArgument(name: "quux", typeResolver: .explicit(Type(name: "Quux")))
        ]
        let invoked = ContainerDataFactory().invoked("foo", isOptional: false, with: "bar", args: args)
        XCTAssertEqual(
            invoked,
            "foo.bar(self.baz, quux: self.quux)"
        )
    }
    
    func testProvided() {
        let args: [FunctionInvocationArgument] = [
            FunctionInvocationArgument(
                name: "baz",
                typeResolver: .provided(
                    Type(name: "Baz"),
                    by: .typed(TypedProvider(type: Type(name: "BazProvider"), methodName: "provide"))
                )
            ),
            FunctionInvocationArgument(
                name: "quux",
                typeResolver: .provided(
                    Type(name: "Quux"),
                    by: .staticMethod(StaticMethodProvider(receiverName: "QuuxProvider", methodName: "provide", args: []))
                )
            )
        ]
        let invoked = ContainerDataFactory().invoked("foo", isOptional: false, with: "bar", args: args)
        XCTAssertEqual(
            invoked,
            "foo.bar(baz: self.baz, quux: self.quux)"
        )
    }
    
    func testBound() {
        let args: [FunctionInvocationArgument] = [
            FunctionInvocationArgument(name: "quux", typeResolver: .bound(Type(name: "QuuxProtocol"), to: Type(name: "Quux")))
        ]
        let invoked = ContainerDataFactory().invoked("foo", isOptional: false, with: "bar", args: args)
        XCTAssertEqual(
            invoked,
            "foo.bar(quux: self.quuxProtocol)"
        )
    }
}
