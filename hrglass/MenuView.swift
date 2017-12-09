//
//  MenuView.swift
//  hrglass
//
//  Created by Justin Hershey on 4/28/17.
//
//

import UIKit


//menu direction ENUM
enum Direction: String{
    
    case Up = "Up"
    case Down = "Down"
    case Left = "Left"
    case Right = "Right"
    case None = "None"
}

protocol MenuDelegate {
    
}


class MenuView: UIView{
    
    var buttonList: [UIButton]
    var open: Bool
    var buttonSize: CGSize
    var parentViewController = UIViewController()

    var listCount: Int
    var startCenter: CGPoint
    var offset: Bool = false
    var direction: Direction = .None
    var startButton: UIButton!
    var spacing: CGFloat = 0.0
    var buttonSpinAngle: CGFloat = 0
    var buttonScalor: CGFloat = 0.7
    var menuAnimationInterval:TimeInterval = 0.3
    
    var backgroundImageView: UIImageView!
    var backgroundImageViewCenter: CGPoint = CGPoint.zero
    /*********************************
     *
     * -------- INITIALIZE -------
     *
     *********************************/
    
    //init for FeedViewController
    init(buttonList: [UIButton], feedViewController: FeedViewController, direction: Direction, startButton: UIButton, spacing: CGFloat, buttonScalor: CGFloat) {
        
        
        self.direction = direction
        self.startButton = startButton
        self.parentViewController = feedViewController
        self.buttonList = buttonList
        self.buttonSize = startButton.bounds.size
        self.listCount = buttonList.count
        self.startCenter = startButton.center
        self.spacing = spacing
        self.open = false
        self.buttonScalor = buttonScalor
        
        super.init(frame:backgroundFrameFor())
        setupViews()
        
    }
    
    // init for AddPostViewController
    init(buttonList: [UIButton], addPostViewController: AddPostViewController, direction: Direction, startButton: UIButton, spacing: CGFloat) {
        
        self.direction = direction
        self.startButton = startButton
        self.parentViewController = addPostViewController
        self.buttonList = buttonList
        self.buttonSize = addPostViewController.moodBtn.frame.size
        self.listCount = buttonList.count
        self.startCenter = startButton.center
        self.spacing = spacing
        self.open = false
        
        super.init(frame:backgroundFrameFor())
        setupViews()
    }

    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    //returns background frame based on the direction of the menu
    func backgroundFrameFor() -> CGRect{

        var size: CGSize = CGSize.zero
        var origin: CGPoint = CGPoint.zero
        
        switch self.direction{

        case .Up:

            size = CGSize(width: self.buttonSize.width, height: self.getMenuHeight())
            origin = CGPoint(x: self.startButton.bounds.minX, y: self.startButton.bounds.minY)

        case .Down:

            size = CGSize(width: self.buttonSize.width * buttonScalor, height: self.getMenuHeight())
            origin = CGPoint(x: self.startCenter.x + self.buttonSize.width, y: self.startButton.frame.maxY + self.buttonSize.height * 2 + spacing)

        case .Left:

            size = CGSize(width: getMenuWidth() , height: self.startButton.bounds.height  * buttonScalor)
            origin = CGPoint(x: self.startButton.frame.minX - size.width - spacing, y: self.startCenter.y - self.buttonSize.height/2)

        case .Right:
            
            size = CGSize(width: getMenuWidth() , height: self.startButton.bounds.height * buttonScalor)
            origin = CGPoint(x: self.startCenter.x + self.buttonSize.width / 2 + spacing, y: self.startCenter.y)


        case .None:
            print("None")

        }
        
        return CGRect(origin: origin, size: size)
    }
    
    
    
    
    //configures button views passed from parent, they all start with the same center
    func setupViews(){

        self.startCenter = self.startButton.center
        self.backgroundColor = UIColor.white
        
        //setup a background image view
        self.backgroundImageView = UIImageView(frame: self.frame)
        self.backgroundImageView.backgroundColor = UIColor.clear
        self.backgroundImageView.isHidden = true
        
        //set show center variables
        self.backgroundImageView.center = CGPoint(x: frame.midX,y:startCenter.y)
        self.backgroundImageViewCenter = self.backgroundImageView.center
        
        //move background to start center
        self.backgroundImageView.transform = CGAffineTransform(scaleX: 0.1, y: 1.0)
        self.backgroundImageView.center = self.startCenter
        self.backgroundImageView.alpha = 0.0
        
        
        //set our frame to zero, otherwise it overlaps the views added to the parent VC and we can't touch buttons
        self.frame = CGRect.zero
        
        
        //add background to view
        if let vc:FeedViewController = parentViewController as? FeedViewController{
            vc.view.addSubview(backgroundImageView)
            
        }else{
            
            let vc = parentViewController as! AddPostViewController
            vc.view.addSubview(backgroundImageView)
        }
        
        
        for button in buttonList{

            button.frame.size = CGSize(width:self.startButton.bounds.width * buttonScalor , height: self.startButton.bounds.height * buttonScalor)
            button.center = self.startCenter
            
            button.isHidden = true
            button.alpha = 0.0
            self.backgroundImageView.bringSubview(toFront: button)
            
            if let vc:FeedViewController = parentViewController as? FeedViewController{
                vc.view.addSubview(button)
                
            }else{
            
                let vc = parentViewController as! AddPostViewController
                vc.view.addSubview(button)
                
            }
        }
    }
    
    
    
