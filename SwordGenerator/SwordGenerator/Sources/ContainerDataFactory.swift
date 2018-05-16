//
//  ContainerDataFactory.swift
//  SwordGenerator
//
//  Created by Andrew Pleshkov on 06/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation

class ContainerDataFactory {
    
    func make(from container: Container) -> ContainerData {
        var externals = Set<TypeKey>()
        var inherited = Set<TypeKey>()
        var data = ContainerData(name: "\(container.name)Container", initializer: ContainerData.Initializer())
        if let parent = container.parent {
            let parentName = "parentContainer"
            let parentType = Type(name: "\(parent.name)Container")
            data.storedProperties.append(
                {
                    var property = ContainerData.StoredProperty(name: parentName, type: parentType)
                    property.referenceType = .unowned
                    return property
                }()
            )
            data.initializer.storedProperties.append("self.\(parentName) = \(parentName)")
            data.initializer.args.append((name: parentName, typeName: parentType.fullName))
            inherited = Set(parentServicesOf(container).map { TypeKey($0.typeResolver.type) })
        }
        container.externals.forEach {
            let key = TypeKey($0.type)
            if externals.contains(key) {
                assertionFailure()
            }
            externals.insert(key)
            let name = varName(of: $0.type, prefix: "external")
            data.storedProperties.append(ContainerData.StoredProperty(name: name, type: $0.type))
            data.initializer.args.append((name: name, typeName: $0.type.fullName))
            data.initializer.storedProperties.append("self.\(name) = \(name)")
        }
        container.services.forEach { (service) in
            switch service.storage {
            case .none:
                switch service.typeResolver {
                case .explicit(let type):
                    let name = varName(of: type)
                    var getter = ContainerData.ReadOnlyProperty(name: name, typeName: type.fullName)
                    let created = create(type: type, named: name, externals: externals, inherited: inherited)
                    getter.body.append(created.creation)
                    getter.body.append(contentsOf: created.injections)
                    getter.body.append("return \(name)")
                    data.readOnlyProperties.append(getter)
                case .provided(var type, let provider):
                    if let provider = provider as? TypedProvider {
                        let providerType = provider.type
                        if providerType.isOptional {
                            type.isOptional = true
                        }
                        let name = varName(of: type)
                        let providerName = "\(name)Provider"
                        let created = create(type: providerType, named: providerName, externals: externals, inherited: inherited)
                        var getter = ContainerData.ReadOnlyProperty(name: name, typeName: type.fullName)
                        getter.body.append(created.creation)
                        getter.body.append(contentsOf: created.injections)
                        getter.body.append("return \(invoked(providerName, isOptional: providerType.isOptional, with: provideMethodName, args: []))")
                        data.readOnlyProperties.append(getter)
                    } else if let provider = provider as? StaticMethodProvider {
                        var getter = ContainerData.ReadOnlyProperty(name: varName(of: type), typeName: type.fullName)
                        getter.body = ["return \(invoked(provider.receiverName, isOptional: false, with: provider.methodName, args: provider.args))"]
                        data.readOnlyProperties.append(getter)
                    } else {
                        assertionFailure("Unknown provider: \(provider)")
                    }
                case .bound(let mimicType, let type):
                    let name = varName(of: mimicType)
                    let created = create(type: type, named: name, externals: externals, inherited: inherited)
                    var getter = ContainerData.ReadOnlyProperty(name: name, typeName: mimicType.fullName)
                    getter.body.append(created.creation)
                    getter.body.append(contentsOf: created.injections)
                    getter.body.append("return \(name)")
                    data.readOnlyProperties.append(getter)
                }
            case .cached:
                switch service.typeResolver {
                case .explicit(let type):
                    let name = varName(of: type)
                    let cachedName = varName(of: type, prefix: "cached")
                    data.storedProperties.append(ContainerData.StoredProperty(name: cachedName, type: type.optional()).set(accessLevel: .private))
                    var getter = ContainerData.ReadOnlyProperty(name: name, typeName: type.fullName)
                    getter.body.append("if let \(cachedName) = self.\(cachedName) { return \(cachedName) }")
                    let created = create(type: type, named: name, externals: externals, inherited: inherited)
                    getter.body.append(created.creation)
                    getter.body.append(contentsOf: created.injections)
                    getter.body.append("self.\(cachedName) = \(name)")
                    getter.body.append("return \(name)")
                case .provided(var type, let provider):
                    if let provider = provider as? TypedProvider {
                        let providerType = provider.type
                        if providerType.isOptional {
                            type.isOptional = true
                        }
                        let name = varName(of: type)
                        let cachedName = varName(of: type, prefix: "cached")
                        data.storedProperties.append(ContainerData.StoredProperty(name: cachedName, type: type.optional()).set(accessLevel: .private))
                        let providerName = "\(name)Provider"
                        var getter = ContainerData.ReadOnlyProperty(name: name, typeName: type.fullName)
                        getter.body.append("if let \(cachedName) = self.\(cachedName) { return \(cachedName) }")
                        let created = create(type: providerType, named: providerName, externals: externals, inherited: inherited)
                        getter.body.append(created.creation)
                        getter.body.append(contentsOf: created.injections)
                        getter.body.append("let \(name) = \(invoked(providerName, isOptional: providerType.isOptional, with: provideMethodName, args: []))")
                        getter.body.append("self.\(cachedName) = \(name)")
                        getter.body.append("return \(name)")
                    } else if let provider = provider as? StaticMethodProvider {
                        let name = varName(of: type)
                        let cachedName = varName(of: type, prefix: "cached")
                        data.storedProperties.append(ContainerData.StoredProperty(name: cachedName, type: type))
                        var getter = ContainerData.ReadOnlyProperty(name: name, typeName: type.fullName)
                        getter.body.append("if let \(cachedName) = self.\(cachedName) { return \(cachedName) }")
                        let creation = invoked(provider.receiverName, isOptional: false, with: provider.methodName, args: provider.args)
                        getter.body.append("let \(name) = \(creation)")
                        getter.body.append("self.\(cachedName) = \(name)")
                        getter.body.append("return \(name)")
                    } else {
                        assertionFailure("Unknown provider: \(provider)")
                    }
                case .bound(let mimicType, let type):
                    let name = varName(of: type)
                    let cachedName = varName(of: type, prefix: "cached")
                    data.storedProperties.append(ContainerData.StoredProperty(name: cachedName, type: mimicType.optional()).set(accessLevel: .private))
                    var getter = ContainerData.ReadOnlyProperty(name: name, typeName: mimicType.fullName)
                    getter.body.append("if let \(cachedName) = self.\(cachedName) { return \(cachedName) }")
                    let created = create(type: type, named: name, externals: externals, inherited: inherited)
                    getter.body.append(created.creation)
                    getter.body.append(contentsOf: created.injections)
                    getter.body.append("self.\(cachedName) = \(name)")
                    getter.body.append("return \(name)")
                }
            }
        }
        return data
    }

