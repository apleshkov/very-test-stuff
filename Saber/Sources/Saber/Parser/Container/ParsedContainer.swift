//
//  ParsedContainer.swift
//  Parser
//
//  Created by andrey.pleshkov on 25/05/2018.
//

import Foundation

struct ParsedContainer: Equatable {

    var name: String

    var moduleName: String? = nil
    
    var scopeName: String

    var protocolName: String

    var dependencies: [ParsedTypeUsage]

    var externals: [ParsedTypeUsage]
    
    var imports: [String]

    var isThreadSafe: Bool

    init(name: String,
         scopeName: String,
         protocolName: String,
         dependencies: [ParsedTypeUsage] = [],
         externals: [ParsedTypeUsage] = [],
         isThreadSafe: Bool = false,
         imports: [String] = []) {
        self.name = name
        self.scopeName = scopeName
        self.protocolName = protocolName
        self.dependencies = dependencies
        self.externals = externals
        self.isThreadSafe = isThreadSafe
        self.imports = imports
    }
}

extension ParsedContainer {
    
    func fullName(modular: Bool) -> String {
        guard modular, let moduleName = self.moduleName else {
            return name
        }
        return "\(moduleName).\(name)"
    }
}

extension ParsedContainer: CustomDebugStringConvertible {

    var debugDescription: String {
        let prefix = "<Container '\(fullName(modular: true))'>"
        var components: [String] = [
            "protocol: '\(protocolName)'",
            "scope: '\(scopeName)'"
        ]
        if dependencies.count > 0 {
            components.append("dependencies: " +  dependencies.map { "'\($0.fullName)'" }.joined(separator: ", "))
        }
        if externals.count > 0 {
            components.append("externals: " + externals.map { "'\($0.fullName)'" }.joined(separator: ", "))
        }
        if imports.count > 0 {
            components.append("imports: " + imports.map { "'\($0)'" }.joined(separator: ", "))
        }
        components.append("thread-safe: \(isThreadSafe)")
        return "\(prefix) \(components.joined(separator: "; "))"
    }
}
