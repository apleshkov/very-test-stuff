//
//  ContainerData.swift
//  SwordGenerator
//
//  Created by Andrew Pleshkov on 01/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation

struct ContainerData {
    
    var name: String
    
    var storedProperties: [StoredProperty] = []
    
    var initializer: Initializer
    
    var readOnlyProperties: [ReadOnlyProperty] = []

    var methods: [Method] = []
    
    init(name: String, initializer: Initializer) {
        self.name = name
        self.initializer = initializer
    }
}

extension ContainerData {

    enum AccessLevel {
        case `open`
        case `internal`
        case `private`

        var source: String {
            switch self {
            case .open: return "open"
            case .internal: return "internal"
            case .private: return "private"
            }
        }
    }

    enum ReferenceType {
        case `strong`
        case `weak`
        case `unowned`

        var source: String {
            switch self {
            case .strong: return "strong"
            case .weak: return "weak"
            case .unowned: return "unowned"
            }
        }
    }

    struct StoredProperty {
        
        var name: String
        var type: Type
        var accessLevel: AccessLevel = .open
        var referenceType: ReferenceType? = nil
        
        init(name: String, type: Type) {
            self.name = name
            self.type = type
        }

        func set(accessLevel: AccessLevel) -> StoredProperty {
            var result = self
            result.accessLevel = accessLevel
            return result
        }
    }
    
    struct Initializer {
        
        var args: [(name: String, typeName: String)] = []
        var creations: [String] = []
        var propertyInjections: [String] = []
        var storedProperties: [String] = []
        
        init() {}
    }
    
    struct ReadOnlyProperty {
        
        var name: String
        var typeName: String
        var accessLevel: AccessLevel = .open
        var body: [String]
        
        init(name: String, typeName: String, body: [String] = []) {
            self.name = name
            self.typeName = typeName
            self.body = body
        }
    }

    struct Method {

        var lines: [String] = []

        init() {}
    }
}
