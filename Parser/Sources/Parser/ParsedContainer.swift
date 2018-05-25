//
//  ParsedContainer.swift
//  Parser
//
//  Created by andrey.pleshkov on 25/05/2018.
//

import Foundation

struct ParsedContainer: Equatable {

    var name: String

    var scopeName: String

    var protocolName: String

    var dependencies: [ParsedType] = []

    var externals: [ParsedType] = []

    init(name: String,
         scopeName: String,
         protocolName: String,
         dependencies: [ParsedType] = [],
         externals: [ParsedType] = []) {
        self.name = name
        self.scopeName = scopeName
        self.protocolName = protocolName
        self.dependencies = dependencies
        self.externals = externals
    }
}
