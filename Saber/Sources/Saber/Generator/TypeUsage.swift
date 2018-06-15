//
//  TypeUsage.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation

struct TypeUsage: SomeType, Equatable {

    var name: String

    var isOptional: Bool = false

    var generics: [TypeUsage] = []

    init(name: String) {
        self.name = name
    }

    var fullName: String {
        var fullName = name
        if generics.count > 0 {
            let list = generics
                .map { $0.fullName }
                .joined(separator: ", ")
            fullName += "<\(list)>"
        }
        if isOptional {
            fullName += "?"
        }
        return fullName
    }

    func set(isOptional: Bool) -> TypeUsage {
        var result = self
        result.isOptional = isOptional
        return result
    }
}
