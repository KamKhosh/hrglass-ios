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



class CreateAccountViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, LoginButtonDelegate{

    @IBOutlet weak var fullnameField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var createAccountBtn: UIButton!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var ref: DatabaseReference!
    
    let dataManager: DataManager = DataManager()
    var usernameFlag: Bool = false;
    var currentUser: User!
    
    @IBOutlet weak var loginIndicatorView: UIActivityIndicatorView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Firebase Reference
        ref = Database.database().reference()
        
        //Delegate Setup
        self.textFieldDelegateSetup()
        self.scrollView.delegate = self
        

        //Keyboard Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //set placeholder's and text color
        fullnameField.attributedPlaceholder =
            NSAttributedString(string: "Fullname", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        passwordField.attributedPlaceholder =
            NSAttributedString(string: "New Password", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        confirmPasswordField.attributedPlaceholder =
            NSAttributedString(string: "Confirm Password", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        emailField.attributedPlaceholder =
            NSAttributedString(string: "Email", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        usernameField.attributedPlaceholder =
            NSAttributedString(string: "Username", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        //init fb login button
        let fbLoginBtn = LoginButton.init(readPermissions: [.publicProfile, .email])
        fbLoginBtn.delegate = self
        
        fbLoginBtn.center = CGPoint(x: self.createAccountBtn.frame.midX, y: self.createAccountBtn.frame.maxY + 30)
        
        self.scrollContentView.addSubview(fbLoginBtn)
        
        //View Setup -- bottom lines
        self.setupView()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    /**************
     *   ACTIONS
     **************/
    
    @IBAction func createAccountAction(_ sender: Any) {
        
        //CREATE ACCOUNT W/ Email and Password
        
        //if any of the fields are black the underline will be changed to red
        
        
        if(fullnameField.text == ""){
            print("Fullname Empty")
            let views: [UIView] = self.scrollContentView.subviews
            for view in views {
                if view.tag == 1{
                    view.layer.borderColor = UIColor.red.cgColor
                }
            }
        }else if(usernameField.text == ""){
            print("username Empty")
            let views: [UIView] = self.scrollContentView.subviews
            for view in views {
                if view.tag == 2{
                    view.layer.borderColor = UIColor.red.cgColor
                }
            }
        }else if(emailField.text == ""){
        
            
            print("email Empty")
            let views: [UIView] = self.scrollContentView.subviews
            for view in views {
                if view.tag == 3{
                    view.layer.borderColor = UIColor.red.cgColor
                }
            }
        }else if !self.isValidEmail(testStr: emailField.text!){
            
            //email address validation
            let views: [UIView] = self.scrollContentView.subviews
            for view in views {
                if view.tag == 3{
                    view.layer.borderColor = UIColor.red.cgColor
                }
            }
        }else if(passwordField.text == ""){
            print("password Empty")
            let views: [UIView] = self.scrollContentView.subviews
            for view in views {
                if view.tag == 4{
                    view.layer.borderColor = UIColor.red.cgColor
                }
            }
        }else if(confirmPasswordField.text == ""){
            print("confirm password Empty")
            let views: [UIView] = self.scrollContentView.subviews
            for view in views {
                if view.tag == 5{
                    view.layer.borderColor = UIColor.red.cgColor
                }
            }
        }else{
            //all fields are filled out
            
            if (confirmPasswordField.text == passwordField.text){
                
                //TODO: ADD Username Check so user's can't use an existing username, same with e-mail
                //after account created and user logged in
                let email:String = emailField.text!
                let password: String = confirmPasswordField.text!
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
                                //on login success, check if username is taken
                                
                                        userRef.setValue(userData, withCompletionBlock: { (error, ref) in
                                            
                                            //setup initial following -- auto follow hr.glass
                                            let newFollowing: NSDictionary = ["lGDGX2kvNBVkXUPKavqMoVzHil43":0]
                                            let followingList = self.ref.child("Following").child((user?.uid)!).child("following_list")
                                            
                                            followingList.setValue(newFollowing)
                                            let followingCount = self.ref.child("Following").child((user?.uid)!).child("following_count")
                                            followingCount.setValue(1)
                                            
                                            
                                            if(error == nil){
                                                self.performSegue(withIdentifier: "toFeedSegue", sender: nil)
                                            }
                                        })
//                                    }
//                                })
                            }
                        }
                    }
                }
                
            }else{
                let views: [UIView] = self.scrollContentView.subviews
                for view in views {
                    if view.tag == 5{
                        view.layer.borderColor = UIColor.red.cgColor
                    }
                }
            }
        }
    }
    
    //username in use alert
    func chooseDifferentUsernameAlert(){
        
        let alert: UIAlertController = UIAlertController(title: "Username already take", message: "choose another", preferredStyle: .actionSheet)
        
        let ok: UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action) in
            
            self.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }

    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    

    //setup textField delegates
    func textFieldDelegateSetup(){
        
        self.fullnameField.delegate = self
        self.usernameField.delegate = self
        self.emailField.delegate = self
        self.passwordField.delegate = self
        self.confirmPasswordField.delegate = self

    }
    
    
    //add bottom lines to textFields
    func setupView(){
        
        self.addBottomLine(forView: fullnameField, tag: 1)
        self.addBottomLine(forView: usernameField, tag: 2)
        self.addBottomLine(forView: emailField, tag: 3)
        self.addBottomLine(forView: passwordField, tag: 4)
        self.addBottomLine(forView: confirmPasswordField, tag:5)
        
    }

    
    //add bottom line method
    func addBottomLine(forView: UITextField, tag: Int){
        
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
            
        case .success(grantedPermissions: let granted, declinedPermissions: let declined, token: let token):
            print("Logged in!")
            //Do further code...
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
        
        alert.addAction(defaultAction)
        
        self.present(alert, animated: true, completion: nil)
        
        
    }
    


    
    
    /**********************
     * TEXT FIELD DELEGATE
     ***********************/
    
    //sets border colors to black
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let views: [UIView] = self.view.subviews
        for view in views {
            if (view.tag == 1 || view.tag == 2 || view.tag == 3 || view.tag == 4 || view.tag == 5 ){
                view.layer.borderColor = UIColor.white.cgColor
            }
        }
    }
    
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        
//        textField.resignFirstResponder()
//        return true
//    }
    
    
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
            
        else if(confirmPasswordField.isFirstResponder){
            
            self.scrollView.scrollRectToVisible(confirmPasswordField.frame, animated: true)
        }
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
             view.endEditing(true)
        }

    }
    
    
}
