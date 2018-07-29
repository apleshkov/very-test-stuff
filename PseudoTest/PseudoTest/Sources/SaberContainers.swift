//
//  AppContainer.swift
//  PseudoTest
//
//  Created by andrey.pleshkov on 15/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation

// @saber.container(AppContainer)
// @saber.scope(App)
protocol AppContaining {}

// @saber.scope(App)
class Foo {
}

// @saber.scope(App)
class Bar {
    
    // @saber.inject
    var makeFoo: (() -> Foo)!
    
    // @saber.inject
    func set(fooFactory: () -> Foo) {
        // ...
    }
    
    init(foo: () -> Foo) {
        // ...
    }
}

// @saber.scope1(App)
class NetworkManager {
}

// @saber.container(UserContainer)
// @saber.scope(User)
// @saber.dependsOn(AppContainer)
protocol UserContaining {}

// @saber.scope1(User)
class UserAPI {
    
    init(networkManager: NetworkManager) {
        // ...
    }
}
