//
//  ContainerData+Test.swift
//  SwordGeneratorTests
//
//  Created by Andrew Pleshkov on 04/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation
@testable import SwordGenerator

extension ContainerData.StoredProperty {
    
    var declaration: String {
        return [
            accessLevel.source,
            referenceType?.source,
            "let \(name): \(typeName)"
            ].compactMap { $0 }.joined(separator: " ")
    }
}

extension ContainerData.ReadOnlyProperty {
    
    var declaration: String {
        return "\(accessLevel.source) var \(name): \(typeName)"
    }
}
