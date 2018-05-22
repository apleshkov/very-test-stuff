//
//  FunctionAnnotationParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 22/05/2018.
//

import Foundation

class FunctionAnnotationParser {

    func parse(_ rawString: String) -> FunctionAnnotation? {
        if rawString == "inject" {
            return FunctionAnnotation.inject
        }
        if rawString == "provider" {
            return FunctionAnnotation.provider
        }
        return nil
    }
}
