//
//  ContainerFactory.swift
//  Saber
//
//  Created by Andrew Pleshkov on 30/05/2018.
//

import Foundation

class ContainerFactory {
    
    private let repo: TypeRepository
    
    init(repo: TypeRepository) {
        self.repo = repo
    }
    
    func make() -> [Container] {
        return []
    }
}

extension ContainerFactory {
    
    
    
    private func makeResolver(for typeUsage: TypeUsage,
                              with repoResolver: TypeRepository.Resolver,
                              in scope: TypeRepository.Scope) throws -> TypeResolver<TypeUsage> {
        switch repoResolver {
        case .explicit:
            return .explicit(typeUsage)
        case .provider(let providerKey):
            guard let data = scope.providers[providerKey] else {
                throw Throwable.message("Unknown '\(typeUsage.fullName)' provider: '\(providerKey.description)' not found")
            }
            let method = data.method
            let providerInfo = try repo.find(by: providerKey)
            if data.method.isStatic {
                return .provided(
                    typeUsage,
                    by: .staticMethod(
                        StaticMethodProvider(
                            receiverName: providerInfo.key.description,
                            methodName: method.name,
                            args: try makeArguments(for: method, in: scope)
                        )
                    )
                )
            }
            throw Throwable.message("")
        case .binder(let binderKey):
            throw Throwable.message("")
        case .external(let member):
            throw Throwable.message("")
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
    
    private func makeArguments(for method: ParsedMethod, in scope: TypeRepository.Scope) throws -> [FunctionInvocationArgument] {
        return try method.args.map {
            guard let info = repo.find(by: $0.type.name) else {
                throw Throwable.message("Unknown type: '\($0.type.fullName)'")
            }
            guard let repoResolver = repo.resolver(for: info.key, scopeName: scope.name) else {
                throw Throwable.message("Unknown resolver for: '\($0.type.fullName)'")
            }
            let typeUsage = make(from: info)
            let typeResolver = try makeResolver(for: typeUsage, with: repoResolver, in: scope)
            return FunctionInvocationArgument(name: $0.name, typeResolver: typeResolver)
        }
    }

    private func make(from info: TypeRepository.Info) -> TypeUsage {
        switch info.parsed {
        case .type(let parsedType):
            return make(from: parsedType)
        case .usage(let parsedUsage),
             .alias(let parsedUsage):
            return make(from: parsedUsage)
        }
    }
    
    private func make(from parsedUsage: ParsedTypeUsage) -> TypeUsage {
        var usage = TypeUsage(name: parsedUsage.name)
        usage.isOptional = parsedUsage.isOptional
        usage.generics = parsedUsage.generics.map {
            return make(from: $0)
        }
        return usage
    }

    private func make(from parsedType: ParsedType) -> TypeUsage {
        var usage = TypeUsage(name: parsedType.name)
        usage.isOptional = false // TODO: parse initializers
        return usage
    }
}