    //will return the width necessary for the background image view (used in right/left cases)
    func getMenuWidth() -> CGFloat{
        
        let width = self.startButton.bounds.width
        let center = self.startCenter
        let spacing = self.spacing
        
        //indexes shifted up by 1 to allow proper spacing
        let maxIndex: CGFloat = CGFloat(self.buttonList.count)
        
        //get the showing center of the last button
        let lastButtonCenter = center.x - (maxIndex * width) - (spacing * maxIndex)
        //get the showing position of the first button center
        let firstButtonCenter = center.x - (width) - spacing
        
        var distance: CGFloat = 0.0
        
        switch self.direction {
        case .Left:
            
            if(firstButtonCenter > 0){
               distance = abs(firstButtonCenter - lastButtonCenter)
            }else{
                distance = abs(lastButtonCenter - firstButtonCenter)
            }
        case .Right:
            if(lastButtonCenter > 0){
                distance = abs(lastButtonCenter - firstButtonCenter)
            }else{
                distance = abs(firstButtonCenter - lastButtonCenter)
            }
            
            
        default:
            print("Not sure how we got here: getMenuWidth for case other than right or left")
        }
        //return distance between both center X's, and add one button width because we are measuring the distance between two centers
        return distance + buttonSize.width
    }
    
    
    
    //will return the width necessary for the background image view (used in up/down cases)
    func getMenuHeight() -> CGFloat{
        
        let height = self.startButton.bounds.height
        let center = self.startCenter
        let spacing = self.spacing
        
        //indexes shifted up by 1 to allow proper spacing
        let maxIndex: CGFloat = CGFloat(self.buttonList.count)
        
        //get the showing center of the last button
        let lastButtonCenterY = center.y - (maxIndex * height) - (spacing * maxIndex)
        //get the showing position of the first button center
        let firstButtonCenterY = center.y - height - spacing
        
        //return distance between both center X's, and add one button width because we are measuring the distance between two centers
        var distance: CGFloat = 0.0
        
        switch self.direction {
        case .Up:
            distance = firstButtonCenterY - lastButtonCenterY

        case .Down:
            distance =  lastButtonCenterY - firstButtonCenterY
            
        default:
            print("Not sure how we got here: getMenuWidth for case other than right or left")
        }
        //return distance between both center X's, and add one button width because we are measuring the distance between two centers
        return distance + buttonSize.height 
    }
    
    
    
    

    //returns button for the index of the parameter given
    func buttonForIndex(index:Int) -> UIButton{
        
        return self.buttonList[index]
        
    }
    
    
    /********************************
     *
     *      ANIMATION FUNCTIONS
     *
     ********************************/
    
    func spinMenuAnimation(angle: CGFloat){
        
        UIView.animate(withDuration: menuAnimationInterval, animations: {
            
            if let _: FeedViewController = self.parentViewController as? FeedViewController{
                
                self.startButton.transform = CGAffineTransform.init(rotationAngle: angle)
                
            }
        })
    }
    
    
    //animates the background image view: by default the background is clear and won't be visible
    func backgroundAnimation(show: Bool){
        UIView.animate(withDuration: menuAnimationInterval, animations: {
            
            if show{
                self.backgroundImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                self.backgroundImageView.center = self.backgroundImageViewCenter
                self.backgroundImageView.isHidden = false
                self.backgroundImageView.alpha = 1.0
                
            }else{
                
                self.backgroundImageView.transform = CGAffineTransform(scaleX: 0.1, y: 1.0)
                self.backgroundImageView.center = self.startCenter
                self.backgroundImageView.alpha = 0.0
            }
        }, completion: { finished in
            
            if !show{
                self.backgroundImageView.isHidden = true
            }
        })
    }

    
    //OPEN MENU
    func show () {
        
        let height = self.startButton.bounds.height
        let width = self.startButton.bounds.width
        let center = self.startCenter
        
        self.open = true

        spinMenuAnimation(angle: buttonSpinAngle)
        backgroundAnimation(show: true)
        
        for button: UIButton in buttonList {
            
            let index: CGFloat = CGFloat(buttonList.index(of: button)!) + 1.0

            //show buttons animation
            //animate the button center movement on open, center is calculated base on the button index
            UIView.animate(withDuration: menuAnimationInterval, animations: {
            
                button.isHidden = false
                button.alpha = 1.0
                
                let newSpacing = (self.spacing * index)
                
                switch self.direction{
                    
                case .Up:
                    button.center = CGPoint(x: center.x ,y: center.y - (index * height) - newSpacing)
                case .Down:
                    button.center = CGPoint(x: center.x ,y: center.y + (index * height) + newSpacing)
                case .Left:
                    button.center = CGPoint(x: center.x - (index * width) - newSpacing ,y: center.y )
                case .Right:
                    button.center = CGPoint(x: center.x + (index * width) + newSpacing ,y: center.y)
                case .None:
                    print("None")
                    
                }
            })
        }
    }
    

    //HIDE MENU
    func close (){

        var i = 0
        spinMenuAnimation(angle: 0)
        backgroundAnimation(show: false)
        
        for button: UIButton in buttonList{
            
            //move all buttons back to start center and hide
            UIView.animate(withDuration: menuAnimationInterval - TimeInterval(CGFloat(i/10)), animations: {
                
                button.alpha = 0.0
                
                if(self.offset){
                    button.center = CGPoint(x: self.startCenter.x + self.startButton.bounds.width, y: self.startCenter.y)
                }else{
                    
                    button.center = self.startCenter
                }
            }, completion: { finished in

                i += 1
                
                button.isHidden = true
            })
        }
        self.open = false
    }
}
