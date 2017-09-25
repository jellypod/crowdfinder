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
                $0.options = ["18 - 23","24 - 29","30 - 35","36 - 41","42 - 47","48 - 53","54 - 59"]
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
            
            let defaults = UserDefaults.standard
            
            defaults.set("\(String(describing:age))|\(String(describing:gender))", forKey: "myinfo")
            defaults.set("\(String(describing:prefAge))|\(String(describing:prefGender))", forKey: "interest")
            
            print(age)
            print(gender)
            print(prefAge)
            print(prefGender)
            self.dismiss(animated:true)
        }
}
}

