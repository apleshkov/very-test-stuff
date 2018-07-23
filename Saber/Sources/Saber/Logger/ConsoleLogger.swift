//
//  ConsoleLogger.swift
//  Saber
//
//  Created by andrey.pleshkov on 23/07/2018.
//

import Foundation

public class ConsoleLogger: Logging {

    public init() {}

    public func log(_ level: LogLevel, message: @autoclosure () -> String) {
        print("[\(level)] \(message())")
    }
}
