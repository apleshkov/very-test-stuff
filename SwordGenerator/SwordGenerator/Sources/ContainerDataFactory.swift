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
            parentServicesOf(container).forEach { (service) in
                let type = service.typeResolver.type
                var getter = ContainerData.ReadOnlyProperty(name: memberName(of: type), typeName: type.fullName)
                getter.body = ["return \(accessor(of: type, owner: "self.\(parentName)"))"]
            }
        }
        container.externals.forEach {
            let name = memberName(of: $0.type)
            data.storedProperties.append(ContainerData.StoredProperty(name: name, type: $0.type))
            data.initializer.args.append((name: name, typeName: $0.type.fullName))
            data.initializer.storedProperties.append("self.\(name) = \(name)")
        }
        container.services.forEach { (service) in
            switch service.storage {
            case .none:
                switch service.typeResolver {
                case .explicit(let type):
                    let name = memberName(of: type)
                    var getter = ContainerData.ReadOnlyProperty(name: name, typeName: type.fullName)
                    let created = create(type: type, named: name)
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
                        let name = memberName(of: type)
                        let providerName = "\(name)Provider"
                        let created = create(type: providerType, named: providerName)
                        var getter = ContainerData.ReadOnlyProperty(name: name, typeName: type.fullName)
                        getter.body.append(created.creation)
                        getter.body.append(contentsOf: created.injections)
                        getter.body.append("return \(invoked(providerName, isOptional: providerType.isOptional, with: provideMethodName, args: []))")
                        data.readOnlyProperties.append(getter)
                    } else if let provider = provider as? StaticMethodProvider {
                        var getter = ContainerData.ReadOnlyProperty(name: memberName(of: type), typeName: type.fullName)
                        getter.body = ["return \(invoked(provider.receiverName, isOptional: false, with: provider.methodName, args: provider.args))"]
                        data.readOnlyProperties.append(getter)
                    } else {
                        assertionFailure("Unknown provider: \(provider)")
                    }
                case .bound(let mimicType, let type):
                    let name = memberName(of: mimicType)
                    let created = create(type: type, named: name)
                    var getter = ContainerData.ReadOnlyProperty(name: name, typeName: mimicType.fullName)
                    getter.body.append(created.creation)
                    getter.body.append(contentsOf: created.injections)
                    getter.body.append("return \(name)")
                    data.readOnlyProperties.append(getter)
                }
            case .cached:
                switch service.typeResolver {
                case .explicit(let type):
                    let name = memberName(of: type)
                    let cachedName = "cached\(type.name)"
                    data.storedProperties.append(
                        ContainerData.StoredProperty(
                            name: cachedName,
                            type: type.set(isOptional: true)
                        ).set(accessLevel: .private)
                    )
                    var getter = ContainerData.ReadOnlyProperty(name: name, typeName: type.fullName)
                    getter.body.append("if let \(cachedName) = self.\(cachedName) { return \(cachedName) }")
                    let created = create(type: type, named: name)
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
                        let name = memberName(of: type)
                        let cachedName = "cached\(type.name)"
                        data.storedProperties.append(ContainerData.StoredProperty(name: cachedName, type: type.set(isOptional: true)).set(accessLevel: .private))
                        let providerName = "\(name)Provider"
                        var getter = ContainerData.ReadOnlyProperty(name: name, typeName: type.fullName)
                        getter.body.append("if let \(cachedName) = self.\(cachedName) { return \(cachedName) }")
                        let created = create(type: providerType, named: providerName)
                        getter.body.append(created.creation)
                        getter.body.append(contentsOf: created.injections)
                        getter.body.append("let \(name) = \(invoked(providerName, isOptional: providerType.isOptional, with: provideMethodName, args: []))")
                        getter.body.append("self.\(cachedName) = \(name)")
                        getter.body.append("return \(name)")
                    } else if let provider = provider as? StaticMethodProvider {
                        let name = memberName(of: type)
                        let cachedName = "cached\(type.name)"
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
                    let name = memberName(of: type)
                    let cachedName = "cached\(type.name)"
                    data.storedProperties.append(ContainerData.StoredProperty(name: cachedName, type: mimicType.set(isOptional: true)).set(accessLevel: .private))
                    var getter = ContainerData.ReadOnlyProperty(name: name, typeName: mimicType.fullName)
                    getter.body.append("if let \(cachedName) = self.\(cachedName) { return \(cachedName) }")
                    let created = create(type: type, named: name)
                    getter.body.append(created.creation)
                    getter.body.append(contentsOf: created.injections)
                    getter.body.append("self.\(cachedName) = \(name)")
                    getter.body.append("return \(name)")
                }
            }
        }
        return data
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
    
    private func constructing(_ type: Type) -> String {
        guard type.constructorInjections.count > 0 else {
            return "\(type.name)()"
        }
        let args: [String] = type.constructorInjections.map {
            let valueName = accessor(of: $0.typeResolver, owner: "self")
            guard let name = $0.name else {
                return valueName
            }
            return "\(name): \(valueName)"
        }
        return "\(type.name)(\(args.joined(separator: ", ")))"
    }
    
    func create(type: Type, named name: String) -> (creation: String, injections: [String]) {
        var injections: [String] = []
        let decl: String
        if type.memberInjections.count > 0 {
            decl = (type.isReference ? "let" : "var")
            type.memberInjections.forEach {
                let lvalue = [name, type.isOptional ? "?" : "", ".\($0.name)"].joined()
                let rvalue = self.accessor(of: $0.typeResolver, owner: "self")
                injections.append("\(lvalue) = \(rvalue)")
            }
        } else {
            decl = "let"
        }
        let creation = "\(decl) \(name) = \(constructing(type))"
        return (creation, injections)
    }

    func accessor(of type: Type, owner: String) -> String {
        return "\(owner).\(memberName(of: type))"
    }

    func accessor(of typeResolver: TypeResolver, owner: String) -> String {
        return accessor(of: typeResolver.type, owner: owner)
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
