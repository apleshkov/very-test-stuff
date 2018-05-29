//
//  ContainerParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 25/05/2018.
//

import Foundation
import SourceKittenFramework

class ContainerParser {

    static func parse(_ structure: [String : SourceKitRepresentable], rawAnnotations: RawAnnotations) -> ParsedContainer? {
        let annotations = rawAnnotations
            .annotations(for: structure)
            .compactMap { return ContainerAnnotationParser.parse($0) }
        guard structure.swiftDeclKind == .protocol, let protocolName = structure.swiftName else {
            return nil
        }
        guard annotations.count > 0 else {
            return nil
        }
        var foundName: String? = nil
        var foundScopeName: String? = nil
        var foundDependencies: [ParsedTypeUsage] = []
        var foundExternals: [ParsedTypeUsage] = []
        annotations.forEach {
            switch $0 {
            case .name(let name):
                foundName = name
            case .scope(let scopeName):
                foundScopeName = scopeName
            case .dependencies(let dependencies):
                foundDependencies.append(contentsOf: dependencies)
            case .externals(let externals):
                foundExternals.append(contentsOf: externals)
            }
        }
        guard let name = foundName, let scopeName = foundScopeName else {
            return nil
        }
        var container = ParsedContainer(name: name, scopeName: scopeName, protocolName: protocolName)
        container.dependencies = foundDependencies
        container.externals = foundExternals
        return container
    }
}
