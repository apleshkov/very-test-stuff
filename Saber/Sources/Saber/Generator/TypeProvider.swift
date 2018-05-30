//
//  TypeProvider.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation

enum TypeProvider {
    case typed(TypedProvider)
    case staticMethod(StaticMethodProvider)
}

struct TypedProvider {

    var type: Type

    var methodName: String

    var args: [FunctionInvocationArgument] = []

    init(type: Type, methodName: String, args: [FunctionInvocationArgument] = []) {
        self.type = type
        self.methodName = methodName
    }
}

struct StaticMethodProvider {

    var receiverName: String

    var methodName: String

    var args: [FunctionInvocationArgument]
}
