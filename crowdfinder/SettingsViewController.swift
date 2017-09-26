//
//  SettingsViewController.swift
//  crowdfinder
//
//  Created by Ravichandra Challa on 24/9/17.
//  Copyright © 2017 Ravichandra Challa. All rights reserved.
//

import UIKit
import Eureka
class SettingsViewController: FormViewController {
    
    func okTapped(cell: ButtonCellOf<String>, row: ButtonRow) {
        print("tapped!")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        form +++ Section("Your Details")
            <<< TextRow(){ row in
                row.tag = "YourAge"
                row.title = "Age"
                row.placeholder = "Your age"
            }
            <<< SegmentedRow<String>()  {
                $0.tag = "YourGender"
                $0.title = "Gender"
                $0.options = ["Male","Female"]
            }
            
            +++ Section("Your Interests")
            <<< PushRow<String>() { //1
                $0.tag = "YourPrefAge"
                $0.title = "Preferred age group" //2
                $0.options = ["18 - 25","25 - 30","30 - 35","35 - 40","40 - 45","45 - 50","50 - 55","55 - 60"]
                $0.onChange { [unowned self] row in //5
                    if let value = row.value {
                        self.dismiss(animated: true, completion: {
                        
                        })
                       // self.viewModel.repeatFrequency = value
                    }
                }
            }
            <<< SegmentedRow<String>()  {
                $0.tag = "YourPrefGender"
                $0.title = "Preferred gender"
                $0.options = ["Male","Female"]
            }
        
            <<< ButtonRow("Submit") {
                $0.title = "OK"
                $0.cell.backgroundColor = .white
                $0.cell.tintColor = .black
            }
                .onCellSelection { [weak self] (cell, row) in
                    okTapped()
            }
        
            <<< ButtonRow("Cancel") {
                $0.title = "Cancel"
                $0.cell.backgroundColor = .white
                $0.cell.tintColor = .black
        }
        .onCellSelection { [weak self] (cell, row) in
            cancelTapped()
        }
    
    func cancelTapped(){
        
        self.dismiss(animated: true)
    }
        
        func okTapped(){
            
            var gender:String = ""
            var age:String = ""
            
            var prefAge:String = ""
            var prefGender:String = ""
            
            let allFormData = form.values()
            
            
            if let yourAge = allFormData["YourAge"] as? String {
                age = yourAge
            }
            
            if let yourGender = allFormData["YourGender"] as? String {
                gender = yourGender
            }
            
            if let yourPrefAge = allFormData["YourPrefAge"] as? String {
                prefAge = yourPrefAge
            }
            
            if let yourPrefGender = allFormData["YourPrefGender"] as? String {
                prefGender = yourPrefGender
            }
            
            var prefAge2:String = prefAge
            switch prefAge {
                case "18 - 25":
                prefAge2 = "18|\(prefGender),19|\(prefGender),20|\(prefGender),21|\(prefGender),22|\(prefGender),23|\(prefGender),24|\(prefGender),25|\(prefGender)"
            case "25 - 30":
                prefAge2 = "25|\(prefGender),26|\(prefGender),27|\(prefGender),28|\(prefGender),29|\(prefGender),30|\(prefGender)"
            case "30 - 35":
                prefAge2 = "30|\(prefGender),31|\(prefGender),32|\(prefGender),33|\(prefGender),34|\(prefGender),35|\(prefGender)"
            case "35 - 40":
                prefAge2 = "35|\(prefGender),36|\(prefGender),37|\(prefGender),38|\(prefGender),39|\(prefGender),40|\(prefGender)"
            case "40 - 45":
                prefAge2 = "40|\(prefGender),41|\(prefGender),42|\(prefGender),43|\(prefGender),44|\(prefGender),45|\(prefGender)"
            case "45 - 50":
                prefAge2 = "45|\(prefGender),46|\(prefGender),47|\(prefGender),48|\(prefGender),49|\(prefGender),50|\(prefGender)"
            case "50 - 55":
                prefAge2 = "50|\(prefGender),51|\(prefGender),52|\(prefGender),53|\(prefGender),54|\(prefGender),55|\(prefGender)"
            case "55 - 60":
                prefAge2 = "55|\(prefGender),56|\(prefGender),57|\(prefGender),58|\(prefGender),59|\(prefGender),60|\(prefGender)"
                default:
                prefAge2 = "55|\(prefGender),56|\(prefGender),57|\(prefGender),58|\(prefGender),59|\(prefGender),60|\(prefGender)"
            }
            
            let defaults = UserDefaults.standard
            
            defaults.set("\(String(describing:age))|\(String(describing:gender))", forKey: "myinfo")
            defaults.set("\(String(describing:prefAge2))", forKey: "interest")
           // defaults.set("\(String(describing:prefAge))|\(String(describing:prefGender))", forKey: "interest")
            
            print(age)
            print(gender)
            print(prefAge)
            print(prefGender)
            self.dismiss(animated:true)
        }
}
}

