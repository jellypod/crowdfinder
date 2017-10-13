//
//  AppDelegate.swift
//  crowdfinder
//
//  Created by Ravichandra Challa on 24/9/17.
//  Copyright © 2017 Ravichandra Challa. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseCore
import FirebaseMessaging
import FirebaseInstanceID
import GoogleMaps
import GooglePlaces
import FirebaseDatabase
import SwiftLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager = CLLocationManager()
    var deferringUpdates: Bool = false
   
    var ref:DatabaseReference!
    var myInfo:String = "0|Male"
    var interest:String = "0|Male"
    var isturnedoffloc = "false"
    var uuid:String = ""
    let nextUpdate:TimeInterval = 300;
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        GMSServices.provideAPIKey("AIzaSyBFGiusWvcQBKYM2wxFRgGDZIJW3dDooTg")
        
        
        let apiKey = "AIzaSyB1W_qFTcshpGSmZFUFMR-D2NZYvrHwV40"
        GMSPlacesClient.provideAPIKey(apiKey)
        print(GMSPlacesClient.openSourceLicenseInfo())
        if apiKey == "YOUR_API_KEY" {
            print("IF YOU SEE THIS IN YOUR CONSOLE IT'S BECAUSE YOU FORGOT TO SET YOUR API_KEY")
            assertionFailure()
        }
        ref = Database.database().reference(fromURL: "https://crowdfinder-1dot0.firebaseio.com/")
        checkAndCreateUUID()
        getUserDefaultData()
       
        
        return true
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
    }
    
    func oneShotLocation()
    {
        if isturnedoffloc == "false"{
        //get user's current loc and add to firebase, also monitor for changes in the same place.
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways)
        {
            Location.getLocation(accuracy: .block, frequency: .oneShot, success: { (_, location) in
                
                let latlngString:String = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                
                // let latlngString:String = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
                self.ref.child("crowddata").child(self.uuid).setValue(
                    [
                        "interest": self.interest,
                        "myinfo": self.myInfo,
                        "currlatlng":"\(latlngString)"
                    ]
                )
               
            }) { (request, last, error) in
                request.cancel() // stop continous location monitoring on error
                ////print("Location monitoring failed due to an error \(error)")
            }
        }
        }
    }
    
   
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        startHikeLocationUpdates()
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        locationManager.stopUpdatingLocation()
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        ref = Database.database().reference()
        let defaults = UserDefaults.standard
        if let tempmyinfo = defaults.string(forKey: "uuid") {
            self.ref.child("crowddata").child(tempmyinfo).removeValue()
        }
    }
    
        func startHikeLocationUpdates() {
                // Create a location manager object
        
                // Set the delegate
                self.locationManager.delegate = self
                self.locationManager.allowsBackgroundLocationUpdates = true
        
                // Request location authorization
                self.locationManager.requestAlwaysAuthorization()
        
                // Specify the type of activity your app is currently performing
                self.locationManager.activityType = .fitness//CLActivityTypeFitness
        
                // Start location updates
                self.locationManager.startUpdatingLocation()
            }
        
            func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                // Add the new locations to the hike
               // print(locations,"*******")
                
                // Defer updates until the user hikes a certain distance or a period of time has passed
                if (!deferringUpdates) {
                    var distance: CLLocationDistance = CLLocationDistanceMax
                    var time: TimeInterval = nextUpdate
                    self.locationManager.allowDeferredLocationUpdates(untilTraveled: distance, timeout:time)
                    deferringUpdates = true;
                } else {
                    oneShotLocation()
                }
            }
    
    func checkAndCreateUUID(){
        
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
    
    func getAlreadyExistingRecFromFirebase(){
        self.ref.child("crowddata").child(self.uuid).removeValue()
    }
        
            func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
                let v = UIAlertView(title: "ALERT", message: notification.alertBody, delegate: nil, cancelButtonTitle: "OK")
                v.show()
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "prova"), object: notification, userInfo: ["text" : notification.alertBody])
            }
    
            func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error!) {
                // Stop deferring updates
                self.deferringUpdates = false
        
                // Adjust for the next goal
            }
        
    
            func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
                print(error)
                dispatchNotif(error.localizedDescription)
            }
    
            func dispatchNotif(_ text: String) {
                let notification = UILocalNotification()
                notification.alertTitle = "NOTIF"
                notification.alertBody = "\(text)"
                notification.fireDate = Date()
                UIApplication.shared.scheduleLocalNotification(notification)
            }


}