    private func varName(of type: Type, prefix: String? = nil) -> String {
        let name = type.name
        guard let prefix = prefix else {
            let first = String(name.first!).lowercased()
            return first + name.dropFirst()
        }
        return "\(prefix)\(name)"
    }

    private func parentServicesOf(_ container: Container) -> [Service] {
        guard let parent = container.parent as? Container else {
            return []
        }
        return parent.services + parentServicesOf(parent)
    }
    
    private func constructing(_ type: Type,
                              externals: Set<TypeKey>,
                              inherited: Set<TypeKey>) -> String {
        guard let injection = type.injectionSuite.constructor, injection.args.count > 0 else {
            return "\(type.name)()"
        }
        let args: [String] = injection.args.map {
            let valueName = value(of: $0.type, externals: externals, inherited: inherited)
            guard let name = $0.name else {
                return valueName
            }
            return "\(name): \(valueName)"
        }
        return "\(type.name)(\(args.joined(separator: ", ")))"
    }
    
    private func create(type: Type,
                        named name: String,
                        externals: Set<TypeKey>,
                        inherited: Set<TypeKey>) -> (creation: String, injections: [String]) {
        var injections: [String] = []
        let decl: String
        let properties = type.injectionSuite.properties
        if properties.count > 0 {
            decl = (type.isReference ? "let" : "var")
            properties.forEach {
                let lvalue = [name, type.isOptional ? "?" : "", ".\($0.name)"].joined()
                let rvalue = value(of: $0.type, externals: externals, inherited: inherited)
                injections.append("\(lvalue) = \(rvalue)")
            }
        } else {
            decl = "let"
        }
        let creation = "\(decl) \(name) = \(constructing(type, externals: externals, inherited: inherited))"
        return (creation, injections)
    }

    private func value(of type: Type,
                       externals: Set<TypeKey>,
                       inherited: Set<TypeKey>) -> String {
        let typeKey = TypeKey(type)
        if externals.contains(typeKey) {
            return "self.\(varName(of: type, prefix: "external"))"
        }
        if inherited.contains(typeKey) {
            return "self.\(varName(of: type, prefix: "parent"))"
        }
        return "self.\(varName(of: type))"
    }
    
    private func invoked(_ receiverName: String, isOptional: Bool, with invocationName: String, args: [FunctionInvocationArgument]) -> String {
        var src = receiverName
        if isOptional {
            src += "?"
        }
        let invocationArgs: [String] = args.map {
            guard let name = $0.name else {
                return $0.valueName
            }
            return "\(name): \($0.valueName)"
        }
        return "\(src).\(invocationName)(\(invocationArgs.joined(separator: ", ")))"
    }
}

private let provideMethodName = "provide"

private struct TypeKey: Hashable {

    private let key: String

    init(_ type: Type) {
        key = type.fullName
    }

    static func ==(lhs: TypeKey, rhs: TypeKey) -> Bool {
        return lhs.key == rhs.key
    }

    var hashValue: Int {
        return key.hashValue
    }
}
