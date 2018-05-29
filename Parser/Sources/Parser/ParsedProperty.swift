//
//  ParsedProperty.swift
//  Parser
//
//  Created by andrey.pleshkov on 23/05/2018.
//

import Foundation

struct ParsedProperty: Equatable {

    var name: String

    var type: ParsedTypeUsage

    var annotations: [PropertyAnnotation] = []

    init(name: String, type: ParsedTypeUsage, annotations: [PropertyAnnotation] = []) {
        self.name = name
        self.type = type
        self.annotations = annotations
    }
}
