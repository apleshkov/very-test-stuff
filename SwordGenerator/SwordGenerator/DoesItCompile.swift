//
//  DoesItCompile.swift
//  SwordGenerator
//
//  Created by Andrew Pleshkov on 30/04/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation

class AContainer {

    let foo: Int = 0
}

class BContainer {

    unowned let parentContainer: AContainer

    let bar: Int

    init(parentContainer: AContainer) {
        let bar = parentContainer.foo + 1

        self.parentContainer = parentContainer
        self.bar = bar
    }
}

extension BContainer {

    var foo: Int {
        return parentContainer.foo
    }
}
