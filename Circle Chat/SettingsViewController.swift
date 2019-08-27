//
//  SettingsViewController.swift
//  Circle Chat
//
//  Created by Dalton Teague on 7/26/19.
//  Copyright © 2019 Dalton Teague. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController {
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
