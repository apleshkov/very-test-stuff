//
//  SwordGeneratorTests.swift
//  SwordGeneratorTests
//
//  Created by Andrew Pleshkov on 30/04/2018.
//  Copyright © 2018 test. All rights reserved.
//

import XCTest
@testable import SwordGenerator

class SwordGeneratorTests: XCTestCase {

    func testInitArguments() {
        var container = Container(name: "Test")
        container.externals.append(ContainerExternal(type: Type(name: "Env")))
        container.externals.append(ContainerExternal(type: Type(name: "User").set(isOptional: true)))
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(
            data.initializer.args.map { "\($0.name): \($0.typeName)" },
            ["env: Env", "user: User?"]
        )
        XCTAssertEqual(
            data.storedProperties.map { $0.declaration },
            [
                "open let env: Env",
                "open let user: User?"
            ]
        )
        XCTAssertEqual(
            data.initializer.storedProperties,
            [
                "self.env = env",
                "self.user = user"
            ]
        )
    }
    
    func testName() {
        let container = Container(name: "Test")
        let data = ContainerDataFactory().make(from: container)
        XCTAssertEqual(data.name, "TestContainer")
    }
}
