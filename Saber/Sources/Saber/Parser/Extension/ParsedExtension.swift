//
//  ParsedExtension.swift
//  Parser
//
//  Created by andrey.pleshkov on 28/05/2018.
//

import Foundation

struct ParsedExtension: Equatable {

    var typeName: String

    var moduleName: String? = nil

    var properties: [ParsedProperty] = []
    
    var methods: [ParsedMethod] = []
    
    var nested: [NestedParsedDecl] = []
    
    init(typeName: String) {
        self.typeName = typeName
    }
}

extension ParsedExtension {
    
    var fullName: String {
        guard let moduleName = self.moduleName else {
            return typeName
        }
        return "\(moduleName).\(typeName)"
    }
}
