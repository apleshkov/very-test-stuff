//
//  ContainerDataFactory.swift
//  SwordGenerator
//
//  Created by Andrew Pleshkov on 06/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation

let indent = "    "

class ContainerDataFactory {
    
    func make(from container: Container) -> ContainerData {
        var data = ContainerData(name: "\(container.name)Container", initializer: ContainerData.Initializer())
        if let parent = container.parent {
            let parentName = "parentContainer"
            let parentType = Type(name: "\(parent.name)Container")
            data.storedProperties.append(["open unowned let \(parentName): \(parentType.fullName)"])
            data.initializer.storedProperties.append("self.\(parentName) = \(parentName)")
            data.initializer.args.append((name: parentName, typeName: parentType.fullName))
            parentServicesOf(container).forEach { (service) in
                let type = service.typeResolver.type
                let name = memberName(of: type)
                data.getters.append([
                    "private var \(name): \(type.fullName) {",
                    "\(indent)return self.\(parentName).\(name)",
                    "}"
                    ])
            }
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

    private func expand(data: inout ContainerData, type: Type, isCached: Bool, isThreadSafe: Bool, accessLevel: String) {
        if isCached {
            let name = memberName(of: type)
            let cachedName = "cached_\(name)"
            data.storedProperties.append(["private var \(cachedName): \(type.set(isOptional: true).fullName)"])
            data.getters.append(
                getter(of: type, accessLevel: accessLevel, cached: (memberName: cachedName, isThreadSafe: isThreadSafe))
            )
        } else {
            data.getters.append(
                getter(of: type, accessLevel: accessLevel)
            )
        }
    }
    
    private func expand(data: inout ContainerData, typeResolver: TypeResolver, isCached: Bool, isThreadSafe: Bool, accessLevel: String) {
        switch typeResolver {
        case .explicit(let type):
            let injectorAccessLevel: String
            if let maker = maker(for: type) {
                expand(data: &data, type: type, isCached: isCached, isThreadSafe: isThreadSafe, accessLevel: accessLevel)
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
                expand(data: &data, type: type, isCached: isCached, isThreadSafe: isThreadSafe, accessLevel: accessLevel)
                if let injector = injector(for: type, accessLevel: "private") {
                    data.injectors.append(injector)
                }
                let providerType = typedProvider.type
                data.makers.append([
                    "private func \(memberName(of: type, prefix: "make"))() -> \(type.fullName) {",
                    "\(indent)let provider = \(accessor(of: providerType, owner: "self"))",
                    "\(indent)return \(invoked("provider", isOptional: providerType.isOptional, with: typedProvider.methodName, args: typedProvider.args))",
                    "}"
                    ])
                expand(data: &data, typeResolver: .explicit(providerType), isCached: false, isThreadSafe: false, accessLevel: "private")
            case .staticMethod(let methodProvider):
                expand(data: &data, type: type, isCached: isCached, isThreadSafe: isThreadSafe, accessLevel: accessLevel)
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
                "\(indent)return \(accessor(of: type, owner: "self"))",
                "}"
                ])
            expand(data: &data, typeResolver: .explicit(type), isCached: isCached, isThreadSafe: isThreadSafe, accessLevel: "private")
        }
    }

    func memberName(of type: Type, prefix: String? = nil) -> String {
        var result: String
        let name = type.name.split(separator: ".").joined()
        if let prefix = prefix {
            result = prefix + name
        } else {
            let first = String(name.first!).lowercased()
            result = first + name.dropFirst()
        }
        if type.generics.count > 0 {
            result += "With"
            result += type.generics.map {
                return memberName(of: $0, prefix: "")
            }.joined(separator: "And")
        }
        return result
    }

    private func parentServicesOf(_ container: Container) -> [Service] {
        guard let parent = container.parent as? Container else {
            return []
        }
        return parent.services + parentServicesOf(parent)
    }
    
    func getter(of type: Type, accessLevel: String, cached: (memberName: String, isThreadSafe: Bool)? = nil) -> [String] {
        var body: [String] = []
        if let cached = cached {
            if cached.isThreadSafe {
                body.append("self.lock.lock()")
                body.append("defer { self.lock.unlock() }")
            }
            body.append("if let cached = self.\(cached.memberName) { return cached }")
        }
        let maker = "self.\(memberName(of: type, prefix: "make"))()"
        let name = memberName(of: type)
        if type.memberInjections.count > 0 {
            let decl = type.isReference ? "let" : "var"
            body.append("\(decl) \(name) = \(maker)")
            let providedValue = type.isReference ? name : "&\(name)"
            if type.isOptional {
                body.append("if \(decl) \(name) = \(name) { self.injectTo(\(name): \(providedValue)) }")
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
        return ["\(accessLevel) var \(name): \(type.fullName) {"] + body.map { "\(indent)\($0)" } + ["}"]
    }
    
    func maker(for type: Type) -> [String]? {
        switch type.initializer {
        case .none:
            return nil
        case .some(let args):
            var lines: [String] = ["private func \(memberName(of: type, prefix: "make"))() -> \(type.fullName) {"]
            let invocationArgs: [String] = args.map {
                let valueName = accessor(of: $0.typeResolver, owner: "self")
                guard let name = $0.name else {
                    return valueName
                }
                return "\(name): \(valueName)"
            }
            lines.append("\(indent)return \(type.name)(\(invocationArgs.joined(separator: ", ")))")
            lines.append("}")
            return lines
        }
    }
    
    func injector(for type: Type, accessLevel: String) -> [String]? {
        let memberInjections = type.memberInjections
        let methodInjections = type.methodInjections
        guard memberInjections.count > 0 || methodInjections.count > 0 else {
            return nil
        }
        let varName = memberName(of: type)
        let typeString: String
        if type.isReference {
            typeString = type.set(isOptional: false).fullName
        } else {
            typeString = "inout " + type.set(isOptional: false).fullName
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
        lines.append("}")
        return lines
    }

    func accessor(of type: Type, owner: String) -> String {
        return "\(owner).\(memberName(of: type))"
    }

    func accessor(of typeResolver: TypeResolver, owner: String) -> String {
        return accessor(of: typeResolver.type, owner: owner)
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
