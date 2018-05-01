//
//  Container.swift
//  SwordCompiler
//
//  Created by andrey.pleshkov on 07/02/2018.
//

import Foundation

struct Container {

    var name: String

    var args: [(name: String, typeName: String, isStoredProperty: Bool)] = []
    
    var dependencies: [Dependency] = []

    init(name: String) {
        self.name = name
    }
}

struct ConstructorInjection {

    var args: [(name: String?, dependencyName: String)]
}

struct PropertyInjection {

    var name: String

    var dependencyName: String
}

struct InjectionSuite {

    var constructor: ConstructorInjection? = nil

    var properties: [PropertyInjection] = []

    init() {}
}

enum DependencyStorage {
    case singleton
    case prototype
}

struct Dependency {

    var name: String

    var typeResolver: TypeResolver

    var storage: DependencyStorage
}

struct Type {

    var name: String

    var isOptional: Bool = false

    var isReference: Bool = false
    
    var injectionSuite = InjectionSuite()

    init(name: String) {
        self.name = name
    }

    var fullName: String {
        return "\(name)\(isOptional ? "?" : "")"
    }
}

extension Type: Hashable {

    static func ==(lhs: Type, rhs: Type) -> Bool {
        return lhs.name == rhs.name
    }

    var hashValue: Int { return name.hashValue }
}

enum TypeResolver {
    case explicit(Type)
    case provided(Type, by: Type)
}

// MARK

func makeTestContainer() -> Container {
    var container = Container(name: "Country")
    container.args.append((name: "code", typeName: "String", isStoredProperty: false))
    container.args.append((name: "omg", typeName: "Int?", isStoredProperty: true))
    
    let foo: Dependency = {
        var type = Type(name: "Foo")
        type.isReference = true
        type.injectionSuite.constructor = ConstructorInjection(args: [(name: "code", dependencyName: "code")])
        return Dependency(
            name: "foo",
            typeResolver: .explicit(type),
            storage: .singleton
        )
    }()
    container.dependencies.append(foo)
    
    let bar: Dependency = {
        var type = Type(name: "Bar")
        type.isReference = true
        type.injectionSuite.constructor = ConstructorInjection(args: [(name: nil, dependencyName: foo.name)])
        return Dependency(
            name: "bar",
            typeResolver: .explicit(type),
            storage: .singleton
        )
    }()
    container.dependencies.append(bar)
    
    let baz: Dependency = {
        var type = Type(name: "Baz")
        type.isReference = false
        type.injectionSuite.properties.append(
            PropertyInjection(name: "bar", dependencyName: bar.name)
        )
        return Dependency(
            name: "baz",
            typeResolver: .explicit(type),
            storage: .singleton
        )
    }()
    container.dependencies.append(baz)
    
    let quux1: Dependency = {
        var type = Type(name: "Quux")
        type.isReference = true
        type.injectionSuite.constructor = ConstructorInjection(args: [(name: "foo", dependencyName: foo.name)])
        return Dependency(
            name: "quux1",
            typeResolver: .explicit(type),
            storage: .prototype
        )
    }()
    container.dependencies.append(quux1)
    
    let quux2: Dependency = {
        var type = Type(name: "Quux")
        type.isReference = true
        var providerType = Type(name: "QuuxProvider")
        providerType.isReference = true
        providerType.injectionSuite.properties.append(
            PropertyInjection(name: "foo", dependencyName: foo.name)
        )
        return Dependency(
            name: "quux2",
            typeResolver: .provided(type, by: providerType),
            storage: .singleton
        )
    }()
    container.dependencies.append(quux2)
    
    let quux3: Dependency = {
        var type = Type(name: "Quux")
        type.isReference = true
        var providerType = Type(name: "QuuxProvider")
        providerType.isReference = true
        return Dependency(
            name: "quux3",
            typeResolver: .provided(type, by: providerType),
            storage: .prototype
        )
    }()
    container.dependencies.append(quux3)
    
    return container
}
