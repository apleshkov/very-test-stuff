//
//  Injections.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation

struct ConstructorInjection {

    var name: String?

    var typeResolver: TypeResolver
}

struct MemberInjection {

    var name: String

    var typeResolver: TypeResolver
}

struct InstanceMethodInjection {

    var methodName: String

    var args: [FunctionInvocationArgument]
}
