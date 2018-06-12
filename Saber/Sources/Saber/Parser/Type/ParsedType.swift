//
//  ParsedType.swift
//  Parser
//
//  Created by andrey.pleshkov on 22/05/2018.
//

import Foundation

struct ParsedType: Equatable {

    var name: String

    var moduleName: String? = nil

    var properties: [ParsedProperty] = []

    var methods: [ParsedMethod] = []
    
    var annotations: [TypeAnnotation] = []

    var isReference: Bool = false
    
    var nested: [NestedParsedDecl] = []

    init(name: String, isReference: Bool = false, nested: [NestedParsedDecl] = []) {
        self.name = name
        self.isReference = isReference
        self.nested = nested
    }
}
