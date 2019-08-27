//
//  PreviewCircleViewController.swift
//  Circle Chat
//
//  Created by Dalton Teague on 7/1/19.
//  Copyright © 2019 Dalton Teague. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseFirestore

class PreviewCircleViewController: UIViewController {

    //variables
    var circleNameString: String! = ""
    var circleDescString: String! = ""
    var circleDateString: String! = ""
    var viewCount: String! = ""
    var circleID: String! = ""
    var username: String! = ""
    
    var circleImage: UIImage!
    
    var channel: Channel!
    var user: User!
    
    var readyToEnter: Bool!
    var escape: Bool! = false
    var firstTimeFlag: Bool! = true
    var fromEdit: Bool! = false
    var fromChat: Bool! = false
    
    let databaseRef = Database.database().reference(fromURL: "https://circle-chat-3cee4.firebaseio.com/")
    
    let db = Firestore.firestore()
    private var channelReference: CollectionReference {
        return db.collection("channels")
    }
    
    //outlets
    @IBAction func enterChatButton(_ sender: Any) {
        enterChannel()
    }
    @IBAction func finishButton(_ sender: Any) {
        finish()
    }
    @IBAction func editButton(_ sender: Any) {
        edit()
    }
    
    @IBOutlet weak var myView: UIView!
    @IBOutlet weak var buttonObject: UIButton!
    @IBOutlet weak var circleName: UILabel!
    @IBOutlet weak var circleDescription: UITextView!
    @IBOutlet weak var circleEndDate: UILabel!
    @IBOutlet weak var circleImageView: UIImageView!
    @IBOutlet weak var viewCountLabel: UILabel!
    
    var parentvc: MapViewController!
    
    //actions
    //functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (escape) {
            escape = false
            finish()
        }
        readyToEnter = false
        
        setChannel()
        
        _ = Auth.auth().addStateDidChangeListener { auth, userParam in
            print("balss1")
            if let theUser = userParam {
                // User is signed in.
                
                print(theUser.displayName as Any, "is signed in")
                self.user = theUser
                
            } else {
                // No user is signed in.
                self.performSegue(withIdentifier: "preview", sender: self)
            }
        }
        
        let date = convertToDate(dateStr: circleDateString)
        let timestamp = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
        
        circleName.text = circleNameString
        circleDescription.text = circleDescString
        circleEndDate.text = timestamp
        viewCountLabel.text = viewCount
        
        print("circle id: ", circleID as Any)
        
        if(circleID == nil) {
            finish()
        }
        
        self.circleImageView.layer.cornerRadius = self.circleImageView.frame.size.width / 2;
        self.circleImageView.clipsToBounds = true;
        databaseRef.child("circle").child(circleID).observeSingleEvent(of: .value, with: { (snapshot)
            in
            if let dict = snapshot.value as? [String: AnyObject] {
                let profileImageURL = dict["image"] as? String
                if profileImageURL != nil && profileImageURL != "" {
                    
                    
                    let url = URL(string: profileImageURL!)
                    URLSession.shared.dataTask(with: url!, completionHandler: { (data,
                        response, error) in
                        if error != nil {
                            print(error!)
                            return
                        }
                        DispatchQueue.main.async {
                            self.circleImage = UIImage(data: data!)
                            self.circleImageView.image = UIImage(data: data!)
                        }
                    }).resume()
                }
                
                //Circle belongs to active user, show Edit button
                if (self.user.uid == dict["user"] as? String) {
                    self.buttonObject.isHidden = false
                }
            }
            
        })
        
        if (fromChat) {
            fromChat = false;
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        print("preview back on top")
        if (fromEdit) {
            print("editing ui elements: ", circleNameString)
            circleName.text = circleNameString
            circleDescription.text = circleDescString
            let date = convertToDate(dateStr: circleDateString)
            let timestamp = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
            circleEndDate.text = timestamp
            circleImageView.image = circleImage
            parentvc.viewWillAppear(true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
    }
    
    func setChannel() {
        
        channelReference.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for doc in snapshot!.documents {
                    if (doc.get("name") as? String == self.circleNameString) {
                        self.channel = Channel(document: doc)!
                        self.readyToEnter = true
                        print("channel added to preview as :", self.channel.id as Any, " ", self.channel.name )
                    }
                }
            }
        }
        
    }
    
    func enterChannel() {
       print("Enter pressed")
        if (readyToEnter || self.channel != nil) {
            let currentUser = Auth.auth().currentUser!
            print("current user is no nil: ", currentUser.uid, ", ", currentUser.displayName)
            
            let appDelegate = UIApplication.shared.delegate
            let vc = ChatViewController(user: currentUser, channel: self.channel)
            appDelegate?.window??.rootViewController = NavigationController(self)
            
            print("passing on this view controller")
            vc.mapVC = self.parentvc
            
            navigationController?.pushViewController(vc, animated: true)
        } else {
            print(self.channel, " could not open channel")
            setChannel()
            if (readyToEnter) {
                enterChannel()
            }
        }
        //present(vc, animated: true, completion: nil)
    }
    
    func edit() {
        print("preview vc is actually: ", self)
        self.performSegue(withIdentifier: "editCircle", sender: self)
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        print("segue bitch into ", segue.identifier as Any)
        if segue.identifier == "editCircle"
        {
            let vc = segue.destination as? EditCircleViewController
                    print("setting them bitches")
                    vc?.circleNameString = circleNameString
                    vc?.circleDescString = circleDescString
                    vc?.circleDateString = circleDateString
                    vc?.circleID = circleID
                    vc?.viewCount = viewCount
                    vc?.parentvc = self
                    vc?.circleImage = circleImage
                    print("bitches set")
        }
    }
    
    
    func finish() {
//        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
//        let mapvc = storyBoard.instantiateViewController(withIdentifier: "mapIdentifier") as! MapViewController
//        UIApplication.shared.keyWindow?.rootViewController = mapvc
//        UIApplication.shared.keyWindow?.makeKeyAndVisible()
        self.dismiss(animated: true, completion: nil)
    }
    
    func convertToDate(dateStr: String) -> Date {
        //let isoDate = "2016-04-14T10:44:00+0000"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        //dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        guard let date = dateFormatter.date(from:dateStr) else { return Date() }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        
        return calendar.date(from:components)!
    }
}

