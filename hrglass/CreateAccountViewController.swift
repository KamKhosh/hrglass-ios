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
        
        //View Setup
        self.setupView()
        
        //Delegate Setup
        self.textFieldDelegateSetup()
        self.scrollView.delegate = self
        

        //Keyboard Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        let fbLoginBtn = LoginButton.init(readPermissions: [.publicProfile, .email])
        fbLoginBtn.delegate = self
        
        fbLoginBtn.center = CGPoint(x: self.createAccountBtn.frame.midX, y: self.createAccountBtn.frame.maxY + 30)
        
        self.scrollContentView.addSubview(fbLoginBtn)
    }
    
    
    
    
    
    /**************
     *   ACTIONS
     **************/
    
    @IBAction func createAccountAction(_ sender: Any) {
        
        //CREATE ACCOUNT W/ Email and Password
        
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
            if (confirmPasswordField.text == passwordField.text){
                
                //TODO: ADD Username Check so user's can't use an existing username, same with e-mail
                //after account created and user logged in
                let email:String = emailField.text!
                let password: String = confirmPasswordField.text!
                let fullname: String = fullnameField.text!
                let username: String = usernameField.text!

                
                
                createAccountBtn.backgroundColor = UIColor.lightGray
                
                //if the typed username has already been taken, usernameflag will be true and this will return
                if self.usernameFlag {
                    self.dataManager.checkIfUsernameExists(username: self.usernameField.text!, completion: { (exists) in
                        if(exists){
                            self.chooseDifferentUsernameAlert()
                        }else{
                            //set username for user
                            let usernameRef = self.ref.child("Users").child((Auth.auth().currentUser!.uid)).child("username")
                            usernameRef.setValue(self.usernameField.text!)
                            
                            //set username in username list
                            let usernames = self.ref.child("Usernames")
                            usernames.setValue("0", forKey: self.usernameField.text!)
                            
                            
                            self.performSegue(withIdentifier: "toFeedSegue", sender: nil)
                        }
                    })
                    return
                }
                
                
                
                //CREATE USER AND LOGIN
                Auth.auth().createUser(withEmail: email , password: password) { (user, error) in
                    
                    if(error == nil){
                        
                        let userData: NSDictionary = ["email":email,"username":username, "name":fullname, "bio":"", "isPrivate": false, "coverPhoto":"", "profilePhoto":""]
                        

                        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                            
                            let userRef = self.ref.child("Users").child((user?.uid)!)
                            
                            print(user?.uid ?? "")
                            
                            if(error == nil){
                                
                                self.dataManager.checkIfUsernameExists(username: self.usernameField.text!, completion: { (exists) in
                                    
                                    if exists{
                                        self.usernameFlag = true
                                        userData.setValue("", forKey: "username")
                                        userRef.setValue(userData, withCompletionBlock: { (error, ref) in
                                            self.chooseDifferentUsernameAlert()
                                        })
                                    }else{
                                        
                                        userRef.setValue(userData, withCompletionBlock: { (error, ref) in
                                            
                                            let usernames = self.ref.child("Usernames")
                                            usernames.setValue("0", forKey: self.usernameField.text!)
                                            
                                            
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
                                    }
                                })
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
    
    
    func chooseDifferentUsernameAlert(){
        
        let alert: UIAlertController = UIAlertController(title: "Username already take", message: "choose another", preferredStyle: .actionSheet)
        
        let ok: UIAlertAction = UIAlertAction(title: "OK", style: .default) { (action) in
            
            self.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }

    

    func textFieldDelegateSetup(){
        
        self.fullnameField.delegate = self
        self.usernameField.delegate = self
        self.emailField.delegate = self
        self.passwordField.delegate = self
        self.confirmPasswordField.delegate = self

    }
    
    
    
    func setupView(){
        
        self.addBottomLine(forView: fullnameField, tag: 1)
        self.addBottomLine(forView: usernameField, tag: 2)
        self.addBottomLine(forView: emailField, tag: 3)
        self.addBottomLine(forView: passwordField, tag: 4)
        self.addBottomLine(forView: confirmPasswordField, tag:5)
        
    }

    
    
    func addBottomLine(forView: UITextField, tag: Int){
        
        let view = UIView(frame:CGRect(x:forView.frame.minX ,y:forView.frame.maxY ,width: forView.frame.width, height: 1.0))
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = 1.0
        view.alpha = 0.2
        view.tag = tag
        self.scrollContentView.addSubview(view)
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        let credential = FacebookAuthProvider.credential(withAccessToken: (AccessToken.current?.authenticationToken)!)
        
        Auth.auth().signIn(with: credential) { (user, error) in
            // ...
            if let error = error {
                
                print(error.localizedDescription)
                let alert = UIAlertController(title: "Alert", message: "Facebook login failed", preferredStyle: .alert)
                
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                
                alert.addAction(defaultAction)
                
                self.present(alert, animated: true, completion: nil)
                
                return
                
            }else if error == nil {
 
                let ref = Database.database().reference().child("Users").child((user?.uid)!)
                
                ref.observeSingleEvent(of: .value, with: { snapshot in
                    
                    if let _ = snapshot.value as? NSDictionary{
                        
                        self.stopLoginIndicator(success: true)
                        self.performSegue(withIdentifier: "toFeedSegue", sender: nil)
                        
                    }else{
                        
                        self.getFBData(uid: (user?.uid)!, completion: { data in
                            
                            //setup initial following -- auto follow hr.glass
                            let newFollowing: NSDictionary = ["lGDGX2kvNBVkXUPKavqMoVzHil43":0]
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
    
    
    //GET FB USER DATA -- WRITE TO FIREBASE
    func getFBData(uid: String, completion:@escaping (NSDictionary) -> ()){
        
        let connection = GraphRequestConnection()
        let params = ["fields" : "id, email, name"]
        connection.add(GraphRequest(graphPath: "/me", parameters:params)) { httpResponse, result in
            switch result {
            case .success(let response):
                print("Graph Request Succeeded: \(response)")
                
                let email: String = response.dictionaryValue?["email"] as! String
                let name: String = response.dictionaryValue?["name"] as! String
                
                let userData: NSDictionary = ["email":email,"username":"", "name":name, "bio":"", "isPrivate": false, "coverPhoto":"", "profilePhoto":"", "followed_by_count":0, "following_count": 0, ]
                
                let userRef = self.ref.child("Users").child(uid)
                
                //set initial userdata and move to feed
                userRef.setValue(userData)
                completion(userData)
                
            case .failed(let error):
                print("Graph Request Failed: \(error)")
            }
        }
        connection.start()
        
    }
    
    
    


    
    
    /**********************
     * TEXT FIELD DELEGATE
     ***********************/
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let views: [UIView] = self.view.subviews
        for view in views {
            if (view.tag == 1 || view.tag == 2 || view.tag == 3 || view.tag == 4 || view.tag == 5 ){
                view.layer.borderColor = UIColor.black.cgColor
            }
        }
    }
    
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        
//        textField.resignFirstResponder()
//        return true
//    }
    
    
    /*******************************
     *
     *  KEYBOARD NOTIFICATION FUNCTIONS
     *
     *******************************/
    
    func keyboardWillShow(notification: NSNotification) {

        
        self.scrollView.isScrollEnabled = true
        
        if(passwordField.isFirstResponder){
            
            self.scrollView.scrollRectToVisible(passwordField.frame, animated: true)
            
        }
        else if(confirmPasswordField.isFirstResponder){
            
            self.scrollView.scrollRectToVisible(confirmPasswordField.frame, animated: true)
            
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {

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
