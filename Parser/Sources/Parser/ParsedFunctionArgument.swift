//
//  ParsedFunctionArgument.swift
//  Parser
//
//  Created by andrey.pleshkov on 22/05/2018.
//

import Foundation

struct ParsedFunctionArgument: Equatable {

    var name: String?

    var type: ParsedType
}
