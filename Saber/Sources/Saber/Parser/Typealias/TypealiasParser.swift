//
//  TypealiasParser.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation
import SourceKittenFramework

class TypealiasParser {

    static func parse(_ structure: [String : SourceKitRepresentable], rawAnnotations: RawAnnotations) -> ParsedTypealias? {
        guard let kind = structure.swiftDeclKind, let name = structure.swiftName else {
            return nil
        }
        switch kind {
        case .typealias:
            guard var rawString = StringExtractor.key.extract(from: structure, contents: rawAnnotations.contents) else {
                return nil
            }
            guard let assignIndex = rawString.index(of: "=") else {
                return nil
            }
            rawString = String(rawString[assignIndex...].dropFirst()).trimmingCharacters(in: .whitespaces)
            guard let type = TypeUsageParser.parse(rawString) else {
                return nil
            }
            return ParsedTypealias(name: name, type: type)
        default:
            return nil
        }
    }
}
