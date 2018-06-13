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

    var isThreadSafe: Bool

    init(name: String,
         scopeName: String,
         protocolName: String,
         dependencies: [ParsedTypeUsage] = [],
         externals: [ParsedTypeUsage] = [],
         isThreadSafe: Bool = false) {
        self.name = name
        self.scopeName = scopeName
        self.protocolName = protocolName
        self.dependencies = dependencies
        self.externals = externals
        self.isThreadSafe = isThreadSafe
    }
}

extension ParsedContainer {
    
    var fullName: String {
        guard let moduleName = self.moduleName else {
            return name
        }
        return "\(moduleName).\(name)"
    }
}
