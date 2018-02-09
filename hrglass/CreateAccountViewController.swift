//
//  CreateAccountViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/17/17.
//
//

import UIKit
import Firebase
import FacebookLogin
import FacebookCore



class CreateAccountViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, LoginButtonDelegate, CheckBoxDelegate{

    

    @IBOutlet weak var fullnameField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
//    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var createAccountBtn: UIButton!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var termsCheckbox: CheckBox!
    
    
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var usernameView: UIView!
    @IBOutlet weak var fullnameView: UIView!
    
    @IBOutlet weak var passwordImageView: UIImageView!
    @IBOutlet weak var emailImageView: UIImageView!
    @IBOutlet weak var usernameImageView: UIImageView!
    @IBOutlet weak var fullnameImageView: UIImageView!
    
    let colors: Colors = Colors()
    var ref: DatabaseReference!
    var parentVC: String = "welcome"
    
    let dataManager: DataManager = DataManager()
    var usernameFlag: Bool = false;
    var currentUser: User!
    var validUsername: Bool = false;
    var fbLoginBtn: LoginButton = LoginButton.init(readPermissions: [.publicProfile, .email])
    
    @IBOutlet weak var loginIndicatorView: UIActivityIndicatorView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Firebase Reference
        ref = Database.database().reference()
        self.termsCheckbox.delegate = self
        //Delegate Setup
        self.textFieldDelegateSetup()
        self.scrollView.delegate = self
        self.createAccountBtn.layer.cornerRadius = 3.0
        self.createAccountBtn.layer.borderWidth = 1.0
        self.createAccountBtn.layer.borderColor = colors.getDarkerPink().cgColor
        
