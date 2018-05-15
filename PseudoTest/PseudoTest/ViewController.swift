//
//  ViewController.swift
//  PseudoTest
//
//  Created by andrey.pleshkov on 15/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let userVC = UserVC(userId: "1")
        addChildViewController(userVC)
        userVC.view.frame = view.bounds
        userVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(userVC.view)
    }
}

