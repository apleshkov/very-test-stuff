//
//  Annotations.swift
//  Parser
//
//  Created by andrey.pleshkov on 21/05/2018.
//

import Foundation

struct ParsedType {

    var name: String

    var isOptional: Bool

    var isUnwrapped: Bool

    var generics: [ParsedType] = []

    init(name: String, isOptional: Bool = false, isUnwrapped: Bool = false) {
        self.name = name
        self.isOptional = isOptional
        self.isUnwrapped = isUnwrapped
    }

    func add(generic: ParsedType) -> ParsedType {
        var result = self
        result.generics.append(generic)
        return result
    }
}

extension ParsedType: Equatable {

    static func ==(lhs: ParsedType, rhs: ParsedType) -> Bool {
        return lhs.name == rhs.name
            && lhs.isOptional == rhs.isOptional
            && lhs.isUnwrapped == rhs.isUnwrapped
            && lhs.generics == rhs.generics
    }
}

struct ParsedFunctionArgument {

    var name: String?

    var type: ParsedType
}

enum ContainerAnnotation {
    case name(String)
    case scope(String)
    case dependsOn([ParsedType])
    case externals(ParsedType)
}

enum TypeAnnotation {
    case bound(of: ParsedType)
    case cached
    case scope(String)
}

enum VariableAnnotation {
    case inject
}

enum FunctionAnnotation {
    case inject
    case provider
}
