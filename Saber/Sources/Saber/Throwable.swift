//
//  Throwable.swift
//  Saber
//
//  Created by Andrew Pleshkov on 30/05/2018.
//

import Foundation

enum Throwable: Error, Equatable {
    case message(String)
    case declCollision(name: String, modules: [String])
}

extension Throwable {

    var localizedDescription: String {
        switch self {
        case .message(let text):
            return text
        case .declCollision(let name, let modules):
            let moduleList = modules.map { "\($0)" }.joined(separator: ", ")
            return "Declaration collision: '\(name)' is declared in different modules: \(moduleList)"
        }
    }
}
