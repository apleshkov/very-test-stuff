//
//  Container+Tests.swift
//  SaberTests
//
//  Created by andrey.pleshkov on 29/05/2018.
//

import Foundation
@testable import Saber

extension Container {

    init(name: String, dependencies: [TypeUsage] = [], isThreadSafe: Bool = false, imports: [String] = []) {
        self.init(name: name, protocolName: "\(name)Protocol", dependencies: dependencies, isThreadSafe: isThreadSafe, imports: imports)
    }
}
