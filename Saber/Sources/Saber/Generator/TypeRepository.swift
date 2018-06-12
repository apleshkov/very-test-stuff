//
//  TypeRepository.swift
//  Saber
//
//  Created by andrey.pleshkov on 31/05/2018.
//

import Foundation

class TypeRepository {

    private(set) var scopes: [ScopeName : Scope] = [:]
    
    private var typeInfos: [Key : Info] = [:]

    /// `.modular(module: "A", name: "Foo")` represented as "A.Foo"
    private var modularNames: [String : Key] = [:]

    /// "Foo" -> ["A", "B"] if "Foo" is declared in both "A" and "B"
    private var shortenNameCollisions: [String : [String]] = [:]

    private var resolvers: [ScopeName : [Key : Resolver]] = [:]

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
        var scopeName: ScopeName?
        var parsed: Parsed
        
        enum Parsed: Equatable {
            case type(ParsedType)
            case usage(ParsedTypeUsage)
            case alias(to: ParsedTypeUsage)
        }
    }
    
    typealias ScopeName = String
    
    struct Scope {
        var name: ScopeName
        var container: ParsedContainer
        var keys: Set<Key>
        var dependencies: Set<ScopeName>
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
        case derived(from: ScopeName, resolver: Resolver)
        case external(member: ExternalMember)
    }
}

extension TypeRepository {

    func find(by key: Key) throws -> Info {
        if case .name(let name) = key, let collisions = shortenNameCollisions[name], collisions.count > 0 {
            guard collisions.count == 1 else {
                throw Throwable.declCollision(name: name, modules: collisions)
            }
            return try find(by: .modular(module: collisions[0], name: name))
        }
        guard let info = typeInfos[key] else {
            throw Throwable.message("Unable to find '\(key.description)'")
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
        if let scopeKey = info.scopeName {
            scopes[scopeKey]?.keys.insert(key)
        }
    }
    
    func resolver(for key: Key, scopeName: ScopeName) -> Resolver? {
        return resolvers[scopeName]?[key]
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

    private func scopeName(from annotations: [TypeAnnotation], of typeName: String) throws -> ScopeName? {
        let foundNames: [String] = annotations.compactMap {
            if case .scope(let name) = $0 {
                return name
            }
            return nil
        }
        if foundNames.count > 1 {
            throw Throwable.message("'\(typeName))' associated with multiple scopes: \(foundNames.joined(separator: ", "))")
        }
        return foundNames.first
    }
}

extension TypeRepository {
    
    private func prepareScopes(parsedData: ParsedData) throws {
        for (_, parsedContainer) in parsedData.containers {
            let scopeName = parsedContainer.scopeName
            let key = scopeName
            let deps: [ScopeName] = try parsedContainer.dependencies.map {
                guard let container = parsedData.containers[$0.name] else {
                    throw Throwable.message("Unknown '\(parsedContainer.name)' dependency: '\($0.name)' not found")
                }
                return container.scopeName
            }
            let scope = Scope(
                name: scopeName,
                container: parsedContainer,
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
            let alias = $0
            switch alias.target {
            case .type(let usage):
                let key = makeKey(for: alias)
                register(
                    Info(
                        key: key,
                        scopeName: try scopeName(from: alias.annotations, of: alias.name),
                        parsed: .alias(to: usage)
                    )
                )
            case .raw(_):
                break
            }
        }
    }

    private func fillTypes(parsedData: ParsedData) throws {
        var binders: [Key : (scopeKey: ScopeName, usage: ParsedTypeUsage)] = [:]
        var providers: [Key : (scopeKey: ScopeName, method: ParsedMethod)] = [:]
        try parsedData.types.forEach {
            let parsedType = $0
            let scopeKey: ScopeName? = try scopeName(
                from: parsedType.annotations,
                of: description(of: parsedType)
            )
            let key = makeKey(for: parsedType)
            register(
                Info(
                    key: key,
                    scopeName: scopeKey,
                    parsed: .type(parsedType)
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
                        scopeName: try find(by: key).scopeName,
                        parsed: .usage(usage)
                    )
                )
            }
            scopes[entry.scopeKey]?.binders[key] = mimicKey
        }
        for (key, entry) in providers {
            let method = entry.method
            guard let usage = method.returnType else {
                throw Throwable.message("Unable to get provided type: '\(key.description).\(method.name)' returns nothing")
            }
            let providedKey: Key
            if let providedInfo = find(by: usage.name) {
                providedKey = providedInfo.key
            } else {
                providedKey = .name(usage.name)
                register(
                    Info(
                        key: providedKey,
                        scopeName: try find(by: key).scopeName,
                        parsed: .usage(usage)
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
                    throw Throwable.message("Invalid '\(parsedContainer.name)' external: unable to find '\(usage.fullName)'")
                }
                guard case .type(let externalParsedType) = externalInfo.parsed else {
                    throw Throwable.message("Invalid '\(parsedContainer.name)' external: unable to find '\(externalInfo.key.description)' parsed type")
                }
                externalParsedType.properties.forEach {
                    let info: Info
                    if let foundInfo = find(by: $0.type.name) {
                        info = foundInfo
                    } else {
                        let key: Key = .name($0.type.name)
                        info = Info(
                            key: key,
                            scopeName: externalInfo.scopeName,
                            parsed: .usage($0.type)
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
                            scopeName: externalInfo.scopeName,
                            parsed: .usage(usage)
                        )
                        register(info)
                    }
                    members[info.key] = ExternalMember.method(
                        from: externalInfo.key,
                        parsed: $0
                    )
                }
            }
            let scopeKey = parsedContainer.scopeName
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
            resolvers[scope.name] = dict
        }
        for (_, scope) in scopes {
            for depKey in scope.dependencies {
                guard let scopedResolvers = resolvers[depKey] else {
                    throw Throwable.message("Unknown '\(scope.name)' dependency: '\(depKey)' not found")
                }
                for (key, resolver) in scopedResolvers {
                    resolvers[scope.name]?[key] = Resolver.derived(from: depKey, resolver: resolver)
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

extension TypeRepository.Key: CustomStringConvertible {
    
    var description: String {
        guard let moduleName = self.moduleName else {
            return name
        }
        return "\(moduleName).\(name)"
    }
}
