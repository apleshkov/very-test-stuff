//
//  Service.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation

enum ServiceStorage {
    case cached
    case none
}

struct Service {

    var typeResolver: TypeResolver

    var storage: ServiceStorage
}
