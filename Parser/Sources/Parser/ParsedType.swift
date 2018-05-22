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

    var members: [ParsedTypeMember] = []

    var functions: [ParsedFunction] = []

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
    
    func add(function: ParsedFunction) -> ParsedType {
        var result = self
        result.functions.append(function)
        return result
    }
}

struct ParsedTypeMember: Equatable {

    var name: String

    var type: ParsedType
}

struct ParsedFunction: Equatable {

    var name: String

    var args: [ParsedArgument] = []
    
    var returnType: ParsedType?
    
    var isStatic: Bool = false
    
    init(name: String, args: [ParsedArgument] = [], returnType: ParsedType? = nil, isStatic: Bool = false) {
        self.name = name
        self.args = args
        self.returnType = returnType
        self.isStatic = isStatic
    }
}
