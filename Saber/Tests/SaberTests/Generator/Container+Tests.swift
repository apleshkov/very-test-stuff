//
//  Container+Tests.swift
//  SaberTests
//
//  Created by andrey.pleshkov on 29/05/2018.
//

import Foundation
@testable import Saber

extension Container {

    init(name: String, dependencies: [Type] = []) {
        self.init(name: name, protocolName: "\(name)Protocol", dependencies: dependencies)
    }
}
