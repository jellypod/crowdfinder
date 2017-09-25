import UIKit
import SwiftLocation
import CoreLocation
import MapKit
import FirebaseDatabase
import GoogleMaps
class ViewController: UIViewController,CLLocationManagerDelegate{
    
    let clusteringManager = FBClusteringManager()
    let configuration = FBAnnotationClusterViewConfiguration.default()
    @IBOutlet private var textView: UITextView?
    @IBOutlet weak var mapView: MKMapView!
    var locManager = CLLocationManager()
    var currentLocation: CLLocation!
    let regionRadius: CLLocationDistance = 500
    var uuid:String = ""
    var userpositions = [FBAnnotation]()
    var array:[FBAnnotation] = []
    var myInfo:String = "32|Male"
    var interest:String = "28 - 32|Female"
    var ref:DatabaseReference!
    var addressFromGoogle:String = ""
    var apikey:String = "AIzaSyBFGiusWvcQBKYM2wxFRgGDZIJW3dDooTg"
    var nearestLocations: [CLLocation] = []
    
    @IBOutlet weak var myLoc: UIButton!
    
    @IBOutlet weak var overlayView: UIView!
    
    var isTimerRunning = false
    
    @IBOutlet weak var toggleOnlineSwitch: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.layer.cornerRadius = 4
        
        ref = Database.database().reference(fromURL: "https://crowdfinder-1dot0.firebaseio.com/")
        locManager.delegate = self
        locManager.requestAlwaysAuthorization()
        clusteringManager.delegate = self
        mapView.delegate = self
        
