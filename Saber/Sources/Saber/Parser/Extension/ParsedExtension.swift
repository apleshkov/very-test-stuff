//
//  ParsedExtension.swift
//  Parser
//
//  Created by andrey.pleshkov on 28/05/2018.
//

import Foundation

struct ParsedExtension: Equatable {

    var typeName: String

    var inheritedFrom: [ParsedTypeUsage] = []

    var nested: [NestedParsedDecl] = []

    init(typeName: String, inheritedFrom: [ParsedTypeUsage] = []) {
        self.typeName = typeName
        self.inheritedFrom = inheritedFrom
    }
}
