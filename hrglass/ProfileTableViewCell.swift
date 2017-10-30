//
//  ProfileTableViewCell.swift
//  hrglass
//
//  Created by Justin Hershey on 5/16/17.
//
//

import UIKit
import Firebase


class ProfileTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource{
    

    var likedDataArray = [PostData]()
    
    let dataManager = DataManager()
    let imageCache: ImageCache = ImageCache()
    var awsManager: AWSManager = AWSManager()
    
    let colors: Colors = Colors()
    
    @IBOutlet weak var nameLbl: UILabel!
    
    @IBOutlet weak var bioTextView: UITextView!
    
    @IBOutlet weak var profilePictureIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var postIndicator: UIActivityIndicatorView!

    @IBOutlet weak var latestPostImageButton: UIButton!
    
    @IBOutlet weak var latestPostBackground: UIView!
    
    @IBOutlet weak var likedCollectionView: UICollectionView!
    
    @IBOutlet weak var bioTextHeight: NSLayoutConstraint!
    
    @IBOutlet weak var likedBackBtn: UIButton!
    
    @IBOutlet weak var likedNextBtn: UIButton!
    
    @IBOutlet weak var likeViewAllBtn: UIButton!
    
    @IBOutlet weak var postsUserLikedLbl: UILabel!
    
    @IBOutlet weak var followingLbl: UILabel!
    
    @IBOutlet weak var followerLbl: UILabel!
    
    @IBOutlet weak var profilePhoto: UIImageView!
    
    @IBOutlet weak var followBtn: UIButton!
    
    @IBOutlet weak var playImageView: UIImageView!
    
    var currentlikedIndex: IndexPath = IndexPath(row: 0, section: 0)
    
    var selectedCellRow: Int = -1
    
    let ref: DatabaseReference = Database.database().reference()
    
    var user: User!
    
    @IBOutlet weak var noRecentPostsLbl: UILabel!
    

