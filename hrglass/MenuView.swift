//
//  MenuView.swift
//  hrglass
//
//  Created by Justin Hershey on 4/28/17.
//
//

import UIKit



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
    
    /*********************************
     *
     * -------- INITIALIZE -------
     *
     *********************************/
    
    init(buttonList: [UIButton], feedViewController: FeedViewController, offset: Bool, direction: Direction) {
        
        self.offset = offset
        self.direction = direction
        self.parentViewController = feedViewController
        self.buttonList = buttonList
        self.buttonSize = feedViewController.menuButton.frame.size
        self.listCount = buttonList.count
        self.startCenter = feedViewController.menuButton.center
        self.open = false
        
        super.init(frame:CGRect(x: startCenter.x - buttonSize.width, y: startCenter.y - buttonSize.height, width: 1, height: 1 ))
        
        setupViews()
    }
    
    init(buttonList: [UIButton], addPostViewController: AddPostViewController, offset: Bool, direction: Direction) {
        
        self.offset = offset
        self.direction = direction
        self.parentViewController = addPostViewController
        self.buttonList = buttonList
        self.buttonSize = addPostViewController.moodBtn.frame.size
        self.listCount = buttonList.count
        self.startCenter = addPostViewController.moodBtn.center
        self.open = false
        
        super.init(frame:CGRect(x: startCenter.x - buttonSize.width, y: startCenter.y - buttonSize.height, width: 1, height: 1 ))
        
        setupViews()
    }

    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    func setupViews(){
        
        var center: CGPoint = self.startCenter
        
        if offset{
            
            center = CGPoint(x: self.startCenter.x + self.buttonSize.width, y: self.startCenter.y)
            
        }
        
        for button in buttonList{

            
            button.frame.size = CGSize(width:self.buttonSize.width * 0.7 , height: self.buttonSize.height * 0.7)
            button.center = center
            
            button.isHidden = true
            button.alpha = 0.0
            
            if offset{
                
                let vc = parentViewController as! FeedViewController
                vc.view.addSubview(button)
                
            }else{
                
                let vc = parentViewController as! AddPostViewController
                vc.view.addSubview(button)
                
            }
        }
    }
    

    
    /********************************
     *
     *      ANIMATION FUNCTIONS
     *
     ********************************/
    
    func spinMenuAnimation(angle: CGFloat){
        
        UIView.animate(withDuration: TimeInterval(0.3), animations: {
            
            if self.offset{
                
                let vc = self.parentViewController as! FeedViewController
                vc.menuButton.transform = CGAffineTransform.init(rotationAngle: angle)
                
            }
        })
    }

    
    //OPEN MENU
    func show () {
        
        let height = self.buttonSize.height
        let width = self.buttonSize.width
        let center = self.startCenter
        
        self.open = true

        spinMenuAnimation(angle: -(CGFloat)(Float.pi))
        
        for button: UIButton in buttonList {
            
            let index: CGFloat = CGFloat(buttonList.index(of: button)!) + 1.0

            UIView.animate(withDuration: TimeInterval(index/10.0), animations: {
            
                button.isHidden = false
                button.alpha = 1.0
                
                
                switch self.direction{
                    
                case .Up:
                    button.center = CGPoint(x: center.x ,y: center.y - (index * height))
                case .Down:
                    button.center = CGPoint(x: center.x ,y: center.y + (index * height))
                case .Left:
                    button.center = CGPoint(x: center.x - (index * width) ,y: center.y )
                case .Right:
                    button.center = CGPoint(x: center.x + (index * width) ,y: center.y)
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
        
        for button: UIButton in buttonList{
            
            UIView.animate(withDuration: TimeInterval(0.4 - CGFloat(i/10)), animations: {
                
                button.alpha = 0.0
                
                if(self.offset){
                    button.center = CGPoint(x: self.startCenter.x + self.buttonSize.width, y: self.startCenter.y)
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
