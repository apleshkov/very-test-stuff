//
//  LogLevel.swift
//  Saber
//
//  Created by Andrew Pleshkov on 23/07/2018.
//

import Foundation

public enum LogLevel {
    case warning
    case error
    case info
    case debug
}

extension LogLevel: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .debug:
            return "debug"
        case .error:
            return "error"
        case .info:
            return "info"
        case .warning:
            return "warning"
        }
    }
}
