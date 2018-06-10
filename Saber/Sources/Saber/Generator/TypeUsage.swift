//
//  TypeUsage.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation

struct TypeUsage: SomeType {

    var name: String

    var isOptional: Bool = false

    var generics: [TypeUsage] = []

    init(name: String) {
        self.name = name
    }

    var fullName: String {
        return "\(name)\(isOptional ? "?" : "")"
    }

    func set(isOptional: Bool) -> TypeUsage {
        var result = self
        result.isOptional = isOptional
        return result
    }
}