        getUserDefaultData()
        startScanning()
        let status  = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
            locManager.requestWhenInUseAuthorization()
            return
        }
        
        if status == .denied || status == .restricted {
            let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable Location Services in Settings", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            
            present(alert, animated: true, completion: nil)
            return
        }
        
        
        
        //get user's current loc and add to firebase, also monitor for changes in the same place.
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            currentLocation = locManager.location
            
            Location.getLocation(accuracy: .house, frequency: .oneShot, success: { (_, location) in
                ////print("new loc: \(location)")
                if self.toggleOnlineSwitch.isOn{
                    var nearestLoc = self.fetchPlacesNearCoordinate(coordinate:location.coordinate,radius:500) as? CLLocation
                    if nearestLoc != nil{
                        let latlngString:String = "\(nearestLoc!.coordinate.latitude),\(nearestLoc!.coordinate.longitude)"
                        
                        // let latlngString:String = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                        self.ref.child("crowddata").child(self.uuid).setValue(
                            [
                                "interest": self.interest,
                                "myinfo": self.myInfo,
                                "currlatlng":"\(latlngString)"
                            ]
                        )
                    }
                    else{
                        let latlngString:String = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                        self.ref.child("crowddata").child(self.uuid).setValue(
                            [
                                "interest": self.interest,
                                "myinfo": self.myInfo,
                                "currlatlng":"\(latlngString)"
                            ]
                        )
                        
                    }
                    
                }
                self.centerMapOnLocation(location: location)
                self.mapView.showsUserLocation = true
                
            }) { (request, last, error) in
                request.cancel() // stop continous location monitoring on error
                ////print("Location monitoring failed due to an error \(error)")
            }
            
            
            Location.getLocation(accuracy: .house, frequency: .significant, success: { (_, location) in
                ////print("new loc: \(location)")
                if self.toggleOnlineSwitch.isOn{
                    var nearestLoc = self.fetchPlacesNearCoordinate(coordinate:location.coordinate,radius:500) as? CLLocation
                    if nearestLoc != nil{
                        let latlngString:String = "\(nearestLoc!.coordinate.latitude),\(nearestLoc!.coordinate.longitude)"
                        // let latlngString:String = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                        self.ref.child("crowddata").child(self.uuid).setValue(
                            [
                                "interest": self.interest,
                                "myinfo": self.myInfo,
                                "currlatlng":"\(latlngString)"
                            ]
                        )
                    }else{
                        let latlngString:String = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                        self.ref.child("crowddata").child(self.uuid).setValue(
                            [
                                "interest": self.interest,
                                "myinfo": self.myInfo,
                                "currlatlng":"\(latlngString)"
                            ]
                        )
                    }
                    
                    //self.fetchPlacesNearCoordinate(coordinate:location.coordinate,radius:500)
                    
                }
                self.centerMapOnLocation(location: location)
                self.mapView.showsUserLocation = true
                
                
            }) { (request, last, error) in
                request.cancel() // stop continous location monitoring on error
                ////print("Location monitoring failed due to an error \(error)")
            }
            
            
            
            //observer other user's logins and movements.
            ref.observe(.childAdded, with: { (snapshot) -> Void in
                ////print("added") //someone logged in...
                self.addAnnotations()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.clusteringManager.delegate = self
                    self.mapView.delegate = self
                    self.clusteringManager.removeAll()
                    self.clusteringManager.add(annotations: self.array)
                    self.mapView.annotations.reversed()
                }
            })
            
            ref.observe(.childRemoved, with: { (snapshot) -> Void in
                ////print("removed") //someone logged out...
                self.addAnnotations()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.clusteringManager.delegate = self
                    self.mapView.delegate = self
                    self.clusteringManager.removeAll()
                    self.clusteringManager.add(annotations: self.array)
                }
            })
            
            ref.observe(.childChanged, with: { (snapshot) -> Void in
                ////print("Changed...") //someone logged in...
                self.addAnnotations()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.clusteringManager.delegate = self
                    self.mapView.delegate = self
                    self.clusteringManager.removeAll()
                    self.clusteringManager.add(annotations: self.array)
                }
            })
            
            
            let defaults = UserDefaults.standard
            if let tempuuid = defaults.string(forKey: "uuid") {
                ////print(tempuuid)
                uuid = tempuuid
                self.ref.child("crowddata").child(self.uuid).setValue(
                    [
                        "interest": self.interest,
                        "myinfo": self.myInfo,
                        "currlatlng":"\(000.000,000.000)"
                    ]
                )
            }else{
                uuid = NSUUID().uuidString
                defaults.set(uuid, forKey: "uuid")
                getAlreadyExistingRecFromFirebase()
                self.ref.child(uuid).setValue(["uuid": uuid])
            }
            
        }
        
    }
    
    func startScanning() {
        let uuid = UUID(uuidString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5")!
        print("\(uuid) AAAAAA")
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, major: 123, minor: 45, identifier: "com.testdating.beaconRegion")
        
        locManager.startMonitoring(for: beaconRegion)
        locManager.startRangingBeacons(in: beaconRegion)
        locManager.requestAlwaysAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        ////print(beacons.count)
        if beacons.count > 0 {
            updateDistance(beacons[0].proximity)
        } else {
            updateDistance(.unknown)
        }
    }
    
    
    
    
    
    
    
    func updateDistance(_ distance: CLProximity) {
        UIView.animate(withDuration: 0.8) {
            switch distance {
            case .unknown:
                self.view.backgroundColor = UIColor.gray
                //print("Unknown......")
                
            case .far:
                self.view.backgroundColor = UIColor.blue
                print("Far......")
                
            case .near:
                self.view.backgroundColor = UIColor.orange
                print("Near......")
                
            case .immediate:
                self.view.backgroundColor = UIColor.red
                print("Immediate......")
            }
        }
    }
    
    
    @IBAction func goToMyLoc(_ sender: Any) {
        Location.getLocation(accuracy: .house, frequency: .oneShot, success: { (_, location) in
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            
            self.mapView.setRegion(region, animated: true)
            
        }) { (request, last, error) in
            request.cancel() // stop continous location monitoring on error
            //////print("Location monitoring failed due to an error \(error)")
        }
    }
    
    func getAlreadyExistingRecFromFirebase(){
        self.ref.child("crowddata").child(self.uuid).removeValue()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getUserDefaultData()
        
        //get user's current loc and add to firebase, also monitor for changes in the same place.
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            currentLocation = locManager.location
            
            Location.getLocation(accuracy: .house, frequency: .oneShot, success: { (_, location) in
                ////print("new loc: \(location)")
                if self.toggleOnlineSwitch.isOn{
                    var nearestLoc = self.fetchPlacesNearCoordinate(coordinate:location.coordinate,radius:500) as? CLLocation
                    if nearestLoc != nil{
                        let latlngString:String = "\(nearestLoc!.coordinate.latitude),\(nearestLoc!.coordinate.longitude)"
                        
                        // let latlngString:String = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                        self.ref.child("crowddata").child(self.uuid).setValue(
                            [
                                "interest": self.interest,
                                "myinfo": self.myInfo,
                                "currlatlng":"\(latlngString)"
                            ]
                        )
                    }
                    else{
                        let latlngString:String = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                        self.ref.child("crowddata").child(self.uuid).setValue(
                            [
                                "interest": self.interest,
                                "myinfo": self.myInfo,
                                "currlatlng":"\(latlngString)"
                            ]
                        )
                        
                    }
                    
                }
                self.centerMapOnLocation(location: location)
                self.mapView.showsUserLocation = true
                
            }) { (request, last, error) in
                request.cancel() // stop continous location monitoring on error
                ////print("Location monitoring failed due to an error \(error)")
            }
}
    }
    
    func getUserDefaultData(){
        let defaults = UserDefaults.standard
        if let tempmyinfo = defaults.string(forKey: "myinfo") {
            myInfo = tempmyinfo
        }
        
        if let tempinterest = defaults.string(forKey: "interest") {
            interest = tempinterest
        }
    }
    
    @IBOutlet weak var btnTurnOnOff: UIButton!
    @IBAction func TurnOnOffClick(_ sender: Any) {
        
        Location.getLocation(accuracy: .house, frequency: .oneShot, success: { (_, location) in
            ////print("new loc: \(location)")
            if self.toggleOnlineSwitch.isOn{
                var nearestLoc = self.fetchPlacesNearCoordinate(coordinate:location.coordinate,radius:500) as? CLLocation
                
                if nearestLoc != nil{
                    let latlngString:String = "\(nearestLoc!.coordinate.latitude),\(nearestLoc!.coordinate.longitude)"
                    //let latlngString:String = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                    self.ref.child("crowddata").child(self.uuid).setValue(
                        [
                            "interest": self.interest,
                            "myinfo": self.myInfo,
                            "currlatlng":"\(latlngString)"
                        ]
                    )
                }else{
                    let latlngString:String = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                    self.ref.child("crowddata").child(self.uuid).setValue(
                        [
                            "interest": self.interest,
                            "myinfo": self.myInfo,
                            "currlatlng":"\(latlngString)"
                        ]
                    )
                }
            }
            
        }) { (request, last, error) in
            request.cancel()
        }
    }
    
    func addAnnotations() -> [FBAnnotation]{
        
        self.array.removeAll()
        self.clusteringManager.removeAll()
        let query = ref.child("crowddata").queryOrdered(byChild:"interest").queryEqual(toValue:self.interest)
        query.observe(.value, with: { (snapshot) in
            for childSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                //print(childSnapshot)
                
                if self.array.count != snapshot.children.allObjects.count {
                    
                    guard let childDict = childSnapshot.value as? [String: Any] else { continue }
                    _ = childDict["interest"] as? String
                    let latlng = childDict["currlatlng"] as? String
                    if latlng != nil{
                        let latlngDoubleArr = (latlng as NSString?)?.components(separatedBy: ",")
                        let lat = latlngDoubleArr?[0]
                        let lng = latlngDoubleArr?[1]
                        let a:FBAnnotation = FBAnnotation()
                        a.coordinate = CLLocationCoordinate2D(latitude: ((lat as NSString?)?.doubleValue)!, longitude:((lng as NSString?)?.doubleValue)!)
                        self.array.append(a)
                    }
                }
            }
        })
        return self.array
    }
    
    
    
    func centerMapOnLocation(location: CLLocation)
    {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 5.0, regionRadius * 5.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    
    @IBAction func segmentChanged(_ sender: Any) {
        if segmentControl.selectedSegmentIndex == 0{
            mapView.mapType = .standard
        }
        else if segmentControl.selectedSegmentIndex == 1 {
            mapView.mapType = .satellite
        }
        else if segmentControl.selectedSegmentIndex == 2{
            mapView.mapType = .hybrid
        }
        
        
    }
    
    @IBAction func toggleStatusOnOff(_ sender: Any) {
        if toggleOnlineSwitch.isOn{
            if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
                CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
                currentLocation = locManager.location
                
                Location.getLocation(accuracy: .house, frequency: .oneShot, success: { (_, location) in
                    ////print("new loc: \(location)")
                    var nearestLoc = self.fetchPlacesNearCoordinate(coordinate:location.coordinate,radius:500) as? CLLocation
                    
                    if nearestLoc != nil{
                        let latlngString:String = "\(nearestLoc!.coordinate.latitude),\(nearestLoc!.coordinate.longitude)"
                        
                        //let latlngString:String = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                        self.ref.child("crowddata").child(self.uuid).setValue(
                            [
                                "interest": self.interest,
                                "myinfo": self.myInfo,
                                "currlatlng":"\(latlngString)"
                            ]
                        )
                    }else{
                        let latlngString:String = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                        self.ref.child("crowddata").child(self.uuid).setValue(
                            [
                                "interest": self.interest,
                                "myinfo": self.myInfo,
                                "currlatlng":"\(latlngString)"
                            ]
                        )
                    }
                    self.centerMapOnLocation(location: location)
                    self.mapView.showsUserLocation = true
                    
                }) { (request, last, error) in
                    request.cancel() // stop continous location monitoring on error
                    ////print("Location monitoring failed due to an error \(error)")
                }
            }
            
        }else{
            self.ref.child("crowddata").child(self.uuid).removeValue()
            self.addAnnotations()
        }
    }
    
}

