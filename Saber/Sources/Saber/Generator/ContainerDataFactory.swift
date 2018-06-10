//
//  ContainerDataFactory.swift
//  Saber
//
//  Created by Andrew Pleshkov on 06/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation

private let indent = "    "

class ContainerDataFactory {
    
    func make(from container: Container) -> ContainerData {
        var data = ContainerData(name: container.name, initializer: ContainerData.Initializer())
        data.inheritedFrom = [container.protocolName]
        container.dependencies.forEach {
            let name = memberName(of: $0)
            let typeName = $0.fullName
            data.storedProperties.append(["open unowned let \(name): \(typeName)"])
            data.initializer.storedProperties.append("self.\(name) = \(name)")
            data.initializer.args.append((name: name, typeName: typeName))
        }
        container.externals.forEach {
            let name = memberName(of: $0.type)
            let typeName = $0.type.fullName
            data.storedProperties.append(["open let \(name): \(typeName)"])
            data.initializer.args.append((name: name, typeName: typeName))
            data.initializer.storedProperties.append("self.\(name) = \(name)")
        }
        container.services.forEach { (service) in
            let isCached: Bool
            switch service.storage {
            case .cached:
                isCached = true
            case .none:
                isCached = false
            }
            expand(data: &data, typeResolver: service.typeResolver, isCached: isCached, isThreadSafe: container.isThreadSafe, accessLevel: "open")
        }
        return data
    }

    private func expand(data: inout ContainerData,
                        decl: TypeDeclaration,
                        isCached: Bool,
                        isThreadSafe: Bool,
                        accessLevel: String) {
        if isCached {
            let name = memberName(of: decl)
            let cachedName = "cached_\(name)"
            data.storedProperties.append(["private var \(cachedName): \(decl.set(isOptional: true).fullName)"])
            data.getters.append(
                getter(of: decl, accessLevel: accessLevel, cached: (memberName: cachedName, isThreadSafe: isThreadSafe))
            )
        } else {
            data.getters.append(
                getter(of: decl, accessLevel: accessLevel)
            )
        }
    }
    
    private func expand(data: inout ContainerData,
                        typeResolver: TypeResolver<TypeDeclaration>,
                        isCached: Bool,
                        isThreadSafe: Bool,
                        accessLevel: String) {
        switch typeResolver {
        case .explicit(let type):
            let injectorAccessLevel: String
            if let maker = maker(for: type) {
                expand(data: &data, decl: type, isCached: isCached, isThreadSafe: isThreadSafe, accessLevel: accessLevel)
                data.makers.append(maker)
                injectorAccessLevel = "private"
            } else {
                injectorAccessLevel = accessLevel
            }
            if let injector = injector(for: type, accessLevel: injectorAccessLevel) {
                data.injectors.append(injector)
            }
        case .provided(let type, let provider):
            switch provider {
            case .typed(let typedProvider):
                expand(data: &data, decl: type, isCached: isCached, isThreadSafe: isThreadSafe, accessLevel: accessLevel)
                if let injector = injector(for: type, accessLevel: "private") {
                    data.injectors.append(injector)
                }
                let providerDecl = typedProvider.decl
                data.makers.append([
                    "private func \(memberName(of: type, prefix: "make"))() -> \(type.fullName) {",
                    "\(indent)let provider = \(accessor(of: .explicit(providerDecl), owner: "self"))",
                    "\(indent)return \(invoked("provider", isOptional: providerDecl.isOptional, with: typedProvider.methodName, args: typedProvider.args))",
                    "}"
                    ])
                expand(data: &data, typeResolver: .explicit(providerDecl), isCached: false, isThreadSafe: false, accessLevel: "private")
            case .staticMethod(let methodProvider):
                expand(data: &data, decl: type, isCached: isCached, isThreadSafe: isThreadSafe, accessLevel: accessLevel)
                if let injector = injector(for: type, accessLevel: "private") {
                    data.injectors.append(injector)
                }
                data.makers.append([
                    "private func \(memberName(of: type, prefix: "make"))() -> \(type.fullName) {",
                    "\(indent)return \(invoked(methodProvider.receiverName, isOptional: false, with: methodProvider.methodName, args: methodProvider.args))",
                    "}"
                    ])
            }
        case .bound(let mimicType, let type):
            data.getters.append([
                "\(accessLevel) var \(memberName(of: mimicType)): \(mimicType.fullName) {",
                "\(indent)return \(accessor(of: .explicit(type), owner: "self"))",
                "}"
                ])
            expand(data: &data, typeResolver: .explicit(type), isCached: isCached, isThreadSafe: isThreadSafe, accessLevel: "private")
        case .derived(_, _):
            break
        case .external(_):
            break
        }
    }

