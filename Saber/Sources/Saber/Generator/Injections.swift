//
//  Injections.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation

struct ConstructorInjection: Equatable {

    var name: String?

    var typeResolver: TypeResolver<TypeUsage>
}

struct MemberInjection: Equatable {

    var name: String

    var typeResolver: TypeResolver<TypeUsage>
}

struct InstanceMethodInjection: Equatable {

    var methodName: String

    var args: [FunctionInvocationArgument]
}
