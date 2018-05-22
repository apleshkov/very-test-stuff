//
//  ParsedFunctionArgument.swift
//  Parser
//
//  Created by andrey.pleshkov on 22/05/2018.
//

import Foundation

struct ParsedFunctionArgument {

    var name: String?

    var type: ParsedType
}

extension ParsedFunctionArgument: Equatable {

    static func == (lhs: ParsedFunctionArgument, rhs: ParsedFunctionArgument) -> Bool {
        return (lhs.name ?? "") == (rhs.name ?? "")
            && lhs.type == rhs.type
    }
}
