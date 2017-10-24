//
//  CustomRefreshControlView.swift
//  hrglass
//
//  Created by Justin Hershey on 10/7/17.
//
//


/*
 
    CustomRefreshControlView UNDER CONSTRUCTION -- NOT IN USE
 
 */
import UIKit

class CustomRefreshControlView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    @IBOutlet weak var spinView: CustomSpinningView!
    
    @IBOutlet var contentView: UIView!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    

}
