//
//  UserContainer.swift
//  PseudoTest
//
//  Created by andrey.pleshkov on 15/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation

class SaberUserContainer: UserContaining {

    unowned let parentContainer: SaberAppContainer
    
    let user: User

    init(parentContainer: SaberAppContainer, user: User) {
        self.parentContainer = parentContainer
        self.user = user
    }
}

extension SaberUserContainer {

    var userVC: UserVC {
        let userVC = UserVC(user: user)
        return userVC
    }
}
