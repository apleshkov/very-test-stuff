//
//  ParsedType.swift
//  Parser
//
//  Created by andrey.pleshkov on 22/05/2018.
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

    static func == (lhs: ParsedType, rhs: ParsedType) -> Bool {
        return lhs.name == rhs.name
            && lhs.isOptional == rhs.isOptional
            && lhs.isUnwrapped == rhs.isUnwrapped
            && lhs.generics == rhs.generics
    }
}
