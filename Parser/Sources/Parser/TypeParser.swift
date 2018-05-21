//
//  TypeParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 21/05/2018.
//

import Foundation

class TypeParser {

    func parse(_ rawString: String) -> ParsedType? {
        let rawString = rawString.trimmingCharacters(in: .whitespaces)
        guard rawString.count > 0 else {
            return nil
        }
        var isOptional = false
        var isUnwrapped = false
        var name = rawString
        if name.hasSuffix("?") {
            isOptional = true
            name = String(name.dropLast())
        } else if name.hasSuffix("!") {
            isUnwrapped = true
            name = String(name.dropLast())
        }
        var generics: [ParsedType] = []
        if let startIndex = name.index(of: "<"), let endIndex = name.index(of: ">") {
            let range = startIndex...endIndex
            generics = name[range.lowerBound..<range.upperBound]
                .dropFirst()
                .split(separator: ",")
                .compactMap { self.parse(String($0)) }
            name.removeSubrange(range)
        }
        var type = ParsedType(name: name)
        type.isOptional = isOptional
        type.isUnwrapped = isUnwrapped
        type.generics = generics
        return type
    }
}
