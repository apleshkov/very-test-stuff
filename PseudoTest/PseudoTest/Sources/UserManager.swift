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

// @saber.scope(Singleton)
class UserManager {
    
    unowned var appContainer: AppContainer
    
    private(set) var userContainer: UserContainer!
    
    init() {
    }
    
    func logIn(userId: String) {
        let user = User(id: userId)
        userContainer = UserContainer(appContainer: appContainer, user: user)
    }
}
