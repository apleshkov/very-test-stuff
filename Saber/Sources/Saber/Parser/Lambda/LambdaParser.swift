//
//  LambdaParser.swift
//  Saber
//
//  Created by andrey.pleshkov on 19/06/2018.
//

import Foundation

class LambdaParser {

    static func parse(_ rawString: String) -> ParsedLambda? {
        guard let arrowRange = rawString.range(of: "->") else {
            return nil
        }
        let rawReturnType = String(rawString[arrowRange.upperBound...].dropFirst())
        return ParsedLambda(
            returnType: TypeUsageParser.parse(rawReturnType)
        )
    }
}
