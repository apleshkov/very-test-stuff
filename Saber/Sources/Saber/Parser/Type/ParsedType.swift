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

    var inheritedFrom: [ParsedTypeUsage] = []

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

    func add(inheritedFrom inherited: ParsedTypeUsage) -> ParsedType {
        var result = self
        result.inheritedFrom.append(inherited)
        return result
    }
    
    func add(method: ParsedMethod) -> ParsedType {
        var result = self
        result.methods.append(method)
        return result
    }
    
    func add(annotation: TypeAnnotation) -> ParsedType {
        var result = self
        result.annotations.append(annotation)
        return result
    }
}
