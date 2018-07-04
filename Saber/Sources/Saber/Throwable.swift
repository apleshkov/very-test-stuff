//
//  Throwable.swift
//  Saber
//
//  Created by Andrew Pleshkov on 30/05/2018.
//

import Foundation

public enum Throwable: Error {
    case message(String)
    case declCollision(name: String, modules: Set<String>)
    case noParsedType(for: TypeRepository.Info)
    case wrapped(Error)
}

extension Throwable: CustomStringConvertible {

    public var description: String {
        switch self {
        case .message(let text):
            return text
        case .declCollision(let name, let modules):
            let moduleList = modules.map { "\($0)" }.joined(separator: ", ")
            return "Declaration collision: '\(name)' is declared in different modules: \(moduleList)"
        case .noParsedType(let info):
            return "Unable to make '\(info.key.description)' declaration: no parsed type"
        case .wrapped(let error):
            return error.localizedDescription
        }
    }
}

extension Throwable: CustomDebugStringConvertible {

    public var debugDescription: String {
        return description
    }
}

extension Throwable {

    var localizedDescription: String {
        return description
    }
}
