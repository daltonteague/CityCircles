//
//  ProfileViewController.swift
//  Circle Chat
//
//  Created by Dalton Teague on 8/5/18.
//  Copyright © 2018 Dalton Teague. All rights reserved.
//

import UIKit
import Firebase

class UserViewController: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate{
    
    
    //variables
    let storageRef = Storage.storage().reference()
    let databaseRef = Database.database().reference()
    
    let db = Firestore.firestore()
    private var reference: CollectionReference?
    private var messageReference: CollectionReference {
        return db.collection("messages")
    }
    
    var userUID: String = ""
    var userName: String = ""
    var activeUsername: String = ""
    var activeUID: String = ""
    var messageID: String = ""
    var readyToEnter: Bool = false
    var channelExists: Bool = false
    var channel: DirectMessage!
    
    var circlesArr = [Circle]()
    
    
    //outlets
    @IBOutlet weak var usernameView: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var aboutUser: UITextView!
    
    @IBAction func sendMessage(_ sender: Any) {
        if (!channelExists) {
            createDirectChannel()
        }
        openDirectChannel()
    }
    @IBAction func backButton(_ sender: Any) {
        back()
    }
    @IBAction func addFriend(_ sender: Any) {
        addFriend()
    }
    @IBAction func invite(_ sender: Any) {
        invite()
    }
    @IBOutlet weak var buttonObject: UIButton!
    
    
    @IBOutlet weak var circleList: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        if let uid = Auth.auth().currentUser?.uid {
            databaseRef.child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot)
                in
                
                let enumerator = snapshot.children
                while let current = enumerator.nextObject() as? DataSnapshot {
                    if (current.key == "friends") {
                        let event = current.value as! [String: Any]
                        for friend in event {
                            if (friend.key == self.usernameView.text) {
                                self.buttonObject.setTitle("Friends", for: .normal)
                                self.buttonObject.setTitleColor(.lightGray, for: .normal)
                            }
                                
                        }
                    }
                }
                
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        circleList.dataSource = self
        circleList.delegate = self
        
