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
    case dependencies([ParsedTypeUsage])
    case externals([ParsedTypeUsage])
}

enum TypeAnnotation: Equatable {
    case bound(to: ParsedTypeUsage)
    case cached
}

enum PropertyAnnotation: Equatable {
    case inject
}

enum MethodAnnotation: Equatable {
    case inject
    case provider
}
