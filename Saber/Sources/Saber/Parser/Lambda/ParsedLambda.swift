//
//  ParsedLambda.swift
//  Saber
//
//  Created by andrey.pleshkov on 19/06/2018.
//

import Foundation

struct ParsedLambda<T>: Equatable where T: Equatable {

    var source: String

    var returnType: T?
}
