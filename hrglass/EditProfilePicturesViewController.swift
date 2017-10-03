//
//  ProfilePictureViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 6/18/17.
//
//

import UIKit
import Firebase
import CLImageEditor

class EditProfilePicturesViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLImageEditorDelegate {
    
    
    var currentUser: User!
    let ref = Database.database().reference()
    
    let imagePicker = UIImagePickerController()
    let dataManager = DataManager()
    let awsManager = AWSManager(uid: (Auth.auth().currentUser?.uid)!)
    
    
    var progressView: ProgressView!
    var timer: Timer!
    
    let colors = Colors()
    
    var isChoosingProfile: Bool = false
    
    var activityInd: UIActivityIndicatorView!

    @IBOutlet weak var profilePictureImageBtn: UIButton!
    
    @IBOutlet weak var profilePicUploadBtn: UIButton!
    
    @IBOutlet weak var coverPicUploadBtn: UIButton!
    
    @IBOutlet weak var coverPhotoImageView: UIImageView!
    
    @IBOutlet weak var uploadBtn: UIButton!
    
    
    
    
    /*******************************
     *
     *  LIFECYCLE
     *
     *******************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self
        self.uploadBtn.isHidden = true
        
        self.profilePictureImageBtn.layer.cornerRadius = self.profilePictureImageBtn.frame.width/2
        self.profilePictureImageBtn.clipsToBounds = true
        
        self.uploadBtn.backgroundColor = UIColor.clear
        self.uploadBtn.layer.borderColor = colors.getMenuColor().cgColor
        self.uploadBtn.layer.borderWidth = 2.0
        self.uploadBtn.layer.cornerRadius = 8.0
        self.uploadBtn.setTitleColor(colors.getMenuColor(), for: .normal)
        self.uploadBtn.clipsToBounds = true
        
        self.profilePicUploadBtn.backgroundColor = UIColor.white
        self.profilePicUploadBtn.layer.borderWidth = 2.0
        self.profilePicUploadBtn.layer.borderColor = colors.getMenuColor().cgColor
        self.profilePicUploadBtn.layer.cornerRadius = 8.0
        self.profilePicUploadBtn.setTitleColor(colors.getMenuColor(), for: .normal)
        
        self.coverPicUploadBtn.layer.cornerRadius = 8.0
        self.coverPicUploadBtn.backgroundColor = colors.getMenuColor()
        
        self.view.sendSubview(toBack: coverPhotoImageView)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    /*******************************
     *
     *  ACTIONS
     *
     *******************************/
    
