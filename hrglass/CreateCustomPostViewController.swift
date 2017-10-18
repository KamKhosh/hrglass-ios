//
//  CreateCustomPostViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 6/23/17.
//
//

import UIKit
import AVFoundation
import Photos
import MediaPlayer

class CreateCustomPostViewController: UIViewController {
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    var loggedInUser: User!
    var savedPost: NSDictionary! = [:]
    
    @IBOutlet weak var galleryBtn: UIButton!
    
    @IBOutlet weak var recordingBtn: UIButton!
    @IBOutlet weak var textBtn: UIButton!
    @IBOutlet weak var cameraBtn: UIButton!
    
    @IBOutlet weak var newsBtn: UIButton!
    @IBOutlet weak var videoBtn: UIButton!
    @IBOutlet weak var musicBtn: UIButton!
    
    var selectedTag: Int = 0;
    
    let dataManager: DataManager = DataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationBar.frame.size = CGSize(width: self.view.frame.width, height: 80)
        
        //removing bottom navigation line
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        
        self.checkForSavedPost()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkForSavedPost(){
        
        if let savedPost: NSDictionary = UserDefaults.standard.dictionary(forKey: "savedPost") as NSDictionary?{
            
            //If there is Data in
            if (savedPost.count > 0){
                
                let alert: UIAlertController = UIAlertController(title: "You have a saved Post ready to submit", message: "", preferredStyle: .actionSheet)
                
                let cancel: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) {(_) -> Void in
                    
                    alert.dismiss(animated: true, completion: nil)
                    
                }
                let delete: UIAlertAction = UIAlertAction(title: "Delete Saved Post", style: .default) {(_) -> Void in
                    
                    UserDefaults.standard.set([:], forKey: "savedPost")
                    alert.dismiss(animated: true, completion: nil)
                    
                }
                delete.setValue(UIColor.red, forKey: "titleTextColor")
                
                let view: UIAlertAction = UIAlertAction(title: "View Post", style: .default) {(_) -> Void in
                    
                    self.savedPost = savedPost
                    alert.dismiss(animated: true, completion: nil)
                    self.performSegue(withIdentifier: "useSavedPost", sender: self)
                    
                }
                
                
                alert.addAction(view)
                alert.addAction(delete)
                alert.addAction(cancel)
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    
    
    func getMPMediaItemWith(persistentId: MPMediaEntityPersistentID) -> MPMediaItem{
        
        let query: MPMediaQuery  = MPMediaQuery.songs()  // general songs query
        
        let pred: MPMediaPropertyPredicate = MPMediaPropertyPredicate(value: persistentId, forProperty: MPMediaItemPropertyPersistentID)
        
        // narrow the query down to just items with that ID
        query.addFilterPredicate(pred)
        
        // now get items (there should be only one):
        let item: MPMediaItem = (query.items?.first)!
        
        return item
        
    }
    
    
    //actionSheet
    
    @IBAction func galleryAction(_ sender: Any) {
        
        self.selectedTag = 0
        self.performSegue(withIdentifier:"toAddPostSegue", sender: self)
        
    }
    
    @IBAction func videoAction(_ sender: Any) {
        self.selectedTag = 1
        self.performSegue(withIdentifier:"toAddPostSegue", sender: self)
        
    }
    
    @IBAction func textAction(_ sender: Any) {
        self.selectedTag = 2
        self.performSegue(withIdentifier:"toAddPostSegue", sender: self)
        
    }
    
    @IBAction func recordingBtn(_ sender: Any) {
        self.selectedTag = 3
        self.performSegue(withIdentifier:"toAddPostSegue", sender: self)
        
    }
    
    @IBAction func musicBtn(_ sender: Any) {
        self.selectedTag = 4
        self.performSegue(withIdentifier:"toAddPostSegue", sender: self)
        
    }
    
    @IBAction func newsAction(_ sender: Any) {
        self.selectedTag = 5
        self.performSegue(withIdentifier:"toAddPostSegue", sender: self)
        
    }
    
    @IBAction func cameraAction(_ sender: Any) {
        self.selectedTag = 6
        self.performSegue(withIdentifier:"toAddPostSegue", sender: self)
        
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "toAddPostSegue"){
            
            
            
            let addPostVC:AddPostViewController = segue.destination as! AddPostViewController
            addPostVC.loggedInUser = self.loggedInUser
            addPostVC.tabPassedFromParent = self.selectedTag
            
            
        }
            
        else if(segue.identifier == "useSavedPost"){
            
            let addPostVC:AddPostViewController =  segue.destination as! AddPostViewController
            
            let cat: Category = Category(rawValue: self.savedPost.value(forKey: "category") as! String)!
            addPostVC.selectedCategory = cat
            addPostVC.selectedMood = Mood(rawValue: self.savedPost.value(forKey: "mood") as! String)!
            addPostVC.loggedInUser = self.loggedInUser
            addPostVC.postWasSaved = true
            
            
            //setting music objects if necessary
            let musicId = self.savedPost.value(forKey: "songString") as! MPMediaEntityPersistentID
            if (String(musicId) != ""){
                let musicItem: MPMediaItem = self.getMPMediaItemWith(persistentId: musicId)
                
                addPostVC.selectedMusicItem = musicItem
                
            }
            
            
//            var secondCat: Category = .None
//            var savedPostHasChild:Bool = false
//            if let child: NSDictionary  = self.savedPost.value(forKey: "secondaryPost") as? NSDictionary{
//                savedPostHasChild = true
//                addPostVC.hasSecondarySavedPost = true
//                secondCat = Category(rawValue: child.value(forKey: "secondaryCategory") as! String)!
//                addPostVC.secondarySelectedCategory = secondCat
//                
//            }
            
            
        
            if  cat == .Video{
                
                let path = self.dataManager.documentsPathForFileName(name: "savedPostData.mp4")
                
                addPostVC.trimmedVideoPath = path.absoluteString
                addPostVC.selectedThumbnail = self.dataManager.getImageForPath(path:"thumbnail")
                addPostVC.selectedObject = self.dataManager.getSavedPostData(category: cat, primary: true)
            }else if (cat == .Music){
                    addPostVC.selectedObject = self.getMPMediaItemWith(persistentId: musicId)
            }else{
                    addPostVC.selectedObject = self.dataManager.getSavedPostData(category: cat, primary: true)
            }
                
                
//                
//            if savedPostHasChild{
//                
//                if (secondCat == .Video){
//                    let path = self.dataManager.documentsPathForFileName(name: "secondarySavedPostData.mp4")
//
//                    addPostVC.selectedThumbnail = self.dataManager.getImageForPath(path:"thumbnail")
////                    addPostVC.secondarySelectedObject = AVAsset(url: path)
//                    addPostVC.trimmedVideoPath = path.absoluteString
//                    addPostVC.secondarySelectedObject = self.dataManager.getSavedPostData(category: secondCat, primary: false)
//                }else{
//                        
//                    addPostVC.secondarySelectedObject = self.dataManager.getSavedPostData(category: secondCat, primary: false)
//
//                }
//            }
        }
    }
    
    
    
    @IBAction func unwindToCreateCustom(unwindSegue: UIStoryboardSegue) {
        
    }
    
}