        //Keyboard Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //set placeholder's and text color
        fullnameField.attributedPlaceholder =
            NSAttributedString(string: "Fullname", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        passwordField.attributedPlaceholder =
            NSAttributedString(string: "Password", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
//        confirmPasswordField.attributedPlaceholder =
//            NSAttributedString(string: "Confirm Password", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        emailField.attributedPlaceholder =
            NSAttributedString(string: "Email", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        usernameField.attributedPlaceholder =
            NSAttributedString(string: "Username", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        //get usernames dictionary which we will eventually be checking against
//        self.dataManager.getUsernamesDictionary { (usernameDict) in
//            if(usernameDict.count > 0){
//                self.usernames = usernameDict
//            }
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        //init fb login button
//        fbLoginBtn = LoginButton.init(readPermissions: [.publicProfile, .email])
        fbLoginBtn.delegate = self
        fbLoginBtn.frame.size = self.createAccountBtn.frame.size
        fbLoginBtn.center = CGPoint(x: self.createAccountBtn.frame.midX, y: self.createAccountBtn.frame.maxY + 40)
        fbLoginBtn.isUserInteractionEnabled = false
        
        self.scrollContentView.addSubview(fbLoginBtn)
        
        //View Setup -- bottom lines
        self.setupView()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    
    /**************************
     *   Checkbox Delegate
     **************************/
    
    
    func didPress(sender: CheckBox) {
        if self.termsCheckbox.isChecked{
            self.fbLoginBtn.isUserInteractionEnabled = true
        }else{
            self.fbLoginBtn.isUserInteractionEnabled = false
        }
    }
    
    
    
    
    
    /**************
     *   ACTIONS
     **************/
    
    
    
    
    
    
    
    @IBAction func createAccountAction(_ sender: Any) {
        
        //CREATE ACCOUNT W/ Email and Password
        
        //if any of the fields are black the underline will be changed to red
        if(fullnameField.text == ""){
            
            self.fullnameImageView.isHighlighted = true
            print("Fullname Empty")
            let views: [UIView] = self.scrollContentView.subviews
            for view in views {
                if view.tag == 1{
                    view.layer.borderColor = colors.getMenuColor().cgColor
                }
            }
        }else if(usernameField.text == ""){
            
            self.usernameImageView.isHighlighted = true
            print("username Empty")
            let views: [UIView] = self.scrollContentView.subviews
            for view in views {
                if view.tag == 2{
                    view.layer.borderColor = colors.getMenuColor().cgColor
                }
            }
        }else if(emailField.text == ""){
        
            self.emailImageView.isHighlighted = true
            print("email Empty")
            let views: [UIView] = self.scrollContentView.subviews
            for view in views {
                if view.tag == 3{
                    view.layer.borderColor = colors.getMenuColor().cgColor
                }
            }
        }else if !self.isValidEmail(testStr: emailField.text!){
            
            self.emailField.becomeFirstResponder()
            //email address validation
            let views: [UIView] = self.scrollContentView.subviews
            for view in views {
                if view.tag == 3{
                    view.layer.borderColor = colors.getMenuColor().cgColor
                }
            }
        }else if(passwordField.text == ""){
            
            self.passwordImageView.isHighlighted = true
            print("password Empty")
            let views: [UIView] = self.scrollContentView.subviews
            for view in views {
                if view.tag == 4{
                    view.layer.borderColor = colors.getMenuColor().cgColor
                }
            }
        }
        
//        else if(confirmPasswordField.text == ""){
//            print("confirm password Empty")
//            let views: [UIView] = self.scrollContentView.subviews
//            for view in views {
//                if view.tag == 5{
//                    view.layer.borderColor = UIColor.red.cgColor
//                }
//            }
//        }
//
        else{
            //all fields are filled out
            
//            if (confirmPasswordField.text == passwordField.text){
            if termsCheckbox.isChecked && validUsername{
                
            
                //TODO: ADD Username Check so user's can't use an existing username, same with e-mail
                //after account created and user logged in
                let email:String = emailField.text!
                let password: String = passwordField.text!
                let fullname: String = fullnameField.text!
                let username: String = usernameField.text!

                createAccountBtn.backgroundColor = UIColor.lightGray
                self.startLoginIndicator()
                
                //CREATE USER AND LOGIN
                Auth.auth().createUser(withEmail: email , password: password) { (user, error) in
                    
                    if(error == nil){
                        // if success, set default userdata
                        let userData: NSDictionary = ["email":email,"username":username, "name":fullname, "bio":"", "isPrivate": false, "coverPhoto":"", "profilePhoto":""]
                        

                        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                            
                            let userRef = self.ref.child("Users").child((user?.uid)!)
                            
                            print(user?.uid ?? "")
                            
                            if(error == nil){
                                
                                
                                
                                        userRef.setValue(userData, withCompletionBlock: { (error, ref) in
                                            
                                            //setup initial following -- auto follow hr.glass
                                            let newFollowing: NSDictionary = ["lGDGX2kvNBVkXUPKavqMoVzHil43":0]
                                            let followingList = self.ref.child("Following").child((user?.uid)!).child("following_list")
                                            
                                            followingList.setValue(newFollowing)
                                            let followingCount = self.ref.child("Following").child((user?.uid)!).child("following_count")
                                            followingCount.setValue(1)
                                            
                                            //set username
                                            let usernameRef = Database.database().reference().child("Usernames").child(username)
                                            usernameRef.setValue(0)
                                            
                                            
                                            if(error == nil){
                                                self.performSegue(withIdentifier: "toFeedSegue", sender: nil)
                                            }
                                        })
                            }
                        }
                    }
                }
                
            }else{
                
                if(!termsCheckbox.isChecked){
                    self.showToast(message: "Accept the Terms and Conditions to continue")
                }else if(!validUsername){
                    self.chooseDifferentUsernameAlert()
                }
            }
        }
    }
    
    //username in use alert
    func chooseDifferentUsernameAlert(){
        
        let alert: UIAlertController = UIAlertController(title: "Username already taken", message: "choose another", preferredStyle: .alert)
        
        let ok: UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action) in
            
            self.usernameField.text = ""
            self.usernameField.becomeFirstResponder()
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func invalidCharactersAlert(){
        
        let alert: UIAlertController = UIAlertController(title: "Invalid Characters", message: "Acceptable ones are 0-9 A-z _ -", preferredStyle: .alert)
        
        let ok: UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action) in
            
            self.usernameField.text = ""
            self.usernameField.becomeFirstResponder()
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
        
        
    }

    
    //check for a valid email address
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    
    func isValidUsername(testStr:String) -> Bool {
        let usernameRegEx = "[A-Z0-9a-z_-]{2,64}"
        
        let usernameTest = NSPredicate(format:"SELF MATCHES %@", usernameRegEx)
        return usernameTest.evaluate(with: testStr)
    }
    
    

    //setup textField delegates
    func textFieldDelegateSetup(){
        
        self.fullnameField.delegate = self
        self.usernameField.delegate = self
        self.emailField.delegate = self
        self.passwordField.delegate = self
//        self.confirmPasswordField.delegate = self

    }
    
    
    //add bottom lines to textFields
    func setupView(){
        
        self.addBottomLine(forView: self.fullnameView, tag: 1)
        self.addBottomLine(forView: self.usernameView, tag: 2)
        self.addBottomLine(forView: self.emailView, tag: 3)
        self.addBottomLine(forView: self.passwordView, tag: 4)
//        self.addBottomLine(forView: confirmPasswordField, tag:5)
        
    }

    
    //add bottom line method
    func addBottomLine(forView: UIView, tag: Int){
        
        let view = UIView(frame:CGRect(x:forView.frame.minX ,y:forView.frame.maxY ,width: forView.frame.width, height: 1.0))
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1.0
        view.alpha = 0.2
        view.tag = tag
        self.scrollContentView.addSubview(view)
    }
    
    
    

    
    /**************************
     * FACEBOOK LOGIN DELEGATE
     *************************/
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        //TODO: Logout
    }
    
    
    func loginButtonWillLogin(_ loginButton: LoginButton) -> Bool {
        
        return true
    }
    

    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        //login to firebase
        
        switch result {
        case .failed(let error):
            print(error)
            self.showActionSheetWithTitle(title: "Facebook Login Failed", message: error.localizedDescription)
        case .cancelled:
            print("User cancelled login.")
            self.showActionSheetWithTitle(title: "Facebook Login Cancelled", message: "")
            
        case .success(grantedPermissions: _, declinedPermissions: _, token: _):
            print("Logged in!")
            

            let credential = FacebookAuthProvider.credential(withAccessToken: (AccessToken.current?.authenticationToken)!)
            
            //use facebook credential to login to firebase
            Auth.auth().signIn(with: credential) { (user, error) in
                // ...
                if let error = error {
                    //Firebase with facebook Login Successful
                    print(error.localizedDescription)
                    let alert = UIAlertController(title: "Alert", message: "Facebook login failed", preferredStyle: .alert)
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    
                    alert.addAction(defaultAction)
                    
                    self.present(alert, animated: true, completion: nil)
                    
                    return
                    
                }else if error == nil {
                    
                    //firebase with facebook login successfull
                    let ref = Database.database().reference().child("Users").child((user?.uid)!)

                    print((user?.uid)!)
                    //get user data
                    ref.observeSingleEvent(of: .value, with: { snapshot in
                        
                        if let _ = snapshot.value as? NSDictionary{
                            //if the user already exists in firebase
                            self.stopLoginIndicator(success: true)
                            self.performSegue(withIdentifier: "toFeedSegue", sender: nil)
                            
                        }else{
                            //if the user doesn't already exist in firebase. Get FB data and write to database
                            
                            self.getFBData(uid: (user?.uid)!, completion: { data in
                                
                                //setup initial following -- auto follow hr.glass
                                let newFollowing: NSDictionary = ["sL7fW1Qa3LOnK3FCUqvr5cl3Mft1":0]
                                let followingList = self.ref.child("Following").child((user?.uid)!).child("following_list")
                                
                                followingList.setValue(newFollowing)
                                let followingCount = self.ref.child("Following").child((user?.uid)!).child("following_count")
                                followingCount.setValue(1)
                                
                                self.stopLoginIndicator(success: true)
                                self.performSegue(withIdentifier: "toFeedSegue", sender: nil)
                                
                            })
                        }
                    })
                    
                }
            }
        }
    }
    
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 10.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        
        self.view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    
    //GET FB USER DATA -- WRITE TO FIREBASE -- RETURN userdata dictionary
    func getFBData(uid: String, completion:@escaping (NSDictionary) -> ()){
        
        let connection = GraphRequestConnection()
        
        //basic data request, by default approved by FB
        let params = ["fields" : "id, email, name"]
        
//        request
        connection.add(GraphRequest(graphPath: "/me", parameters:params)) { httpResponse, result in
            switch result {
            case .success(let response):
                
                //request success
                print("Graph Request Succeeded: \(response)")
                
                let email: String = response.dictionaryValue?["email"] as! String
                let name: String = response.dictionaryValue?["name"] as! String
                
                //set firebase userdata dicrionary and save
                let userData: NSDictionary = ["email":email,"username":"", "name":name, "bio":"", "isPrivate": false, "coverPhoto":"", "profilePhoto":""]
                
                let userRef = self.ref.child("Users").child(uid)
                
                //set initial userdata and move to feed
                userRef.setValue(userData)
                completion(userData)
                
            case .failed(let error):
                print("Graph Request Failed: \(error)")
            }
        }
        
        //start connection request
        connection.start()
        
    }
    
    
    
