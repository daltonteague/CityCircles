//
//  LoginViewController.swift
//  Circle Chat
//
//  Created by Dalton Teague on 8/5/18.
//  Copyright © 2018 Dalton Teague. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    //variabls
    var databaseRef : DatabaseReference! = nil
    //outlets
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        databaseRef = Database.database().reference(fromURL: "https://circle-chat-3cee4.firebaseio.com/")
        
        //Specify an email keyboard for the email login
        self.username.delegate = self
        self.username.keyboardType = UIKeyboardType.emailAddress
        self.password.delegate = self
        
        
    }
    
    
    
    //Outlets connected to the login and signup UI buttons
    @IBAction func login(_ sender: Any) {
        login()
    }
    @IBAction func signup(_ sender: Any) {
        signup()
    }

    
    //functions
    func login() {
        
        guard let username = username.text else {
            print("Issue entering username")
            return
        }
        guard let password = password.text else {
            print("Issue entering password")
            return
        }
        Auth.auth().signIn(withEmail: username, password: password, completion: { (user, error) in
            if error != nil {
                print("error boiiii: ", error!)
                return
            }
            self.performSegue(withIdentifier: "mapIdentifier", sender: nil)
            //self.dismiss(animated: true, completion: nil)
        })
        
    }
    
    func signup() {
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
}
