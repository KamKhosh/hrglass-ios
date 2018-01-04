//
//  AllPostsViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/23/17.
//
//

import UIKit

class AllPostsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, PostViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    //Set this on segue
    var postsArray: [PostData]!
    let colors: Colors = Colors()
    var imageCache: ImageCache!
    var awsManager: AWSManager = AWSManager()
    var dataManager: DataManager = DataManager()
    
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
        
        let postVC: PostViewController = storyboard!.instantiateViewController(withIdentifier: "postViewController") as! PostViewController
        
        postVC.delegate = self
        postVC.imageCache = self.imageCache
        postVC.postData = postsArray[indexPath.row]
        postVC.source = "Profile"
        addChildViewController(postVC)
        
        postVC.view.frame = view.bounds
//        postVC.topGradientView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        
        view.addSubview(postVC.view)
        postVC.didMove(toParentViewController: self)
        
    }
    
    //Post View Delegates -- these are currently hidden from this view since all the posts here have already been liked
    func likedButtonPressed(liked: Bool, indexPath: IndexPath) {
        //don't do anything
        
    }
    
    func moreButtonPressed(data: PostData, indexPath: IndexPath) {
        
        //don't do anything
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
            
        }
        
    }

    

    

}
