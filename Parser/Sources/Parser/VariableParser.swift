//
//  VariableParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 23/05/2018.
//

import Foundation
import SourceKittenFramework

class VariableParser {

    static func parse(_ structure: [String : SourceKitRepresentable]) -> ParsedVariable? {
        guard let kind = structure.swiftDeclKind,
            let name = structure.swiftName,
            let typeName = structure.swiftTypeName else {
            return nil
        }
        switch kind {
        case .varInstance:
            guard let type = TypeParser.parse(typeName) else {
                return nil
            }
            return ParsedVariable(name: name, type: type)
        default:
            return nil
        }
    }
}
