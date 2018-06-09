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

    var inheritedFrom: [ParsedTypeUsage] = []

    var properties: [ParsedProperty] = []
    
    var methods: [ParsedMethod] = []
    
    var nested: [NestedParsedDecl] = []

    init(typeName: String, inheritedFrom: [ParsedTypeUsage] = []) {
        self.typeName = typeName
        self.inheritedFrom = inheritedFrom
    }
}
