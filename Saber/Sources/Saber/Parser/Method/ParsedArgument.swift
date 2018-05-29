//
//  ParsedFunctionArgument.swift
//  Parser
//
//  Created by andrey.pleshkov on 22/05/2018.
//

import Foundation

struct ParsedArgument: Equatable {

    var name: String?

    var type: ParsedTypeUsage
}