    var latestContentSelected: (() -> Void)? = nil
    var collectionContentSelected: (() -> Void)? = nil

    
    /****************************************
     *
     * ----------- LIFECYCLE -------------
     *
     ****************************************/
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.likedCollectionView.delegate = self
        self.likedCollectionView.dataSource = self
        
    }
    
    
    @IBAction func latestPostBtnAction(_ sender: Any) {
        
        if let latestPostBtnAction = self.latestContentSelected{
            
            latestPostBtnAction()
        }
    }
    
    
    
    /****************************************
     *
     * -------------- ACTIONS ---------------
     *
     ******************************************/
    

    // follow or unfollow user
    @IBAction func followBtnAction(_ sender: Any) {
        
        if (followBtn.titleLabel?.text == "Follow"){
            
            followBtn.setTitle("Unfollow", for: .normal)
            followBtn.setTitleColor(colors.getMenuColor(), for: .normal)
            followBtn.backgroundColor = UIColor.clear
            
            dataManager.addToFollowerList(userId: self.user.userID as String, privateAccount: self.user.isPrivate)
            
        }else{
            
            followBtn.setTitle("Follow", for: .normal)
            followBtn.setTitleColor(UIColor.white, for: .normal)
            followBtn.backgroundColor = colors.getMenuColor()
            
            dataManager.removeFromFollowerList(userId: self.user.userID as String)
        }
    }
    
    
    
    @IBAction func likedBackAction(_ sender: Any) {
        
        //scroll left on liked collectionView by subtracting 2 to currentIndex (if not at beginning) then scroll to current index and get more data if necessary
        let scrollDistance = (currentlikedIndex.row - 2)
        
        if(scrollDistance >= -1){
            
            if(scrollDistance == -1){
                
                currentlikedIndex = IndexPath(row: currentlikedIndex.row - 1, section: 0)
            }else{
                currentlikedIndex = IndexPath(row: currentlikedIndex.row - 2, section: 0)
            }
            
            self.likedCollectionView.scrollToItem(at: currentlikedIndex, at: .left, animated: true)
        }
    }
    
    
    
    @IBAction func likedViewAllAction(_ sender: Any) {
        
        //goto Viewall liked content view -> storyboard segue
        
    }
    

    
    
    @IBAction func likedNextAction(_ sender: Any) {
        
        //scroll right on liked collectionView by adding 2 to currentIndex (if not at end) then scroll to current index and get more data if necessary
        let scrollDistance = self.likedDataArray.count - (currentlikedIndex.row + 2)
        
        if(scrollDistance >= 1){
            
            if(scrollDistance == 1){
                
                currentlikedIndex = IndexPath(row: currentlikedIndex.row + 1, section: 0)
            }else{
                currentlikedIndex = IndexPath(row: currentlikedIndex.row + 2, section: 0)
            }
            self.likedCollectionView.scrollToItem(at: currentlikedIndex, at: .left, animated: true)
        }
    }
    
    
    
    
    /**********************************
     *
     * COLLECTION VIEW DELEGATE METHODS
     *
     **********************************/
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var cell: ProfileCollectionViewCell = ProfileCollectionViewCell()
        
        
        if (collectionView == likedCollectionView){
            
            cell = likedCollectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as! ProfileCollectionViewCell
            
            let image = UIImage(named: "clearPlaceholderImage")
            cell.imageButton.setImage(image, for: .normal)
            cell.loadingIndicator.startAnimating()
            
            //user of liked data
            let user: NSDictionary = likedDataArray[indexPath.row].user
            //uid of user
            let uid: String = user.value(forKey: "uid") as! String
            
            cell.playImageView.isHidden = true
            
            //when cell is touched
            cell.contentSelected = {
                
                if let collectionContentSelected = self.collectionContentSelected{
                    
                    self.selectedCellRow = indexPath.row
                    collectionContentSelected()
                }
            }
            
            
            
            
            switch likedDataArray[indexPath.row].category {
                
            case .Video:
                
                //just set the photo for now until we get video stuff setup
                cell.borderView.layer.borderColor = colors.getPurpleColor().cgColor
                
                
                let thumbnailURL: String = String(format:"%@/%@/images/thumbnail.jpg", self.awsManager.getS3Prefix(), uid)
                self.imageCache.getImage(urlString: thumbnailURL, completion: { image in
                    
                    cell.imageButton.setImage(image, for: .normal)
                    cell.loadingIndicator.stopAnimating()
                    cell.playImageView.isHidden = false
                    
                })
                
            case .Photo:
                
                self.imageCache.getImage(urlString: likedDataArray[indexPath.row].data, completion: { image in
                    
                    cell.imageButton.setImage(image, for: .normal)
                    cell.loadingIndicator.stopAnimating()
                    
                })
                cell.borderView.layer.borderColor = colors.getMenuColor().cgColor
                

            case .Music:
                print("Music")
                
                cell.borderView.layer.borderColor = colors.getMusicColor().cgColor
                
                let thumbnailURL: String = String(format:"%@/%@/images/thumbnail.jpg", self.awsManager.getS3Prefix(), uid)
                self.imageCache.getImage(urlString: thumbnailURL, completion: { image in
                    
                    cell.imageButton.setImage(image, for: .normal)
                    cell.loadingIndicator.stopAnimating()
                    cell.playImageView.isHidden = false
                    
                })
                
            case .Text:
                print("Text")
                self.imageCache.getImage(urlString: likedDataArray[indexPath.row].data, completion: { image in
                    
                    cell.imageButton.setImage(image, for: .normal)
                    cell.loadingIndicator.stopAnimating()
                    
                })
                cell.borderView.layer.borderColor = colors.getTextPostColor().cgColor
                
            case .Recording:
                
                print("Recording")
                cell.borderView.layer.borderColor = colors.getAudioColor().cgColor
                cell.imageButton.setImage(UIImage(named: "audioWave"), for: .normal)
                cell.loadingIndicator.stopAnimating()
                cell.playImageView.isHidden = false
                
            case .Link:
                print("Link")
                
            case .None:
                print("None")
            }
        }
        
        cell.borderView.layer.cornerRadius = cell.borderView.frame.width / 2
        cell.borderView.layer.borderWidth = 5.0
        cell.imageButton.imageView?.contentMode = .scaleAspectFill
        cell.imageButton.layer.cornerRadius = cell.imageButton.frame.width / 2
        cell.imageButton.clipsToBounds = true
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var items: Int = 0

        if (collectionView == likedCollectionView){
            
            items = likedDataArray.count
            
            if (items == 0){
                
                self.hideLikedContentBtns()
            }else{
                
                self.showLikedContentBtns()
            }
        }
        return items
    }
    
    
    
    //shows the liked content buttons
    func showLikedContentBtns(){
        self.likedBackBtn.isHidden = false
        self.likedNextBtn.isHidden = false
        self.likeViewAllBtn.isHidden = false
        
    }
    
    //hides liked contents buttons when there is no liked content
    func hideLikedContentBtns(){
        self.likedBackBtn.isHidden = true
        self.likedNextBtn.isHidden = true
        self.likeViewAllBtn.isHidden = true
        
    }

    
    
  

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
