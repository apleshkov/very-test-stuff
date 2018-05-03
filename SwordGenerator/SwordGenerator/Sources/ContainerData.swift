//
//  ContainerData.swift
//  SwordGenerator
//
//  Created by Andrew Pleshkov on 01/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation

struct ContainerData {
    
    var name: String
    
    var properties: [Property] = []
    
    var initializer: Initializer
    
    var getters: [Getter] = []
    
    init(name: String, initializer: Initializer) {
        self.name = name
        self.initializer = initializer
    }
    
    enum AccessLevel {
        case `private`
        case `fileprivate`
        case `open`
        case `internal`
        
        var source: String {
            switch self {
            case .private: return "private"
            case .fileprivate: return "fileprivate"
            case .open: return "open"
            case .internal: return "internal"
            }
        }
    }
    
    enum ReferenceType {
        case `strong`
        case `weak`
        case `unowned`
        
        var source: String {
            switch self {
            case .strong: return "strong"
            case .weak: return "weak"
            case .unowned: return "unowned"
            }
        }
    }
}

extension ContainerData {
    
    struct Property {
        
        var name: String
        var typeName: String
        var accessLevel: AccessLevel = .open
        var referenceType: ReferenceType? = nil
        
        init(name: String, typeName: String) {
            self.name = name
            self.typeName = typeName
        }
        
        var declaration: String {
            return [
                accessLevel.source,
                referenceType?.source,
                "let \(name): \(typeName)"
            ].compactMap { $0 }.joined(separator: " ")
        }
    }
    
    struct Initializer {
        
        var args: [(name: String, typeName: String)] = []
        
        var creations: [String] = []
        var propertyInjections: [String] = []
        var storedProperties: [String] = []
        
        init() {}
    }
    
    struct Getter {
        
        var name: String
        var typeName: String
        var body: [String]
        
        init(name: String, typeName: String, body: [String] = []) {
            self.name = name
            self.typeName = typeName
            self.body = body
        }
    }
}

extension ContainerData {
    
    static func make(from container: Container) -> ContainerData {
        var data = ContainerData(name: "\(container.name)Container", initializer: Initializer())
        if let parent = container.parent {
            let parentName = "parentContainer"
            let parentTypeName = "\(parent.name)Container"
            data.properties.append(
                {
                    var property = Property(name: parentName, typeName: parentTypeName)
                    property.referenceType = .unowned
                    return property
                }()
            )
            data.initializer.storedProperties.append("self.\(parentName) = \(parentName)")
            data.initializer.args.append((name: parentName, typeName: parentTypeName))
            parentDependenciesOf(container).forEach { (dep) in
                var getter: Getter
                switch dep.typeResolver {
                case .explicit(let type):
                    getter = Getter(name: dep.name, typeName: type.fullName)
                case .provided(var type, let providerType):
                    if providerType.isOptional {
                        type.isOptional = true
                    }
                    getter = Getter(name: dep.name, typeName: type.fullName)
                }
                getter.body = ["return self.\(parentName).\(dep.name)"]
                data.getters.append(getter)
            }
        }
        container.args.forEach {
            if $0.isStoredProperty {
                data.properties.append(Property(name: $0.name, typeName: $0.typeName))
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
                    var getter = Getter(name: dep.name, typeName: type.fullName)
                    getter.body.append(created.creation)
                    getter.body.append(contentsOf: created.injections)
                    getter.body.append("return \(dep.name)")
                    data.getters.append(getter)
                case .provided(var type, let providerType):
                    if providerType.isOptional {
                        type.isOptional = true
                    }
                    let providerName = "\(dep.name)Provider"
                    let created = create(type: providerType, named: providerName)
                    var getter = Getter(name: dep.name, typeName: type.fullName)
                    getter.body.append(created.creation)
                    getter.body.append(contentsOf: created.injections)
                    getter.body.append("return \(invoked(providerName, of: providerType, with: "get()"))")
                    data.getters.append(getter)
                }
            case .singleton:
                switch dep.typeResolver {
                case .explicit(let type):
                    data.properties.append(Property(name: dep.name, typeName: type.fullName))
                    let created = create(type: type, named: dep.name)
                    data.initializer.creations.append(created.creation)
                    data.initializer.propertyInjections.append(contentsOf: created.injections)
                    data.initializer.storedProperties.append("self.\(dep.name) = \(dep.name)")
                case .provided(var type, let providerType):
                    if providerType.isOptional {
                        type.isOptional = true
                    }
                    let providerName = "\(dep.name)Provider"
                    data.properties.append(Property(name: providerName, typeName: providerType.fullName))
                    let created = create(type: providerType, named: providerName)
                    data.initializer.creations.append(created.creation)
                    data.initializer.propertyInjections.append(contentsOf: created.injections)
                    data.initializer.storedProperties.append("self.\(providerName) = \(providerName)")
                    data.getters.append(
                        {
                            var getter = Getter(name: dep.name, typeName: type.fullName)
                            getter.body = ["return \(invoked(providerName, of: providerType, with: "get()"))"]
                            return getter
                        }()
                    )
                }
            }
        }
        return data
    }
    
    private static func parentDependenciesOf(_ container: Container) -> [Dependency] {
        guard let parent = container.parent as? Container else {
            return []
        }
        let names = Set(container.dependencies.map { $0.name })
        let parentDependencies = parent.dependencies + parentDependenciesOf(parent)
        let filtered = parentDependencies.filter { names.contains($0.name) == false }
        return filtered
    }
    
    private static func constructing(_ type: Type) -> String {
        guard let injection = type.injectionSuite.constructor, injection.args.count > 0 else {
            return "\(type.name)()"
        }
        let args: [String] = injection.args.map {
            guard let name = $0.name else {
                return $0.dependencyName
            }
            return "\(name): \($0.dependencyName)"
        }
        return "\(type.name)(\(args.joined(separator: ", ")))"
    }
    
    private static func create(type: Type, named name: String) -> (creation: String, injections: [String]) {
        var injections: [String] = []
        let decl: String
        let properties = type.injectionSuite.properties
        if properties.count > 0 {
            decl = (type.isReference ? "let" : "var")
            properties.forEach {
                let lvalue = invoked(name, of: type, with: $0.name)
                let rvalue = $0.dependencyName
                injections.append("\(lvalue) = \(rvalue)")
            }
        } else {
            decl = "let"
        }
        let creation = "\(decl) \(name) = \(constructing(type))"
        return (creation, injections)
    }
    
    private static func invoked(_ reciever: String, of type: Type, with invocation: String) -> String {
        var src = "\(reciever)"
        if type.isOptional {
            src += "?"
        }
        return "\(src).\(invocation)"
    }
}
