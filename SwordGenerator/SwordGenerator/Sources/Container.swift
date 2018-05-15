//
//  Container.swift
//  SwordCompiler
//
//  Created by andrey.pleshkov on 07/02/2018.
//

import Foundation

struct ContainerArgument {
    
    var name: String
    
    var typeName: String
    
    var isStoredProperty: Bool
    
    init(name: String, typeName: String, isStoredProperty: Bool) {
        self.name = name
        self.typeName = typeName
        self.isStoredProperty = isStoredProperty
    }
}

protocol Containing {
    
    var name: String { get }
    
    var args: [ContainerArgument] { get }
    
    var dependencies: [Dependency] { get }
}

struct Container: Containing {

    var name: String

    var parent: Containing? = nil
    
    var args: [ContainerArgument] = []
    
    var dependencies: [Dependency] = []

    init(name: String, parent: Containing? = nil) {
        self.name = name
        self.parent = parent
    }
}

struct FunctionInvocationArgument {
    
    var name: String?
    
    var valueName: String
}

struct ConstructorInjection {

    var args: [FunctionInvocationArgument]
}

struct PropertyInjection {

    var name: String

    var dependencyName: String
}

struct InjectionSuite {

    var constructor: ConstructorInjection? = nil

    var properties: [PropertyInjection] = []

    init() {}
}

enum DependencyStorage {
    case singleton
    case prototype
}

struct Dependency {

    var name: String

    var typeResolver: TypeResolver

    var storage: DependencyStorage
}

struct Type {

    var name: String

    var isOptional: Bool = false

    var isReference: Bool = false
    
    var injectionSuite = InjectionSuite()

    init(name: String) {
        self.name = name
    }

    var fullName: String {
        return "\(name)\(isOptional ? "?" : "")"
    }
}

extension Type: Hashable {

    static func ==(lhs: Type, rhs: Type) -> Bool {
        return lhs.name == rhs.name
    }

    var hashValue: Int { return name.hashValue }
}

enum TypeResolver {
    case explicit(Type)
    case provided(Type, by: TypeProviding)
}

// MARK: Providers

protocol TypeProviding {}

struct TypedProvider: TypeProviding {
    
    var type: Type
    
    init(_ type: Type) {
        self.type = type
    }
}

struct StaticMethodProvider: TypeProviding {
    
    var receiverName: String
    
    var methodName: String
    
    var args: [FunctionInvocationArgument]
}
