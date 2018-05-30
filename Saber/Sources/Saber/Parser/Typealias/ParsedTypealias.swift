//
//  ParsedTypealias.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation

struct ParsedTypealias: Equatable {

    var name: String

    var target: Target

    var moduleName: String? = nil

    init(name: String, target: Target) {
        self.name = name
        self.target = target
    }
    
    enum Target: Equatable {
        case type(ParsedTypeUsage)
        case raw(String)
    }
}
