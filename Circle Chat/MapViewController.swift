//
//  MapViewController.swift
//  Circle Chat
//
//  Created by Dalton Teague on 6/15/18.
//  Copyright © 2018 Dalton Teague. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase
import FirebaseFirestore

struct Circle {
    var name:String
    var desc:String
    var open:Bool
    var endDate:String
    var userID:String
    var circleID:String
    var size:String
    var viewCount: String
}

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBAction func redButton(_ sender: Any) {
        placementMarker.image = UIImage(named: "pin red.png")
        clearButtonBackgrounds()
        redButtonView.setBackgroundImage(UIImage(named: "selected.png"), for: .normal)
        createCircleColor = "red"
    }
    @IBAction func orangeButton(_ sender: Any) {
        placementMarker.image = UIImage(named: "pin orange.png")
        clearButtonBackgrounds()
        orangeButtonView.setBackgroundImage(UIImage(named: "selected.png"), for: .normal)
        createCircleColor = "orange"
    }
    @IBAction func yellowButton(_ sender: Any) {
        placementMarker.image = UIImage(named: "pin yellow.png")
        clearButtonBackgrounds()
        yellowButtonView.setBackgroundImage(UIImage(named: "selected.png"), for: .normal)
        createCircleColor = "yellow"
    }
    @IBAction func greenButton(_ sender: Any) {
        placementMarker.image = UIImage(named: "pin green.png")
        clearButtonBackgrounds()
        greenButtonView.setBackgroundImage(UIImage(named: "selected.png"), for: .normal)
        createCircleColor = "green"
    }
    @IBAction func blueButton(_ sender: Any) {
        placementMarker.image = UIImage(named: "pin blue.png")
        clearButtonBackgrounds()
        blueButtonView.setBackgroundImage(UIImage(named: "selected.png"), for: .normal)
        createCircleColor = "blue"
    }
    @IBAction func purpleButton(_ sender: Any) {
        placementMarker.image = UIImage(named: "pin purple.png")
        clearButtonBackgrounds()
        purpleButtonView.setBackgroundImage(UIImage(named: "selected.png"), for: .normal)
        createCircleColor = "purple"
    }
    @IBOutlet weak var redButtonView: UIButton!
    @IBOutlet weak var orangeButtonView: UIButton!
    @IBOutlet weak var yellowButtonView: UIButton!
    @IBOutlet weak var greenButtonView: UIButton!
    @IBOutlet weak var blueButtonView: UIButton!
    @IBOutlet weak var purpleButtonView: UIButton!
    
    
    @IBAction func smallButton(_ sender: Any) {
        showCircleRadius()
        createCircleRadius = "small"
        mediumButtonView.setBackgroundImage(nil, for: .normal)
        largeButtonView.setBackgroundImage(nil, for: .normal)
        smallButtonView.setBackgroundImage(UIImage(named: "selected.png"), for: .normal)
    }
    @IBAction func mediumButton(_ sender: Any) {
        showCircleRadius()
        createCircleRadius = "medium"
        smallButtonView.setBackgroundImage(nil, for: .normal)
        largeButtonView.setBackgroundImage(nil, for: .normal)
        mediumButtonView.setBackgroundImage(UIImage(named: "selected.png"), for: .normal)
    }
    @IBAction func largeButton(_ sender: Any) {
        showCircleRadius()
        createCircleRadius = "large"
        smallButtonView.setBackgroundImage(nil, for: .normal)
        mediumButtonView.setBackgroundImage(nil, for: .normal)
        largeButtonView.setBackgroundImage(UIImage(named: "selected.png"), for: .normal)
    }
    
    
    @IBOutlet weak var smallButtonView: UIButton!
    @IBOutlet weak var mediumButtonView: UIButton!
    @IBOutlet weak var largeButtonView: UIButton!
    
    
    @IBOutlet weak var placementMarker: UIImageView!
    @IBOutlet weak var toolBarView: UITextView!
    @IBOutlet weak var createCircleButtonView: UIButton!
    @IBOutlet weak var optionsButtonView: UIButton!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var circleList: UITableView!
    
    @IBOutlet weak var profileButton: UIButton!
    @IBAction func visitProfile(_ sender: Any) {
        let button = sender as! UIButton
        selectedUser = circlesArr[button.tag].userID
        print("visiting profile of: ", selectedUser)
        visitProfile()
    }
    @IBAction func createCircleButton(_ sender: Any) {
        createCircle()
    }
    @IBAction func optionsButton(_ sender: Any) {
        if (placingMarker) {
            cancelPlacement()
        } else {
            self.performSegue(withIdentifier: "options", sender: self)
        }
    }
    
    @IBAction func openPreview(_ sender: Any) {
        openPreview()
    }
    
    var selectedUser: String! = ""
    var createCircleColor: String! = "blue"
    var createCircleRadius: String! = "medium"
    var center: CLLocationCoordinate2D!
    var overlayPreview: MKCircle!
    
    var locationManager = CLLocationManager()
    let regionRadius: CLLocationDistance = 1000
    var lastUserLocation: CLLocation!
    var selectedAnnotation: MKPointAnnotation?
    
    var reinstantiate: Bool = false
    var placingMarker: Bool = false
    var prevSelected: MKPointAnnotation?
    
    var numEvents: Int!
    var circlesArr = [Circle]()
    var channels: [Channel] = []
    
    let databaseRef = Database.database().reference(fromURL: "https://circle-chat-3cee4.firebaseio.com/")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let statWindow = UIApplication.shared.value(forKey:"statusBarWindow") as! UIView
        let statusBar = statWindow.subviews[0] as UIView
        statusBar.backgroundColor = UIColor.white.withAlphaComponent(0.45)
        
        //let appDelegate = UIApplication.shared.delegate
        //appDelegate?.window??.rootViewController = self
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        if (circlesArr.count > 0) {
            circleList.dataSource = self
            circleList.delegate = self
        }
        
        mapView.showsUserLocation = true
        mapView.showAnnotations(self.mapView.annotations, animated: true)
        
        placementMarker.isHidden = true;
        mediumButtonView.setBackgroundImage(UIImage(named: "selected.png"), for: .normal)
        blueButtonView.setBackgroundImage(UIImage(named: "selected.png"), for: .normal)
        hideButtons()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("map view appears")
        
        if (self.selectedAnnotation != nil) {
            
            let annotationLocation = CLLocation(latitude: (selectedAnnotation?.coordinate.latitude)!, longitude: (selectedAnnotation?.coordinate.longitude)!)
            centerMapOnLocation(location: annotationLocation)
            
            for i in (0 ..< circlesArr.count) {
                if (self.selectedAnnotation?.title == circlesArr[i].name) {
                    databaseRef.child("circle").child(circlesArr[i].circleID).observeSingleEvent(of: .value, with: { (snapshot)
                        in
                        if let dict = snapshot.value as? [String: AnyObject] {
                            self.selectedAnnotation?.title = dict["name"] as? String
                            self.circlesArr[i].name = dict["name"] as! String
                            self.circlesArr[i].desc = dict["description"] as! String
                            self.circlesArr[i].endDate = dict["end_date"] as! String
                            self.circlesArr[i].open = dict["open"] as! Bool
                            self.circlesArr[i].size = dict["radius"] as! String
                            
                            self.selectedUser = dict["user"] as? String
                            
                            let indexPath = IndexPath(row: i, section: 0)
                            let cell = self.circleList.cellForRow(at: indexPath) as! MyCustomCell
                            cell.eventName.text = dict["name"] as? String
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
                }
            }
        }
    }
    
    func visitProfile() {
        self.performSegue(withIdentifier: "userProfile", sender: self)
    }
    
    func openPreview() {
        if (selectedAnnotation != nil) {
            self.performSegue(withIdentifier: "previewCircle", sender: self)
        }
    }
    
    func hideButtons() {
        
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
            self.redButtonView.frame.origin.x -= 150
            self.orangeButtonView.frame.origin.x -= 150
            self.yellowButtonView.frame.origin.x -= 150
            self.greenButtonView.frame.origin.x -= 150
            self.blueButtonView.frame.origin.x -= 150
            self.purpleButtonView.frame.origin.x -= 150
            self.smallButtonView.frame.origin.x += 150
            self.mediumButtonView.frame.origin.x += 150
            self.largeButtonView.frame.origin.x += 150
        }, completion: { finished in
            print("Hid buttons!")
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("prefilling")
        switch(CLLocationManager.authorizationStatus()) {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .denied, .notDetermined, .restricted:
            locationManager.stopUpdatingLocation()
        @unknown default:
            locationManager.stopUpdatingLocation()
        }
        fillArray()
    }
    
    func fillArray() {
        
        if (circlesArr.count > 0) {
            circleList.dataSource = self
            circleList.delegate = self
        }
        
        print("filling")
        databaseRef.child("circle").observeSingleEvent(of: .value) { snapshot in
            let enumerator = snapshot.children
            self.lastUserLocation = self.locationManager.location
            
            while let current = enumerator.nextObject() as? DataSnapshot {
                let event = current.value as! [String: Any]
                let lat = event["lat"] as! Double
                let lon = event["lon"] as! Double
                print("lat and lon", lat, lon)
                let eventLoc = CLLocation(latitude: lat, longitude: lon)
                print("Distance from current location: ", eventLoc.distance(from: self.lastUserLocation))
                if (eventLoc.distance(from: self.lastUserLocation) <= 2000) {
                    
                    let radius: Double
                    let size = event["radius"] as? String
                    switch(size) {
                        case "small":
                            radius = 50
                            break
                        case "medium":
                            radius = 200
                            break
                        case "large":
                            radius = 600
                            break
                        default:
                            radius = 200
                    }
                    
                    let eventCircle = MKCircle.init(center: eventLoc.coordinate, radius: radius as CLLocationDistance)
                    
                    let annotation = MKPointAnnotation.init()
                    annotation.coordinate = CLLocationCoordinate2DMake(lat, lon)
                    annotation.title = event["name"] as? String
                    annotation.subtitle  = event["color"] as? String
                    
                    
                    print("adding ", event["name"] as? String as Any, " annotation with radius ", radius)
                    self.mapView.addAnnotation(annotation)
                    self.mapView.addOverlay(eventCircle)
                    
                    let newCircle = Circle(name: (event["name"] as? String)!, desc: (event["description"] as? String)!,
                                           open: (event["open"] as? Bool)!, endDate: (event["end_date"] as? String)!, userID: (event["user"] as? String)!, circleID: current.key, size: (event["radius"] as? String)!, viewCount: (event["views"] as? String)!)
                    
                    self.circlesArr.append(newCircle)
                    
                    self.circleList.dataSource = self
                    self.circleList.delegate = self
                    self.circleList.reloadData()
                    self.mapView.showAnnotations(self.mapView.annotations, animated: true)
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        print("got to viewForAnnotatin")
        if annotation is MKUserLocation {
            return nil
        }
        let color = annotation.subtitle
        
        let identifier = "MyCustomAnnotation"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = false
            
            switch(color) {
            case "red":
                annotationView!.image = UIImage(named: "pin red.png")
                break;
            case "blue":
                annotationView!.image = UIImage(named: "pin blue.png")
                break;
            case "black":
                annotationView!.image = UIImage(named: "pin black.png")
                break;
            case "green":
                annotationView!.image = UIImage(named: "pin green.png")
                break;
            case "yellow":
                annotationView!.image = UIImage(named: "pin yellow.png")
                break;
            case "orange":
                annotationView!.image = UIImage(named: "pin orange.png")
                break;
            case "purple":
                annotationView!.image = UIImage(named: "pin purple.png")
                break;
            default:
                annotationView!.image = UIImage(named: "pin blue.png")
                break;
            }
            
            annotationView?.centerOffset = CGPoint(x: 0, y: -(annotationView?.image?.size.height)! / 2)
            
        } else {
            annotationView!.annotation = annotation
        }
        
        return annotationView
    }
    
    func createCircle() {
        if (!placingMarker) {
            placingMarker = true
            showCircleRadius()
            selectLocation()
        } else {
            self.performSegue(withIdentifier: "createCircle", sender: self)
        }
    }
    
    
    func selectLocation() {
        
        self.placementMarker.isHidden = false;
        self.createCircleButtonView.setImage(UIImage(named: "check icon.png"), for: .normal)
        self.optionsButtonView.setImage(UIImage(named: "cancel icon.png"), for: .normal)
        self.toolBarView.text = "Place Circle"
        
        UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveLinear, animations: {
            
            
            self.view.translatesAutoresizingMaskIntoConstraints = true
            self.toolBarView.translatesAutoresizingMaskIntoConstraints = true
            self.circleList.translatesAutoresizingMaskIntoConstraints = true
            self.placementMarker.translatesAutoresizingMaskIntoConstraints = true
            
            var toolBarFrame = self.toolBarView.frame
            var circleListFrame = self.circleList.frame
            var mapFrame = self.mapView.frame
            circleListFrame.origin.y += 220
            toolBarFrame.origin.y += 220
            mapFrame.size.height += 300
            mapFrame.origin.y += 30
            self.placementMarker.frame.origin.y += 350
            self.createCircleButtonView.frame.origin.y += 220
            self.optionsButtonView.frame.origin.y += 220
            self.toolBarView.frame = toolBarFrame
            self.circleList.frame = circleListFrame
            self.mapView.frame = mapFrame
            self.redButtonView.frame.origin.x += 150
            self.orangeButtonView.frame.origin.x += 150
            self.yellowButtonView.frame.origin.x += 150
            self.greenButtonView.frame.origin.x += 150
            self.blueButtonView.frame.origin.x += 150
            self.purpleButtonView.frame.origin.x += 150
            self.smallButtonView.frame.origin.x -= 150
            self.mediumButtonView.frame.origin.x -= 150
            self.largeButtonView.frame.origin.x -= 150
        }, completion: { finished in
            print("Moved list!")
            self.view.translatesAutoresizingMaskIntoConstraints = true
            self.toolBarView.translatesAutoresizingMaskIntoConstraints = true
            self.circleList.translatesAutoresizingMaskIntoConstraints = true
            self.placementMarker.translatesAutoresizingMaskIntoConstraints = true
            self.toolBarView.layoutIfNeeded()
            self.view.layoutIfNeeded()
        })
        
    }
    
    
    
    func cancelPlacement() {
        placingMarker = false
        
        self.placementMarker.isHidden = true;
        self.createCircleButtonView.setImage(UIImage(named: "plus white.png"), for: .normal)
        self.optionsButtonView.setImage(UIImage(named: "options.png"), for: .normal)
        self.toolBarView.text = "Nearby"
        
        UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveLinear, animations: {
            
            
            self.view.translatesAutoresizingMaskIntoConstraints = true
            self.toolBarView.translatesAutoresizingMaskIntoConstraints = true
            self.circleList.translatesAutoresizingMaskIntoConstraints = true
            self.placementMarker.translatesAutoresizingMaskIntoConstraints = true
            
            var toolBarFrame = self.toolBarView.frame
            var circleListFrame = self.circleList.frame
            var mapFrame = self.mapView.frame
            circleListFrame.origin.y -= 220
            toolBarFrame.origin.y -= 220
            mapFrame.size.height -= 300
            mapFrame.origin.y -= 30
            self.placementMarker.frame.origin.y -= 350
            self.createCircleButtonView.frame.origin.y -= 220
            self.optionsButtonView.frame.origin.y -= 220
            self.toolBarView.frame = toolBarFrame
            self.circleList.frame = circleListFrame
            self.mapView.frame = mapFrame
            self.redButtonView.frame.origin.x -= 150
            self.orangeButtonView.frame.origin.x -= 150
            self.yellowButtonView.frame.origin.x -= 150
            self.greenButtonView.frame.origin.x -= 150
            self.blueButtonView.frame.origin.x -= 150
            self.purpleButtonView.frame.origin.x -= 150
            self.smallButtonView.frame.origin.x += 150
            self.mediumButtonView.frame.origin.x += 150
            self.largeButtonView.frame.origin.x += 150
        }, completion: { finished in
            print("Moved list!")
            self.view.translatesAutoresizingMaskIntoConstraints = true
            self.toolBarView.translatesAutoresizingMaskIntoConstraints = true
            self.circleList.translatesAutoresizingMaskIntoConstraints = true
            self.placementMarker.translatesAutoresizingMaskIntoConstraints = true
            self.toolBarView.layoutIfNeeded()
            self.view.layoutIfNeeded()
        })
    }
    
    func showCircleRadius() {
    
        let radius: Double
        let size = createCircleRadius
        switch(size) {
        case "small":
            radius = 50
            break
        case "medium":
            radius = 200
            break
        case "large":
            radius = 600
            break
        default:
            radius = 200
        }
        //updatePreviewOverlay(radius: radius)
    }
    
    func updatePreviewOverlay(radius: Double) {
        for overlay in mapView.overlays {
            if (overlayPreview != nil && overlay.isEqual(overlayPreview as MKOverlay)) {
                mapView.removeOverlay(overlay)
            }
        }
        overlayPreview = MKCircle.init(center: mapView.centerCoordinate, radius: radius as CLLocationDistance)
        mapView.addOverlay(overlayPreview)
    }
    
    func clearButtonBackgrounds() {
        redButtonView.setBackgroundImage(nil, for: .normal)
        orangeButtonView.setBackgroundImage(nil, for: .normal)
        yellowButtonView.setBackgroundImage(nil, for: .normal)
        greenButtonView.setBackgroundImage(nil, for: .normal)
        blueButtonView.setBackgroundImage(nil, for: .normal)
        purpleButtonView.setBackgroundImage(nil, for: .normal)
    }
    
    func addRadiusCircle(location: CLLocation){
        self.mapView.delegate = self
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        center = mapView.centerCoordinate
        if (placingMarker) {
            showCircleRadius()
        }
    }
    
    //renders the circle overlay
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle && !overlay.isEqual(overlayPreview){
            
            let circle = MKCircleRenderer(overlay: overlay)
            let annotations = self.mapView.annotations
            
            for annotation in annotations {
                if (annotation.coordinate.latitude == overlay.coordinate.latitude &&
                    annotation.coordinate.longitude == overlay.coordinate.longitude) {
                    print("found matching annotation")
                    let color = annotation.subtitle
                    
                    switch(color) {
                    case "red":
                        circle.fillColor = UIColor.red.withAlphaComponent(0.1)
                        circle.strokeColor = UIColor.red
                        break;
                    case "blue":
                        circle.fillColor = UIColor.blue.withAlphaComponent(0.1)
                        circle.strokeColor = UIColor.blue
                        break;
                    case "black":
                        circle.fillColor = UIColor.black.withAlphaComponent(0.1)
                        circle.strokeColor = UIColor.black
                        break;
                    case "green":
                        circle.fillColor = UIColor.green.withAlphaComponent(0.1)
                        circle.strokeColor = UIColor.green
                        break;
                    case "yellow":
                        circle.fillColor = UIColor.yellow.withAlphaComponent(0.1)
                        circle.strokeColor = UIColor.yellow
                        break;
                    case "orange":
                        circle.fillColor = UIColor.orange.withAlphaComponent(0.1)
                        circle.strokeColor = UIColor.orange
                        break;
                    case "purple":
                        circle.fillColor = UIColor.purple.withAlphaComponent(0.1)
                        circle.strokeColor = UIColor.purple
                        break;
                    default:
                        circle.fillColor = UIColor.blue.withAlphaComponent(0.1)
                        circle.strokeColor = UIColor.blue
                        break;
                    }
                }
            }
            circle.lineWidth = 1
            return circle
        } else {
            print("made it to renderer")
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    //determines the user location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        lastUserLocation = location
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.mapView.setRegion(region, animated: true)
        //addRadiusCircle(location: location)
    }
    
    //uses user location to set mapview region
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion.init(center: location.coordinate,
                                                                  latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //sleep(1)
        if circlesArr.count != 0 {
            return circlesArr.count
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //sleep(1)
        let cell:MyCustomCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MyCustomCell
        cell.myView?.backgroundColor = UIColor.white
        cell.userImage.layer.cornerRadius = cell.userImage.frame.size.width / 2;
        cell.userImage.clipsToBounds = true;
        if circlesArr.count != 0 {
            let circle = circlesArr[indexPath.row]
            //cell.userImage = databaseRef.child("users").child(circle.userID)
            
        databaseRef.child("users").child(circle.userID).observeSingleEvent(of: .value, with: { (snapshot)
                in
                if let dict = snapshot.value as? [String: AnyObject] {
                    cell.eventUser?.text = dict["username"] as? String
                }
            })
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
            cell.profileButton.tag = indexPath.row
        }
        return cell
    }
    
    //handles selection of circle map annotations
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let selected = view.annotation as? MKPointAnnotation else { return }
        print(" annotations are ", view.annotation, " selected: ", selected)
        openCirclePreview(mapView: mapView, view: selected)
    }
    
    func openCirclePreview(mapView: MKMapView, view: MKPointAnnotation) {
        self.selectedAnnotation = view
        if (self.selectedAnnotation != nil) {
            let annotationLocation = CLLocation(latitude: (self.selectedAnnotation?.coordinate.latitude)!, longitude: (self.selectedAnnotation?.coordinate.longitude)!)
            centerMapOnLocation(location: annotationLocation)
            
            for i in (0 ..< circlesArr.count) {
                if (self.selectedAnnotation?.title == circlesArr[i].name) {
                    let indexPath = IndexPath(row: i, section: 0)
                    self.circleList.scrollToRow(at: indexPath, at: .top, animated: true)
                    self.circleList.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition(rawValue: 0)!)
                }
            }
            
            //let previewCircle = (storyboard?.instantiateViewController(withIdentifier: "preview"))! as! PreviewCircleViewController
            //present(previewCircle, animated: true, completion: nil)
            //self.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.performSegue(withIdentifier: "previewCircle", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        print("segue bitch into ", segue.identifier as Any)
        if segue.identifier == "previewCircle"
        {
            let vc = segue.destination as? PreviewCircleViewController
            vc?.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            for i in (0 ..< circlesArr.count) {
                print("compare ", self.selectedAnnotation?.title as Any, " with ", circlesArr[i].name)
                if (self.selectedAnnotation?.title == circlesArr[i].name) {
                    print("setting them bitches")
                    vc?.circleNameString = circlesArr[i].name
                    vc?.circleDescString = circlesArr[i].desc
                    vc?.circleDateString = circlesArr[i].endDate
                    vc?.circleID = circlesArr[i].circleID
                    vc?.viewCount = circlesArr[i].viewCount
                    vc?.parentvc = self
                }
            }
        } else if segue.identifier == "userProfile"
        {
            let vc = segue.destination as? UserViewController
            vc?.userUID = self.selectedUser
        } else if segue.identifier == "createCircle" {
            let vc = segue.destination as? CreateCircleViewController
            vc?.color = createCircleColor
            vc?.latitude = center.latitude
            vc?.longitude = center.longitude
            vc?.radius = createCircleRadius
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let eventName = circlesArr[indexPath.item].name
        for annotation in mapView.annotations as [MKAnnotation] {
            if eventName == annotation.title {
                selectedAnnotation = annotation as! MKPointAnnotation
                let annotationLocation = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
                centerMapOnLocation(location: annotationLocation)
            }
            
        }
        
    }
    
}

class SegueFromLeft: UIStoryboardSegue {
    override func perform() {
        let src = self.source
        let dst = self.destination
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: -src.view.frame.size.width, y: 0)
        
        UIView.animate(withDuration: 0.25,
                       delay: 0.0,
                       options: .curveEaseInOut,
                       animations: {
                        dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
        },
                       completion: { finished in
                        src.present(dst, animated: false, completion: nil)
        }
        )
    }
}
