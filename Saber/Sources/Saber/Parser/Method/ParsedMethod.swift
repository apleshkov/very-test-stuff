//
//  ParsedMethod.swift
//  Parser
//
//  Created by andrey.pleshkov on 23/05/2018.
//

import Foundation

struct ParsedMethod: Equatable {

    var name: String

    var args: [ParsedArgument]

    var returnType: ParsedTypeUsage?

    var isStatic: Bool

    var annotations: [MethodAnnotation]

    var isFailableInitializer: Bool

    init(name: String,
         args: [ParsedArgument] = [],
         returnType: ParsedTypeUsage? = nil,
         isStatic: Bool = false,
         annotations: [MethodAnnotation] = [],
         isFailableInitializer: Bool = false) {
        self.name = name
        self.args = args
        self.returnType = returnType
        self.isStatic = isStatic
        self.annotations = annotations
        self.isFailableInitializer = isFailableInitializer
    }
}

extension ParsedMethod {

    var isInitializer: Bool {
        return name == "init"
    }
}

extension ParsedMethod: Loggable, CustomStringConvertible {
    
    var description: String {
        var message = name
        if isStatic {
            message = "static " + message
        }
        if isFailableInitializer {
            message += "?"
        }
        message += "("
        message += args.map { $0.description }.joined(separator: ", ")
        message += ")"
        if let returnType = returnType {
            message += " -> \(returnType.fullName)"
        }
        if annotations.count > 0 {
            message += " -- annotations: \(annotations)"
        }
        return message
    }
    
    func log(with logger: Logging, level: LogLevel) {
        logger.log(level, message: "- \(self)")
    }
}
