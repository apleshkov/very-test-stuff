//
//  Type.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation

struct Type {

    enum Initializer {
        case none
        case some(args: [ConstructorInjection])
    }

    var name: String

    var isOptional: Bool = false

    var isReference: Bool = false

    var initializer: Initializer = .some(args: [])

    var generics: [Type] = []

    var memberInjections: [MemberInjection] = []

    var methodInjections: [InstanceMethodInjection] = []

    var didInjectHandlerName: String? = nil

    init(name: String) {
        self.name = name
    }

    var fullName: String {
        return "\(name)\(isOptional ? "?" : "")"
    }

    func set(initializer: Initializer) -> Type {
        var result = self
        result.initializer = initializer
        return result
    }

    func set(isOptional: Bool) -> Type {
        var result = self
        result.isOptional = isOptional
        return result
    }

    func set(isReference: Bool) -> Type {
        var result = self
        result.isReference = isReference
        return result
    }
}

extension Type: Hashable {

    static func ==(lhs: Type, rhs: Type) -> Bool {
        return lhs.name == rhs.name
    }

    var hashValue: Int {
        return name.hashValue
    }
}
