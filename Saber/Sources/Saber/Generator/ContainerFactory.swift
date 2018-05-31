//
//  ContainerFactory.swift
//  Saber
//
//  Created by Andrew Pleshkov on 30/05/2018.
//

import Foundation

private enum TypeKey: Hashable {

    case name(String)
    case modular(module: String, name: String)
    
    init(name: String, moduleName: String?) {
        if let moduleName = moduleName {
            self = .modular(module: moduleName, name: name)
        } else {
            self = .name(name)
        }
    }
    
    var moduleName: String? {
        switch self {
        case .name(_):
            return nil
        case .modular(let moduleName, _):
            return moduleName
        }
    }
}

class ContainerFactory {
    
    private let parsedData: ParsedData
    
    private let knownScopeNames: Set<String>
    
    private var scopedTypes: [TypeKey : (scope: String, type: Type)] = [:]
    
    private var bound: [TypeKey : Type] = [:]
    
    private var provided: [String : String] = [:]
    
    private var typedAliases: [TypeKey : ParsedTypeUsage] = [:]
    
    private var rawAliases: Set<String> = []
    
    private var containers: [String : Container] = [:]
    
    init(parsedData: ParsedData) throws {
        self.parsedData = parsedData
        self.knownScopeNames = parsedData.containers.reduce(Set<String>()) {
            var scopeNames = $0
            scopeNames.insert($1.value.scopeName)
            return scopeNames
        }
        try fillTypes()
        fillAliases()
        try completeTypes()
    }
    
    private func fillTypes() throws {
        var parsedBinders: [(what: ParsedType, to: ParsedTypeUsage)] = []
        try parsedData.types.forEach {
            let parsedType = $0.value
            let name = parsedType.name
            let foundScopes = parsedType.inheritedFrom.filter { knownScopeNames.contains($0.name) }.map { $0.name }
            guard foundScopes.count == 1 else {
                if foundScopes.count > 0 {
                    throw Throwable.message("'\(fullName(of: parsedType))' associated with more than on scopes: \(foundScopes.joined(separator: ", "))")
                } else {
                    throw Throwable.message("'\(fullName(of: parsedType))' associated with no scope")
                }
            }
            let key = makeKey(for: parsedType)
            let scope = foundScopes[0]
            var type = Type(name: name)
            type.isReference = parsedType.isReference
            scopedTypes[key] = (scope, type)
        }
        try parsedBinders.forEach {
            let whatKey = makeKey(for: $0.what)
            guard let whatEntry = scopedTypes[whatKey] else {
                throw Throwable.message("Unable to bind '\(fullName(of: $0.what))' to \(fullName(of: $0.to)): unknown type")
            }
            var toType = Type(name: $0.to.name)
            toType.isReference = whatEntry.type.isReference
            toType.isOptional = $0.to.isOptional
            bound[whatKey] = toType
        }
    }
    
    private func fillAliases() {
        parsedData.aliases.forEach {
            let alias = $0.value
            switch alias.target {
            case .type(let usage):
                let key = makeKey(for: alias)
                typedAliases[key] = usage
            case .raw(_):
                rawAliases.insert(alias.name)
            }
        }
    }
    
    private func completeTypes() {
        parsedData.types.forEach {
            let parsedType = $0.value
            parsedType.properties.forEach {
                guard $0.annotations.contains(.inject) else {
                    return
                }
                
            }
        }
    }
    
    private func makeKey(for type: ParsedType) -> TypeKey {
        guard let moduleName = type.moduleName else {
            return .name(type.name)
        }
        return .modular(module: moduleName, name: type.name)
    }
    
    private func makeKey(for alias: ParsedTypealias) -> TypeKey {
        guard let moduleName = alias.moduleName else {
            return .name(alias.name)
        }
        return .modular(module: moduleName, name: alias.name)
    }
    
    private func findType(by key: TypeKey) -> Type? {
        guard let type = scopedTypes[key]?.type else {
            guard let usage = typedAliases[key] else {
                return nil
            }
            return findType(by: usage.name)
        }
        return type
    }
    
    private func findType(by name: String) -> Type? {
        if let type = scopedTypes[.name(name)]?.type {
            return type
        }
        let chunks = name.split(separator: ".")
        guard chunks.count > 1 else {
            return nil
        }
        let key = TypeKey.modular(
            module: String(chunks[0]),
            name: chunks.dropFirst().joined(separator: ".")
        )
        return findType(by: key)
    }
    
//    private func makeType(from usage: ParsedTypeUsage) -> Type {
//        var type = Type(name: usage.name)
//        type.isOptional = usage.isOptional
//        type.isReference = usage.is
//    }
    
    private func fillContainers(with parsedData: ParsedData) {
        parsedData.containers.forEach {
            let parsedContainer = $0.value
            let container = makeContainer(from: parsedContainer)
            containers[parsedContainer.scopeName] = container
        }
    }
    
    private func makeContainer(from parsedContainer: ParsedContainer) -> Container {
        var container = Container(name: parsedContainer.name, protocolName: parsedContainer.protocolName)
//        container.externals = parsedContainer.externals.map {
//
//        }
        return container
    }
}

private func fullName(of type: ParsedType) -> String {
    guard let moduleName = type.moduleName else {
        return type.name
    }
    return "\(moduleName).\(type.name)"
}

private func fullName(of usage: ParsedTypeUsage) -> String {
    guard usage.generics.count > 0 else {
        return usage.name
    }
    let generics = usage.generics.map { fullName(of: $0) }.joined(separator: ", ")
    return "\(usage.name)<\(generics)>"
}
