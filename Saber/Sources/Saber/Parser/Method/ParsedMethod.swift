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

    var returnType: ParsedTypeUsage?

    var isStatic: Bool = false

    var annotations: [MethodAnnotation] = []

    init(name: String,
         args: [ParsedArgument] = [],
         returnType: ParsedTypeUsage? = nil,
         isStatic: Bool = false,
         annotations: [MethodAnnotation] = []) {
        self.name = name
        self.args = args
        self.returnType = returnType
        self.isStatic = isStatic
        self.annotations = annotations
    }
}
