//
//  ContainerFactory.swift
//  Saber
//
//  Created by Andrew Pleshkov on 30/05/2018.
//

import Foundation

class ContainerFactory {

    private let repo: TypeRepository

    private var processingDeclarations: Set<DeclKey> = []

    private var declarationValues: [DeclKey : DeclValue] = [:]
    
    init(repo: TypeRepository) {
        self.repo = repo
    }
}

extension ContainerFactory {

    func make() throws -> [Container] {
        var result: [Container] = []
        for (_, scope) in repo.scopes {
            var container = Container(name: scope.container.name, protocolName: scope.container.protocolName)
            container.dependencies = try makeDependencies(for: scope)
            container.externals = try makeContainerExternals(for: scope)
            container.services = try makeServices(for: scope)
            container.isThreadSafe = scope.container.isThreadSafe
            container.imports = scope.container.imports
            result.append(container)
        }
        return result
    }

    private func makeContainerExternals(for scope: TypeRepository.Scope) throws -> [ContainerExternal] {
        var dict: [TypeRepository.Key : ContainerExternal] = [:]
        for (_, member) in scope.externals {
            let fromKey = member.fromKey
            var external: ContainerExternal = try {
                if let external = dict[fromKey] {
                    return external
                }
                let usage = try makeTypeUsage(from: fromKey, in: scope)
                return ContainerExternal(type: usage, kinds: [])
            }()
            switch member {
            case .method(_, let parsedMethod):
                let args = try makeArguments(for: parsedMethod, in: scope)
                external.kinds.append(.method(name: parsedMethod.name, args: args))
            case .property(_, let name):
                external.kinds.append(.property(name: name))
            }
            dict[fromKey] = external
        }
        return dict.map { $0.value }
    }

    private func makeServices(for scope: TypeRepository.Scope) throws -> [Service] {
        var result: [Service] = []
        for key in scope.keys {
            let info = try repo.find(by: key)
            let value: DeclValue
            do {
                value = try ensure(info: info, in: scope)
            } catch (error: Throwable.noParsedType(_)) {
                continue
            }
            let typeResolver = TypeResolver<TypeDeclaration>.explicit(value.declaration)
            let service = Service(
                typeResolver: typeResolver,
                storage: value.isCached ? .cached : .none
            )
            result.append(service)
        }
        for (providerKey, data) in scope.providers {
            let typeUsage = try makeTypeUsage(from: data.of, in: scope)
            let typeProvider = try makeTypeProvider(key: providerKey, in: scope)
            let typeResolver = TypeResolver<TypeDeclaration>.provided(typeUsage, by: typeProvider)
            let service = Service(
                typeResolver: typeResolver,
                storage: .none
            )
            result.append(service)
        }
        for (binderKey, mimicKey) in scope.binders {
            let typeUsage = try makeTypeUsage(from: mimicKey, in: scope)
            let binderInfo = try repo.find(by: binderKey)
            let binderValue = try ensure(info: binderInfo, in: scope)
            let typeResolver = TypeResolver<TypeDeclaration>.bound(typeUsage, to: binderValue.declaration)
            let service = Service(
                typeResolver: typeResolver,
                storage: .none
            )
            result.append(service)
        }
        return result
    }
    
    private func makeDependencies(for scope: TypeRepository.Scope) throws -> [TypeUsage] {
        return try scope.dependencies.map {
            guard let dependency = repo.scopes[$0] else {
                throw Throwable.message("Unknown scope: \($0)")
            }
            return TypeUsage(name: dependency.container.fullName)
        }
    }
}

extension ContainerFactory {

    private func makeTypeProvider(key providerKey: TypeRepository.Key, in scope: TypeRepository.Scope) throws -> TypeProvider {
        guard let data = scope.providers[providerKey] else {
            throw Throwable.message("Unknown provider: '\(providerKey.description)' not found")
        }
        let method = data.method
        let providerInfo = try repo.find(by: providerKey)
        return TypeProvider(
            decl: try ensure(info: providerInfo, in: scope).declaration,
            methodName: method.name,
            args: try makeArguments(for: method, in: scope)
        )
    }

    private func makeResolver(for typeUsage: TypeUsage,
                              with repoResolver: TypeRepository.Resolver,
                              in scope: TypeRepository.Scope) throws -> TypeResolver<TypeUsage> {
        switch repoResolver {
        case .explicit:
            return .explicit(typeUsage)
        case .provider(let providerKey):
            let provider = try makeTypeProvider(key: providerKey, in: scope)
            return .provided(typeUsage, by: provider)
        case .binder(let binderKey):
            let binderInfo = try repo.find(by: binderKey)
            return .bound(typeUsage, to: try makeTypeUsage(from: binderInfo, in: scope))
        case .external(let member):
            switch member {
            case .method(let fromKey, let parsedMethod):
                let fromUsage = try makeTypeUsage(from: fromKey, in: scope)
                let args = try makeArguments(for: parsedMethod, in: scope)
                return .external(
                    from: fromUsage,
                    kind: .method(name: parsedMethod.name, args: args)
                )
            case .property(let fromKey, let name):
                let fromUsage = try makeTypeUsage(from: fromKey, in: scope)
                return .external(
                    from: fromUsage,
                    kind: .property(name: name)
                )
            }
        case .derived(let fromName, let fromResolver):
            guard let fromScope = repo.scopes[fromName] else {
                throw Throwable.message("Unknown scope: '\(fromName)'")
            }
            let typeResolver = try makeResolver(for: typeUsage, with: fromResolver, in: fromScope)
            return .derived(
                from: TypeUsage(name: fromScope.container.fullName),
                typeResolver: typeResolver
            )
        }
    }

