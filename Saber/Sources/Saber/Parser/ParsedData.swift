//
//  ParsedData.swift
//  Saber
//
//  Created by andrey.pleshkov on 29/05/2018.
//

import Foundation

struct ParsedData: Equatable {
    
    var types: [String : ParsedType] = [:]
}

// MARK: Factory

class ParsedDataFactory {

    private var allTypes: [String : ParsedType] = [:]

    private var postponed: [ParsedExtension] = []
    
    init() {}

    func register(_ type: ParsedType) {
        assert(allTypes[type.name] == nil)
        allTypes[type.name] = type
    }

    @discardableResult
    func register(_ ext: ParsedExtension) -> Bool {
        guard var type = allTypes[ext.typeName] else {
            postponed.append(ext)
            return false
        }
        type.inheritedFrom.append(contentsOf: ext.inheritedFrom)
        type.properties.append(contentsOf: ext.properties)
        type.methods.append(contentsOf: ext.methods)
        type.nested.append(contentsOf: ext.nested)
        allTypes[type.name] = type
        return true
    }
    
    func make() -> ParsedData {
        postponed = postponed.filter {
            return !register($0)
        }
        assert(postponed.count == 0)
        return ParsedData(types: allTypes)
    }
}
