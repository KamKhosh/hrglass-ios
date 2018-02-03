//
//  BreatingAnimation.swift
//  AnimationPlayground
//
//  Created by Justin Hershey on 11/27/17.
//  Copyright © 2017 Justin Hershey. All rights reserved.
//

import UIKit

class BreathingAnimation: UIView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    var timer: Timer!
    var animationInterval: TimeInterval = 1.0
    var inflate: Bool = true
    var isAnimating: Bool = false
    
    var imageView: UIImageView!
    
    init(frame: CGRect, image: UIImage){
        super.init(frame: frame)
        
        self.imageView = UIImageView(frame: self.bounds)
        self.imageView.image = image

        self.addSubview(self.imageView)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func startAnimating(){
        //        self.animate()
        self.isAnimating = true
        timer = Timer.scheduledTimer(timeInterval: animationInterval, target: self, selector: #selector(timerAnimate), userInfo: nil, repeats: true)
    }
    
    
    @objc func timerAnimate(){
    
    
            self.isHidden = false
    
    
            if inflate{
                self.inflate = false
                UIView.animate(withDuration: animationInterval, animations: {
                    self.imageView.transform = CGAffineTransform(scaleX: 1.0, y: 0.8)
                })
    
            }else{
                self.inflate = true
                UIView.animate(withDuration: animationInterval, animations: {
                    self.imageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.2)
    
                })
            }
        }
    
    
    func stopAnimating(){
        
        self.isHidden = true
        self.isAnimating = false
        timer.invalidate()
    }
    
    
}

