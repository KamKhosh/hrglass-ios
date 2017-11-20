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
    var dataManager: DataManager = DataManager()
    
    
    @IBOutlet weak var submitBtn: UIButton!
    
    @IBOutlet weak var backBtn: UIButton!
    
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.usernameField.delegate = self
        self.addBottomLine(forView: usernameField, tag: 1)
        
        //if parent view is from account, show back button and change button title
        if parentView == "accountView"{
            
            self.submitBtn.setTitle("Change Username", for: .normal)
            self.backBtn.isHidden = false
        }
        
        
        usernameField.attributedPlaceholder =
            NSAttributedString(string: "Username", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        //swipe down gesture setup -- to dismiss keyboard
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
    
    @objc func dismisskeyboard(){
        
        self.usernameField.resignFirstResponder()
        
    }

    @IBAction func submitAction(_ sender: Any) {
        
        //TODO: ADD Username Check so user's can't use an existing username
        if(self.usernameField.text != ""){
            
            dataManager.checkIfUsernameExists(username: self.usernameField.text!, completion: { (exists) in
                
                if (exists){
                    //username already exists
                    self.usernameExistsAlert()
                    
                }else{
                    //set new usename
                    let username = self.usernameField.text!
                    
                    let data: NSDictionary = UserDefaults.standard.dictionary(forKey: "userData")! as NSDictionary
                    
                    let tempDict: NSMutableDictionary = data.mutableCopy() as! NSMutableDictionary
                    tempDict.setValue(username, forKey: "username")
                    
                    UserDefaults.standard.set(tempDict, forKey: "userdata")
                    UserDefaults.standard.synchronize()
                    
                    let usernameRef = self.ref.child("Users").child(self.currentUserId!).child("username")
                    let usernames = self.ref.child("Usernames").child(self.currentUserId!)
                    usernames.setValue(self.usernameField.text!)
                    usernameRef.setValue(self.usernameField.text!)
                    
                    if self.parentView == "feedView"{
                        self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                    }else if self.parentView == "accountView" {
                        self.performSegue(withIdentifier: "unwindToAccount", sender: nil)
                    }
                }
            })
        }else{
            let views: [UIView] = self.view.subviews
            for view in views {
                if view.tag == 1{
                    view.layer.borderColor = UIColor.red.cgColor
                }
            }
        }
    }
    
    
    //add textfield bottom lines
    func addBottomLine(forView: UITextField, tag: Int){
        
        let view = UIView(frame:CGRect(x:forView.frame.minX ,y:forView.frame.maxY ,width: forView.frame.width, height: 1.0))
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1.0
        view.alpha = 0.3
        view.tag = tag
        self.view.addSubview(view)
        
    }

    
    //username exitst alert
    func usernameExistsAlert(){
        
        let alert: UIAlertController = UIAlertController(title: "Username already taken", message: "choose another", preferredStyle: .actionSheet)
        
        let ok: UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action) in
            
            self.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }

    
    
    /**********************
     * TEXT FIELD DELEGATE
     ***********************/
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let views: [UIView] = self.view.subviews
        for view in views {
            if (view.tag == 1){
                view.layer.borderColor = UIColor.white.cgColor
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        self.dismisskeyboard()
        return true
    }
    
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "unwindToAccounts"{
            
            let vc: AccountViewController = segue.destination as! AccountViewController
            vc.newUsername = self.usernameField.text!
            
        }else if segue.identifier == "unwindToFeed"{
            
            
        }
        
    }

}
