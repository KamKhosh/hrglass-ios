//
//  PhotoView.swift
//  hrglass
//
//  Created by Justin Hershey on 7/27/17.
//
//  



// CLASS NOT CURRENTLY IN USE IN ANY CAPACITY

import UIKit

class PhotoView: UIView{

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        imageView = UIImageView(frame: CGRect.zero)
        imageView.frame.size = CGSize(width: self.frame.width, height: self.frame.width)
        imageView.center = self.center
        imageView.contentMode = .scaleAspectFill
        
        self.addSubview(imageView)
        
        self.backgroundColor = UIColor.init(white: 0.0, alpha: 0.8)
        
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        tapGesture.numberOfTapsRequired = 1
        self.addGestureRecognizer(tapGesture)

    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    func setImage(image: UIImage){
    
        self.imageView.image = image
        
    }
    
    func dismiss(){
        
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            
        }) { (success) in
            if success{
            
               self.removeFromSuperview()
            }
        }
    }
    
    func show(frame: CGRect){
        
//        let xScale = frame.size.width / self.frame.width
//        let yScale = frame.size.height / self.frame.height
        
//        UIView.animate(withDuration: 0.2, animations: {
//            self.transform = CGAffineTransform(scaleX: xScale, y: yScale)
//            
//        })
//        
        
    }
    
}
