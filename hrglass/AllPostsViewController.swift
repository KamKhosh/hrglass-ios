//
//  AllPostsViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/23/17.
//
//

import UIKit
import Clarifai
import Firebase

class AllPostsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, PostViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    //Set this on segue
    var postsArray: [PostData]!
    let colors: Colors = Colors()
    var imageCache: ImageCache!
    var awsManager: AWSManager = AWSManager()
    var dataManager: DataManager = DataManager()
    var moreMenuPostData: PostData!
    var loggedInUser: User!
    
    var postPopupView: PostViewController!
    
    @IBOutlet weak var playImageView: UIImageView!
    
    
    /****************************************
     *
     * ----------- LIFECYCLE ------------
     *
     ******************************************/

 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        self.collectionView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    
    /***********************************
     *
     * COLLECTION VIEW DELEGATE METHODS
     *
     ***********************************/
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "postCellViewAll", for: indexPath) as! AllPostsCollectionViewCell
        

        let image = UIImage(named: "clearPlaceholderImage")
        cell.imageView.image = image
        
        cell.loadingIndicator.startAnimating()
        
        let user: NSDictionary = postsArray[indexPath.row].user
        let uid: String = user.value(forKey: "uid") as! String
        
        cell.borderView.layer.borderColor = self.dataManager.getUIColorForCategory(category: postsArray[indexPath.row].category).cgColor
        
        cell.moreBtnSelected = {
            
            self.moreButtonPressed(data:self.postsArray[indexPath.row], indexPath: indexPath)
        }
        
        switch postsArray[indexPath.row].category {
            
        case .Video:
            

            let thumbnailURL: String = String(format:"%@/%@/images/thumbnail.jpg", self.awsManager.getS3Prefix(), uid)
            self.imageCache.getImage(urlString: thumbnailURL, completion: { image in
                
                cell.imageView.image = image
                cell.loadingIndicator.stopAnimating()
                cell.playImageView.isHidden = false
                
            })
            
            
        case .Photo:
            self.imageCache.getImage(urlString: postsArray[indexPath.row].data, completion: { image in
                
                cell.imageView.image = image
                cell.loadingIndicator.stopAnimating()
            })
            //default is photo for now
            
        case .Recording:
            print("Recording")
            
            cell.borderView.layer.borderColor = colors.getAudioColor().cgColor
            cell.imageView.image = UIImage(named: "audioWave")
            
        case .Text:
            print("Text")
            cell.borderView.layer.borderColor = colors.getTextPostColor().cgColor
            self.imageCache.getImage(urlString: postsArray[indexPath.row].data, completion: { image in
                
                cell.imageView.image = image
                cell.loadingIndicator.stopAnimating()
            })
            //default is photo for now
            
         
        case .Music:
            print("Music")
            
            let thumbnailURL: String = String(format:"%@/%@/images/thumbnail.jpg", self.awsManager.getS3Prefix(), uid)
            self.imageCache.getImage(urlString: thumbnailURL, completion: { image in
                
                cell.imageView.image = image
                cell.loadingIndicator.stopAnimating()

                
            })
            
        case .Link:
            print("Link")
            
            dataManager.setURLView(urlString: postsArray[indexPath.row].data as String, completion: { (image, label) in
                
                cell.imageView.image = image
                
                let linkLabel = UILabel(frame: CGRect(x: cell.imageView.bounds.minX, y:cell.imageView.bounds.midY, width: cell.imageView.frame.width ,height: cell.imageView.frame.height/3))
                
                linkLabel.adjustsFontSizeToFitWidth = true
                linkLabel.numberOfLines = 2
                linkLabel.backgroundColor = UIColor.darkGray
                linkLabel.alpha = 0.7
                linkLabel.text = label
                linkLabel.textAlignment = .center
                linkLabel.textColor = UIColor.white
                
                cell.imageView.addSubview(linkLabel)

            })
            
        default:
            print("Default")
            
        }
        
        cell.borderView.layer.cornerRadius = cell.borderView.frame.width / 2
        cell.borderView.layer.borderWidth = 2.0
        
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView.layer.cornerRadius = cell.imageView.frame.width / 2
        cell.imageView.clipsToBounds = true
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return postsArray.count
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Do things
        
        self.postPopupView = storyboard!.instantiateViewController(withIdentifier: "postViewController") as! PostViewController
        
        self.postPopupView.delegate = self
        self.postPopupView.imageCache = self.imageCache
        self.postPopupView.postData = postsArray[indexPath.row]
        self.postPopupView.source = "Profile"
        addChildViewController(self.postPopupView)
        
        self.postPopupView.view.frame = view.bounds
