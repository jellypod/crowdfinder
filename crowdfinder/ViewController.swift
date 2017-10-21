import UIKit
import SwiftLocation
import CoreLocation
import MapKit
import FirebaseDatabase
import GoogleMaps
import SwiftOverlays
import GooglePlaces
class ViewController:UIViewController, CLLocationManagerDelegate,GMSAutocompleteViewControllerDelegate{
    let bgColor:UIColor = UIColor(red: 255/255, green: 87/255, blue: 82/255, alpha: 1.0)
    let clusteringManager = FBClusteringManager()
    let configuration = FBAnnotationClusterViewConfiguration.default()
    @IBOutlet private var textView: UITextView?
    @IBOutlet weak var mapView: MKMapView!
    var locManager = CLLocationManager()
    var currentLocation: CLLocation!
    let regionRadius: CLLocationDistance = 500
    var uuid:String = ""
    var placeNameAtCoordinate:String = ""
    var userpositions = [FBAnnotation]()
    var array:[FBAnnotation] = []
    var myInfo:String = "0|Male"
    var interest:String = "0|Male"
    var isturnedoffloc = "false"
    var ref:DatabaseReference!
    var addressFromGoogle:String = ""
    var apikey:String = "AIzaSyBFGiusWvcQBKYM2wxFRgGDZIJW3dDooTg"
    var nearestLocations: [CLLocation] = []
    @IBOutlet weak var myLoc: UIButton!
    
    @IBOutlet weak var pref: UIBarButtonItem!
    
    var autoSuggestLocation = CLLocation()
    @IBOutlet weak var navTitle: UINavigationItem!
    @IBOutlet weak var overlayView: UIView!
    let navCenterButton = UIButton(type: .system)
    var isTimerRunning = false
    
    @IBOutlet weak var toggleOnlineSwitch: UISwitch!
   
     var resultSearchController:UISearchController? = nil
    
    @IBAction func autoSuggestClick(_ sender: Any) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    
    @IBAction func prefClick(_ sender: Any) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let settingsViewController = storyBoard.instantiateViewController(withIdentifier: "settings") as! SettingsViewController
        self.navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navCenterButton.tintColor = .white
        navCenterButton.titleLabel?.font = UIFont(name: (navCenterButton.titleLabel?.font.fontName)!, size: 15)
        self.navigationItem.titleView = navCenterButton//UIBarButtonItem(customView: button)
        mapView.showsUserLocation = true
        ref = Database.database().reference(fromURL: "https://crowdfinder-1dot0.firebaseio.com/")
        locManager.delegate = self
        locManager.requestAlwaysAuthorization()
        clusteringManager.delegate = self
        mapView.delegate = self
        getUserDefaultData()
        checkAndCreteUUID()
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
        
