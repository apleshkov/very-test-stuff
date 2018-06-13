//
//  ParsedMethod.swift
//  Parser
//
//  Created by andrey.pleshkov on 23/05/2018.
//

import Foundation

struct ParsedMethod: Equatable {

    var name: String

    var args: [ParsedArgument]

    var returnType: ParsedTypeUsage?

    var isStatic: Bool

    var annotations: [MethodAnnotation]

    var isFailableInitializer: Bool

    init(name: String,
         args: [ParsedArgument] = [],
         returnType: ParsedTypeUsage? = nil,
         isStatic: Bool = false,
         annotations: [MethodAnnotation] = [],
         isFailableInitializer: Bool = false) {
        self.name = name
        self.args = args
        self.returnType = returnType
        self.isStatic = isStatic
        self.annotations = annotations
        self.isFailableInitializer = isFailableInitializer
    }
}

extension ParsedMethod {

    var isInitializer: Bool {
        return name == "init"
    }
}
