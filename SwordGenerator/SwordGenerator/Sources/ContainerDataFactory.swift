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
            expand(data: &data, typeResolver: service.typeResolver, isCached: isCached, isThreadSafe: container.isThreadSafe)
        }
        return data
    }

    private func expand(data: inout ContainerData, typeResolver: TypeResolver, isCached: Bool, isThreadSafe: Bool) {
        switch typeResolver {
        case .explicit(let type):
            if isCached {
                let name = memberName(of: type)
                let cachedName = "cached_\(name)"
                data.storedProperties.append(["private var \(cachedName): \(type.set(isOptional: true).fullName)"])
                data.getters.append(
                    getter(of: type, named: name, cached: (memberName: cachedName, isThreadSafe: isThreadSafe))
                )
            } else {
                data.getters.append(
                    getter(of: type, named: memberName(of: type))
                )
            }
            data.makers.append(
                maker(for: type)
            )
            if let injector = injector(for: type) {
                data.injectors.append(injector)
            }
        case .provided(let type, let provider):
            switch provider {
            case .typed(let typedProvider):
                expand(data: &data, typeResolver: .explicit(type), isCached: isCached, isThreadSafe: isThreadSafe)
                let providerType = typedProvider.type
                data.makers.append([
                    "private func make() -> \(type.fullName) {",
                    "\(indent)let provider = \(accessor(of: providerType, owner: "self"))",
                    "\(indent)return \(invoked("provider", isOptional: providerType.isOptional, with: typedProvider.methodName, args: typedProvider.args))",
                    "}"
                    ])
                expand(data: &data, typeResolver: .explicit(providerType), isCached: false, isThreadSafe: false)
            case .staticMethod(let methodProvider):
                expand(data: &data, typeResolver: .explicit(type), isCached: isCached, isThreadSafe: isThreadSafe)
                data.makers.append([
                    "private func make() -> \(type.fullName) {",
                    "\(indent)return \(invoked(methodProvider.receiverName, isOptional: false, with: methodProvider.methodName, args: methodProvider.args))",
                    "}"
                    ])
            }
        case .bound(let mimicType, let type):
            data.getters.append([
                "open var \(memberName(of: mimicType)): \(mimicType.fullName) {",
                "\(indent)return \(accessor(of: type, owner: "self"))",
                "}"
                ])
            expand(data: &data, typeResolver: .explicit(type), isCached: isCached, isThreadSafe: isThreadSafe)
        }
    }

    private func memberName(of type: Type) -> String {
        let name = type.name
        let first = String(name.first!).lowercased()
        return first + name.dropFirst()
    }

    private func parentServicesOf(_ container: Container) -> [Service] {
        guard let parent = container.parent as? Container else {
            return []
        }
        return parent.services + parentServicesOf(parent)
    }
    
    func getter(of type: Type, named name: String, cached: (memberName: String, isThreadSafe: Bool)? = nil) -> [String] {
        var body: [String] = []
        if let cached = cached {
            if cached.isThreadSafe {
                body.append("self.lock.lock()")
                body.append("defer { self.lock.unlock() }")
            }
            body.append("if let cached = self.\(cached.memberName) { return cached }")
        }
        if type.memberInjections.count > 0 {
            let decl = type.isReference ? "let" : "var"
            body.append("\(decl) \(name): \(type.fullName) = self.make()")
            let provided = type.isReference ? name : "&\(name)"
            if type.isOptional {
                body.append("if \(decl) \(name) = \(name) { self.inject(to: \(provided)) }")
            } else {
                body.append("self.inject(to: \(provided))")
            }
        } else {
            body.append("let \(name): \(type.fullName) = self.make()")
        }
        if let cached = cached {
            body.append("self.\(cached.memberName) = \(name)")
        }
        body.append("return \(name)")
        return ["open var \(name): \(type.fullName) {"] + body.map { "\(indent)\($0)" } + ["}"]
    }
    
    func maker(for type: Type) -> [String] {
        var lines: [String] = ["private func make() -> \(type.fullName) {"]
        let args: [String] = type.constructorInjections.map {
            let valueName = accessor(of: $0.typeResolver, owner: "self")
            guard let name = $0.name else {
                return valueName
            }
            return "\(name): \(valueName)"
        }
        lines.append("\(indent)return \(type.initializerName)(\(args.joined(separator: ", ")))")
        lines.append("}")
        return lines
    }
    
    func injector(for type: Type) -> [String]? {
        let injections = type.memberInjections
        guard injections.count > 0 else {
            return nil
        }
        let varName = "injectee"
        let typeString: String
        if type.isReference {
            typeString = type.set(isOptional: false).fullName
        } else {
            typeString = "inout " + type.set(isOptional: false).fullName
        }
        var lines = ["open func inject(to \(varName): \(typeString)) {"]
        injections.forEach {
            let lvalue = "\(varName).\($0.name)"
            let rvalue = self.accessor(of: $0.typeResolver, owner: "self")
            lines.append("\(indent)\(lvalue) = \(rvalue)")
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
