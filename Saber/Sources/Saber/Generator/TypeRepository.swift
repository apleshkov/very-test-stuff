//
//  TypeRepository.swift
//  Saber
//
//  Created by andrey.pleshkov on 31/05/2018.
//

import Foundation

class TypeRepository {

    private var scopes: [ScopeKey : Scope] = [:]
    
    private var typeInfos: [Key : Info] = [:]

    /// .modular(module: "A", name: "Foo") represented as "A.Foo"
    private var modularNames: [String : Key] = [:]

    /// "Foo" -> ["A", "B"] if "Foo" is declared in both "A" and "B"
    private var shortenNameCollisions: [String : [String]] = [:]

    private var resolvers: [ScopeKey : [Key : Resolver]] = [:]

    init(parsedData: ParsedData) throws {
        try prepareScopes(parsedData: parsedData)
        try fillAliases(parsedData: parsedData)
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
        var parsedType: ParsedType?
        var parsedUsage: ParsedTypeUsage?
    }
    
    typealias ScopeKey = Key
    
    struct Scope {
        var key: ScopeKey
        var name: String
        var keys: Set<Key>
        var dependencies: Set<ScopeKey>
        var externals: [Key : ExternalMember]
        var providers: [Key : (of: Key, method: ParsedMethod)]
        var binders: [Key : Key]
    }
    
    enum ExternalMember: Equatable {
        case property(from: Key, name: String)
        case method(from: Key, parsed: ParsedMethod)
    }
    
    indirect enum Resolver: Equatable {
        case explicit
        case provider(Key)
        case binder(Key)
        case derived(from: ScopeKey, resolver: Resolver)
        case external(member: ExternalMember)
    }
}

extension TypeRepository {

    func find(by key: Key) throws -> Info {
        if case .name(let name) = key, let collisions = shortenNameCollisions[name], collisions.count > 1 {
            throw Throwable.declCollision(name: name, modules: collisions)
        }
        guard let info = typeInfos[key] else {
            throw Throwable.message("Unable to find '\(description(of: key))'")
        }
        return info
    }

    func find(by name: String) -> Info? {
        if let key = modularNames[name] {
            return try? find(by: key)
        }
        if let info = try? find(by: .name(name)) {
            return info
        }
        return nil
    }

    private func register(_ info: Info) {
        let key = info.key
        typeInfos[key] = info
        if let moduleName = key.moduleName {
            modularNames["\(moduleName).\(key.name)"] = key
            var collisions = shortenNameCollisions[key.name] ?? []
            collisions.append(moduleName)
            shortenNameCollisions[key.name] = collisions
        }
        if let scopeKey = info.scopeKey {
            scopes[scopeKey]?.keys.insert(key)
        }
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

    private func makeScopeKey(for name: String) throws -> ScopeKey {
        let chunks = name.split(separator: ".")
        if chunks.count == 1 {
            return .name(name)
        }
        guard chunks.count == 2 else {
            throw Throwable.message("Invalid scope name: '\(name)'")
        }
        return .modular(module: String(chunks[0]), name: String(chunks[1]))
    }

    private func makeScopeKey(from annotations: [TypeAnnotation], of typeName: String) throws -> ScopeKey? {
        let foundNames: [String] = annotations.compactMap {
            if case .scope(let name) = $0 {
                return name
            }
            return nil
        }
        if foundNames.count > 1 {
            throw Throwable.message("'\(typeName))' associated with multiple scopes: \(foundNames.joined(separator: ", "))")
        }
        if let name = foundNames.first {
            return try makeScopeKey(for: name)
        }
        return nil
    }
}

extension TypeRepository {
    
    private func prepareScopes(parsedData: ParsedData) throws {
        for (_, parsedContainer) in parsedData.containers {
            let scopeName = parsedContainer.scopeName
            let key = try makeScopeKey(for: scopeName)
            let deps: [ScopeKey] = try parsedContainer.dependencies.map {
                guard let container = parsedData.containers[$0.name] else {
                    throw Throwable.message("Unknown '\(parsedContainer.name)' dependency: '\($0.name)' not found")
                }
                return try makeScopeKey(for: container.scopeName)
            }
            let scope = Scope(
                key: key,
                name: scopeName,
                keys: [],
                dependencies: Set(deps),
                externals: [:],
                providers: [:],
                binders: [:]
            )
            scopes[key] = scope
        }
    }

    private func fillAliases(parsedData: ParsedData) throws {
        try parsedData.aliases.forEach {
            let alias = $0.value
            switch alias.target {
            case .type(let usage):
                let key = makeKey(for: alias)
                register(
                    Info(
                        key: key,
                        scopeKey: try makeScopeKey(from: alias.annotations, of: alias.name),
                        parsedType: nil,
                        parsedUsage: usage
                    )
                )
            case .raw(_):
                break
            }
        }
    }

