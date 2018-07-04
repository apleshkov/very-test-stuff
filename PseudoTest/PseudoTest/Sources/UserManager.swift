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
// @saber.cached
class UserManager {
    
    private unowned let appContainer: AppContainer
    
    private(set) var userContainer: UserContainer!
    
    // @saber.inject
    init(appContainer: AppContainer) {
        self.appContainer = appContainer
    }
    
    func logIn(userId: String) {
        let user = User(id: userId)
        let data = UserData(user: user)
        userContainer = UserContainer(appContainer: appContainer, userData: data)
    }
}
