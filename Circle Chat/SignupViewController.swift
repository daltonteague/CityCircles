//
//  SignupViewController.swift
//  Circle Chat
//
//  Created by Dalton Teague on 6/11/19.
//  Copyright © 2019 Dalton Teague. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class SignupViewController: UIViewController {
    
    //variabls
    let databaseRef = Database.database().reference(fromURL: "https://circle-chat-3cee4.firebaseio.com/")
    //outlets
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var passwordConfirm: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    //actions
    
    @IBAction func goBack(_ sender: Any) {
    }
    @IBAction func createProfile(_ sender: Any) {
        create()
    }
    //functions
    func create() {
        guard let email = email.text else {
            print("Issue entering email")
            return
        }
        guard let username = username.text else {
            print("Issue entering username")
            return
        }
        guard let password = password.text else {
            print("Issue entering password")
            return
        }
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                print(error!)
                return
            }
            guard let uid = user?.user.uid else {
                return
            }
            
            let userRef = self.databaseRef.child("users").child(uid)
            let values = ["username":username, "email":email, "pic":"", "circle":"", "about":""]
            
            userRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
                if error != nil {
                    print(error!)
                    return
                }
                self.dismiss(animated:true, completion: nil)
            })
        })
    }
    
}
