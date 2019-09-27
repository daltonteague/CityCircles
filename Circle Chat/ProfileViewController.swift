//
//  ProfileViewController.swift
//  Circle Chat
//
//  Created by Dalton Teague on 8/5/18.
//  Copyright © 2018 Dalton Teague. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate{
    
    
    //variables
    let storageRef = Storage.storage().reference()
    let databaseRef = Database.database().reference()
    
    var userUID: String = ""
    
    var circlesArr = [Circle]()
    var friendsArr = [String]()
    
    var canEdit: Bool = false
    var changedPic: Bool = false
    var alertFinished: Bool = false
    
    var originalAbout: String = ""
    var originalURL: String = ""
    
    //outlets
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var editImageIcon: UIImageView!
    
    @IBOutlet weak var circleList: UITableView!
    @IBOutlet weak var friendsList: UITableView!
    @IBOutlet weak var aboutUser: UITextView!
    @IBOutlet weak var editText: UILabel!
    
    @IBAction func backButton(_ sender: Any) {
        back()
    }
    
    @IBAction func editButton(_ sender: Any) {
        if (!canEdit) {
            canEdit = true
            aboutUser.isEditable = true
            editText.text = "Save Changes"
            editImageIcon.isHidden = false
        } else {
            canEdit = false
            aboutUser.isEditable = false
            editText.text = "Edit"
            editImageIcon.isHidden = true
            saveChanges()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        friendsList.dataSource = self
        friendsList.delegate = self
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
    
    //actions
    @IBAction func saveAction(_ sender: Any) {
        saveChanges()
    }
    @IBAction func logout(_ sender: Any) {
        logout()
    }
    @IBAction func uploadImage(_ sender: Any) {
        if (canEdit) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = true
            picker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(picker, animated: true, completion: nil)
            changedPic = true
        }
    }
    
    //functions
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.profileImageView.layer.cornerRadius = min(self.profileImageView.frame.size.width, self.profileImageView.frame.size.height) / 2
        self.profileImageView.clipsToBounds = true
    }
    
    
    //Pulls user data from firebase and links it to the storyboard UI elements
    func setupProfile() {
        
        if Auth.auth().currentUser?.uid == nil {
            logout()
        } else {
//            self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2;
//            self.profileImageView.clipsToBounds = true;
            
            if let uid = Auth.auth().currentUser?.uid {
                databaseRef.child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot)
                in
                if let dict = snapshot.value as? [String: AnyObject] {
                    self.username.text = dict["username"] as? String
                    let profileImageURL = dict["pic"] as? String
                    self.userUID = snapshot.key
                    
                    let about = dict["about"] as? String
                    if (about == "") {
                        self.aboutUser.text = "Add something about yourself!"
                        self.aboutUser.textColor = .lightGray
                    } else {
                        self.aboutUser.text = about
                        self.aboutUser.textColor = .darkGray
                    }
                    
                    self.aboutUser.isEditable = false
                    
                    //Used to tell if profile changes have been made
                    self.originalAbout = about ?? ""
                    self.originalURL = profileImageURL ?? ""
                    
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
                    let enumerator = snapshot.children
                    while let current = enumerator.nextObject() as? DataSnapshot {
                        if (current.key == "friends") {
                            let event = current.value as! [String: Any]
                            for friend in event {
                                print("Adding friend: ", friend.value)
                                self.friendsArr.append(friend.value as! String)
                                self.friendsList.reloadData()
                            }
                        }
                    }
                    
                })
            }
        }
    }
    
    func logout() {
        
        unsavedChangesAlert()
        
        do {
            try Auth.auth().signOut()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginViewController = storyboard.instantiateViewController(withIdentifier: "login") as! LoginViewController
            UIApplication.shared.keyWindow?.rootViewController = loginViewController
            UIApplication.shared.keyWindow?.makeKeyAndVisible()
            //present(loginViewController, animated: true, completion: nil)
        } catch {
            print("Exception thrown while logging out.")
        }
        
        
        self.performSegue(withIdentifier: "logout", sender: self)
    }
    
    func back() {
        
        unsavedChangesAlert()
        
        if (alertFinished) {
            print("dismissing back")
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    //If user has begun editing fields and attempts to exit the view,
    //create alert to check whether changes should be saved or discarded
    func unsavedChangesAlert() {
        
        if (canEdit && (changedPic || originalAbout != aboutUser.text)) {
            
            let alertController = UIAlertController(title: "", message:
                "You have unsaved changes. Do you want to save or discard them?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Save", style: .default, handler: { action in
                self.saveChanges()
                self.alertFinished = true
                self.dismiss(animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "Discard", style: .default, handler: { action in
                self.alertFinished = true
                self.dismiss(animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
                return
            }))
            
            self.present(alertController, animated: true, completion: nil)
            
        } else {
            
            self.dismiss(animated: true, completion: nil)
            
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
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
        
        let reducedImg = self.profileImageView.image?.resizeWithWidth(width: 100)
        let compressData = reducedImg?.pngData()!
        //max value is 1.0 and minimum is 0.0
        //let compressedImage = UIImage(data: compressData!)
        
        if let uploadData = compressData {
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
                                } else {
                                    self.changedPic = false
                                    print("set profile pic to: ", urlText)
                                }
                            })
                    }
                })
            }
        }
        
        self.databaseRef.child("users").child((Auth.auth().currentUser?.uid)!)
            .updateChildValues(["about" : aboutUser.text], withCompletionBlock: { (error, ref) in
                if error != nil {
                    print(error!)
                    return
                }
            })
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //sleep(1)
        if (tableView == circleList) {
            print("returning circles count of ", circlesArr.count)
            if circlesArr.count != 0 {
                return circlesArr.count
            }
        }
        if (tableView == friendsList) {
            print("returning friends count of ", friendsArr.count)
            if friendsArr.count != 0 {
                return friendsArr.count
            }
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //sleep(1)
        if (tableView == circleList) {
            print("table view was circle list")
            let cell:MyCustomCell = tableView.dequeueReusableCell(withIdentifier: "circleCell", for: indexPath) as! MyCustomCell
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
    } else if (tableView == friendsList) {
            print("table view was friend list")
            let cell:MyCustomCell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath) as! MyCustomCell
            cell.myView?.backgroundColor = UIColor.lightGray
            cell.userImage.layer.cornerRadius = cell.userImage.frame.size.width / 2;
            cell.userImage.clipsToBounds = true;
            if friendsArr.count != 0 {
                let friend = friendsArr[indexPath.row]
                print(friend)
                databaseRef.child("users").child(friend).observeSingleEvent(of: .value, with: { (snapshot)
                    in
                    if let dict = snapshot.value as? [String: AnyObject] {
                        print(dict["username"])
                        cell.eventName?.text = dict["username"] as? String
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
                                    cell.userImage.image = UIImage(data: data!)
                                }
                            }).resume()
                        }
                    }
                })
            }
            return cell
        
    }
        return MyCustomCell()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
