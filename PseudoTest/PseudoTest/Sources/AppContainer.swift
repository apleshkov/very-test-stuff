//
//  AppContainer.swift
//  PseudoTest
//
//  Created by andrey.pleshkov on 15/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation

protocol AppContainer: Container, Singleton {
}


class SaberAppContainer: AppContainer {
    
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
