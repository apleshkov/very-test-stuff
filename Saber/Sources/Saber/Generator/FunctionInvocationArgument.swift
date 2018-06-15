//
//  FunctionInvocationArgument.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation

struct FunctionInvocationArgument: Equatable {

    var name: String?

    var typeResolver: TypeResolver<TypeUsage>
}
