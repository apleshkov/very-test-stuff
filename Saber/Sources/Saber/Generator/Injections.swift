//
//  Injections.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation

struct ConstructorInjection {

    var name: String?

    var typeResolver: TypeResolver<TypeUsage>
}

struct MemberInjection {

    var name: String

    var typeResolver: TypeResolver<TypeUsage>
}

struct InstanceMethodInjection {

    var methodName: String

    var args: [FunctionInvocationArgument]
}
