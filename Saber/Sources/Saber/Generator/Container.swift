//
//  Container.swift
//  SwordCompiler
//
//  Created by andrey.pleshkov on 07/02/2018.
//

import Foundation

struct Container {

    var name: String

    var protocolName: String

    var dependencies: [Type] = []

    var externals: [ContainerExternal] = []
    
    var services: [Service] = []

    var isThreadSafe: Bool = false

    init(name: String, protocolName: String, dependencies: [Type] = []) {
        self.name = name
        self.dependencies = dependencies
        self.protocolName = protocolName
    }
    
    func add(dependency: Type) -> Container {
        var result = self
        result.dependencies.append(dependency)
        return result
    }
    
    func add(service: Service) -> Container {
        var result = self
        result.services.append(service)
        return result
    }
}

struct ContainerExternal {
    
    enum Kind {
        case property(name: String)
        case method(name: String, args: [FunctionInvocationArgument])
    }
    
    var type: Type
    
    var kinds: [Kind]
    
    init(type: Type, kinds: [Kind]) {
        self.type = type
        self.kinds = kinds
    }
}
