//
//  BouncingBallsView.swift
//  AnimationPlayground
//
//  Created by Justin Hershey on 11/25/17.
//  Copyright © 2017 Justin Hershey. All rights reserved.
//

import UIKit

class BouncingBallsView: UIView, UICollisionBehaviorDelegate {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    
    var circlesArray: [UIDynamicItem] = [UIDynamicItem]()
    
    var animator: UIDynamicAnimator!
    var gravity: UIGravityBehavior!
    var collision: UICollisionBehavior!
    var itemBehaviour: UIDynamicItemBehavior!
    
    var gravityMagnitude: CGFloat = 0.3
    var circleColors: [UIColor] = [UIColor]()
    var numBalls: Int = 4;
    
    init(frame: CGRect, numBalls: Int, ballColors: [UIColor]){
        super.init(frame: frame)
        
//        self.backgroundColor = UIColor.gray
        self.numBalls = numBalls
        self.circleColors = ballColors
        animator = UIDynamicAnimator(referenceView: self)
        
        
        //setup the balls
        self.setupSubBalls()
        
        //setup behaviors
        self.setupBehaviors()
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setupSubBalls(){
        
        self.isHidden = true
        
        //add circles to view
        for i in 0...numBalls - 1{
            
            let ballsFloat = CGFloat(self.numBalls)
            let circleWidth = self.bounds.width / (ballsFloat * 2)
            
            //setup circle frame based on it's position in the array
            let circleFrame: CGRect = CGRect(x: self.bounds.minX + (CGFloat(i) * circleWidth), y: self.bounds.minY + CGFloat(i) * circleWidth, width: circleWidth, height: circleWidth)
            
            //circle attributes
            let circle = UIView(frame:circleFrame)
            circle.tag = i
            circle.layer.cornerRadius = circle.bounds.width / 2
            circle.clipsToBounds = true
            circle.backgroundColor = self.circleColors[i % circleColors.count];
            
            if i % 2  == 1 {
                circle.center = CGPoint(x: CGFloat(i) * self.bounds.width/ballsFloat + circleWidth, y: self.bounds.maxY - 3 * circleWidth)
            }else{
                circle.center = CGPoint(x: CGFloat(i) * self.bounds.width/ballsFloat + circleWidth, y: self.bounds.maxY - 4 * circleWidth)
            }
            
            
            self.circlesArray.append(circle)
            self.addSubview(circle)
        }
    }
    
    func setupBehaviors(){
        
        //setup animator behaviors
        gravity = UIGravityBehavior(items: circlesArray)
        gravity.magnitude = self.gravityMagnitude
        
        collision = UICollisionBehavior(items: circlesArray)
        collision.translatesReferenceBoundsIntoBoundary = true
        collision.collisionDelegate = self
        
        
        itemBehaviour = UIDynamicItemBehavior(items: circlesArray)
        itemBehaviour.allowsRotation = false
        itemBehaviour.elasticity = 1.0
    }
    
    
    //sets the behaviors and subviews to restart the animation
    func startAnimating(){
        
        //we could run setup sub balls again without checking to show one ball on top of another, it's kind of cool looking
        if (self.circlesArray.count == 0){
            self.setupSubBalls()
        }
        
        if self.animator != nil{
            self.setupBehaviors()
        }
        
        if gravity != nil{
            animator.addBehavior(gravity)
        }
        
        if collision != nil{
            animator.addBehavior(collision)
        }
        
        if itemBehaviour != nil{
            animator.addBehavior(itemBehaviour)
        }
        
        self.itemBehaviour.isAnchored = false
        self.isHidden = false
        
    }
    
    
    // removes subviews, behaviors and hides self
    func stopAnimating(){
        
        self.circlesArray = [UIDynamicItem]()
        
        for view in self.subviews{
            view.removeFromSuperview()
        }
        
        self.itemBehaviour.isAnchored = true
        self.isHidden = true
        
        self.animator.removeAllBehaviors()
    }
    
}
