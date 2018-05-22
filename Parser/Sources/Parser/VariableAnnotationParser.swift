//
//  VariableAnnotationParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 22/05/2018.
//

import Foundation

class VariableAnnotationParser {

    func parse(_ rawString: String) -> VariableAnnotation? {
        if rawString == "inject" {
            return VariableAnnotation.inject
        }
        return nil
    }
}
