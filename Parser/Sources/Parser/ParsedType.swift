//
//  ParsedType.swift
//  Parser
//
//  Created by andrey.pleshkov on 22/05/2018.
//

import Foundation

struct ParsedType: Equatable {

    var name: String

    var isOptional: Bool

    var isUnwrapped: Bool

    var generics: [ParsedType] = []
    
    var inheritedFrom: [ParsedType] = []

    var variables: [ParsedVariable] = []

    var methods: [ParsedMethod] = []
    
    var typeAnnotations: [TypeAnnotation] = []
    
    var containerAnnotations: [ContainerAnnotation] = []

    var isReference: Bool = false

    init(name: String, isOptional: Bool = false, isUnwrapped: Bool = false, isReference: Bool = false) {
        self.name = name
        self.isOptional = isOptional
        self.isUnwrapped = isUnwrapped
        self.isReference = isReference
    }

    func add(generic: ParsedType) -> ParsedType {
        var result = self
        result.generics.append(generic)
        return result
    }
    
    func add(inheritedFrom inherited: ParsedType) -> ParsedType {
        var result = self
        result.inheritedFrom.append(inherited)
        return result
    }
    
    func add(method: ParsedMethod) -> ParsedType {
        var result = self
        result.methods.append(method)
        return result
    }
    
    func add(typeAnnotation: TypeAnnotation) -> ParsedType {
        var result = self
        result.typeAnnotations.append(typeAnnotation)
        return result
    }
    
    func add(containerAnnotation: ContainerAnnotation) -> ParsedType {
        var result = self
        result.containerAnnotations.append(containerAnnotation)
        return result
    }
}
