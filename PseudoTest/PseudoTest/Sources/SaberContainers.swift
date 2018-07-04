//
//  AppContainer.swift
//  PseudoTest
//
//  Created by andrey.pleshkov on 15/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation

// @saber.container(AppContainer)
// @saber.scope(Singleton)
protocol AppContaining {}

// @saber.container(UserContainer)
// @saber.scope(User)
// @saber.dependsOn(AppContainer)
protocol UserContaining {}


class SaberAppContainer: AppContaining {
    
    private var cachedUserManager: UserManager?
}

extension SaberAppContainer {
    
    var userManager: UserManager {
        guard let cachedUserManager = cachedUserManager else {
            let userManager = UserManager(appContainer: self)
            self.cachedUserManager = userManager
            return userManager
        }
        return cachedUserManager
    }
}

extension SaberAppContainer {
    
    func inject(to injectee: ViewController) {
        injectee.userManager = self.userManager
    }
}