extension ViewController : FBClusteringManagerDelegate {
    
    func cellSizeFactor(forCoordinator coordinator:FBClusteringManager) -> CGFloat {
        return 1.0
    }
}


extension ViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            let mapBoundsWidth = Double(self.mapView.bounds.size.width)
            let mapRectWidth = self.mapView.visibleMapRect.size.width
            let scale = mapBoundsWidth / mapRectWidth
            
            let annotationArray = self.clusteringManager.clusteredAnnotations(withinMapRect: self.mapView.visibleMapRect, zoomScale:scale)
            
            DispatchQueue.main.async {
                self.clusteringManager.display(annotations: annotationArray, onMapView:self.mapView)
            }
        }
        
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var reuseId = ""
        
        if annotation is FBAnnotationCluster {
            reuseId = "Cluster"
            var clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
            if clusterView == nil {
                clusterView = FBAnnotationClusterView(annotation: annotation, reuseIdentifier: reuseId, configuration: self.configuration)
            } else {
                
                clusterView?.annotation = annotation
            }
            
            let a = annotation as! FBAnnotationCluster
            if a.annotations.count > 1 {
                for _ in a.annotations {
                    let loc = CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude)
                    ////print(loc)
                    /* getAddressFromGoogle(location: loc)
                     if addressFromGoogle != ""{
                     a.title = addressFromGoogle
                     
                     }else{
                     a.title = "\(a.coordinate.latitude),\(a.coordinate.longitude)"
                     }
                     let intArr = self.interest.components(separatedBy: "|")
                     let age:String = intArr[0]
                     let gender:String = intArr[1]
                     a.subtitle = "Crowd: \(a.annotations.count) \(gender)s aged \(age)"
                     
                     clusterView!.canShowCallout = true
                     clusterView!.calloutOffset = CGPoint(x: -5, y: 5)
                     
                     let button = NavigateUIButton()
                     button.frame = CGRect.init(x: 1, y: 1, width: 32, height: 32)
                     button.location = loc
                     button.addTarget(self, action: #selector(self.navigateToLocation(_:)), for: .touchUpInside)
                     button.setTitle(addressFromGoogle, for: .normal)
                     clusterView!.rightCalloutAccessoryView = button*/
                    getAddressFrom(location: loc) { (address) in
                        if address == nil{
                            a.title = "\(a.coordinate.latitude),\(a.coordinate.longitude)"
                        }else{
                            a.title = address
                        }
                        let intArr = self.interest.components(separatedBy: "|")
                        let age:String = intArr[0]
                        let gender:String = intArr[1]
                        a.subtitle = "Crowd: \(a.annotations.count) \(gender)s aged \(age)"
                        
                        clusterView!.canShowCallout = true
                        clusterView!.calloutOffset = CGPoint(x: -5, y: 5)
                        
                        let button = NavigateUIButton()
                        button.frame = CGRect.init(x: 1, y: 1, width: 32, height: 32)
                        button.location = loc
                        button.addTarget(self, action: #selector(self.navigateToLocation(_:)), for: .touchUpInside)
                        button.setTitle(address, for: .normal)
                        clusterView!.rightCalloutAccessoryView = button
                    }
                    
                    
                }
            }
            return clusterView
            
        } else {
            
            reuseId = "Pin"
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView?.pinTintColor = UIColor.purple
            } else {
                pinView?.annotation = annotation
            }
            
            let a = annotation
            if a.coordinate.latitude == mapView.userLocation.coordinate.latitude
                && a.coordinate.longitude == mapView.userLocation.coordinate.longitude
            {
                pinView?.isHidden = true
            }
            
            
            return pinView
        }
        
    }
    
    
    
    @objc func navigateToLocation(_ sender:NavigateUIButton){
        
        if #available(iOS 10.0, *) {
            let placemark = MKPlacemark(coordinate: (sender.location?.coordinate)!)
            let item = MKMapItem(placemark: placemark)
            /* getAddressFromGoogle(location: sender.location!)
             item.name = addressFromGoogle
             item.openInMaps()*/
            getAddressFrom(location: sender.location!
            ) { (address) in
                item.name = address
                item.openInMaps()
            }
            
        } else {
            // Fallback on earlier versions
        }
        
        
    }
    
    
    func getAddressFrom(location: CLLocation, completion:@escaping ((String?) -> Void)) {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let placemark = placemarks?.first,
                let subThoroughfare = placemark.subThoroughfare,
                let thoroughfare = placemark.thoroughfare,
                let locality = placemark.locality,
                let administrativeArea = placemark.administrativeArea {
                let address = subThoroughfare + " " + thoroughfare + ", " + locality + " " + administrativeArea
                
                return completion(address)
                
            }
            completion(nil)
        }
    }
    
    func getAddressFromGoogle(location:CLLocation){
        let googleGeocoder = GMSGeocoder()
        googleGeocoder.reverseGeocodeCoordinate(location.coordinate) { response , error in
            if let address = response?.firstResult() {
                let lines = address.lines! as [String]
                
                self.addressFromGoogle = lines.joined(separator: "\n")
            }
            
        }
    }
    
    func fetchPlacesNearCoordinate(coordinate: CLLocationCoordinate2D, radius: Double){
        let url = URL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(coordinate.latitude),\(coordinate.longitude)&radius=\(radius)&types=restaurant,food,pub,bar,club&key=\(apikey)")
        
        let urlRequest = URLRequest(url: url!)
        
        
        let task = URLSession.shared.dataTask(with: urlRequest) {
            (data, response, error) in
            
            guard error == nil else {
                //print(error!)
                return
            }
            
            guard let responseData = data else {
                //print("Error: did not receive data")
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: responseData, options: []) as! NSDictionary
            let results = json?["results"] as? Array<NSDictionary>
            //print("results = \(results!.count)")
            if results != nil{
                for result in results! {
                    
                    //let name = result["name"] as! String
                    if let geometry = result["geometry"] as? [String: Any] {
                        if let location = geometry["location"] as? [String: Any] {
                            
                            let lat = location["lat"]
                            let lng = location["lng"]
                            if lat != nil && lng != nil{
                                var loc = CLLocation(latitude: CLLocationDegrees(lat! as! NSNumber),longitude: CLLocationDegrees(lng! as! NSNumber))
                                
                                self.nearestLocations.append(loc)
                                
                            }
                        }
                    }
                }
            }
        }
        task.resume()
        //print(nearestLocations.count)
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        getClosesLocation(userLocation: userLocation)
    }
    
    func getClosesLocation(userLocation:CLLocation) -> CLLocation?
    {
        var closestLocation: CLLocation?
        var smallestDistance: CLLocationDistance?
        
        for location in nearestLocations {
            let distance = userLocation.distance(from: location)
            if smallestDistance == nil || distance < smallestDistance! {
                closestLocation = location
                smallestDistance = distance
            }
        }
        //print(closestLocation?.coordinate.latitude,closestLocation?.coordinate.longitude)
        
        if closestLocation == nil{
            return nil
        }
        
        return closestLocation!
    }
    
}