    func memberName(of type: SomeType, prefix: String? = nil) -> String {
        var result: String
        let name = type.name.split(separator: ".").joined()
        if let prefix = prefix {
            result = prefix + name
        } else {
            let first = String(name.first!).lowercased()
            result = first + name.dropFirst()
        }
        if let usage = type as? TypeUsage, usage.generics.count > 0 {
            result += "With"
            result += usage.generics
                .map { memberName(of: $0, prefix: "") }
                .joined(separator: "And")
        }
        return result
    }
    
    func getter(of decl: TypeDeclaration, accessLevel: String, cached: (memberName: String, isThreadSafe: Bool)? = nil) -> [String] {
        var body: [String] = []
        if let cached = cached {
            if cached.isThreadSafe {
                body.append("self.lock.lock()")
                body.append("defer { self.lock.unlock() }")
            }
            body.append("if let cached = self.\(cached.memberName) { return cached }")
        }
        let maker = "self.\(memberName(of: decl, prefix: "make"))()"
        let name = memberName(of: decl)
        if decl.memberInjections.count > 0 {
            let strDecl = decl.isReference ? "let" : "var"
            body.append("\(strDecl) \(name) = \(maker)")
            let providedValue = decl.isReference ? name : "&\(name)"
            if decl.isOptional {
                body.append("if \(strDecl) \(name) = \(name) { self.injectTo(\(name): \(providedValue)) }")
            } else {
                body.append("self.injectTo(\(name): \(providedValue))")
            }
        } else {
            body.append("let \(name) = \(maker)")
        }
        if let cached = cached {
            body.append("self.\(cached.memberName) = \(name)")
        }
        body.append("return \(name)")
        return ["\(accessLevel) var \(name): \(decl.fullName) {"] + body.map { "\(indent)\($0)" } + ["}"]
    }
    
    func maker(for decl: TypeDeclaration) -> [String]? {
        switch decl.initializer {
        case .none:
            return nil
        case .some(let args):
            var lines: [String] = ["private func \(memberName(of: decl, prefix: "make"))() -> \(decl.fullName) {"]
            let invocationArgs: [String] = args.map {
                let valueName = accessor(of: $0.typeResolver, owner: "self")
                guard let name = $0.name else {
                    return valueName
                }
                return "\(name): \(valueName)"
            }
            lines.append("\(indent)return \(decl.name)(\(invocationArgs.joined(separator: ", ")))")
            lines.append("}")
            return lines
        }
    }
    
    func injector(for decl: TypeDeclaration, accessLevel: String) -> [String]? {
        let memberInjections = decl.memberInjections
        let methodInjections = decl.methodInjections
        guard memberInjections.count > 0 || methodInjections.count > 0 else {
            return nil
        }
        let varName = memberName(of: decl)
        let typeString: String
        if decl.isReference {
            typeString = decl.set(isOptional: false).fullName
        } else {
            typeString = "inout " + decl.set(isOptional: false).fullName
        }
        var lines = ["\(accessLevel) func injectTo(\(varName): \(typeString)) {"]
        memberInjections.forEach {
            let lvalue = "\(varName).\($0.name)"
            let rvalue = self.accessor(of: $0.typeResolver, owner: "self")
            lines.append("\(indent)\(lvalue) = \(rvalue)")
        }
        methodInjections.forEach {
            let invocation = invoked(varName, isOptional: false, with: $0.methodName, args: $0.args)
            lines.append("\(indent)\(invocation)")
        }
        if let handlerName = decl.didInjectHandlerName {
            let invocation = invoked(varName, isOptional: false, with: handlerName, args: [])
            lines.append("\(indent)\(invocation)")
        }
        lines.append("}")
        return lines
    }

    func accessor<T>(of typeResolver: TypeResolver<T>, owner: String) -> String where T: SomeType {
        switch typeResolver {
        case .explicit(let type):
            return "\(owner).\(memberName(of: type))"
        case .provided(let type, _):
            return "\(owner).\(memberName(of: type))"
        case .bound(let type, _):
            return "\(owner).\(memberName(of: type))"
        case .derived(let containerType, let typeResolver):
            return "\(owner).\(accessor(of: typeResolver, owner: memberName(of: containerType)))"
        case .external(let externalType, let kind):
            switch kind {
            case .property(let name):
                return "\(owner).\(memberName(of: externalType)).\(name)"
            case .method(let name, let args):
                let receiver = "\(owner).\(memberName(of: externalType))"
                return invoked(receiver, isOptional: false, with: name, args: args)
            }
        }
    }
    
    func invoked(_ receiverName: String, isOptional: Bool, with invocationName: String, args: [FunctionInvocationArgument]) -> String {
        var src = receiverName
        if isOptional {
            src += "?"
        }
        let invocationArgs: [String] = args.map {
            let valueName = self.accessor(of: $0.typeResolver, owner: "self")
            guard let name = $0.name else {
                return valueName
            }
            return "\(name): \(valueName)"
        }
        return "\(src).\(invocationName)(\(invocationArgs.joined(separator: ", ")))"
    }
}
