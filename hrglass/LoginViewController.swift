//
//  LoginViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/17/17.
//

import UIKit
import Firebase
import FacebookLogin
import FacebookCore


class LoginViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, LoginButtonDelegate{

    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var loginIndicationView: UIActivityIndicatorView!
    
    @IBOutlet weak var passwordImageView: UIImageView!
    @IBOutlet weak var emailImageView: UIImageView!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var emailView: UIView!
    
    let ref: DatabaseReference = Database.database().reference()
    let dataManager: DataManager = DataManager()
    let colors: Colors = Colors()
    var fbLoginBtn: LoginButton!
    var parentVC: String = "welcome"
    

    /*******************************
     *
     *  LIFECYCLE
     *
     *******************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        //Delegate Setup
        self.textFieldDelegateSetup()
        self.scrollView.delegate = self
        self.scrollView.isScrollEnabled = false
        
        // Setup Facebook Login Button
        fbLoginBtn = LoginButton.init(readPermissions: [ .publicProfile, .email ])
        fbLoginBtn.delegate = self
        fbLoginBtn.frame.size = self.loginBtn.frame.size
        fbLoginBtn.center = CGPoint(x: loginBtn.center.x, y: loginBtn.frame.maxY + 40)
        
        
        
        
        self.loginBtn.layer.cornerRadius = 3.0;
        self.loginBtn.layer.borderWidth = 1.0
        self.loginBtn.layer.borderColor = colors.getDarkerPink().cgColor
        
        //Keyboard Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        usernameField.attributedPlaceholder =
            NSAttributedString(string: "Email", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        passwordField.attributedPlaceholder =
            NSAttributedString(string: "Password", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
    
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fbLoginBtn.center = CGPoint(x: loginBtn.center.x, y: loginBtn.frame.maxY + 40)
        self.scrollContentView.addSubview(fbLoginBtn)
        self.setupView()
    }
    
    
    /************
     * ACTIONS
     ************/
    @IBAction func loginAction(_ sender: Any) {
        
        //login without facebook
        
        if(usernameField.text == ""){
            print("Fullname Empty")
            
            
            let views: [UIView] = self.view.subviews
            for view in views {
                if view.tag == 1{
                    view.layer.borderColor = colors.getMenuColor().cgColor
                }
            }
        }else if(passwordField.text == ""){
            print("username Empty")
            let views: [UIView] = self.view.subviews
            for view in views {
                
                if view.tag == 2{
                    
                    view.layer.borderColor = colors.getMenuColor().cgColor
                }
            }
        }
        
        else{
            
            let email = usernameField.text
            let password = passwordField.text

            self.startLoginIndicator()
            
            Auth.auth().signIn(withEmail: email!, password: password!) { (user, error) in
                
                if(error == nil){
                    
                    self.performSegue(withIdentifier: "toFeedSegue", sender: nil)
                    self.stopLoginIndicator(success: true)
                    
                }else{
                    
                    self.stopLoginIndicator(success: false)
                    
                    let alert = UIAlertController(title: "Login Failed", message: "Username or Password Incorrect", preferredStyle: .alert)
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    
                    alert.addAction(defaultAction)
                    
                    self.present(alert, animated: true, completion: nil)
                    
                }
            }
        }
    }

    
    
    
    /**************************
     * FACEBOOK LOGIN DELEGATE
     *************************/
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        //TODO: Logout
        
    }
    
    
    func loginButtonWillLogin(_ loginButton: LoginButton) -> Bool {
        //
        return true
    }
    
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        
        
        switch result {
        case .failed(let error):
            print(error)
            self.showActionSheetWithTitle(title: "Facebook login Failed", message: error.localizedDescription)
        case .cancelled:
            print("User cancelled login.")
            self.showActionSheetWithTitle(title: "Facebook login Cancelled", message: "")
            
        case .success(_, _, _):
            
            print("Logged in!")
            //login to firebase
            if ((AccessToken.current?.authenticationToken) != nil) {
                
                let credential = FacebookAuthProvider.credential(withAccessToken: (AccessToken.current?.authenticationToken)!)
                
                self.startLoginIndicator()
                
                Auth.auth().signIn(with: credential) { (user, error) in
                    
                    if let error = error {
                        
                        print(error.localizedDescription)
                        
                        self.stopLoginIndicator(success: false)
                        
                        self.showActionSheetWithTitle(title: "Error", message: "Facebook-Firebase login failed")
                        
                    }else if error == nil {
                        
                        //Check if firebase Userdata exists, if not create user
                        let ref = Database.database().reference().child("Users").child((user?.uid)!)
                        
                        ref.observeSingleEvent(of: .value, with: { snapshot in
                            
                            if let _ = snapshot.value as? NSDictionary{
                                
                                self.stopLoginIndicator(success: true)
                                
                                self.dataManager.resetLocalUserPhotos()
                                self.performSegue(withIdentifier: "toFeedSegue", sender: nil)
                                
                            }else{
                                
                                self.getFBData(uid: (user?.uid)!, completion: { data in
                                    
                                    self.dataManager.resetLocalUserPhotos()
                                    
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
            }else{
                
                self.showActionSheetWithTitle(title: "Facebook Token is Nil", message: "hmm, odd")
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
                
                let userData: NSDictionary = ["email":email,"username":"", "name":name, "bio":"", "isPrivate": false, "coverPhoto":"", "profilePhoto":""]
                
                let userRef = Database.database().reference().child("Users").child(uid)
                
                //set initial userdata and move to feed
                userRef.setValue(userData)
                completion(userData)
                
            case .failed(let error):
                print("Graph Request Failed: \(error)")
            }
        }
        connection.start()
    }
    
    
    
    func showActionSheetWithTitle(title:String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(defaultAction)
        alert.popoverPresentationController?.sourceRect = self.loginBtn.frame
        alert.popoverPresentationController?.sourceView = self.loginBtn
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    func textFieldDelegateSetup(){
        
        self.usernameField.delegate = self
        self.passwordField.delegate = self

    }
    

    func setupView(){
        
        self.addBottomLine(forView: self.emailView, tag: 1)
        self.addBottomLine(forView: self.passwordView, tag: 2)
        
    }
    
    
    func startLoginIndicator() {

        self.loginIndicationView.startAnimating()
        self.loginBtn.setTitle("", for: .normal)
        self.loginBtn.isUserInteractionEnabled = false
       
    }

    
    func stopLoginIndicator(success: Bool) {
        
        self.loginIndicationView.stopAnimating()
        
        if success {
            self.loginBtn.setTitle("Success", for: .normal)
            
        }else{
            
            self.loginBtn.setTitle("Log in", for: .normal)
            self.loginBtn.isUserInteractionEnabled = true
        }
    }
    
    
    func addBottomLine(forView: UIView, tag: Int){
        //adds a line beneath the view in the parameters
        
        let view = UIView(frame:CGRect(x:forView.frame.minX ,y:forView.frame.maxY ,width: forView.frame.width, height: 1.0))
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1.0
        view.alpha = 0.2
        view.tag = tag
        
        self.scrollContentView.addSubview(view)
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        

        self.removeIconHighlighting()
        
       if (textField == self.usernameField){
            self.emailImageView.isHighlighted = true
        }else if (textField == self.passwordField){
            self.passwordImageView.isHighlighted = true
        }
        
        
        let views: [UIView] = self.view.subviews
        for view in views {
            if (view.tag == 1 || view.tag == 2){
                view.layer.borderColor = UIColor.white.cgColor
            }
        }
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        
        self.removeIconHighlighting()
        
        if (self.usernameField.text! != "" && self.passwordField.text! != ""){
            self.loginAction(self)
        }else if(self.usernameField.isFirstResponder && self.passwordField.text == ""){
            self.passwordField.becomeFirstResponder()
        }
        else{
            textField.resignFirstResponder()
        }
        
        
        return true
    }
    
    
    func removeIconHighlighting(){
        
        self.emailImageView.isHighlighted = false
        self.passwordImageView.isHighlighted = false
    }
    
    
    @objc func keyboardWillShow(notification: NSNotification) {
        
        self.scrollView.isScrollEnabled = true
        
        if(passwordField.isFirstResponder){
            
            self.scrollView.scrollRectToVisible(passwordField.frame, animated: true)
        }
            
        else if(usernameField.isFirstResponder){
            
            self.scrollView.scrollRectToVisible(usernameField.frame, animated: true)
        }
    }
    
    
    
    @objc func keyboardWillHide(notification: NSNotification) {
        
        self.scrollView.scrollsToTop = true
        self.scrollView.isScrollEnabled = false
    }
    
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if (scrollView.contentOffset.y == 0){
            self.removeIconHighlighting()
            view.endEditing(true)
        }
    }
    
    
    
    /*******************************
     * UITEXTFIELD DELEGATES
     ********************************/
    
    //    override func textFieldDidBeginEditing(_ textField: UITextField) {
    //
    //    }
    
    //    override func textFieldDidEndEditing(_ textField: UITextField) {
    //
    //
    //    }

//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        
//        self.scrollView.scrollsToTop = true
//        self.scrollView.isScrollEnabled = false
//        textField.resignFirstResponder()
//        return true
//    }
    
    
    
    @IBAction func createAccountAction(_ sender: Any) {
        
        if self.parentVC == "welcome"{
             self.performSegue(withIdentifier: "toCreateAccountSegue", sender: self)
        }else if self.parentVC == "create"{
            self.performSegue(withIdentifier: "unwindToCreateAccount", sender: self)
        }
        
    }
    
    
    @IBAction func unwindToLogin(unwindSegue: UIStoryboardSegue) {
        
        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "toFeedView" {
            
            //pre segue setup
        }else if segue.identifier == "unwindToCreateAccount"{
            let vc: CreateAccountViewController = segue.destination as! CreateAccountViewController
            vc.parentVC = "welcome"
            
            
        }else if segue.identifier == "toCreateAccountSegue" {
            let vc: CreateAccountViewController = segue.destination as! CreateAccountViewController
            vc.parentVC = "login"
            
        }
    }
}
