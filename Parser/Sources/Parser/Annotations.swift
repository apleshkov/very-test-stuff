//
//  Annotations.swift
//  Parser
//
//  Created by andrey.pleshkov on 21/05/2018.
//

import Foundation

enum ContainerAnnotation: Equatable {
    case name(String)
    case scope(String)
    case dependsOn([ParsedType])
    case externals([ParsedType])
}

enum TypeAnnotation: Equatable {
    case bound(to: ParsedType)
    case cached
    case scope(String)
}

enum VariableAnnotation: Equatable {
    case inject
}

enum FunctionAnnotation: Equatable {
    case inject
    case provider
}
