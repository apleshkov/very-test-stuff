//
//  TypeParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 21/05/2018.
//

import Foundation
import SourceKittenFramework

class TypeParser {

    static func parse(_ structure: [String : SourceKitRepresentable],
                      rawAnnotations: RawAnnotations) -> ParsedType? {
        guard let kind = structure.swiftDeclKind, let name = structure.swiftName else {
            return nil
        }
        switch kind {
        case .struct, .class:
            let isReference = (kind == .class)
            var type = ParsedType(name: name, isReference: isReference)
            if let inherited = structure.swiftInherited {
                inherited.forEach {
                    guard let name = $0.swiftName else {
                        return
                    }
                    type.inheritedFrom.append(ParsedTypeUsage(name: name))
                }
            }
            structure.swiftSubstructures?.forEach {
                if let nestedType = TypeParser.parse($0, rawAnnotations: rawAnnotations) {
                    type.nested.append(.type(nestedType))
                }
                if let nestedExtension = ExtensionParser.parse($0, rawAnnotations: rawAnnotations) {
                    type.nested.append(.extension(nestedExtension))
                }
                if let method = MethodParser.parse($0, rawAnnotations: rawAnnotations) {
                    type.methods.append(method)
                }
                if let property = PropertyParser.parse($0, rawAnnotations: rawAnnotations) {
                    type.properties.append(property)
                }
            }
            type.annotations = rawAnnotations
                .annotations(for: structure)
                .compactMap { TypeAnnotationParser.parse($0) }
            return type
        default:
            return nil
        }
    }
}
