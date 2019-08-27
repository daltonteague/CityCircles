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

class CreateCircleViewController: UIViewController, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //variables
    let storageRef = Storage.storage().reference()
    let databaseRef = Database.database().reference(fromURL: "https://circle-chat-3cee4.firebaseio.com/")
    
    var dateString: String!
    let locationManager = CLLocationManager()
    var latitude: Double!
    var longitude: Double!
    var radius: String!
    var url: String!
    var color: String!
    //outlets
    @IBOutlet weak var eventName: UITextField!
    @IBOutlet weak var eventDescription: UITextView!
    @IBOutlet weak var endDate: UIDatePicker!
    @IBOutlet weak var isOpen: UISwitch!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var sizePicker: UIPickerView!
    @IBOutlet weak var circleImage: UIImageView!
    
    private let dataSource = ["Small", "Medium", "Large"]
    
    private var finished: Bool = false
    
    let db = Firestore.firestore()
    
    private let channelCellIdentifier = "channelCell"
    private var currentChannelAlertController: UIAlertController?
    
    private var channelReference: CollectionReference {
        return db.collection("channels")
    }
    
    public var channels = [Channel]()
    private var channelListener: ListenerRegistration?
    
    private let currentUser: User
    
    deinit {
        channelListener?.remove()
    }
    
    init(currentUser: User) {
        self.currentUser = currentUser
        super.init(coder: .init())!
        
        title = "Channels"
    }
    
    required init?(coder aDecoder: NSCoder) {
        //self.user = User()
        self.currentUser = Auth.auth().currentUser!
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem
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
        
        self.circleImage.layer.cornerRadius = self.circleImage.frame.size.width / 2;
        self.circleImage.clipsToBounds = true;
        
        sizePicker.dataSource = self
        sizePicker.delegate = self
        //radius = dataSource[0]
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        //latitude = locValue.latitude
        //longitude = locValue.longitude
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
        self.dismiss(animated: true)
    }
    
    //functions
    @IBAction func datePickerChanged(sender: UIDatePicker) {
        
        print("print \(sender.date)")
        
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "MMM dd, YYYY"
        dateString = dateFormatter.string(from: sender.date)
    }
    
    func finish() {
        if (!finished) {
            finished = true
            saveChanges()
        }
        
        
        //self.dismiss(animated:true, completion:nil)
        
    }
    
    func saveChanges() {
        
        let imageName = NSUUID().uuidString
        let storedImage = storageRef.child("profile_images").child(imageName)
        
        if let uploadData = self.circleImage.image!.pngData() {
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
                    self.url = url?.absoluteString
                    guard let name = self.eventName.text else {
                        print("Issue entering event name")
                        return
                    }
                    guard let desc = self.eventDescription.text else {
                        print("Issue entering event description")
                        return
                    }
                    let date = "\(self.endDate.date)"
                    
                    let circleOpen = self.isOpen.isOn
                    
                    guard let user = Auth.auth().currentUser?.uid else {
                        return
                    }
                    
                    let newCircleRef = self.databaseRef
                        .child("circle")
                        .childByAutoId()
                    
                    let newCircleData = [
                        "name" : name,
                        "description" : desc,
                        "end_date" : date,
                        "open" : circleOpen,
                        "user" : user,
                        "radius" : self.radius as Any,
                        "lat" : self.latitude as Any,
                        "lon" : self.longitude as Any,
                        "image" : self.url as Any,
                        "views" : "0",
                        "color" : self.color as Any
                        ] as [String : Any]
                    
                    newCircleRef.setValue(newCircleData)
                    
                    //Add a chat channel to the database connected to this circle
                    self.createChannel()
                    
                    
                    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                    let mapvc = storyBoard.instantiateViewController(withIdentifier: "mapIdentifier") as! MapViewController
                    UIApplication.shared.keyWindow?.rootViewController = mapvc
                    UIApplication.shared.keyWindow?.makeKeyAndVisible()
                })
            }
        }
        
    }
    
    
    
    private func createChannel() {
        
        guard let channelName = eventName.text else {
            return
        }
        
        let channel = Channel(name: channelName)
        channelReference.addDocument(data: channel.representation) { error in
            if let e = error {
                print("Error saving channel: \(e.localizedDescription)")
            }
        }
        
        channels.append(channel)
        channels.sort()
        
        
        if let presenter = presentingViewController as? MapViewController {
            presenter.channels.append(channel)
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
            circleImage.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
}

extension CreateCircleViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //radius = dataSource[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dataSource[row]
    }
    
}
