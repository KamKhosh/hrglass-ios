//
//  ChangePasswordViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/23/17.
//
//

import UIKit
import Firebase

class ChangePasswordViewController: UIViewController {

    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var newPasswordField: UITextField!
    @IBOutlet weak var oldPasswordField: UITextField!
    
    
    /*********************************
     *
     * ---------- LIFECYCLE ---------
     *
     *********************************/
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.addBottomLine(forView: oldPasswordField, tag: 1)
        self.addBottomLine(forView: newPasswordField, tag: 2)
        self.addBottomLine(forView: confirmPasswordField, tag: 3)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*********************************
     *
     * ---------- ACTIONS ---------
     *
     *********************************/
    
    @IBAction func changeAction(_ sender: Any) {
        
        
        
        if(oldPasswordField.text == ""){
            print("password Empty")
            let views: [UIView] = self.view.subviews
            for view in views {
                if view.tag == 1{
                    view.layer.borderColor = UIColor.red.cgColor
                }
            }
        }else if(confirmPasswordField.text == ""){
            print("confirm password Empty")
            let views: [UIView] = self.view.subviews
            for view in views {
                if view.tag == 2{
                    view.layer.borderColor = UIColor.red.cgColor
                }
            }
        }else{
            if (confirmPasswordField.text == newPasswordField.text){
                
                let oldPassword: String = oldPasswordField.text!
                let newPassword: String = confirmPasswordField.text!
                
                
                //                let uid: String = (Auth.auth().currentUser?.uid)!
                let email: String = (Auth.auth().currentUser?.email!)!
                
                
                //                EmailAuthProvid\er
                //                let credential = Auth.auth().credential(withEmail: email, password: oldPassword)
                let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
                
                // Prompt the user to re-provide their sign-in credentials
                
                Auth.auth().currentUser?.reauthenticate(with: credential) { error in
                    if error != nil {
                        // An error happened.
                        let alert = UIAlertController(title: "Authentication Failed", message: "Check old Password", preferredStyle: .alert)
                        
                        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        
                        alert.addAction(defaultAction)
                        
                        self.present(alert, animated: true, completion: nil)
                        
                        
                    } else {
                        // User re-authenticated.
                        
                        Auth.auth().currentUser?.updatePassword(to: newPassword, completion: { (error) in
                            
                            if(error == nil){
                                
                                let alert = UIAlertController(title: "Success", message: "Password Changed", preferredStyle: .alert)
                                
                                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: self.passwordChanged(alert:))
                                
                                alert.addAction(defaultAction)
                                
                                self.present(alert, animated: true, completion: nil)
                                
                                
                            }
                        })
                        
                    }
                }
                
                
                
                
                
            }else{
                let views: [UIView] = self.view.subviews
                for view in views {
                    if view.tag == 5{
                        view.layer.borderColor = UIColor.red.cgColor
                    }
                }
            }
        }
    }


    
    
    func addBottomLine(forView: UITextField, tag: Int){
        
        let view = UIView(frame:CGRect(x:forView.frame.minX ,y:forView.frame.maxY ,width: forView.frame.width, height: 1.0))
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = 1.0
        view.alpha = 0.2
        view.tag = tag
        self.view.addSubview(view)
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    

    func passwordChanged(alert: UIAlertAction){
        
        self.performSegue(withIdentifier: "unwindToAccounts", sender: nil)
    }

}