//        postVC.topGradientView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        
        view.addSubview(self.postPopupView.view)
        self.postPopupView.didMove(toParentViewController: self)
        
    }
    
    //Post View Delegates -- these are currently hidden from this view since all the posts here have already been liked
    func likedButtonPressed(liked: Bool, indexPath: IndexPath) {
        //don't do anything
        
    }
    
    func moreButtonPressed(data: PostData, indexPath: IndexPath) {
        
        let fullname: String = data.user.value(forKey: "name") as! String
        
        let alert: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let block: UIAlertAction = UIAlertAction(title: String(format:"Block %@", self.dataManager.getFirstName(name: fullname)) , style: .default) {(_) -> Void in
            
            self.blockUserAction(data: data)
            alert.dismiss(animated: true, completion: nil)
        }
        
        let flag: UIAlertAction = UIAlertAction(title:"Flag Post" , style: .default) {(_) -> Void in
            
            alert.dismiss(animated: true, completion: nil)
            let flagContent: NSMutableDictionary = data.postDataAsDictionary().mutableCopy() as! NSMutableDictionary
            let ref: DatabaseReference = Database.database().reference().child("Flags").child(data.user.value(forKey: "uid") as! String).child(Auth.auth().currentUser!.uid)
            
            let flagAlert: UIAlertController = UIAlertController(title: "Flag Reason", message: nil, preferredStyle: .actionSheet)
            
            let cancel: UIAlertAction = UIAlertAction(title: "Cancel" , style: .cancel) {(_) -> Void in
                
                flagAlert.dismiss(animated: true, completion: nil)
            }
            
            let inappropriate: UIAlertAction = UIAlertAction(title: "Inappropriate" , style: .default) {(_) -> Void in
                flagContent.setValue("Inappropriate", forKey: "reason")
                ref.setValue(flagContent)
                self.showToast(message: "Post Flagged for being Inappropriate")
                flagAlert.dismiss(animated: true, completion: nil)
            }
            
            let mature: UIAlertAction = UIAlertAction(title: "Mature Content" , style: .default) {(_) -> Void in
                flagContent.setValue("Mature", forKey: "reason")
                ref.setValue(flagContent)
                self.showToast(message: "Post Flagged for Mature Content")
                flagAlert.dismiss(animated: true, completion: nil)
            }
            
            let insensitive: UIAlertAction = UIAlertAction(title: "Insensitive" , style: .default) {(_) -> Void in
                flagContent.setValue("Insensitive", forKey: "reason")
                ref.setValue(flagContent)
                self.showToast(message: "Post Flagged for Insensitivity")
                flagAlert.dismiss(animated: true, completion: nil)
            }
            
            let gore: UIAlertAction = UIAlertAction(title: "Violence/Gore" , style: .default) {(_) -> Void in
                flagContent.setValue("Gore", forKey: "reason")
                ref.setValue(flagContent)
                self.showToast(message: "Post Flagged for Violence/Gore")
                flagAlert.dismiss(animated: true, completion: nil)
            }
            
            flagAlert.addAction(cancel)
            flagAlert.addAction(gore)
            flagAlert.addAction(insensitive)
            flagAlert.addAction(mature)
            flagAlert.addAction(inappropriate)
            
            flagAlert.popoverPresentationController?.sourceRect = self.postPopupView.moreBtn.frame
            flagAlert.popoverPresentationController?.sourceView = self.postPopupView.moreBtn
            
            self.present(flagAlert, animated: true, completion: nil)
        }
        
        let message: UIAlertAction = UIAlertAction(title: String(format:"Send %@ a Message", self.dataManager.getFirstName(name: fullname)) , style: .default) {(_) -> Void in
            
            self.moreMenuPostData = data
            alert.dismiss(animated: true, completion: nil)
        }
        
        let delete: UIAlertAction = UIAlertAction(title: String(format:"Expire Post", self.dataManager.getFirstName(name: fullname)) , style: .default) {(_) -> Void in
            //set the expire time to the post creation time
            let ref: DatabaseReference = Database.database().reference().child("Posts").child((Auth.auth().currentUser?.uid)!).child("expire_time")
            ref.setValue(data.creationDate)
            
            alert.dismiss(animated: true, completion: nil)
        }
        
        
        
        let cancel: UIAlertAction = UIAlertAction(title: "Cancel" , style: .cancel) {(_) -> Void in
            alert.dismiss(animated: true, completion: nil)
        }
        
        
        if (data.user.value(forKey: "uid") as? String  == Auth.auth().currentUser?.uid){
            
            alert.addAction(delete)
        }else{
            
            alert.addAction(message)
            alert.addAction(block)
            alert.addAction(flag)
            
        }
        
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceRect = self.postPopupView.moreBtn.frame
        alert.popoverPresentationController?.sourceView = self.postPopupView.moreBtn
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    func blockUserAction(data: PostData){
        
        //don't do anything
        print(String(format:"Block User (%@) Action", data))
        self.dataManager.blockUser(postData: data)
        self.performSegue(withIdentifier: "unwindToFeedSegue", sender: self)
    
    }
    
    
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 150, y: self.view.frame.size.height-100, width: 300, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
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
    
    
    
    
    
    
    /****************************************
     *
     * ----------- NAVIGATION ------------
     *
     ******************************************/

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "unwindToProfile" {
            
            self.postsArray.removeAll()
            self.collectionView.reloadData()
            
        }else if (segue.identifier == "toMessagesView"){
            
            let messageVC: MessagesViewController = segue.destination as! MessagesViewController
            messageVC.selectedUserId = self.moreMenuPostData.user.value(forKey: "uid") as! String
            messageVC.nameString = (self.moreMenuPostData.user.value(forKey: "name") as! String)
            messageVC.loggedInUser = self.loggedInUser
        }
        
    }

    

    

}
