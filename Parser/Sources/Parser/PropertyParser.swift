//
//  VariableParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 23/05/2018.
//

import Foundation
import SourceKittenFramework

class PropertyParser {

    static func parse(_ structure: [String : SourceKitRepresentable],
                      rawAnnotations: RawAnnotations) -> ParsedProperty? {
        guard let kind = structure.swiftDeclKind,
            let name = structure.swiftName,
            let typeName = structure.swiftTypeName else {
            return nil
        }
        switch kind {
        case .varInstance:
            guard let type = TypeUsageParser.parse(typeName) else {
                return nil
            }
            return ParsedProperty(
                name: name,
                type: type,
                annotations: rawAnnotations.annotations(for: structure).compactMap { PropertyAnnotationParser.parse($0) }
            )
        default:
            return nil
        }
    }
}
