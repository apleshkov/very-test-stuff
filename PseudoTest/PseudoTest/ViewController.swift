//
//  ViewController.swift
//  PseudoTest
//
//  Created by andrey.pleshkov on 15/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import UIKit

// @saber.scope(Singleton)
// @saber.injectOnly
class ViewController: UIViewController {

    // @saber.inject
    weak var userManager: UserManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let userVC = userManager.userContainer.userVC
        addChildViewController(userVC)
        userVC.view.frame = view.bounds
        userVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(userVC.view)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        (UIApplication.shared.delegate as! AppDelegate).appContainer.injectTo(viewController: self)
    }
}

