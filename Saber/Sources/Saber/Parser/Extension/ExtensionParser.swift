//
//  ExtensionParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 28/05/2018.
//

import Foundation
import SourceKittenFramework

class ExtensionParser {

    static func parse(_ structure: [String : SourceKitRepresentable],
                      rawAnnotations: RawAnnotations) -> ParsedExtension? {
        guard let kind = structure.swiftDeclKind, let name = structure.swiftName else {
            return nil
        }
        switch kind {
        case .extension:
            var inherited: [ParsedTypeUsage] = []
            structure.swiftInherited?.forEach {
                guard let name = $0.swiftName else {
                    return
                }
                inherited.append(ParsedTypeUsage(name: name))
            }
            var ext = ParsedExtension(typeName: name, inheritedFrom: inherited)
            structure.swiftSubstructures?.forEach {
                if let nestedType = TypeParser.parse($0, rawAnnotations: rawAnnotations) {
                    ext.nested.append(.type(nestedType))
                }
                if let nestedExtension = ExtensionParser.parse($0, rawAnnotations: rawAnnotations) {
                    ext.nested.append(.extension(nestedExtension))
                }
            }
            return ext
        default:
            return nil
        }
    }
}
