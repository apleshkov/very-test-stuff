//
//  Logging.swift
//  Saber
//
//  Created by andrey.pleshkov on 23/07/2018.
//

import Foundation

public enum LogLevel: CustomStringConvertible {
    case warning
    case error
    case info
    case debug

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

public protocol Logging {

    func log(_ level: LogLevel, message: @autoclosure () -> String)

    func warn(_ message: @autoclosure () -> String)

    func error(_ message: @autoclosure () -> String)

    func info(_ message: @autoclosure () -> String)

    func debug(_ message: @autoclosure () -> String)
}

extension Logging {

    public func warn(_ message: @autoclosure () -> String) {
        log(.warning, message: message)
    }

    public func error(_ message: @autoclosure () -> String) {
        log(.error, message: message)
    }

    public func info(_ message: @autoclosure () -> String) {
        log(.info, message: message)
    }

    public func debug(_ message: @autoclosure () -> String) {
        log(.debug, message: message)
    }
}
