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
    var yourAge:[String]?
    var interest:[String]?
    
    var gender:String = ""
    var age:String = ""
    
    var prefAge:String = ""
    var prefGender:String = ""
    
    let bgColor:UIColor = UIColor(red: 182/255, green: 220/255, blue: 255/255, alpha: 1.0)
    let tintColor:UIColor = UIColor(red: 71/255, green: 136/255, blue: 199/255, alpha: 1.0)
   
    func getSetUserDefaultData(){
        let defaults = UserDefaults.standard
        if let tempmyinfo = defaults.string(forKey: "myinfo") {
            yourAge = tempmyinfo.components(separatedBy: "|")
        }
        
        if let tempinterest = defaults.string(forKey: "interest") {
            interest = tempinterest.components(separatedBy: "|")
        }
        
        if let tempinterest2 = defaults.string(forKey: "tempInterest") {
            prefAge = tempinterest2
        }
        
        
        if let tempprefGender = defaults.string(forKey: "prefGender") {
            prefGender = tempprefGender
        }
        
    }
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
         getSetUserDefaultData()
       
        self.tableView?.backgroundColor = bgColor
        self.tableView?.tintColor = tintColor
        
        form +++ Section(header: "Preferences", footer: "")
        form +++ Section("Your Details")
            
            <<< TextRow(){ row in
                row.tag = "YourAge"
                row.title = "Age"
                row.placeholder = "Your age"
                 if yourAge != nil{
                    row.value = yourAge?[0]
                }
                row.add(rule: RuleRequired())
                row.validationOptions = .validatesOnChange
            }
                .cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
            }
            <<< SegmentedRow<String>()  {
                $0.tag = "YourGender"
                $0.title = "Gender"
                $0.options = ["Male","Female"]
                if yourAge != nil{
                    $0.value = yourAge?[1]
                }
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                
            }
                .cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
            }
            
            +++ Section("Your Interests")
            <<< PushRow<String>() { //1
                $0.tag = "YourPrefAge"
                $0.title = "Age Group" //2
                $0.options = ["18 - 25","25 - 30","30 - 35","35 - 40","40 - 45","45 - 50","50 - 55","55 - 60"]
                $0.onChange { [unowned self] row in //5
                    if let value = row.value {
                        self.dismiss(animated: true, completion:nil)
                       // self.viewModel.repeatFrequency = value
                    }
                }
                
                $0.value = prefAge
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                
                }.cellUpdate { cell, row in
                    if !row.isValid {
                        cell.textLabel?.textColor = .red
                    }
            }
            
            <<< SegmentedRow<String>()  {
                $0.tag = "YourPrefGender"
                $0.title = "Gender"
                $0.options = ["Male","Female","Any"]
                $0.value = prefGender
                 $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }
                .cellUpdate { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
            }
            
          
       +++ Section("")
            <<< ButtonRow("Submit") {
                $0.title = "Save"
                $0.cell.backgroundColor = .white
                $0.cell.tintColor = tintColor
                
            }
                .onCellSelection { [weak self] (cell, row) in
                    okTapped()
            }
        
            <<< ButtonRow("Cancel") {
                $0.title = "Cancel"
                $0.cell.backgroundColor = .white
                $0.cell.tintColor = tintColor
        }
        .onCellSelection { [weak self] (cell, row) in
            cancelTapped()
        }
    
    func cancelTapped(){
        
        self.dismiss(animated: true)
    }
        
        func okTapped(){
            
           
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
            
            if age == "" || gender == "" || prefAge == "" || prefGender == ""{
                let alert = UIAlertController(title: "Oh No", message: "😲 We need all the fields to be filled in. Please fill in all the fields and try again!", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)

            }else{
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
            defaults.set("\(String(describing:prefAge))", forKey: "tempInterest")
            defaults.set("\(String(describing:prefGender))", forKey: "prefGender")
           // defaults.set("\(String(describing:prefAge))|\(String(describing:prefGender))", forKey: "interest")
            
           
            self.dismiss(animated:true)
            }
        }
}
}

