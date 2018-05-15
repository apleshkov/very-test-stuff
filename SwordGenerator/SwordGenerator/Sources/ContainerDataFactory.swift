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
            let parentTypeName = "\(parent.name)Container"
            data.storedProperties.append(
                {
                    var property = ContainerData.StoredProperty(name: parentName, typeName: parentTypeName)
                    property.referenceType = .unowned
                    return property
                }()
            )
            data.initializer.storedProperties.append("self.\(parentName) = \(parentName)")
            data.initializer.args.append((name: parentName, typeName: parentTypeName))
            parentDependenciesOf(container).forEach { (dep) in
                var getter: ContainerData.ReadOnlyProperty
                switch dep.typeResolver {
                case .explicit(let type),
                     .bound(let type, _):
                    getter = ContainerData.ReadOnlyProperty(name: dep.name, typeName: type.fullName)
                case .provided(var type, let provider):
                    if (provider as? TypedProvider)?.type.isOptional == true {
                        type.isOptional = true
                    }
                    getter = ContainerData.ReadOnlyProperty(name: dep.name, typeName: type.fullName)
                }
                getter.body = ["return self.\(parentName).\(dep.name)"]
                data.readOnlyProperties.append(getter)
            }
        }
        container.args.forEach {
            if $0.isStoredProperty {
                data.storedProperties.append(ContainerData.StoredProperty(name: $0.name, typeName: $0.typeName))
                data.initializer.storedProperties.append("self.\($0.name) = \($0.name)")
            }
            data.initializer.args.append((name: $0.name, typeName: $0.typeName))
        }
        container.dependencies.forEach { (dep) in
            switch dep.storage {
            case .prototype:
                switch dep.typeResolver {
                case .explicit(let type):
                    let created = create(type: type, named: dep.name)
                    var getter = ContainerData.ReadOnlyProperty(name: dep.name, typeName: type.fullName)
                    getter.body.append(created.creation)
                    getter.body.append(contentsOf: created.injections)
                    getter.body.append("return \(dep.name)")
                    data.readOnlyProperties.append(getter)
                case .provided(var type, let provider):
                    if let provider = provider as? TypedProvider {
                        let providerType = provider.type
                        if providerType.isOptional {
                            type.isOptional = true
                        }
                        let providerName = "\(dep.name)Provider"
                        let created = create(type: providerType, named: providerName)
                        var getter = ContainerData.ReadOnlyProperty(name: dep.name, typeName: type.fullName)
                        getter.body.append(created.creation)
                        getter.body.append(contentsOf: created.injections)
                        getter.body.append("return \(invoked(providerName, isOptional: providerType.isOptional, with: provideMethodName, args: []))")
                        data.readOnlyProperties.append(getter)
                    } else if let provider = provider as? StaticMethodProvider {
                        var getter = ContainerData.ReadOnlyProperty(name: dep.name, typeName: type.fullName)
                        getter.body = ["return \(invoked(provider.receiverName, isOptional: false, with: provider.methodName, args: provider.args))"]
                        data.readOnlyProperties.append(getter)
                    } else {
                        assertionFailure("Unknown provider: \(provider)")
                    }
                case .bound(let mimicType, let type):
                    let created = create(type: type, named: dep.name)
                    var getter = ContainerData.ReadOnlyProperty(name: dep.name, typeName: mimicType.fullName)
                    getter.body.append(created.creation)
                    getter.body.append(contentsOf: created.injections)
                    getter.body.append("return \(dep.name)")
                    data.readOnlyProperties.append(getter)
                }
            case .cached:
                switch dep.typeResolver {
                case .explicit(let type):
                    data.storedProperties.append(ContainerData.StoredProperty(name: dep.name, typeName: type.fullName))
                    let created = create(type: type, named: dep.name)
                    data.initializer.creations.append(created.creation)
                    data.initializer.propertyInjections.append(contentsOf: created.injections)
                    data.initializer.storedProperties.append("self.\(dep.name) = \(dep.name)")
                case .provided(var type, let provider):
                    if let provider = provider as? TypedProvider {
                        let providerType = provider.type
                        if providerType.isOptional {
                            type.isOptional = true
                        }
                        let providerName = "\(dep.name)Provider"
                        data.storedProperties.append(ContainerData.StoredProperty(name: dep.name, typeName: type.fullName))
                        let created = create(type: providerType, named: providerName)
                        data.initializer.creations.append(created.creation)
                        data.initializer.propertyInjections.append(contentsOf: created.injections)
                        data.initializer.storedProperties.append("self.\(dep.name) = \(invoked(providerName, isOptional: providerType.isOptional, with: provideMethodName, args: []))")
                    } else if let provider = provider as? StaticMethodProvider {
                        data.storedProperties.append(ContainerData.StoredProperty(name: dep.name, typeName: type.fullName))
                        let creation = invoked(provider.receiverName, isOptional: false, with: provider.methodName, args: provider.args)
                        data.initializer.creations.append("let \(dep.name) = \(creation)")
                        data.initializer.storedProperties.append("self.\(dep.name) = \(dep.name)")
                    } else {
                        assertionFailure("Unknown provider: \(provider)")
                    }
                case .bound(let mimicType, let type):
                    data.storedProperties.append(ContainerData.StoredProperty(name: dep.name, typeName: mimicType.fullName))
                    let created = create(type: type, named: dep.name)
                    data.initializer.creations.append(created.creation)
                    data.initializer.propertyInjections.append(contentsOf: created.injections)
                    data.initializer.storedProperties.append("self.\(dep.name) = \(dep.name)")
                }
            }
        }
        return data
    }
    
    private func parentDependenciesOf(_ container: Container) -> [Dependency] {
        guard let parent = container.parent as? Container else {
            return []
        }
        let names = Set(container.dependencies.map { $0.name })
        let parentDependencies = parent.dependencies + parentDependenciesOf(parent)
        let filtered = parentDependencies.filter { names.contains($0.name) == false }
        return filtered
    }
    
    private func constructing(_ type: Type) -> String {
        guard let injection = type.injectionSuite.constructor, injection.args.count > 0 else {
            return "\(type.name)()"
        }
        let args: [String] = injection.args.map {
            guard let name = $0.name else {
                return $0.valueName
            }
            return "\(name): \($0.valueName)"
        }
        return "\(type.name)(\(args.joined(separator: ", ")))"
    }
    
    private func create(type: Type, named name: String) -> (creation: String, injections: [String]) {
        var injections: [String] = []
        let decl: String
        let properties = type.injectionSuite.properties
        if properties.count > 0 {
            decl = (type.isReference ? "let" : "var")
            properties.forEach {
                let lvalue = [
                    name,
                    type.isOptional ? "?" : "",
                    ".\($0.name)"
                ].joined()
                let rvalue = $0.dependencyName
                injections.append("\(lvalue) = \(rvalue)")
            }
        } else {
            decl = "let"
        }
        let creation = "\(decl) \(name) = \(constructing(type))"
        return (creation, injections)
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
