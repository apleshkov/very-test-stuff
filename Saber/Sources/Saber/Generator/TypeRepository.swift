//
//  TypeRepository.swift
//  Saber
//
//  Created by andrey.pleshkov on 31/05/2018.
//

import Foundation

class TypeRepository {

    private var scopes: [ScopeKey : Scope] = [:]
    
    private var typedAliases: [Key : ParsedTypeUsage] = [:]
    
    private var rawAliasNames = Set<String>()
    
    private var typeInfos: [Key : Info] = [:]

    private var bound: [Key : Key] = [:] // mimic -> real
    
    private var provided: [Key : (provider: Key, method: ParsedMethod)] = [:]
    
    private var resolvers: [ScopeKey : [Key : Resolver]] = [:]

    init(parsedData: ParsedData) throws {
        try prepareScopes(parsedData: parsedData)
        fillAliases(parsedData: parsedData)
        try fillTypes(parsedData: parsedData)
        try fillExternals(parsedData: parsedData)
        try fillResolvers()
    }
}

extension TypeRepository {

    enum Key: Hashable {
        case name(String)
        case modular(module: String, name: String)
    }
    
    struct Info: Equatable {
        var key: Key
        var scopeKey: ScopeKey?
        var parsedType: ParsedType
    }
    
    typealias ScopeKey = Key
    
    struct Scope {
        var key: ScopeKey
        var name: String
        var keys: Set<Key>
        var dependencies: Set<ScopeKey>
        var externals: [Key : ExternalMember]
    }
    
    enum ExternalMember: Equatable {
        case property(from: Key, name: String, key: Key)
        case method(from: Key, parsed: ParsedMethod, key: Key)
    }
    
    indirect enum Resolver: Equatable {
        case explicit(Key)
        case provided(Key, resolver: Resolver?)
        case bound(Key, to: Key)
        case derived(from: ScopeKey, resolver: Resolver)
        case external(member: ExternalMember)
    }
}

extension TypeRepository {

    func find(by key: Key) throws -> Info {
        if let info = typeInfos[key] {
            return info
        }
        if let info = find(by: key.name, assumed: key.moduleName) {
            return info
        }
        if let usage = typedAliases[key], let info = find(by: usage.name, assumed: key.moduleName) {
            return info
        }
        throw Throwable.message("Unable to find '\(description(of: key))'")
    }

    func find(by name: String, assumed moduleName: String?) -> Info? {
        if let info = typeInfos[.name(name)] {
            return info
        }
        let chunks = name.split(separator: ".")
        guard chunks.count > 1 else {
            return try? find(by: Key(name: name, moduleName: moduleName))
        }
        let key = Key.modular(
            module: String(chunks[0]),
            name: chunks.dropFirst().joined(separator: ".")
        )
        return try? find(by: key)
    }
    
    func resolver(for key: Key, scopeKey: ScopeKey) -> Resolver? {
        return resolvers[scopeKey]?[key]
    }
}

extension TypeRepository.Key {

    init(name: String, moduleName: String?) {
        if let moduleName = moduleName {
            self = .modular(module: moduleName, name: name)
        } else {
            self = .name(name)
        }
    }
    