        //observer other user's logins and movements.
        ref.observe(.childAdded, with: { (snapshot) -> Void in
            ////print("added") //someone logged ign...
            self.placeNameAtCoordinate = ""
            _ = self.addAnnotations()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.clusteringManager.delegate = self
                self.mapView.delegate = self
                self.clusteringManager.removeAll()
                self.clusteringManager.add(annotations: self.array)
                _ = self.mapView.annotations.reversed()
            }
        })
        
        ref.observe(.childRemoved, with: { (snapshot) -> Void in
            ////print("removed") //someone logged out...
            self.placeNameAtCoordinate = ""
            _ = self.addAnnotations()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.clusteringManager.delegate = self
                self.mapView.delegate = self
                self.clusteringManager.removeAll()
                self.clusteringManager.add(annotations: self.array)
            }
        })
        
        ref.observe(.childChanged, with: { (snapshot) -> Void in
            ////print("Changed...") //someone logged in...
            self.placeNameAtCoordinate = ""
            _ = self.addAnnotations()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.clusteringManager.delegate = self
                self.mapView.delegate = self
                self.clusteringManager.removeAll()
                self.clusteringManager.add(annotations: self.array)
            }
        })
    }
    
    func checkAndCreteUUID(){
        
        //check and create uuid
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
            self.ref.child("crowddata").child(self.uuid).setValue(
                [
                    "interest": "",
                    "myinfo": "",
                    "currlatlng":"\(000.000,000.000)"
                ]
            )
        }
    }

    @IBAction func checkinClick(_ sender: Any) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let venueViewController = storyBoard.instantiateViewController(withIdentifier: "venueresults") as! VenueResultsViewController
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways)
            {
            Location.getLocation(accuracy: .block, frequency: .oneShot, success: { (_, location) in
                venueViewController.latlng = String(describing:location.coordinate.latitude) + "," + String(describing:location.coordinate.longitude)
                venueViewController.uuid = self.uuid
                venueViewController.myInfo = self.myInfo
                venueViewController.interest = self.interest
                self.navigationController?.pushViewController(venueViewController, animated: true)
                
            }) { (request, last, error) in
                request.cancel()
            }
        }
    }
    
    
    func oneShotLocation()
    {
        //get user's current loc and add to firebase, also monitor for changes in the same place.
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            currentLocation = locManager.location
            // Wait overlay with text
            let text = "Retrieving your location. Please wait.."
            self.showWaitOverlayWithText(text)
            Location.getLocation(accuracy: .block, frequency: .oneShot, success: { (_, location) in
                self.centerMapOnLocation(location: location)
                self.mapView.showsUserLocation = true
                self.removeAllOverlays()
                
            }) { (request, last, error) in
                request.cancel() // stop continous location monitoring on error
                ////print("Location monitoring failed due to an error \(error)")
            }
        }
    }
    
    @IBAction func settingsClick(_ sender: Any) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let settingsViewController = storyBoard.instantiateViewController(withIdentifier: "settings") as! SettingsViewController
        self.navigationController?.pushViewController(settingsViewController, animated: true)


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
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            currentLocation = locManager.location
            
            Location.getLocation(accuracy: .block, frequency: .oneShot, success: { (_, location) in
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                self.mapView.addAnnotation(annotation)

                
                self.centerMapOnLocation(location: location)
                self.mapView.showsUserLocation = true
                
            }) { (request, last, error) in
                request.cancel()
            }
        }
    }
    
   
    func getAlreadyExistingRecFromFirebase(){
        self.ref.child("crowddata").child(self.uuid).removeValue()
    }
    
   
    override func viewWillAppear(_ animated: Bool) {
        var nav = self.navigationController?.navigationBar
        let tintColor:UIColor = UIColor(red: 255/255, green: 87/255, blue: 82/255, alpha: 1.0)
        nav?.barTintColor = tintColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getUserDefaultData()
        _ = self.addAnnotations()
    }
    
    func getUserDefaultData(){
        let defaults = UserDefaults.standard
        if let tempmyinfo = defaults.string(forKey: "myinfo") {
            myInfo = tempmyinfo
        }
        
        if let tempinterest = defaults.string(forKey: "interest") {
            interest = tempinterest
        }
        
        if let tempisturnedoffloc = defaults.string(forKey: "isturnedoffloc") {
            isturnedoffloc = tempisturnedoffloc
        }
        
        if myInfo == "0|Male"{
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let settingsViewController = storyBoard.instantiateViewController(withIdentifier: "settings") as! SettingsViewController
            self.navigationController?.pushViewController(settingsViewController, animated: true)
        }
    }
    
   
    var annotationPopupText:String!
    func addAnnotations() -> [FBAnnotation]{
        self.array.removeAll()
        self.clusteringManager.removeAll()
        let query = ref.child("crowddata").queryOrdered(byChild:"myinfo")
        query.observe(.value, with: { (snapshot) in
            
            for childSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                if self.array.count != (snapshot.children.allObjects as! [DataSnapshot]).count {
                    
                    guard let childDict = childSnapshot.value as? [String: Any] else { continue }
                    let myinfofromFB:String! = childDict["myinfo"] as? String
                    
                    if self.interest.contains("Any"){
                        let tempMyInfo = childDict["myinfo"] as? String // 32|Female 33|Male
                        var tempMyInfoArr = tempMyInfo?.components(separatedBy: "|")
                        if self.interest.contains(tempMyInfoArr![0]) && childSnapshot.key != self.uuid {
                            self.annotationPopupText = myinfofromFB
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
                    else if self.interest.contains(myinfofromFB) && childSnapshot.key != self.uuid{
                        self.annotationPopupText = myinfofromFB
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
    
    
    
   /* @IBAction func toggleStatusOnOff(_ sender: Any) {
        let defaults = UserDefaults.standard
        if toggleOnlineSwitch.isOn{
            if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
                CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
                currentLocation = locManager.location
                
                Location.getLocation(accuracy: .block, frequency: .oneShot, success: { (_, location) in
                    ////print("new loc: \(location)")
                    let nearestLoc = self.fetchPlacesNearCoordinate(coordinate:location.coordinate,radius:200) as? CLLocation
                    
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
                   // self.centerMapOnLocation(location: location)
                   // self.mapView.showsUserLocation = true
                    
                }) { (request, last, error) in
                    request.cancel() // stop continous location monitoring on error
                    ////print("Location monitoring failed due to an error \(error)")
                }
            }
            defaults.set("false", forKey: "isturnedoffloc")
            
        }else{
            
            
            defaults.set("true", forKey: "isturnedoffloc")
            self.ref.child("crowddata").child(self.uuid).removeValue()
        }
        
    }*/
   
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
            clusterView?.backgroundColor = UIColor.purple
            if clusterView == nil {
                clusterView = FBAnnotationClusterView(annotation: annotation, reuseIdentifier: reuseId, configuration: self.configuration)
            } else {
                
                clusterView?.annotation = annotation
            }
            
            let a = annotation as! FBAnnotationCluster
            
            var addr:String = ""
            var loc:CLLocation = CLLocation(latitude:000.000, longitude: 000.000)
           
            
            if a.annotations.count > 1 {
                for _ in a.annotations {
                    loc = CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude)
                    
                    Location.getPlacemark(forLocation: loc, success: { placemarks in
                        var placeMark: CLPlacemark?
                        placeMark = placemarks.first
                        if let locationName = placeMark?.addressDictionary?["Name"] as? String {
                            addr += locationName + ", "
                        }
                        
                        // Street address
                        if let street = placeMark?.addressDictionary?["Thoroughfare"] as? String {
                            addr += street + ", "
                        }
                        
                        // City
                        if let city = placeMark?.addressDictionary?["City"] as? String {
                            addr += city + ", "
                        }
                        
                        // Zip code
                        if let zip = placeMark?.addressDictionary?["ZIP"] as? String {
                            addr += zip + ", "
                        }
                        
                        // Country
                        if let country = placeMark?.addressDictionary?["Country"] as? String {
                            addr += country
                        }
                        
                        
                        a.title = addr
                        
                    }) { error in
                        print("Cannot retrive placemark due to an error \(error)")
                        addr = String(loc.coordinate.latitude)+","+String(loc.coordinate.longitude)
                        a.title = addr
                    }
                    
                    fetchPlacesNearCoordinate(coordinate: loc.coordinate, radius: 10)
                    clusterView!.canShowCallout = true
                    clusterView!.backgroundColor = .red
                    clusterView!.calloutOffset = CGPoint(x: -5, y: 5)
                    
                    let button = NavigateUIButton()
                    button.frame = CGRect.init(x: 1, y: 1, width: 32, height: 32)
                    button.location = loc
                    button.addTarget(self, action: #selector(self.navigateToLocation(_:)), for: .touchUpInside)
                    button.setTitle(a.title, for: .normal)
                    clusterView!.rightCalloutAccessoryView = button
                    self.placeNameAtCoordinate = ""
            
                }
                
            
                a.subtitle = "Crowd : \(a.annotations.count) people matching your interest"
            }
            return clusterView
            
        } else {
            
            reuseId = "Pin"
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView?.pinTintColor = bgColor
            } else {
                pinView?.annotation = annotation
                pinView?.isHidden = false
                
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
    
    func getAdressName(coords: CLLocation) -> String {
        var address:String = ""
        CLGeocoder().reverseGeocodeLocation(coords) { (placemark, error) in
            if error != nil {
                
                print("Hay un error")
                
            } else {
                
                let place = placemark! as [CLPlacemark]
                
                if place.count > 0 {
                    let place = placemark![0]
                    
                    var adressString : String = ""
                    
                    if place.thoroughfare != nil {
                        adressString = adressString + place.thoroughfare! + ", "
                    }
                    if place.subThoroughfare != nil {
                        adressString = adressString + place.subThoroughfare! + "\n"
                    }
                    if place.locality != nil {
                        adressString = adressString + place.locality! + " - "
                    }
                    if place.postalCode != nil {
                        adressString = adressString + place.postalCode! + "\n"
                    }
                    if place.subAdministrativeArea != nil {
                        adressString = adressString + place.subAdministrativeArea! + " - "
                    }
                    
                    /*if place.country != nil {
                        adressString = adressString + place.country!
                    }*/
                    
                    address =  adressString
                }
                
            }
        }
        return address
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
    
    func getCityFrom(location: CLLocation, completion:@escaping ((String?) -> Void)) {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let placemark = placemarks?.first,
                let subThoroughfare = placemark.subThoroughfare,
                let thoroughfare = placemark.thoroughfare,
                let locality = placemark.locality,
                let administrativeArea = placemark.administrativeArea {
                let address = locality
                
                return completion(address)
                
            }
            completion(nil)
        }
    }
    
    func getAddressFromGoogle(location:CLLocation) -> String{
        let googleGeocoder = GMSGeocoder()
        googleGeocoder.reverseGeocodeCoordinate(location.coordinate) { response , error in
            if let address = response?.firstResult() {
                let lines = address.lines! as [String]
                
                self.addressFromGoogle = lines.joined(separator: "\n")
            }
            
        }
        
        return self.addressFromGoogle
    }
    
    func fetchPlacesNearCoordinate(coordinate: CLLocationCoordinate2D, radius: Double){
        let url = URL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(coordinate.latitude),\(coordinate.longitude)&radius=10&types=establishment,point_of_interest,bar&key=\(apikey)")
        print(url)
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
            print(results)
            if results != nil{
                for result in results! {
                    let types = result["types"] as? [String]
                    if((types?.contains("bar"))! || (types?.contains("establishment"))!){
                        self.placeNameAtCoordinate = (result["name"] as? String)!
                    }
                    if let geometry = result["geometry"] as? [String: Any] {
                        if let location = geometry["location"] as? [String: Any] {
                            
                            let lat = location["lat"]
                            let lng = location["lng"]
                            if lat != nil && lng != nil{
                                let loc = CLLocation(latitude: CLLocationDegrees(truncating: lat! as! NSNumber),longitude: CLLocationDegrees(truncating: lng! as! NSNumber))
                                
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
        _ = getClosesLocation(userLocation: userLocation)
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
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        let location = CLLocationCoordinate2DMake(place.coordinate.latitude, place.coordinate.longitude)
        let tempLoc:CLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        //autoSuggestLocation = tempLoc
        self.centerMapOnLocation(location: tempLoc)
        _ = self.addAnnotations()
       
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //oneShotLocation()
        print("Fired did update")
    }
    
}





