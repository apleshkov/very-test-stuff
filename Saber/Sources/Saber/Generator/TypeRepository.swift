//
//  TypeRepository.swift
//  Saber
//
//  Created by andrey.pleshkov on 31/05/2018.
//

import Foundation

class TypeRepository {

    private var typeInfos: [Key : Info] = [:]

    private var typedAliases: [Key : ParsedTypeUsage] = [:]

    private var rawAliasNames = Set<String>()

    init(parsedData: ParsedData) throws {
        fillAliases(parsedData: parsedData)

        var knownScopes = Set<String>()
        parsedData.containers.forEach {
            knownScopes.insert($0.value.scopeName)
        }
        try fillTypes(parsedData: parsedData, knownScopes: knownScopes)

    }
}

extension TypeRepository {

    enum Key: Hashable {
        case name(String)
        case modular(module: String, name: String)
    }

    struct Info: Equatable {
        var scope: String
        var type: Type
        var typeResolver: TypeResolver
    }
}

extension TypeRepository {

    func find(by key: Key) -> Info? {
        guard let info = typeInfos[key] else {
            guard let usage = typedAliases[key] else {
                return nil
            }
            return find(by: usage.name)
        }
        return info
    }

    func find(by name: String) -> Info? {
        if let info = typeInfos[.name(name)] {
            return info
        }
        let chunks = name.split(separator: ".")
        guard chunks.count > 1 else {
            return nil
        }
        let key = Key.modular(
            module: String(chunks[0]),
            name: chunks.dropFirst().joined(separator: ".")
        )
        return find(by: key)
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
        guard let moduleName = type.moduleName else {
            return .name(type.name)
        }
        return .modular(module: moduleName, name: type.name)
    }

    private func makeKey(for alias: ParsedTypealias) -> Key {
        guard let moduleName = alias.moduleName else {
            return .name(alias.name)
        }
        return .modular(module: moduleName, name: alias.name)
    }

    private func typeResolver(of usage: ParsedTypeUsage) throws -> TypeResolver {
        guard let resolver = find(by: usage.name)?.typeResolver else {
            throw Throwable.message("Type resolver not found for \(description(of: usage))")
        }
        return resolver
    }
}

extension TypeRepository {

    private func fillTypes(parsedData: ParsedData, knownScopes: Set<String>) throws {
        try parsedData.types.forEach {
            let parsedType = $0.value
            let name = parsedType.name
            let foundScopes = parsedType.inheritedFrom
                .filter { knownScopes.contains($0.name) }
                .map { $0.name }
            guard foundScopes.count == 1 else {
                if foundScopes.count > 0 {
                    throw Throwable.message("'\(description(of: parsedType))' associated with multiple scopes: \(foundScopes.joined(separator: ", "))")
                }
                throw Throwable.message("'\(description(of: parsedType))' associated with no scope")
            }
            let key = makeKey(for: parsedType)
            let scope = foundScopes[0]
            var type = Type(name: name)
            type.isReference = parsedType.isReference
            typeInfos[key] = Info(
                scope: scope,
                type: type,
                typeResolver: .explicit(type)
            )
        }
    }

    private func fillInitializers(parsedData: ParsedData) throws {
        try parsedData.types.forEach {
            let parsedType = $0.value
            let key = makeKey(for: parsedType)
            let initializer: Type.Initializer
            if parsedType.annotations.contains(.injectOnly) {
                initializer = .none
            } else {
                let parsedInitializers = parsedType.methods.filter {
                    $0.name == "init"
                }
                if parsedInitializers.count == 0 {
                    initializer = .some(args: [])
                } else if parsedInitializers.count == 1 {
                    let args: [ConstructorInjection] = try parsedInitializers[0].args.map {
                        let resolver = try typeResolver(of: $0.type)
                        return ConstructorInjection(name: $0.name, typeResolver: resolver)
                    }
                    initializer = .some(args: args)
                } else {
                    let injected = parsedInitializers.filter {
                        $0.annotations.contains(.inject)
                    }
                    guard injected.count == 1 else {
                        if injected.count == 0 {
                            throw Throwable.message("\(description(of: parsedType)) has multiple initializers")
                        }
                        throw Throwable.message("\(description(of: parsedType)) has multiple injectable initializers")
                    }
                    let args: [ConstructorInjection] = try injected[0].args.map {
                        let resolver = try typeResolver(of: $0.type)
                        return ConstructorInjection(name: $0.name, typeResolver: resolver)
                    }
                    initializer = .some(args: args)
                }
            }
            typeInfos[key]?.type.initializer = initializer
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
