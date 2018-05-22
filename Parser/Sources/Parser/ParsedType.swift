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

    var members: [ParsedTypeMember] = []

    var functions: [ParsedTypeFunction] = []

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
}

struct ParsedTypeMember: Equatable {

    var name: String

    var type: ParsedType
}

struct ParsedTypeFunction: Equatable {

    var name: String

    var args: [ParsedFunctionArgument] = []
}
