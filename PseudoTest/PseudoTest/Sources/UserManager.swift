//
//  UserManager.swift
//  PseudoTest
//
//  Created by Andrew Pleshkov on 15/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation


struct User {
    
    var id: String
}


class UserManager: Singleton {
    
    private let appContainer: SaberAppContainer
    
    private(set) var userContainer: SaberUserContainer!
    
    // @saber.inject
    init(appContainer: SaberAppContainer) {
        self.appContainer = appContainer
    }
    
    func logIn(userId: String) {
        let user = User(id: userId)
        userContainer = SaberUserContainer(parentContainer: appContainer, user: user)
    }
}
