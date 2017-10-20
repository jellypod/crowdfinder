//
//  VenueResultsViewController.swift
//  crowdfinder
//
//  Created by Ravichandra Challa on 19/10/17.
//  Copyright © 2017 Ravichandra Challa. All rights reserved.
//

import UIKit
import FoursquareAPIClient
import SwiftOverlays
import FirebaseDatabase


class VenueTableViewCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var address: UILabel!
}

class VenueResultsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    var latlng:String = "000.000,000.000"
    var uuid:String = ""
    var interest:String = ""
    var myInfo:String = ""
    var ref:DatabaseReference!
    
    
    @IBOutlet weak var tableView: UITableView!
     var items: [Venue] = []
    let client = FoursquareAPIClient(clientId: "FIYPO2UAGO3TZXBO5HQDB5JYMRHNEZTTONU2J0IZX0YYE3R0", clientSecret: "EAUQM2JUVVJIYWZQ0UQEMRVG5XUEBOYWY5RJNLGIBBQ5BCJY")
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self as! UITableViewDataSource
        self.tableView.delegate = self
        ref = Database.database().reference(fromURL: "https://crowdfinder-1dot0.firebaseio.com/")
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.showImageAndTextOverlay(UIImage(named:"icon-search")!, text: "Retreiving places near you...")
        searchVenues()
        tableView.reloadData()
        self.removeAllOverlays()
    }
    
   
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
  
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:VenueTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell") as! VenueTableViewCell
        print(self.items[indexPath.row])
        cell.label.text = self.items[indexPath.row].venueName
        cell.address.text = self.items[indexPath.row].venueAddress
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.ref.child("crowddata").child(self.uuid).setValue(
            [
                "interest": self.interest,
                "myinfo": self.myInfo,
                "currlatlng":"\(items[indexPath.row].venueLatlng)",
                 "venuename":"\(items[indexPath.row].venueName)"
            ]
        )
        
        navigationController?.popViewController(animated: true)
    }
    
   override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchVenues(){
        let parameter: [String: String] = [
            "ll": latlng,
            "limit": "10",
            ];
        
        client.request(path: "venues/search", parameter: parameter) { result in
            switch result {
            case let .success(data):
                // parse the JSON data with NSJSONSerialization or Lib like SwiftyJson
                // e.g. {"meta":{"code":200},"notifications":[{"...
                self.extract_json(responseData:data)
            case let .failure(error):
                // Error handling
                switch error {
                case let .connectionError(connectionError):
                    print(connectionError)
                case let .apiError(apiError):
                    print(apiError.errorType)   // e.g. endpoint_error
                    print(apiError.errorDetail) // e.g. The requested path does not exist.
                }
            }
        }
    }
    

    func extract_json(responseData:Data)
    {
        let json = try? JSONSerialization.jsonObject(with: responseData, options: []) as! NSDictionary
        //sprint(json)
        let results = json?["response"] as? [String: Any]
        let venues = results!["venues"] as? Array<NSDictionary>
        print(venues)
        for venue in venues!{
            var venueObj:Venue = Venue()
            if let venueName = venue["name"]{
                print(venueName)
                venueObj.venueName = venueName as! String
            }
       
            if let venueAddress = venue["location"] as? [String:Any]{
                if venueAddress["lat"] != nil && venueAddress["lng"] != nil
                {
                    venueObj.venueLatlng = String(describing:venueAddress["lat"]!) + "," + String(describing:venueAddress["lng"]!)
                    if let venueLoc = venueAddress["address"]
                    {
                        print(venueLoc)
                        venueObj.venueAddress  = String(describing:venueLoc)
                        
                    }else if let city = venueAddress["city"], let country = venueAddress["country"] , let postalCode = venueAddress["postalCode"] {
                            venueObj.venueAddress  = String(describing:city)+" "+String(describing:country)+" "+String(describing:postalCode)
                    }
                    else if let formatterAddress = venueAddress["formattedAddress"]{
                        venueObj.venueAddress  = String(describing:formatterAddress)
                    }
                    
                    if venueObj.venueAddress == "("{
                        venueObj.venueAddress = "Address not found."
                    }
                    
                   
                        items.append(venueObj)
                    }
                }
            }
        
         tableView.reloadData()
        }
    
    }


class Venue{
    var venueName:String = ""
    var venueLatlng:String = ""
    var venueAddress:String = ""
}



