//
//  FunctionAnnotationParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 22/05/2018.
//

import Foundation

class MethodAnnotationParser {

    func parse(_ rawString: String) -> MethodAnnotation? {
        if rawString == "inject" {
            return MethodAnnotation.inject
        }
        if rawString == "provider" {
            return MethodAnnotation.provider
        }
        return nil
    }
}
