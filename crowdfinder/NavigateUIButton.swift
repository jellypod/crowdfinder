//
//  NavigateUIButton.swift
//  SwiftLocation
//
//  Created by Ravichandra Challa on 9/9/17.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import UIKit
import MapKit
class NavigateUIButton: UIButton {
    
    var address:String?
    var location:CLLocation?
    
    required init() {
        // set myValue before super.init is called
        super.init(frame: .zero)
        
        // set other operations after super.init, if required
        let image = UIImage(named: "locon") as UIImage?
        self.frame.size.height = 45
        
        setImage(image, for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
