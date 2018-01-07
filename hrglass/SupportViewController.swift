//
//  SupportViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 1/7/18.
//

import UIKit
import Firebase

class SupportViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var emailLbl: UILabel!
    @IBOutlet weak var feedbackTextView: UITextView!
    @IBOutlet weak var submitBtn: UIButton!
    
    @IBOutlet weak var keyboardHeightLayoutConstraint: NSLayoutConstraint!
    
    
    var email: String = ""
    let placeholderText = "Enter your question or feedback here!"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.feedbackTextView.layer.borderColor = UIColor.darkGray.cgColor
        self.feedbackTextView.layer.borderWidth = 1.0
        self.feedbackTextView.layer.cornerRadius = 5.0
        
        
        self.feedbackTextView.delegate = self
        self.feedbackTextView.text = "Enter your question or feedback here!"
        if let data: NSDictionary = UserDefaults.standard.value(forKey: "userData") as? NSDictionary{
            
            self.email = (data.value(forKey:"email")as? String)!
            self.emailLbl.text = self.email
        }
        self.adjustUITextViewHeight(arg: self.feedbackTextView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    @IBAction func submitAction(_ sender: Any) {
        
        if self.feedbackTextView.text != "" && self.feedbackTextView.text != placeholderText{
            
            let uid = Auth.auth().currentUser?.uid
            let supportRef: DatabaseReference = Database.database().reference().child("Support").child(uid!)
            let queryDict: NSDictionary = NSDictionary.init(dictionary: ["query":self.feedbackTextView.text, "email":self.email, "uid":uid ?? ""])
            
            supportRef.setValue(queryDict)
        }
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    /***********************************
     *
     * ----- TEXTVIEW DELEGATES -----
     *
     ***********************************/
    
    func textViewDidBeginEditing(_ textView: UITextView){
        
        if(textView.text == self.placeholderText){
            textView.text = ""
        }
    }
    
    
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if(textView.text == ""){
            textView.text = self.placeholderText
        }

        self.feedbackTextView.center = CGPoint(x: self.view.bounds.midX,y: self.view.frame.midY)
    }
    
    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n")
        {
            self.feedbackTextView.resignFirstResponder
            self.feedbackTextView.endEditing(true)
            return false
        }
        return true
    }
    
    
    
    func textViewDidChange(_ textView: UITextView) {
        let numLines: Int = Int(textView.contentSize.height / textView.font!.lineHeight);
        
        if numLines > 1{
            
            self.adjustUITextViewHeight(arg: textView)
            self.feedbackTextView.center = CGPoint(x: self.view.center.x,y: self.view.frame.height - keyboardHeightLayoutConstraint.constant - self.feedbackTextView.frame.height - 5)
        }else {
            textView.isScrollEnabled = true
        }
    }
    
    
    
    func adjustUITextViewHeight(arg : UITextView)
    {
        
        let fixedWidth = arg.frame.size.width
        arg.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = arg.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = arg.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        arg.frame = newFrame
    }
    
    
    
    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                self.keyboardHeightLayoutConstraint?.constant = 0.0
            } else {
                self.keyboardHeightLayoutConstraint?.constant = endFrame?.size.height ?? 0.0
            }
            
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
}
