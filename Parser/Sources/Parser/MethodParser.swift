//
//  MethodParser.swift
//  Parser
//
//  Created by Andrew Pleshkov on 22/05/2018.
//

import Foundation
import SourceKittenFramework

class MethodParser {
    
    func parse(_ structure: [String : SourceKitRepresentable]) -> ParsedFunction? {
        guard let kind = structure.swiftDeclKind,
            let rawName = structure.swiftDeclName else {
            return nil
        }
        switch kind {
        case .functionMethodInstance:
            let name: String
            if let index = rawName.index(of: "(") {
                name = String(rawName[..<index])
            } else {
                name = rawName
            }
            let args = parseArgs(structure)
            let returnType = parseType(structure)
            return ParsedFunction(name: name, args: args, returnType: returnType)
        default:
            return nil
        }
    }
    
    func parseArgs(_ structure: [String : SourceKitRepresentable]) -> [ParsedArgument] {
        return (structure.swiftSubstructures ?? []).compactMap { (structure) in
            guard let kind = structure.swiftDeclKind else {
                return nil
            }
            switch kind {
            case .varParameter:
                let name: String?
                if let nameLength = structure[SwiftDocKey.nameLength] as? Int64, nameLength > 0 {
                    name = structure.swiftDeclName
                } else {
                    name = nil
                }
                guard let type = parseType(structure) else {
                    return nil
                }
                return ParsedArgument(name: name, type: type)
            default:
                return nil
            }
        }
    }
    
    func parseType(_ structure: [String : SourceKitRepresentable]) -> ParsedType? {
        guard let rawType = structure.swiftTypeName else {
            return nil
        }
        return TypeParser().parse(rawType)
    }
}
