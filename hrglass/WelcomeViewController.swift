//
//  WelcomeViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/17/17.
//
//

import UIKit
import Firebase

class WelcomeViewController: UIViewController, UIGestureRecognizerDelegate {

    
    let colors: Colors = Colors()
    var handle: AuthStateDidChangeListenerHandle! = nil
    
    @IBOutlet weak var signUpBtn: UIButton!
    
    @IBOutlet weak var loginBtn: UIButton!
    
    @IBOutlet weak var logoImageView: UIImageView!
    
    @IBOutlet weak var leftCircle: UIView!
    
    @IBOutlet weak var middleCircle: UIView!
    
    @IBOutlet weak var rightCircle: UIView!
    
    @IBOutlet weak var descriptionLbl: UILabel!
    
    @IBOutlet weak var titleLbl: UILabel!
    
    
    @IBOutlet weak var taglineContentView: UIView!
    
    var splashView: UIView!
    
    let LEFT_TEXT: String = "Choose from Photo, Video, Song, Article, Written Message"
    let RIGHT_TEXT: String = "You are only given one post per day. After 24 hours, your post is removed from the home feed"
    let MIDDLE_TEXT: String = "Names are hidden until you like a post. Thus, the best content will truly make itself known"

    let LEFT_TITLE: String = "Content Creation"
    let RIGHT_TITLE: String = "Bring real content back"
    let MIDDLE_TITLE: String = "Let real content shine"
    
    var contentViewing: String = "left"
    
    
    /*******************************
     *
     *  LIFECYCLE
     *
     *******************************/
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.navigationController?.navigationBar.isHidden = true
        
        let backgroundLayer = colors.getGradientLayer()
        backgroundLayer.frame = view.frame
        view.layer.insertSublayer(backgroundLayer, at: 0)
                
        self.logoImageView.layer.cornerRadius = self.logoImageView.frame.width/2
        self.signUpBtn.layer.cornerRadius = 3.0
        self.signUpBtn.layer.borderWidth = 1.0
        self.signUpBtn.layer.borderColor = colors.getDarkerPink().cgColor
        
        let swipeGestureLeft: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeActionLeft))
        swipeGestureLeft.direction = .left
        self.view.addGestureRecognizer(swipeGestureLeft)
        
        let swipeGestureRight: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeActionRight))
        swipeGestureRight.direction = .right
        self.view.addGestureRecognizer(swipeGestureRight)
        
        setupCircles()
        validLoginCheck()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.splashView != nil{
            self.splashView.removeFromSuperview()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func validLoginCheck(){
        
        //show splash overlay
        self.showLoginSplash()
        
        //listen for auth state changes
        Auth.auth().addStateDidChangeListener { (auth, user) in
            
            if(Auth.auth().currentUser != nil){
                
                //user not nil
                //disable login/create buttons
                self.signUpBtn.isHidden = true
                self.loginBtn.isUserInteractionEnabled = false
                
                //remove auth listener and goto feed
                Auth.auth().removeStateDidChangeListener(self)
                self.performSegue(withIdentifier: "toFeedSegue", sender: nil)
                
            }else {
                //no user
                //remove splash overlay
                if self.splashView != nil{
                   self.splashView.removeFromSuperview()
                }
                
                //remove auth listener and allow login/signup button interactions
                Auth.auth().removeStateDidChangeListener(self)
                self.signUpBtn.isHidden = false
                self.loginBtn.isUserInteractionEnabled = true
                
            }
        }
    }
    
    
    //shows overlay so we don't see the login screen
    func showLoginSplash(){
        
        let frac: CGFloat = 0.7
        splashView = UIView(frame: CGRect(x: 0,y: 0, width: self.view.frame.width ,height:self.view.frame.height))
        splashView.backgroundColor = UIColor.black
        self.view.addSubview(self.splashView)
        let splashImageView: UIImageView = UIImageView(frame: CGRect(x: self.view.frame.width/2 - (self.view.frame.width * frac)/2 ,y: self.view.frame.height/2 - (self.view.frame.width * frac) / 2, width: self.view.frame.width * frac ,height:self.view.frame.width * frac))
        splashImageView.contentMode = .scaleAspectFill
        splashImageView.image = UIImage(named: "logo gradient")
        splashView.addSubview(splashImageView)
    }
    
    func setupCircles(){
        
        self.leftCircle.layer.cornerRadius = self.leftCircle.frame.width / 2
        self.middleCircle.layer.cornerRadius = self.middleCircle.frame.width / 2
        self.rightCircle.layer.cornerRadius = self.rightCircle.frame.width / 2
        self.leftCircle.backgroundColor = UIColor.white
        
    }

    
    
    
    //handle left swipes,
    @objc func swipeActionLeft(){
        
        //if we are on the left or middle view we can still
        if(self.contentViewing == "left"){
            self.contentViewing = "middle"
            self.descriptionLbl.text = MIDDLE_TEXT
            self.titleLbl.text = MIDDLE_TITLE
            
            self.leftCircle.backgroundColor = UIColor.gray
            self.middleCircle.backgroundColor = UIColor.white
            
        }
        else if (self.contentViewing == "middle"){
            self.contentViewing = "right"
            self.descriptionLbl.text = RIGHT_TEXT
            self.titleLbl.text = RIGHT_TITLE
            
            self.rightCircle.backgroundColor = UIColor.white
            self.middleCircle.backgroundColor = UIColor.gray
         
            
        }
    }
    
    
    //handle right swipes
    @objc func swipeActionRight(){
        
        if(self.contentViewing == "right"){
            self.contentViewing = "middle"
            self.descriptionLbl.text = MIDDLE_TEXT
            self.titleLbl.text = MIDDLE_TITLE
            
            self.rightCircle.backgroundColor = UIColor.gray
            self.middleCircle.backgroundColor = UIColor.white
            
        }else if (self.contentViewing == "middle"){
            self.contentViewing = "left"
            self.descriptionLbl.text = LEFT_TEXT
            self.titleLbl.text = LEFT_TITLE
            
            self.leftCircle.backgroundColor = UIColor.white
            self.middleCircle.backgroundColor = UIColor.gray
            
        }
    }
    
    
    /*******************************
     *
     *  NAVIGATION
     *
     *******************************/

    
    @IBAction func unwindToWelcome(unwindSegue: UIStoryboardSegue) {

    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        Auth.auth().removeStateDidChangeListener(self)
  
    }

}
