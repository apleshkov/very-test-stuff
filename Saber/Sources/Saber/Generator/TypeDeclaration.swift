//
//  TypeDeclaration.swift
//  Saber
//
//  Created by Andrew Pleshkov on 10/06/2018.
//

import Foundation

struct TypeDeclaration: SomeType, Equatable {
    
    enum Initializer: Equatable {
        case none
        case some(args: [FunctionInvocationArgument])
    }
    
    var name: String
    
    var isOptional: Bool
    
    var isReference: Bool
    
    var initializer: Initializer
    
    var memberInjections: [MemberInjection]
    
    var methodInjections: [InstanceMethodInjection]
    
    var didInjectHandlerName: String?
    
    init(name: String,
         isOptional: Bool = false,
         isReference: Bool = false,
         initializer: Initializer = .some(args: []),
         memberInjections: [MemberInjection] = [],
         methodInjections: [InstanceMethodInjection] = [],
         didInjectHandlerName: String? = nil) {
        self.name = name
        self.isOptional = isOptional
        self.isReference = isReference
        self.initializer = initializer
        self.memberInjections = memberInjections
        self.methodInjections = methodInjections
        self.didInjectHandlerName = didInjectHandlerName
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
