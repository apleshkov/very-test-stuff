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

    var dependencies: [TypeUsage]

    var externals: [ContainerExternal] = []
    
    var services: [Service] = []

    var isThreadSafe: Bool
    
    var imports: [String]

    init(name: String, protocolName: String, dependencies: [TypeUsage] = [], isThreadSafe: Bool = false, imports: [String] = []) {
        self.name = name
        self.dependencies = dependencies
        self.protocolName = protocolName
        self.isThreadSafe = isThreadSafe
        self.imports = imports
    }
    
    func add(dependency: TypeUsage) -> Container {
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
    
    var type: TypeUsage
    
    var kinds: [Kind]
    
    init(type: TypeUsage, kinds: [Kind]) {
        self.type = type
        self.kinds = kinds
    }
}