        setupProfile()
        fillArray()
        
        
        
    }
    
    func fillArray() {
        print("filling")
        databaseRef.child("circle").observeSingleEvent(of: .value) { snapshot in
            let enumerator = snapshot.children
            while let current = enumerator.nextObject() as? DataSnapshot {
                let event = current.value as! [String: Any]
                print("comparing ", self.userUID, " with ", event["user"] as? String)
                if (self.userUID == event["user"] as? String) {
                    
                    let newCircle = Circle(name: (event["name"] as? String)!, desc: (event["description"] as? String)!,
                                           open: (event["open"] as? Bool)!, endDate: (event["end_date"] as? String)!, userID: (event["user"] as? String)!, circleID: current.key, size: (event["radius"] as? String)!, viewCount: (event["views"] as? String)!)
                    
                    self.circlesArr.append(newCircle)
                    self.circleList.reloadData()
                }
            }
        }
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //Adds user as friend, then asks them if they want to add you back
    //friendships don't have to be mutual
    //Need an 'Added You' page
    func addFriend() {
        print("clicked addfriend")
        if let uid = Auth.auth().currentUser?.uid {
            //databaseRef.child("users").child(uid).child("friends").push
            storeFriendToDB(postID: uid)
                //.child(username?.text ?? "Failed to add friend").updateChildValues([username?.text:userUID])
            print("Added ", userName, "unsuccessfully", " to friends list")
            buttonObject.setTitle("Added Friend", for: .normal)
            buttonObject.setTitleColor(.lightGray, for: .normal)
        }
        
        //*SET UP PUSH NOTIFICATIONS*//
    }
    
    //Invites user to a circle, create view for this
    func invite() {
        
    }
    
    //actions
    @IBAction func saveAction(_ sender: Any) {
        saveChanges()
    }
    @IBAction func logout(_ sender: Any) {
        logout()
    }
    @IBAction func uploadImage(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerController.SourceType.photoLibrary
        self.present(picker, animated: true, completion: nil)
    }
    
    //functions
    func setupProfile() {
        
        if Auth.auth().currentUser?.uid == nil {
            logout()
        } else {
            self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2;
            self.profileImageView.clipsToBounds = true;
            
            if let uid = Auth.auth().currentUser?.uid {
                databaseRef.child("users").child(self.userUID).observeSingleEvent(of: .value, with: { (snapshot)
                    in
                    if let dict = snapshot.value as? [String: AnyObject] {
                        self.userName = dict["username"] as! String
                        self.usernameView.text = self.userName
                        let profileImageURL = dict["pic"] as? String
                        self.userUID = snapshot.key
                        self.aboutUser.text = dict["about"] as? String
                        if profileImageURL != nil && profileImageURL != "" {
                            let url = URL(string: profileImageURL!)
                            URLSession.shared.dataTask(with: url!, completionHandler: { (data,
                                response, error) in
                                if error != nil {
                                    print(error!)
                                    return
                                }
                                DispatchQueue.main.async {
                                    self.profileImageView?.image = UIImage(data: data!)
                                }
                            }).resume()
                        }
                    }
                    
                })
                databaseRef.child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot)
                    in
                    if let dict = snapshot.value as? [String: AnyObject] {
                        self.activeUsername = dict["username"] as! String
                    }
                })
            }
        }
    }
    
    func storeFriendToDB(postID :String!, userID : String! = Auth.auth().currentUser!.uid){
        
        let parentRef = databaseRef.child("users").child(userID).child("friends")
        
        parentRef.observeSingleEvent(of: .value, with: {(friendsList) in
            
            if friendsList.exists(){
                if let listDict = friendsList.value as? NSMutableDictionary{
                    
                    listDict.setObject(self.userUID, forKey: self.userName as! NSCopying)
                    parentRef.setValue(listDict)
                    
                }
            }else{
                parentRef.setValue([self.userName : self.userUID])
            }
        })
    }
    
    func logout() {
        saveChanges()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "login")
        present(loginViewController, animated: true, completion: nil)
    }
    
    func back() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        saveChanges()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func saveChanges() {
        
        let imageName = NSUUID().uuidString
        let storedImage = storageRef.child("profile_images").child(imageName)
        
        if let uploadData = self.profileImageView.image!.pngData() {
            storedImage.putData(uploadData, metadata: nil) { (metadata, error) in
                if error != nil {
                    print(error!)
                    return
                }
                storedImage.downloadURL(completion: { (url, error) in
                    if error != nil {
                        print(error!)
                        return
                    }
                    print("pic url downloaded as: ", url)
                    if let urlText = url?.absoluteString {
                        self.databaseRef.child("users").child((Auth.auth().currentUser?.uid)!)
                            .updateChildValues(["pic" : urlText], withCompletionBlock: { (error, ref) in
                                if error != nil {
                                    print(error!)
                                    return
                                }
                                print("set profile pic to: ", urlText)
                            })
                    }
                })
            }
        }
        
    }
    
    func createDirectChannel() {
        
        if (activeUsername == "" || userName == "" || channelExists) {
            return
        } else {
            channelExists = true
        }
        
        if let uid = Auth.auth().currentUser?.uid {
            self.activeUID = uid
        databaseRef.child("users").child(uid).child("messages").observeSingleEvent(of: .value, with: { (snapshot)
            in
            
            if (snapshot.exists()) {
                let enumerator = snapshot.children
                var foundChannel = false
                while let current = enumerator.nextObject() as? DataSnapshot {
                    if (current.key == self.userName) {
                        if let dict = current.value as? [String: AnyObject] {
                            self.messageID = dict["messageID"] as? String ?? ""
                            if (self.messageID != "") {
                                foundChannel = true
                                self.getChannel()
                            }
                        }
                    }
                }
                if (!foundChannel) {
                    self.createNewChannel()
                }
            } else {
                self.createNewChannel()
            }
        })
        }
        
    }
    
    func getChannel() {
        print("Entering existing channel")
        messageReference.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for doc in snapshot!.documents {
                    if (doc.documentID == self.messageID) {
                        self.channel = DirectMessage(document: doc)!
                        self.readyToEnter = true
                        print("channel added to preview as :", self.channel.id as Any, " ", self.channel.user1, " ", self.channel.user2 )
                        self.openDirectChannel()
                    }
                }
            }
        }
    }
    
    func createNewChannel() {
        //Must create a DM channel for the users and save its ID
        //for both users with the corresponding user
        let user1 = self.activeUsername
        let user2 = self.userName
        print("Creating new DM channel for ", user1, " and ", user2)
        
        
        self.channel = DirectMessage(user1: user1, user2: user2)
        
        messageReference.addDocument(data: channel.representation) { error in
            if let e = error {
                print("Error saving channel: \(e.localizedDescription)")
            }
        }
        
        messageReference.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for doc in snapshot!.documents {
                    if (doc.get("user2_ID") as? String == self.userName) {
                        self.channel = DirectMessage(document: doc)!
                        self.readyToEnter = true
                        print("channel added to preview as :", self.channel.id as Any, " ", self.channel.user1, " ", self.channel.user2)
                        
                        //create unique ID by appending both users' IDs together
                        self.messageID = self.channel.id ?? ""
                        
                        let userRef = self.databaseRef.child("users").child(self.activeUID).child("messages").child(user2)
                        userRef.setValue(["messageID":self.messageID])
                        
                        
                        let receiverRef = self.databaseRef.child("users").child(self.userUID).child("messages").child(user1)
                        receiverRef.setValue(["messageID":self.messageID])
                        self.openDirectChannel()
                    }
                }
            }
        }
    }
    
    func openDirectChannel() {
        
        print("Enter pressed")
        if (readyToEnter || self.channel != nil) {
            let currentUser = Auth.auth().currentUser!
            print("current user is no nil: ", currentUser.uid, ", ", currentUser.displayName)
            
            let appDelegate = UIApplication.shared.delegate
            let vc = ChatViewController(user: currentUser, message: self.channel)
            appDelegate?.window??.rootViewController = NavigationController(self)
            
            navigationController?.pushViewController(vc, animated: true)
        } else {
            print(self.channel, " could not open direct channel")
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if circlesArr.count != 0 {
                return circlesArr.count
            }
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //sleep(1)
            print("table view was circle list")
            let cell:MyCustomCell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! MyCustomCell
            cell.myView?.backgroundColor = UIColor.lightGray
            cell.userImage.layer.cornerRadius = cell.userImage.frame.size.width / 2;
            cell.userImage.clipsToBounds = true;
            print("circles arr count ", circlesArr.count)
            if circlesArr.count != 0 {
                let circle = circlesArr[indexPath.row]
                
                databaseRef.child("circle").child(circlesArr[indexPath.row].circleID).observeSingleEvent(of: .value, with: { (snapshot)
                    in
                    if let dict = snapshot.value as? [String: AnyObject] {
                        let profileImageURL = dict["image"] as? String
                        cell.viewCount.text = dict["views"] as? String
                        
                        if profileImageURL != nil && profileImageURL != "" {
                            
                            let url = URL(string: profileImageURL!)
                            URLSession.shared.dataTask(with: url!, completionHandler: { (data,
                                response, error) in
                                if error != nil {
                                    print(error!)
                                    return
                                }
                                DispatchQueue.main.async {
                                    cell.userImage.image = UIImage(data: data!)
                                }
                            }).resume()
                        }
                    }
                })
                cell.eventName?.text = circle.name
                
            }
            return cell
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
