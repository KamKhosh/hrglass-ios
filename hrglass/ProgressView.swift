//
//  ProgressView.swift
//  hrglass
//
//  Created by Justin Hershey on 9/5/17.
//
//

import UIKit

class ProgressView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    let colors: Colors = Colors()
    var loadingFrame: UIView!
    var backgroudLoadingColor: UIColor!
    var percentageComplete: CGFloat = 0;
    
    var cornerRadius: CGFloat = 3.0
    
    override init(frame: CGRect){
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.init(white: 1.0, alpha: 0.7)
        self.layer.cornerRadius = cornerRadius
        self.backgroudLoadingColor = colors.getMenuColor()
        
        self.setupLoadingFrame()

    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    
    func setupLoadingFrame(){
        
        loadingFrame = UIView(frame: CGRect(x: -self.bounds.width,y: 0,width: self.bounds.width, height: self.bounds.height))

        loadingFrame.backgroundColor = self.backgroudLoadingColor
        
        self.addSubview(loadingFrame)
        
    }
    
 
    
    func updateProgress(){
        
        if (self.percentageComplete < 1.0){

            DispatchQueue.main.async(execute: {() -> Void in
                
                UIView.animate(withDuration: 0.1, animations: {
                    
                    self.loadingFrame.center = CGPoint(x:self.center.x - (self.bounds.width * (1 - self.percentageComplete)), y: self.center.y)
                })
                
            })
            
            print(loadingFrame.center)
        }
    }

}
