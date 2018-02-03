//
//  ForgotPasswordViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 1/28/18.
//

import UIKit
import Firebase

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate {
    
    
    
    @IBOutlet weak var resetBtn: UIButton!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var emailView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailTextField.attributedPlaceholder =
            NSAttributedString(string: "Email", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        self.emailTextField.delegate = self

        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        self.setupView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func resetAction(_ sender: Any) {
        
        let email: String = self.emailTextField.text!
        
        if(self.isValidEmail(testStr: email)){
            
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                // Your code here
                var message: String = ""
                var title: String = ""
                
                if error == nil{
                    
                    title = "Password reset email sent"
                    message = self.emailTextField.text!
                    
                
                }else{
                    title = "Error"
                    message = "Failed to send reset email"
                    
                }
                
                self.showAlert(title: title, message: message)
            }
            
        }else{
            
            self.showAlert(title: "Warning", message: "Not a valid email address")
        }
    }
    
    
    
    func showAlert(title: String, message: String){
        
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok:  UIAlertAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            self.performSegue(withIdentifier: "unwindToLogin", sender: nil)
        })
        
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
        
        
    }
    
    
    /**********************
     * TEXT FIELD DELEGATE
     ***********************/
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    
    
    //add bottom lines to textFields
    func setupView(){
        
        self.addBottomLine(forView: self.emailView, tag: 1)
        
        
    }
    
    
    //add bottom line method
    func addBottomLine(forView: UIView, tag: Int){
        
        let view = UIView(frame:CGRect(x:forView.frame.minX ,y:forView.frame.maxY ,width: forView.frame.width, height: 1.0))
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1.0
        view.alpha = 0.2
        view.tag = tag
        self.view.addSubview(view)
    }
    
    
    //check for a valid email address
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
