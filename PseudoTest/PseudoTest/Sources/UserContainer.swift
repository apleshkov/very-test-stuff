//
//  UserContainer.swift
//  PseudoTest
//
//  Created by andrey.pleshkov on 15/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation

protocol UserScope: Scope {}

class UserStorage: UserScope {

    private let storage: UserDefaults

    // @saber.inject
    init(storage: UserDefaults) {
        self.storage = storage
    }

    var userId: String {
        return "1"
    }
}

protocol UserContainer: Container, UserScope {


}

class SaberUserContainer: UserContainer {

    unowned let parentContainer: SaberAppContainer

    init(parentContainer: SaberAppContainer) {
        self.parentContainer = parentContainer
    }
}

extension SaberUserContainer {

    var storage: UserDefaults {
        return parentContainer.storage
    }
}

extension SaberUserContainer {

    var userStorage: UserStorage {
        let userStorage = UserStorage(storage: storage)
        return userStorage
    }

    var userVC: UserVC {
        let userVC = UserVC(userStorage: userStorage)
        return userVC
    }
}
