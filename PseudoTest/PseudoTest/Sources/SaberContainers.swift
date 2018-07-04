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
// @saber.externals(UserData)
protocol UserContaining {}

struct UserData {
    
    var user: User
}
