//
//  TypeParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 21/05/2018.
//

import Foundation
import SourceKittenFramework

class TypeParser {

    private static func clearRawTypeString(_ rawString: String) -> String {
        var rawString = rawString.trimmingCharacters(in: .whitespaces)
        if rawString.hasPrefix("(") {
            rawString = String(rawString.dropFirst())
            rawString = clearRawTypeString(rawString)
        }
        if rawString.hasSuffix(")") {
            rawString = String(rawString.dropLast())
            rawString = clearRawTypeString(rawString)
        }
        return rawString
    }

    static func parse(_ rawString: String) -> ParsedType? {
        if rawString.contains("->") || rawString.contains(":") {
            return nil
        }
        let rawString = clearRawTypeString(rawString)
        guard rawString.count > 0 else {
            return nil
        }
        if rawString == "()" {
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

    static func parse(_ structure: [String : SourceKitRepresentable],
                      rawAnnotations: RawAnnotations) -> ParsedType? {
        guard let kind = structure.swiftDeclKind, let name = structure.swiftName else {
            return nil
        }
        switch kind {
        case .struct, .class:
            let isReference = (kind == .class)
            var type = ParsedType(name: name, isReference: isReference)
            if let inherited = structure[SwiftDocKey.inheritedtypes] as? [[String : SourceKitRepresentable]] {
                inherited.forEach {
                    guard let name = $0.swiftName else {
                        return
                    }
                    type.inheritedFrom.append(ParsedType(name: name))
                }
            }
            structure.swiftSubstructures?.forEach {
                if let method = MethodParser.parse($0) {
                    type.methods.append(method)
                }
                if let variable = VariableParser.parse($0) {
                    type.variables.append(variable)
                }
            }
            let annotations = rawAnnotations.annotations(for: structure)
            type.typeAnnotations = annotations.compactMap {
                return TypeAnnotationParser.parse($0)
            }
            type.containerAnnotations = annotations.compactMap {
                return ContainerAnnotationParser.parse($0)
            }
            return type
        default:
            return nil
        }
    }
}
