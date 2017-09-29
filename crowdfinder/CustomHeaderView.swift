//
//  CustomHeaderView.swift
//  crowdfinder
//
//  Created by Ravichandra Challa on 29/9/17.
//  Copyright © 2017 Ravichandra Challa. All rights reserved.
//

import UIKit


class CustomHeaderView: UIView {
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        var tintColor:UIColor = UIColor(red: 71/255, green: 136/255, blue: 199/255, alpha: 1.0)
        self.frame = CGRect(x: 0, y: 0,width: 100, height: 30)
        self.backgroundColor = tintColor
        
        
        //self.addSubview(textField)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
