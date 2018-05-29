//
//  ExtensionParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 28/05/2018.
//

import Foundation
import SourceKittenFramework

class ExtensionParser {

    static func parse(_ structure: [String : SourceKitRepresentable]) -> ParsedExtension? {
        guard let kind = structure.swiftDeclKind, let name = structure.swiftName else {
            return nil
        }
        switch kind {
        case .extension:
            var inherited: [ParsedTypeUsage] = []
            (structure.swiftInherited ?? []).forEach {
                guard let name = $0.swiftName else {
                    return
                }
                inherited.append(ParsedTypeUsage(name: name))
            }
            return ParsedExtension(
                typeName: name,
                inheritedFrom: inherited
            )
        default:
            return nil
        }
    }
}
