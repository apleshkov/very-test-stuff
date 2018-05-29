//
//  Container.swift
//  SwordCompiler
//
//  Created by andrey.pleshkov on 07/02/2018.
//

import Foundation

struct Container {

    var name: String

    var protocolName: String

    var dependencies: [Type] = []

    var externals: [ContainerExternal] = []
    
    var services: [Service] = []

    var isThreadSafe: Bool = false

    init(name: String, protocolName: String, dependencies: [Type] = []) {
        self.name = name
        self.dependencies = dependencies
        self.protocolName = protocolName
    }
    
    func add(dependency: Type) -> Container {
        var result = self
        result.dependencies.append(dependency)
        return result
    }
    
    func add(service: Service) -> Container {
        var result = self
        result.services.append(service)
        return result
    }
}

struct FunctionInvocationArgument {
    
    var name: String?
    
    var typeResolver: TypeResolver
}

struct ContainerExternal {
    
    enum Kind {
        case property(name: String)
        case method(name: String, args: [FunctionInvocationArgument])
    }
    
    var type: Type
    
    var kinds: [Kind]
    
    init(type: Type, kinds: [Kind]) {
        self.type = type
        self.kinds = kinds
    }
}

enum ServiceStorage {

    case cached
    case none
}

struct Service {

    var typeResolver: TypeResolver

    var storage: ServiceStorage
}

struct ConstructorInjection {

    var name: String?

    var typeResolver: TypeResolver
}

struct MemberInjection {

    var name: String

    var typeResolver: TypeResolver
}

struct InstanceMethodInjection {
    
    var methodName: String
    
    var args: [FunctionInvocationArgument]
}

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

    var hashValue: Int { return name.hashValue }
}

indirect enum TypeResolver {
    case explicit(Type)
    case provided(Type, by: TypeProvider)
    case bound(Type, to: Type)
    case derived(from: Type, typeResolver: TypeResolver)
    case external(from: Type, kind: ContainerExternal.Kind)
}

// MARK: Providers

enum TypeProvider {
    case typed(TypedProvider)
    case staticMethod(StaticMethodProvider)
}

struct TypedProvider {

    var type: Type

    var methodName: String

    var args: [FunctionInvocationArgument] = []
    
    init(type: Type, methodName: String, args: [FunctionInvocationArgument] = []) {
        self.type = type
        self.methodName = methodName
    }
}

struct StaticMethodProvider {
    
    var receiverName: String
    
    var methodName: String
    
    var args: [FunctionInvocationArgument]
}
