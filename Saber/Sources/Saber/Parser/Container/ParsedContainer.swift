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

    var dependencies: [ParsedTypeUsage] = []

    var externals: [ParsedTypeUsage] = []

    init(name: String,
         scopeName: String,
         protocolName: String,
         dependencies: [ParsedTypeUsage] = [],
         externals: [ParsedTypeUsage] = []) {
        self.name = name
        self.scopeName = scopeName
        self.protocolName = protocolName
        self.dependencies = dependencies
        self.externals = externals
    }
}
