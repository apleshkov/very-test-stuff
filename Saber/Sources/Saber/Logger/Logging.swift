//
//  Logging.swift
//  Saber
//
//  Created by andrey.pleshkov on 23/07/2018.
//

import Foundation

public protocol Logging {

    func log(_ level: LogLevel, message: @autoclosure () -> String)
    
    func log(_ level: LogLevel, loggable: Loggable)

    func warn(_ message: @autoclosure () -> String)

    func error(_ message: @autoclosure () -> String)

    func info(_ message: @autoclosure () -> String)

    func debug(_ message: @autoclosure () -> String)
}

extension Logging {

    public func log(_ level: LogLevel, loggable: Loggable) {
        loggable.log(with: self, level: level)
    }
    
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
