//
//  ParsedMethod.swift
//  Parser
//
//  Created by andrey.pleshkov on 23/05/2018.
//

import Foundation

struct ParsedMethod: Equatable {

    var name: String

    var args: [ParsedArgument] = []

    var returnType: ParsedType?

    var isStatic: Bool = false

    init(name: String, args: [ParsedArgument] = [], returnType: ParsedType? = nil, isStatic: Bool = false) {
        self.name = name
        self.args = args
        self.returnType = returnType
        self.isStatic = isStatic
    }
}
