//
//  WelcomeViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/17/17.
//
//

import UIKit
import Firebase

class WelcomeViewController: UIViewController {

    
    let colors: Colors = Colors()
    var handle: AuthStateDidChangeListenerHandle! = nil
    
    @IBOutlet weak var signUpBtn: UIButton!
    
    @IBOutlet weak var loginBtn: UIButton!
    
    @IBOutlet weak var logoImageView: UIImageView!
    
    var splashView: UIView!
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
        
        loginBtn.layer.borderColor = UIColor.white.cgColor
        loginBtn.layer.borderWidth = 2.0
        
        self.logoImageView.layer.cornerRadius = self.logoImageView.frame.width/2
        
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