    var name: String {
        switch self {
        case .name(let name):
            return name
        case .modular(_, let name):
            return name
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

extension TypeRepository {

    private func makeKey(for type: ParsedType) -> Key {
        return Key(name: type.name, moduleName: type.moduleName)
    }

    private func makeKey(for alias: ParsedTypealias) -> Key {
        return Key(name: alias.name, moduleName: alias.moduleName)
    }
    
    private func makeScopeKey(for name: String, assumed moduleName: String?) throws -> ScopeKey {
        let chunks = name.split(separator: ".")
        if chunks.count == 1 {
            return Key(name: name, moduleName: moduleName)
        }
        guard chunks.count == 2 else {
            throw Throwable.message("Invalid scope name: '\(name)'")
        }
        return .modular(module: String(chunks[0]), name: String(chunks[1]))
    }
}

extension TypeRepository {
    
    private func prepareScopes(parsedData: ParsedData) throws {
        for (_, parsedContainer) in parsedData.containers {
            let scopeName = parsedContainer.scopeName
            let moduleName = parsedContainer.moduleName
            let key = try makeScopeKey(for: scopeName, assumed: moduleName)
            let deps = try parsedContainer.dependencies.map {
                return try makeScopeKey(for: $0.name, assumed: moduleName)
            }
            let scope = Scope(
                key: key,
                name: scopeName,
                keys: [],
                dependencies: Set(deps),
                externals: [:]
            )
            scopes[key] = scope
        }
    }
    
    private func fillAliases(parsedData: ParsedData) {
        parsedData.aliases.forEach {
            let alias = $0.value
            switch alias.target {
            case .type(let usage):
                let key = makeKey(for: alias)
                typedAliases[key] = usage
            case .raw(_):
                rawAliasNames.insert(alias.name)
            }
        }
    }

    private func fillTypes(parsedData: ParsedData) throws {
        var binders: [Key : ParsedTypeUsage] = [:]
        var providers: [Key : ParsedMethod] = [:]
        try parsedData.types.forEach {
            let parsedType = $0.value
            let foundScopeKeys = parsedType.inheritedFrom
                .compactMap { try? makeScopeKey(for: $0.name, assumed: parsedType.moduleName) }
                .filter { scopes[$0] != nil }
                .map { $0 }
            if foundScopeKeys.count > 1 {
                let names = foundScopeKeys.map { description(of: $0) }
                throw Throwable.message("'\(description(of: parsedType))' associated with multiple scopes: \(names.joined(separator: ", "))")
            }
            let scopeKey = foundScopeKeys.first
            let key = makeKey(for: parsedType)
            typeInfos[key] = Info(
                key: key,
                scopeKey: scopeKey,
                parsedType: parsedType
            )
            if let scopeKey = scopeKey {
                scopes[scopeKey]?.keys.insert(key)
            }
            parsedType.annotations.forEach {
                if case .bound(let to) = $0 {
                    binders[key] = to
                }
            }
            for method in parsedType.methods {
                if method.annotations.contains(.provider) {
                    providers[key] = method
                    break
                }
            }
        }
        for (key, usage) in binders {
            guard let mimicInfo = find(by: usage.name, assumed: key.moduleName) else {
                throw Throwable.message("Unable to find '\(description(of: usage))' bound to \(description(of: key))")
            }
            bound[mimicInfo.key] = key
        }
        for (key, method) in providers {
            guard let usage = method.returnType else {
                throw Throwable.message("Unable to get provided type: '\(description(of: key)).\(method.name)' returns nothing")
            }
            guard let providedInfo = find(by: usage.name, assumed: key.moduleName) else {
                throw Throwable.message("Unable to find '\(description(of: usage))' provided by \(description(of: key))")
            }
            provided[providedInfo.key] = (provider: key, method: method)
        }
    }
    
    private func fillExternals(parsedData: ParsedData) throws {
        for (_, parsedContainer) in parsedData.containers {
            var members: [Key : ExternalMember] = [:]
            try parsedContainer.externals.forEach { (usage) in
                guard let externalInfo = find(by: usage.name, assumed: parsedContainer.moduleName) else {
                    throw Throwable.message("Invalid '\(parsedContainer.name)' external: unable to find '\(description(of: usage))'")
                }
                try externalInfo.parsedType.properties.forEach {
                    guard let info = find(by: $0.type.name, assumed: parsedContainer.moduleName) else {
                        throw Throwable.message("Invalid '\(description(of: externalInfo.key))' property '\($0.name)': unable to find '\(description(of: $0.type))'")
                    }
                    members[info.key] = .property(
                        from: externalInfo.key,
                        name: $0.name,
                        key: info.key
                    )
                }
                try externalInfo.parsedType.methods.forEach {
                    guard $0.isStatic == false, let usage = $0.returnType else {
                        return
                    }
                    guard let info = find(by: usage.name, assumed: parsedContainer.moduleName) else {
                        throw Throwable.message("Invalid '\(description(of: externalInfo.key))' method '\($0.name)': unable to find '\(description(of: usage))'")
                    }
                    members[info.key] = ExternalMember.method(
                        from: externalInfo.key,
                        parsed: $0,
                        key: info.key
                    )
                }
            }
            let scopeKey = try makeScopeKey(for: parsedContainer.scopeName, assumed: parsedContainer.moduleName)
            scopes[scopeKey]?.externals = members
        }
    }
    
    private func fillResolvers() throws {
        for (_, scope) in scopes {
            var dict: [Key : Resolver] = [:]
            for (_, info) in typeInfos {
                dict[info.key] = try makeResolver(for: info, in: scope)
            }
            resolvers[scope.key] = dict
        }
    }
    
    private func makeResolver(for info: Info, in scope: Scope) throws -> Resolver? {
        let key = info.key
        if let providerData = provided[key] {
            guard providerData.method.isStatic == false else {
                return .provided(key, resolver: nil)
            }
            do {
                let providerInfo = try find(by: providerData.provider)
                let resolver = try makeResolver(for: providerInfo, in: scope)
                return .provided(key, resolver: resolver)
            } catch {
                throw Throwable.message("Unknown provider for '\(description(of: key))'")
            }
        }
        guard let scopeKey = info.scopeKey else {
            return nil
        }
        guard scope.key == scopeKey else {
            let dependencies = scope.dependencies.compactMap { scopes[$0] }
            for dep in dependencies {
                if let resolver = try makeResolver(for: info, in: dep) {
                    return Resolver.derived(from: dep.key, resolver: resolver)
                }
            }
            return nil
        }
        if scope.keys.contains(key) {
            return .explicit(key)
        }
        if let binderKey = bound[key] {
            return .bound(key, to: binderKey)
        }
        if let member = scope.externals[key] {
            return .external(member: member)
        }
        return nil
    }
}

private func description(of type: ParsedType) -> String {
    guard let moduleName = type.moduleName else {
        return type.name
    }
    return "\(moduleName).\(type.name)"
}

private func description(of usage: ParsedTypeUsage) -> String {
    guard usage.generics.count > 0 else {
        return usage.name
    }
    let generics = usage.generics.map { description(of: $0) }.joined(separator: ", ")
    return "\(usage.name)<\(generics)>"
}

private func description(of key: TypeRepository.Key) -> String {
    guard let moduleName = key.moduleName else {
        return key.name
    }
    return "\(moduleName).\(key.name)"
}
