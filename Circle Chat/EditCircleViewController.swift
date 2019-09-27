//
//  CreateCircleViewController.swift
//  Circle Chat
//
//  Created by Dalton Teague on 6/23/19.
//  Copyright © 2019 Dalton Teague. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation
import Firebase
import FirebaseFirestore

class EditCircleViewController: UIViewController, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    var circleNameString: String! = ""
    var circleDescString: String! = ""
    var circleDateString: String! = ""
    var viewCount: String! = ""
    var circleID: String! = ""
    var username: String! = ""
    var circleImage: UIImage!
    var timestamp: Timestamp = Timestamp.init()
    
    //copies of what these values start as, to alert
    //user before leaving unsaved changes
    var originalName: String! = ""
    var originalDesc: String! = ""
    var originalDate: String! = ""
    var originalImage: UIImage!
    var originalSize: String! = ""
    
    //variables
    let storageRef = Storage.storage().reference()
    let databaseRef = Database.database().reference(fromURL: "https://circle-chat-3cee4.firebaseio.com/")

    private let db = Firestore.firestore()
    
    var dateString: String!
    let locationManager = CLLocationManager()
    var latitude: Double!
    var longitude: Double!
    var radius: String!
    var url: String!
    //outlets
    @IBOutlet weak var eventName: UITextField!
    @IBOutlet weak var eventDescription: UITextView!
    @IBOutlet weak var circleImageView: UIImageView!
    @IBOutlet weak var isOpen: UISwitch!
    @IBOutlet weak var sizePicker: UIPickerView!
    @IBOutlet weak var endDate: UIDatePicker!
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    private let dataSource = ["Small", "Medium", "Large"]
    var saved: Bool = false
    var alertFinished: Bool = false
    
    var parentvc: PreviewCircleViewController!
    
    private let channelCellIdentifier = "channelCell"
    private var currentChannelAlertController: UIAlertController?
    
    private var channelReference: CollectionReference {
        return db.collection("channels")
    }
    
    private var channelListener: ListenerRegistration?
    
    private let currentUser: User
    
    deinit {
        channelListener?.remove()
    }
    
    init(currentUser: User) {
        self.currentUser = currentUser
        parentvc = PreviewCircleViewController()
        print("init")
        super.init(coder: .init())!
        
        title = "Channels"
    }
    
    required init?(coder aDecoder: NSCoder) {
        //self.user = User()
        print("int")
        self.currentUser = Auth.auth().currentUser!
        parentvc = PreviewCircleViewController()
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("load")
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        
        channelListener = channelReference.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }
        }
        
        eventName.text = circleNameString
        eventName.delegate = self
        eventDescription.text = circleDescString
        eventDescription.delegate = self
        endDate.date = timestamp.dateValue()
        originalName = circleNameString
        originalDesc = circleDescString
        originalDate = dateString
        
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
                            self.circleImageView.image = self.circleImage
                            self.originalImage = self.circleImage
                        }
                    }).resume()
                }
            }
        })
        //self.circleImageView.image = circleImage
        sizePicker.dataSource = self
        sizePicker.delegate = self
        radius = dataSource[0]
        originalSize = radius
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        latitude = locValue.latitude
        longitude = locValue.longitude
    }
    
    @IBAction func uploadImage(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerController.SourceType.photoLibrary
        self.present(picker, animated: true, completion: nil)
    }
    
    //actions
    @IBAction func finishButton(_ sender: Any) {
        finish()
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        
        unsavedChangesAlert()
        
        if (alertFinished) {
            print("dismissing back")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func deleteButton(_ sender: Any) {
        deleteCircle()
    }
    
    //functions
    @IBAction func datePickerChanged(sender: UIDatePicker) {
        
        print("print \(sender.date)")
        
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "MMM dd, YYYY"
        dateString = dateFormatter.string(from: sender.date)
    }
    
    
    func finish() {
        
        saveChanges()
        
        guard let name = eventName.text else {
            print("Issue entering event name")
            return
        }
        guard let desc = eventDescription.text else {
            print("Issue entering event description")
            return
        }
        let date = "\(endDate.date)"
        
        let circleOpen = isOpen.isOn
        guard let currentRadius = radius else {
            print("Issue entering radius")
            return
        }
        guard let user = Auth.auth().currentUser?.uid else {
            return
        }
        
        
        let key = databaseRef.child("circle").child(circleID).key
        let post = [
            "name" : name,
            "description" : desc,
            "end_date" : date,
            "open" : circleOpen,
            "user" : user,
            "radius" : currentRadius,
            "lat" : latitude as Any,
            "lon" : longitude as Any,
            "image" : url as Any,
            "views" : "0"
            ] as [String : Any]
        let childUpdates = ["/posts/\\(key)": post,
                            "/user-posts/\\(userID)/\\(key)/": post]
        self.databaseRef.child("circle").child(self.circleID)
            .updateChildValues(post)
        
//        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
//        let mapvc = storyBoard.instantiateViewController(withIdentifier: "mapIdentifier") as! MapViewController
//        UIApplication.shared.keyWindow?.rootViewController = mapvc
//        UIApplication.shared.keyWindow?.makeKeyAndVisible()
        saved = true
            print("parent is ", self.parentvc)
            //let vc = self.presentingViewController as! PreviewCircleViewController
            self.parentvc.circleNameString = eventName.text
            self.parentvc.circleDescString = eventDescription.text
            self.parentvc.circleDateString = circleDateString
            self.parentvc.circleImage = circleImage
            self.parentvc.fromEdit = true
        
        self.dismiss(animated:true, completion:nil)
        
    }
    
    func deleteCircle() {
        
        let alertController = UIAlertController(title: "", message:
            "Are you sure you want to delete this circle?", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Delete", style: .default, handler: { action in
            
            self.db.collection("channels").document(self.circleID).delete()
            
                print("removed ", self.circleNameString, " ", self.circleID)
            self.databaseRef.child("circle").child(self.circleID).removeValue()
            
            self.performSegue(withIdentifier: "mapIdentifier", sender: nil)
       
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
            return
        }))
        
        self.present(alertController, animated: true, completion: nil)
        
        
    }
    
    //If user has begun editing fields and attempts to exit the view,
    //create alert to check whether changes should be saved or discarded
    func unsavedChangesAlert() {
        
        if (originalName != circleNameString || originalDesc != circleDescString || originalDate != dateString || originalImage != circleImage || originalSize != radius) {
            
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
            
        }
    }
    
    func saveChanges() {
        
        let imageName = NSUUID().uuidString
        let storedImage = storageRef.child("profile_images").child(imageName)
        
        let reducedImg = self.circleImage.resizeWithWidth(width: 125)
        let compressData = reducedImg?.pngData()!
        
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
                        self.databaseRef.child("circle").child(self.circleID)
                            .updateChildValues(["image" : urlText], withCompletionBlock: { (error, ref) in
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
    
    func cancel() {
        saved = false
        self.dismiss(animated:true, completion:nil)
    }
    
    override func didMove(toParent parent: UIViewController?) {
        if (saved) {
            let vc = parent as! PreviewCircleViewController
            
            vc.circleNameString = circleNameString
            vc.circleDescString = circleDescString
            vc.circleDateString = circleDateString
            vc.circleID = circleID
            vc.viewCount = viewCount
            vc.circleImage = circleImage
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
            circleImage = selectedImage
            circleImageView.image = circleImage
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

extension EditCircleViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        radius = dataSource[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dataSource[row]
    }
    
    
}
