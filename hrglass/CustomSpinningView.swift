//
//  CustomSpinningView.swift
//  hrglass
//
//  Created by Justin Hershey on 10/7/17.
//
//

import UIKit

class CustomSpinningView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var spinView: UIImageView!
    var baseView: UIImageView!
    
    var isAnimating: Bool = false
    
    override init(frame: CGRect){
        super.init(frame: frame)
        
        self.spinView = UIImageView(frame: self.frame)
        self.spinView.image = UIImage(named:"logoGlassOnly")
        self.spinView.layer.cornerRadius = self.frame.width/2
        
        
        self.baseView = UIImageView(frame: self.frame)
        self.baseView.image = UIImage(named:"logoOutsideCircle")
        self.baseView.layer.cornerRadius = self.frame.width/2
        
        self.backgroundColor = UIColor.clear
        
        self.addSubview(baseView)
        self.addSubview(spinView)
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    

    
    
    func animate(){
        
        if (isAnimating){
            UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseInOut, animations: {
                
                self.spinView.transform = CGAffineTransform(rotationAngle: 360.0)
                
            }) { (success) in
                self.animate()
            }
        }
    }
    
    func startAnimating(){
        self.isAnimating = true
        self.isHidden = false
        self.animate()
    }
    
    func stopAnimating(){
        self.isAnimating = false
        self.isHidden = true
    }
    
    

}
