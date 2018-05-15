//
//  AppContainer.swift
//  PseudoTest
//
//  Created by andrey.pleshkov on 15/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation


protocol Scope {}

protocol Singleton: Scope {}

protocol Container {}


enum AppProvider {

    var storage: UserDefaults { return UserDefaults.standard }
}


protocol AppContainer: Container, Singleton {

    var storage: UserDefaults { get }
}


class SaberAppContainer: AppContainer {

    let storage: UserDefaults

    init(storage: UserDefaults) {
        self.storage = storage
    }
}
