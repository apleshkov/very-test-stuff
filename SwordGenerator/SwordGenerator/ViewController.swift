//
//  ViewController.swift
//  SwordGenerator
//
//  Created by Andrew Pleshkov on 30/04/2018.
//  Copyright © 2018 test. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let container = makeTestContainer()
        let data = ContainerData.make(from: container)
        Renderer().render(data)
    }
}

// MARK

func makeTestContainer() -> Container {
    var container = Container(name: "Country")
    container.args.append(ContainerArgument(name: "code", typeName: "String", isStoredProperty: false))
    container.args.append(ContainerArgument(name: "omg", typeName: "Int?", isStoredProperty: true))
    
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
