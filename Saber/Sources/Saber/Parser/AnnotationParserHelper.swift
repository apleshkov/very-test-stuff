//
//  AnnotationParserHelper.swift
//  Parser
//
//  Created by andrey.pleshkov on 22/05/2018.
//

import Foundation
import SourceKittenFramework

enum AnnotationParserHelper {

    static func argument(from rawString: String, prefix: String) -> String? {
        guard rawString.hasPrefix(prefix) else {
            return nil
        }
        let arg = rawString
            .dropFirst(prefix.count + 1)
            .dropLast()
            .trimmingCharacters(in: .whitespaces)
        guard arg.count > 0 else {
            return nil
        }
        return arg
    }

    static func arguments(from rawString: String, prefix: String) -> [String]? {
        let arg = argument(from: rawString, prefix: prefix) ?? ""
        return arg
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 0 }
    }
}

extension Dictionary where Key == String, Value == SourceKitRepresentable {

    subscript(key: SwiftDocKey) -> SourceKitRepresentable? {
        return self[key.rawValue]
    }

    var swiftDeclKind: SwiftDeclarationKind? {
        return (self[SwiftDocKey.kind] as? String).flatMap { SwiftDeclarationKind(rawValue: $0) }
    }

    var swiftName: String? {
        return self[SwiftDocKey.name] as? String
    }
    
    var swiftTypeName: String? {
        return self[SwiftDocKey.typeName] as? String
    }
    
    var swiftSubstructures: [[String: SourceKitRepresentable]]? {
        return self[SwiftDocKey.substructure] as? [[String: SourceKitRepresentable]]
    }

    var swiftInherited: [[String: SourceKitRepresentable]]? {
        return self[SwiftDocKey.inheritedtypes] as? [[String: SourceKitRepresentable]]
    }
}
