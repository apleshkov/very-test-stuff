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

    var decl: TypeDeclaration

    var methodName: String

    var args: [FunctionInvocationArgument] = []

    init(decl: TypeDeclaration, methodName: String, args: [FunctionInvocationArgument] = []) {
        self.decl = decl
        self.methodName = methodName
    }
}

struct StaticMethodProvider {

    var receiverName: String

    var methodName: String

    var args: [FunctionInvocationArgument]
    
    var isCached: Bool
    
    init(receiverName: String, methodName: String, args: [FunctionInvocationArgument] = [], isCached: Bool = false) {
        self.receiverName = receiverName
        self.methodName = methodName
        self.args = args
        self.isCached = isCached
    }
}