    @IBAction func chooseProfilePicAction(_ sender: Any) {
        
        self.isChoosingProfile = true
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    
    //Handles Uploading either a profile or cover photo or both
    @IBAction func uploadAction(_ sender: Any) {
        
        var i = 0;
        
        if coverPhotoImageView.image != nil{
            
            if (progressView == nil){
                self.progressView = ProgressView(frame: self.uploadBtn.bounds)
                self.uploadBtn.addSubview(self.progressView)
                self.progressUpdateTimer()
            }
            
            
            uploadCoverPhoto(completion: { bool in
                
                if bool{
                    i += 1
                    
                    if i == 2{
                        
                        self.uploadComplete()
                    }
                }
            })
            
        }else{
            i += 1
        }
        
        if profilePictureImageBtn.backgroundImage(for: .normal) != nil{
            
            if (progressView == nil){
                self.progressView = ProgressView(frame: self.uploadBtn.bounds)
                self.uploadBtn.addSubview(self.progressView)
                self.progressUpdateTimer()
            }
            
            uploadProfilePhoto(completion: { bool in
                
                if bool{
                    i += 1
                    
                    if i == 2{
                        
                        self.uploadComplete()
                    }
                }
            })
            
        }else{
            i += 1
        }
    }
    
    
    @IBAction func chooseCoverPicAction(_ sender: Any) {
        
        self.isChoosingProfile = false
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    
    
    
    /*******************************
     *
     *  UPLOAD FUNCTIONS
     *
     *******************************/
    
    
    func resetUploadBtn(){
        activityInd.stopAnimating()
        self.uploadBtn.backgroundColor = colors.getMenuColor()
        self.uploadBtn.setTitle("Upload Photos", for: .normal)
        
    }
    
    func disableUploadBtn(){
        
        self.uploadBtn.backgroundColor = UIColor.darkGray
        self.uploadBtn.setTitle("", for: .normal)
        self.uploadBtn.isUserInteractionEnabled = false
        activityInd = UIActivityIndicatorView(frame: CGRect(x: self.uploadBtn.frame.origin.x ,y: self.uploadBtn.frame.origin.y, width: 30, height: 30))
        
        self.activityInd.color = UIColor.white
        self.activityInd.hidesWhenStopped = true
        self.activityInd.startAnimating()
        self.view.addSubview(self.activityInd)
        
        
    }

    
    
    func uploadCoverPhoto(completion: @escaping (Bool) -> ()){
        
        let imageName: String = "coverPhoto.jpg"
        
        let coverRef = self.ref.child("Users").child(currentUser.userID as String)
        disableUploadBtn()
        
        let uploadImage: UIImage = self.coverPhotoImageView.image!
        
        let data: Data = UIImageJPEGRepresentation(uploadImage, 0.8)! as Data
        
        //Save photo to local documents dir
        dataManager.saveImageForPath(imageData: data, name: "coverPhoto")
        
        let path = dataManager.documentsPathForFileName(name: "coverPhoto.jpg")
        
        self.awsManager.uploadPhotoAction(resourceURL: path, fileName: "coverPhoto", type:"jpg", completion:{ success in
            
            if success{
                
                print("Success, Stop the things")
                
                let downloadURL: String = String(format:"%@/%@/images/\(imageName)", self.awsManager.getS3Prefix(), (Auth.auth().currentUser?.uid)!)
                self.currentUser.coverPhoto = downloadURL as String
                coverRef.child("coverPhoto").setValue(downloadURL)
                completion(true)
                
            }else{
                
                print("Failure, try again?")
                self.postFailedAlert(title: "Post Failed", message: "try again")
                
                return
            }
        })
    }
    
    

    
    func uploadProfilePhoto(completion: @escaping (Bool) -> ()){
        
        let imageName: String = "profilePhoto.jpg"

        let profileRef = self.ref.child("Users").child(currentUser.userID as String)
        
        disableUploadBtn()
        
        let uploadImage: UIImage = self.profilePictureImageBtn.backgroundImage(for: .normal)!
        
        let data: Data = UIImageJPEGRepresentation(uploadImage, 0.8)! as Data
        
        //Save photo to local documents dir
        dataManager.saveImageForPath(imageData: data, name: "profilePhoto")
        
        let path = dataManager.documentsPathForFileName(name: "profilePhoto.jpg")
        
        self.awsManager.uploadPhotoAction(resourceURL: path, fileName: "profilePhoto", type:"jpg", completion:{ success in
            
            if success{
                
                print("Success, Stop the things")
                
                //store downloadURL
                let downloadURL: String = String(format:"%@/%@/images/\(imageName)", self.awsManager.getS3Prefix(), (Auth.auth().currentUser?.uid)!)
                self.currentUser.profilePhoto = downloadURL as String
                
                profileRef.child("profilePhoto").setValue(downloadURL)
                self.updatePostPhotoURL(urlString: downloadURL)
                completion(true)
                
            }else{
                
                print("Failure, try again?")
                self.postFailedAlert(title: "Post Failed", message: "try again")
                
                return
            }
        })

    }
    
    
    
    
    func uploadComplete(){
        
        let alert: UIAlertController = UIAlertController(title: "Success", message: "Upload Complete", preferredStyle: .alert)
        
        let ok: UIAlertAction = UIAlertAction(title: "Ok", style: .default) {(_) -> Void in
            
            self.progressView.removeFromSuperview()
            self.resetUploadBtn()
            alert.dismiss(animated: true, completion: nil)
            self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
            
        }
        
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    
    
    func postFailedAlert(title: String, message: String){
        
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok: UIAlertAction = UIAlertAction(title: "Ok", style: .default) {(_) -> Void in
            
            
            self.resetUploadBtn()
            alert.dismiss(animated: true, completion: nil)
            
        }
        
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    /*******************************
     *
     *  Post Profile Photo Update
     *
     ******************************/
    
    //In the case where the user updates their profile picture with a current post we need to update the post profilephotos download URL
    
    func updatePostPhotoURL(urlString: String){
        
        let postRef: DatabaseReference = self.ref.child("Posts").child(currentUser.userID as String).child("user")
        
        postRef.observeSingleEvent(of: .value, with: { snapshot in
            
            if let _: NSDictionary = snapshot.value as? NSDictionary{
                
                postRef.child("profilePhoto").setValue(urlString)
                
            }
        })
    }
    
    
    /************************
     *
     * IMAGE PICKER DELEGATE
     *
     ***********************/
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        //if picture is edited use the edited version
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage{
            
            if (isChoosingProfile){
                
                profilePictureImageBtn.contentMode = .scaleAspectFill
                profilePictureImageBtn.setImage(UIImage(named: "crop"), for: .normal)
                profilePictureImageBtn.setBackgroundImage(editedImage, for: .normal)
                self.uploadBtn.isHidden = false
                
            }else{
                
                coverPhotoImageView.contentMode = .scaleAspectFill
                coverPhotoImageView.image = editedImage
                self.uploadBtn.backgroundColor = UIColor.init(white: 1.0, alpha: 0.7)
                self.profilePicUploadBtn.backgroundColor = UIColor.init(white: 1.0, alpha: 0.7)
                self.uploadBtn.isHidden = false
            }
            
        }
        else{
            //else us the original
            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                
                
                if (isChoosingProfile){
                    
                    profilePictureImageBtn.contentMode = .scaleAspectFill
                    profilePictureImageBtn.setImage(UIImage(named: "crop"), for: .normal)
                    profilePictureImageBtn.setBackgroundImage(pickedImage, for: .normal)
                    self.uploadBtn.isHidden = false
                    
                }else{
                    
                    coverPhotoImageView.contentMode = .scaleAspectFill
                    coverPhotoImageView.image = pickedImage
                    self.uploadBtn.backgroundColor = UIColor.init(white: 1.0, alpha: 0.7)
                    self.profilePicUploadBtn.backgroundColor = UIColor.init(white: 1.0, alpha: 0.7)
                    self.uploadBtn.isHidden = false
                }
            }

        }
        
        dismiss(animated: true, completion: nil)
    }
    
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    
    
    func progressUpdateTimer(){
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.photoTimer), userInfo: nil, repeats: true)
    }
    
    
    func photoTimer(){
        
        if (self.progressView.percentageComplete <= 1.0){
            
            self.awsManager.photoUploadProgressCheck()
            self.progressView.percentageComplete = CGFloat(self.awsManager.photoUploadProgress)
            
            self.progressView.updateProgress()
            
        }else{
            
            self.timer.invalidate()
        }
    }
    
    
    
