//
//  Container.swift
//  SwordCompiler
//
//  Created by andrey.pleshkov on 07/02/2018.
//

import Foundation

struct ContainerExternal {
    
    var type: Type
    
    init(type: Type) {
        self.type = type
    }
}

protocol Containing {
    
    var name: String { get }

    var externals: [ContainerExternal] { get }
    
    var services: [Service] { get }
}

struct Container: Containing {

    var name: String

    var parent: Containing?

    var externals: [ContainerExternal] = []
    
    var services: [Service] = []

    var isThreadSafe: Bool = false

    init(name: String, parent: Containing? = nil) {
        self.name = name
        self.parent = parent
    }
}

struct FunctionInvocationArgument {
    
    var name: String?
    
    var typeResolver: TypeResolver
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

struct Type {

    var name: String

    var isOptional: Bool = false

    var isReference: Bool = false
    
    var constructorInjections: [ConstructorInjection] = []

    var memberInjections: [MemberInjection] = []

    init(name: String) {
        self.name = name
    }

    var fullName: String {
        return "\(name)\(isOptional ? "?" : "")"
    }

    var initializerName: String {
        return name
    }

    func set(isOptional: Bool) -> Type {
        var result = self
        result.isOptional = isOptional
        return result
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
    case provided(Type, by: TypeProvider)
    case bound(Type, to: Type)

    var type: Type {
        switch self {
        case .explicit(let type):
            return type
        case .provided(let type, _):
            return type
        case .bound(let type, _):
            return type
        }
    }
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
    
    init(type: Type, methodName: String) {
        self.type = type
        self.methodName = methodName
    }
}

struct StaticMethodProvider {
    
    var receiverName: String
    
    var methodName: String
    
    var args: [FunctionInvocationArgument]
}
