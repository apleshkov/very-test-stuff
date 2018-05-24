//
//  ContainerAnnotationParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 22/05/2018.
//

import Foundation

private enum Prefix {
    static let name = "name"
    static let scope = "scope"
    static let dependsOn = "dependsOn"
    static let externals = "externals"
}

class ContainerAnnotationParser {

    static func parse(_ rawString: String) -> ContainerAnnotation? {
        let rawString = rawString.trimmingCharacters(in: .whitespaces)
        guard rawString.count > 0 else {
            return nil
        }
        if rawString.hasPrefix(Prefix.name),
            let name = AnnotationParserHelper.argument(from: rawString, prefix: Prefix.name) {
            return ContainerAnnotation.name(name)
        }
        if rawString.hasPrefix(Prefix.scope),
            let scope = AnnotationParserHelper.argument(from: rawString, prefix: Prefix.scope) {
            return ContainerAnnotation.scope(scope)
        }
        if rawString.hasPrefix(Prefix.dependsOn),
            let args = AnnotationParserHelper.arguments(from: rawString, prefix: Prefix.dependsOn) {
            let types = args.compactMap { TypeParser.parse($0) }
            return ContainerAnnotation.dependsOn(types)
        }
        if rawString.hasPrefix(Prefix.externals),
            let args = AnnotationParserHelper.arguments(from: rawString, prefix: Prefix.externals) {
            let types = args.compactMap { TypeParser.parse($0) }
            return ContainerAnnotation.externals(types)
        }
        return nil
    }
}
