//
//  UserVC.swift
//  PseudoTest
//
//  Created by andrey.pleshkov on 15/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation
import UIKit

class UserVC: UIViewController, UserScope {

    private let userId: String

    // @saber.inject
    init(userStorage: UserStorage) {
        self.userId = userStorage.userId
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UserVC {

    override func viewDidLoad() {
        super.viewDidLoad()

        print(userId)
    }
}