    //CLImageEditor Functions
    func presentImageEditorWithImage(image:UIImage){
        
        
        guard let editor = CLImageEditor(image: image, delegate: self) else {
            
            return;
        }
        
        editor.theme.backgroundColor = UIColor.white
        editor.theme.toolbarColor = UIColor.white
        editor.theme.toolbarTextColor = UIColor.lightGray
        editor.theme.toolIconColor = "black"
        
        self.present(editor, animated: true, completion: {});
    }
    
    
    
    func imageEditor(_ editor: CLImageEditor!, didFinishEditingWith image: UIImage!) {
        
        self.profilePictureImageBtn.setImage(image, for: .normal)

        editor.dismiss(animated: true, completion: nil)
        
    }
    
    
    //ACTIONS
    @IBAction func profileImageAction(_ sender: Any) {
        
        
//        self.presentImageEditorWithImage(image: self.profilePictureImageBtn.backgroundImage(for: .normal)!)
        
    }
    
    @IBAction func unwindToEditProfilePictures(unwindSegue: UIStoryboardSegue) {
        

        
    }
    
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "unwindToFeed") {
            
        }else if (segue.identifier == "toCropView"){
            
            let cropVC: CropViewController = segue.destination as! CropViewController
            
            cropVC.originalImage = self.profilePictureImageBtn.backgroundImage(for: .normal)
            cropVC.parentView = "editProfilePics"
            
        }
    }


}
