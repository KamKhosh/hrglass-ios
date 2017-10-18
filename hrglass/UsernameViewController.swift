//
//  InfoSetupViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 6/21/17.
//
//

import UIKit
import Firebase

class UsernameViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var usernameField: UITextField!
    
    let currentUserId = Auth.auth().currentUser?.uid
    let ref = Database.database().reference()
    var parentView: String = "feedView"
    @IBOutlet weak var submitBtn: UIButton!
    
    @IBOutlet weak var backBtn: UIButton!
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.usernameField.delegate = self
        self.addBottomLine(forView: usernameField, tag: 1)
        
        if parentView == "accountView"{
            
            self.submitBtn.setTitle("Change Username", for: .normal)
            self.backBtn.isHidden = false
        }
        
        
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismisskeyboard))
        swipeDown.direction = .down
        swipeDown.delegate = self
        self.view.addGestureRecognizer(swipeDown)
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /***********************
     *
     *      ACITONS
     *
     ************************/
    
    func dismisskeyboard(){
        
        self.usernameField.resignFirstResponder()
        
    }

    @IBAction func submitAction(_ sender: Any) {
        
        //TODO: ADD Username Check so user's can't use an existing username
        if(self.usernameField.text != ""){
            let username = self.usernameField.text!
            
            let data: NSDictionary = UserDefaults.standard.dictionary(forKey: "userData")! as NSDictionary
            
            let tempDict: NSMutableDictionary = data.mutableCopy() as! NSMutableDictionary
            tempDict.setValue(username, forKey: "username")
            
            UserDefaults.standard.set(tempDict, forKey: "userdata")
            UserDefaults.standard.synchronize()
            
            let usernameRef = ref.child("Users").child(currentUserId!).child("username")
            usernameRef.setValue(self.usernameField.text!)

            
            if self.parentView == "feedView"{
                performSegue(withIdentifier: "unwindToFeed", sender: nil)
            }else if self.parentView == "accountView" {
                performSegue(withIdentifier: "unwindToAccount", sender: nil)
            }
            
            
        }else{
            let views: [UIView] = self.view.subviews
            for view in views {
                if view.tag == 1{
                    view.layer.borderColor = UIColor.red.cgColor
                }
            }
        }
    }
    
    
    func addBottomLine(forView: UITextField, tag: Int){
        
        let view = UIView(frame:CGRect(x:forView.frame.minX ,y:forView.frame.maxY ,width: forView.frame.width, height: 1.0))
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = 1.0
        view.alpha = 0.3
        view.tag = tag
        self.view.addSubview(view)
        
    }


    
    
    /**********************
     * TEXT FIELD DELEGATE
     ***********************/
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let views: [UIView] = self.view.subviews
        for view in views {
            if (view.tag == 1){
                view.layer.borderColor = UIColor.black.cgColor
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        self.dismisskeyboard()
        return true
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "unwindToAccounts"{
            
            let vc: AccountViewController = segue.destination as! AccountViewController
            vc.newUsername = self.usernameField.text!
            
        }else if segue.identifier == "unwindToFeed"{
            
            
        }
        
    }

}
