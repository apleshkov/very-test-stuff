//
//  ParsedTypealias.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation

struct ParsedTypealias: Equatable {

    var name: String

    var type: ParsedTypeUsage

    var moduleName: String? = nil

    init(name: String, type: ParsedTypeUsage) {
        self.name = name
        self.type = type
    }
}
