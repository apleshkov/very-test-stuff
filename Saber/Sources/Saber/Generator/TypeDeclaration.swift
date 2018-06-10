//
//  TypeDeclaration.swift
//  Saber
//
//  Created by Andrew Pleshkov on 10/06/2018.
//

import Foundation

struct TypeDeclaration: SomeType {
    
    enum Initializer {
        case none
        case some(args: [ConstructorInjection])
    }
    
    var name: String
    
    var isOptional: Bool = false
    
    var isReference: Bool = false
    
    var initializer: Initializer = .some(args: [])
    
    var memberInjections: [MemberInjection] = []
    
    var methodInjections: [InstanceMethodInjection] = []
    
    var didInjectHandlerName: String? = nil
    
    init(name: String) {
        self.name = name
    }
    
    var fullName: String {
        return "\(name)\(isOptional ? "?" : "")"
    }
    
    func set(initializer: Initializer) -> TypeDeclaration {
        var result = self
        result.initializer = initializer
        return result
    }
    
    func set(isOptional: Bool) -> TypeDeclaration {
        var result = self
        result.isOptional = isOptional
        return result
    }
    
    func set(isReference: Bool) -> TypeDeclaration {
        var result = self
        result.isReference = isReference
        return result
    }
}