    func showActionSheetWithTitle(title:String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.popoverPresentationController?.sourceRect = self.createAccountBtn.frame
        alert.popoverPresentationController?.sourceView = self.createAccountBtn
        
        alert.addAction(defaultAction)
        
        self.present(alert, animated: true, completion: nil)
        
        
    }
    


    
    
    /**********************
     * TEXT FIELD DELEGATE
     ***********************/
    
    ////check for username
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        //check username entered on finished editing username field
        if textField == self.usernameField && self.usernameField.text! != ""{
            
            self.validUsername = self.isValidUsername(testStr: textField.text!)
            
            if (!validUsername){
                self.invalidCharactersAlert()
            }else{
                self.dataManager.existingUsernameCheck(desiredUsername: textField.text!, completion: { (valid) in
                    
                    if !valid{
                        self.chooseDifferentUsernameAlert()
                    }

                })
            }
        }
    }
    
    
    //sets border colors to black
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let views: [UIView] = self.view.subviews
        for view in views {
            if (view.tag == 1 || view.tag == 2 || view.tag == 3 || view.tag == 4 || view.tag == 5 ){
                view.layer.borderColor = UIColor.white.cgColor
            }
        }
        
        self.removeIconHighlighing()
        
        if (textField == self.fullnameField){
            self.fullnameImageView.isHighlighted = true
        }else if (textField == self.usernameField){
            self.usernameImageView.isHighlighted = true
        }else if (textField == self.emailField){
            self.emailImageView.isHighlighted = true
        }else if (textField == self.passwordField){
            self.passwordImageView.isHighlighted = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        
        self.removeIconHighlighing()
        
        if (self.fullnameField.text! != "" && self.fullnameField.isFirstResponder){
            self.usernameField.becomeFirstResponder()
        }else if(self.usernameField.text! != "" && self.usernameField.isFirstResponder){
            self.emailField.becomeFirstResponder()
        }else if(self.emailField.text! != "" && self.emailField.isFirstResponder){
            self.passwordField.becomeFirstResponder()
        }else{
            self.scrollView.scrollRectToVisible(self.fullnameField.frame, animated: true)
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    
    func removeIconHighlighing(){
        self.fullnameImageView.isHighlighted = false
        self.usernameImageView.isHighlighted = false
        self.emailImageView.isHighlighted = false
        self.passwordImageView.isHighlighted = false
    }
    
    /**********************************
     *
     *  KEYBOARD NOTIFICATION FUNCTIONS
     *
     **********************************/
    
    @objc func keyboardWillShow(notification: NSNotification) {

        
        self.scrollView.isScrollEnabled = true
        
        if(passwordField.isFirstResponder){
            
            self.scrollView.scrollRectToVisible(passwordField.frame, animated: true)
        }
            
//        else if(confirmPasswordField.isFirstResponder){
//
//            self.scrollView.scrollRectToVisible(confirmPasswordField.frame, animated: true)
//        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {

        self.scrollView.scrollsToTop = true
        self.scrollView.isScrollEnabled = false
    }
    
    
    
    /*******************************
     *
     *  INDICATOR METHODS
     *
     *******************************/
    
    
    func startLoginIndicator() {
        
        self.loginIndicatorView.startAnimating()
        self.createAccountBtn.setTitle("", for: .normal)
        self.createAccountBtn.isUserInteractionEnabled = false
        
    }
    
    func stopLoginIndicator(success: Bool) {
        
        self.loginIndicatorView.stopAnimating()
        
        if success {
            self.createAccountBtn.setTitle("Success", for: .normal)
            
        }else{
            
            self.createAccountBtn.setTitle("Create Account", for: .normal)
            self.createAccountBtn.isUserInteractionEnabled = true
        }
    }
    
    
    /*******************************
     *
     *  SCROLL DELEGATE
     *
     *******************************/
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        if (scrollView.contentOffset.y == 0){
            self.removeIconHighlighing()
             view.endEditing(true)
        }
    }
    
    @IBAction func unwindToCreateAccount(unwindSegue: UIStoryboardSegue) {
        
        
    }
    
    @IBAction func loginAction(_ sender: Any) {
        
        if self.parentVC == "welcome"{
            self.performSegue(withIdentifier: "toLoginSegue", sender: self)
        }else if self.parentVC == "login"{
            self.performSegue(withIdentifier: "unwindToLogin", sender: self)
        }
        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "unwindToLogin"{
            let vc: LoginViewController = segue.destination as! LoginViewController
            vc.parentVC = "welcome"
            
        }else if segue.identifier == "toLoginSegue" {
            let vc: LoginViewController = segue.destination as! LoginViewController
            vc.parentVC = "create"
            
        }
    }
    
    
    
}
