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
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func validLoginCheck(){
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            
            if(Auth.auth().currentUser != nil){

                self.signUpBtn.isHidden = true
                self.loginBtn.isUserInteractionEnabled = false
                
                Auth.auth().removeStateDidChangeListener(self)
                self.performSegue(withIdentifier: "toFeedSegue", sender: nil)
                
            }else {
                
                Auth.auth().removeStateDidChangeListener(self)
                self.signUpBtn.isHidden = false
                self.loginBtn.isUserInteractionEnabled = true
                
            }
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
