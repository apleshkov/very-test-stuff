//
//  TypeAnnotationParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 22/05/2018.
//

import Foundation

private enum Prefix {
    static let bound = "bindTo"
    static let cached = "cached"
}

class TypeAnnotationParser {

    static func parse(_ rawString: String) -> TypeAnnotation? {
        let rawString = rawString.trimmingCharacters(in: .whitespaces)
        guard rawString.count > 0 else {
            return nil
        }
        if rawString.hasPrefix(Prefix.bound),
            let content = AnnotationParserHelper.argument(from: rawString, prefix: Prefix.bound),
            let type = TypeParser.parse(content) {
            return TypeAnnotation.bound(to: type)
        }
        if rawString == Prefix.cached {
            return TypeAnnotation.cached
        }
        return nil
    }
}
