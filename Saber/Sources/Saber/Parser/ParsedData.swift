//
//  ParsedData.swift
//  Saber
//
//  Created by andrey.pleshkov on 29/05/2018.
//

import Foundation

struct ParsedData: Equatable {
    
    var containers: [String : ParsedContainer] = [:]
    
    var types: [String : ParsedType] = [:]

    var aliases: [String : ParsedTypealias] = [:]
}

// MARK: Factory

class ParsedDataFactory {

    private var containers: [String : ParsedContainer] = [:]
    
    private var types: [String : ParsedType] = [:]

    private var aliases: [String : ParsedTypealias] = [:]

    private var postponed: [ParsedExtension] = []
    
    init() {}

    func register(_ container: ParsedContainer) {
        assert(containers[container.name] == nil)
        containers[container.name] = container
    }
    
    func register(_ type: ParsedType) {
        assert(types[type.name] == nil)
        types[type.name] = type
    }

    func register(_ alias: ParsedTypealias) {
        aliases[alias.name] = alias
    }

    @discardableResult
    func register(_ ext: ParsedExtension) -> Bool {
        guard var type = types[ext.typeName] else {
            postponed.append(ext)
            return false
        }
        type.inheritedFrom.append(contentsOf: ext.inheritedFrom)
        type.properties.append(contentsOf: ext.properties)
        type.methods.append(contentsOf: ext.methods)
        type.nested.append(contentsOf: ext.nested)
        types[type.name] = type
        return true
    }

    func make() -> ParsedData {
        postponed = postponed.filter {
            return !register($0)
        }
        assert(postponed.count == 0)
        return ParsedData(
            containers: containers,
            types: types,
            aliases: aliases
        )
    }
}
