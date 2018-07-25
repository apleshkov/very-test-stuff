//
//  ParsedProperty.swift
//  Parser
//
//  Created by andrey.pleshkov on 23/05/2018.
//

import Foundation

struct ParsedProperty: Equatable {

    var name: String

    var type: ParsedTypeUsage

    var annotations: [PropertyAnnotation] = []

    var isLazy: Bool

    init(name: String,
         type: ParsedTypeUsage,
         annotations: [PropertyAnnotation] = [],
         isLazy: Bool = false) {
        self.name = name
        self.type = type
        self.annotations = annotations
        self.isLazy = isLazy
    }
}

extension ParsedProperty: Loggable {
    
    func log(with logger: Logging, level: LogLevel) {
        var message = "\(name): \(type.fullName)"
        if isLazy {
            message = "lazy " + message
        }
        if annotations.count > 0 {
            message += " -- "
            message += annotations
                .map { $0.description }
                .joined(separator: ", ")
        }
        message = "- " + message
        logger.log(level, message: message)
    }
}