    private func fillTypes(parsedData: ParsedData) throws {
        var binders: [Key : (scopeKey: ScopeKey, usage: ParsedTypeUsage)] = [:]
        var providers: [Key : (scopeKey: ScopeKey, method: ParsedMethod)] = [:]
        try parsedData.types.forEach {
            let parsedType = $0.value
            let scopeKey: ScopeKey? = try makeScopeKey(
                from: parsedType.annotations,
                of: description(of: parsedType)
            )
            let key = makeKey(for: parsedType)
            register(
                Info(
                    key: key,
                    scopeKey: scopeKey,
                    parsedType: parsedType,
                    parsedUsage: nil
                )
            )
            if let scopeKey = scopeKey {
                parsedType.annotations.forEach {
                    if case .bound(let to) = $0 {
                        binders[key] = (scopeKey, to)
                    }
                }
                for method in parsedType.methods {
                    if method.annotations.contains(.provider) {
                        providers[key] = (scopeKey, method)
                        break
                    }
                }
            }
        }
        for (key, entry) in binders {
            let mimicKey: Key
            let usage = entry.usage
            if let mimicInfo = find(by: usage.name) {
                mimicKey = mimicInfo.key
            } else {
                mimicKey = .name(usage.name)
                register(
                    Info(
                        key: mimicKey,
                        scopeKey: try find(by: key).scopeKey,
                        parsedType: nil,
                        parsedUsage: usage
                    )
                )
            }
            scopes[entry.scopeKey]?.binders[key] = mimicKey
        }
        for (key, entry) in providers {
            let method = entry.method
            guard let usage = method.returnType else {
                throw Throwable.message("Unable to get provided type: '\(description(of: key)).\(method.name)' returns nothing")
            }
            let providedKey: Key
            if let providedInfo = find(by: usage.name) {
                providedKey = providedInfo.key
            } else {
                providedKey = .name(usage.name)
                register(
                    Info(
                        key: providedKey,
                        scopeKey: try find(by: key).scopeKey,
                        parsedType: nil,
                        parsedUsage: usage
                    )
                )
            }
            scopes[entry.scopeKey]?.providers[key] = (of: providedKey, method: method)
        }
    }
    
    private func fillExternals(parsedData: ParsedData) throws {
        for (_, parsedContainer) in parsedData.containers {
            var members: [Key : ExternalMember] = [:]
            try parsedContainer.externals.forEach { (usage) in
                guard let externalInfo = find(by: usage.name) else {
                    throw Throwable.message("Invalid '\(parsedContainer.name)' external: unable to find '\(description(of: usage))'")
                }
                guard let externalParsedType = externalInfo.parsedType else {
                    throw Throwable.message("Invalid '\(parsedContainer.name)' external: unable to find '\(description(of: externalInfo.key))' parsed type")
                }
                externalParsedType.properties.forEach {
                    let info: Info
                    if let foundInfo = find(by: $0.type.name) {
                        info = foundInfo
                    } else {
                        let key: Key = .name($0.type.name)
                        info = Info(
                            key: key,
                            scopeKey: externalInfo.scopeKey,
                            parsedType: nil,
                            parsedUsage: $0.type
                        )
                        register(info)
                    }
                    members[info.key] = .property(
                        from: externalInfo.key,
                        name: $0.name
                    )
                }
                externalParsedType.methods.forEach {
                    guard $0.isStatic == false, let usage = $0.returnType else {
                        return
                    }
                    let info: Info
                    if let foundInfo = find(by: usage.name) {
                        info = foundInfo
                    } else {
                        let key: Key = .name(usage.name)
                        info = Info(
                            key: key,
                            scopeKey: externalInfo.scopeKey,
                            parsedType: nil,
                            parsedUsage: usage
                        )
                        register(info)
                    }
                    members[info.key] = ExternalMember.method(
                        from: externalInfo.key,
                        parsed: $0
                    )
                }
            }
            let scopeKey = try makeScopeKey(for: parsedContainer.scopeName)
            scopes[scopeKey]?.externals = members
        }
    }
    
    private func fillResolvers() throws {
        for (_, scope) in scopes {
            var dict: [Key : Resolver] = [:]
            for key in scope.keys {
                dict[key] = .explicit
            }
            for (key, member) in scope.externals {
                dict[key] = .external(member: member)
            }
            for (providerKey, entry) in scope.providers {
                dict[entry.of] = .provider(providerKey)
            }
            for (binderKey, key) in scope.binders {
                dict[key] = .binder(binderKey)
            }
            resolvers[scope.key] = dict
        }
        for (_, scope) in scopes {
            for depKey in scope.dependencies {
                guard let scopedResolvers = resolvers[depKey] else {
                    throw Throwable.message("Unknown '\(description(of: scope.key))' dependency: '\(description(of: depKey))' not found")
                }
                for (key, resolver) in scopedResolvers {
                    resolvers[scope.key]?[key] = Resolver.derived(from: depKey, resolver: resolver)
                }
            }
        }
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