    private func makeResolver(for parsedUsage: ParsedTypeUsage, in scope: TypeRepository.Scope) throws -> TypeResolver<TypeUsage> {
        guard let info = repo.find(by: parsedUsage.name) else {
            throw Throwable.message("Unknown type: '\(parsedUsage.fullName)'")
        }
        guard let repoResolver = repo.resolver(for: info.key, scopeName: scope.name) else {
            throw Throwable.message("Unknown resolver for: '\(parsedUsage.fullName)'")
        }
        let typeUsage = try makeTypeUsage(from: info, in: scope)
        return try makeResolver(for: typeUsage, with: repoResolver, in: scope)
    }
}

extension ContainerFactory {
    
    private func makeArguments(for method: ParsedMethod, in scope: TypeRepository.Scope) throws -> [FunctionInvocationArgument] {
        return try method.args.map {
            let typeResolver = try makeResolver(for: $0.type, in: scope)
            return FunctionInvocationArgument(name: $0.name, typeResolver: typeResolver, isLazy: $0.isLazy)
        }
    }

    private func makeTypeUsage(from key: TypeRepository.Key, in scope: TypeRepository.Scope) throws -> TypeUsage {
        let info = try repo.find(by: key)
        return try makeTypeUsage(from: info, in: scope)
    }

    private func makeTypeUsage(from info: TypeRepository.Info, in scope: TypeRepository.Scope) throws -> TypeUsage {
        switch info.parsed {
        case .type(_):
            let decl = try ensure(info: info, in: scope)
            var usage = TypeUsage(name: decl.declaration.name)
            usage.isOptional = decl.declaration.isOptional
            return usage
        case .usage(let parsedUsage),
             .alias(let parsedUsage):
            return makeTypeUsage(from: parsedUsage)
        }
    }
    
    private func makeTypeUsage(from parsedUsage: ParsedTypeUsage) -> TypeUsage {
        var usage = TypeUsage(name: parsedUsage.name)
        usage.isOptional = parsedUsage.isOptional
        usage.generics = parsedUsage.generics.map {
            return makeTypeUsage(from: $0)
        }
        return usage
    }
}

extension ContainerFactory {

    private func ensure(info: TypeRepository.Info, in scope: TypeRepository.Scope) throws -> DeclValue {
        let key = DeclKey(scopeName: scope.name, key: info.key)
        guard processingDeclarations.contains(key) == false else {
            throw Throwable.message("Cyclic dependency found: '\(info.key.description)' is still processing")
        }
        if let value = declarationValues[key] {
            return value
        }
        guard case .type(let parsedType) = info.parsed else {
            throw Throwable.noParsedType(for: info)
        }
        processingDeclarations.insert(key)
        defer {
            processingDeclarations.remove(key)
        }
        let isInjectOnly = parsedType.annotations.contains(.injectOnly)
        var decl = TypeDeclaration(name: info.key.description)
        decl.isReference = parsedType.isReference
        for property in parsedType.properties {
            guard property.annotations.contains(.inject) else {
                continue
            }
            let injection = MemberInjection(
                name: property.name,
                typeResolver: try makeResolver(for: property.type, in: scope),
                isLazy: property.isLazy
            )
            decl.memberInjections.append(injection)
        }
        var didInjectHandlerName: String? = nil
        var parsedInitializers: [ParsedMethod] = []
        for method in parsedType.methods {
            if method.isInitializer {
                if !isInjectOnly {
                    parsedInitializers.append(method)
                }
                continue
            }
            if didInjectHandlerName == nil && method.annotations.contains(.didInject) {
                didInjectHandlerName = method.name
                continue
            }
            if method.annotations.contains(.inject) {
                let injection = InstanceMethodInjection(methodName: method.name, args: try makeArguments(for: method, in: scope))
                decl.methodInjections.append(injection)
            }
        }
        decl.initializer = try {
            if isInjectOnly {
                return .none
            }
            guard let initializer = try findInitializer(from: parsedInitializers, for: parsedType) else {
                return .some(args: [])
            }
            decl.isOptional = initializer.isFailableInitializer
            return .some(args: try makeArguments(for: initializer, in: scope))
        }()
        let isCached = parsedType.annotations.contains(.cached)
        let value: DeclValue = (decl, isCached)
        declarationValues[key] = value
        return value
    }

    private func findInitializer(from methods: [ParsedMethod], for parsedType: ParsedType) throws -> ParsedMethod? {
        guard methods.count > 0 else {
            return nil
        }
        if methods.count == 1 {
            return methods[0]
        }
        let injected = methods.filter { $0.annotations.contains(.inject) }
        if injected.count > 1 {
            throw Throwable.message("Unable to find initializer for '\(parsedType.fullName)': multiple injected-initializers found")
        }
        guard let initializer = injected.first else {
            throw Throwable.message("Unable to find initializer for '\(parsedType.fullName)': \(methods.count) initializers found, but none of them marked as injected")
        }
        return initializer
    }
}


private struct DeclKey: Hashable {

    var scopeName: TypeRepository.ScopeName

    var key: TypeRepository.Key
}

private typealias DeclValue = (declaration: TypeDeclaration, isCached: Bool)
