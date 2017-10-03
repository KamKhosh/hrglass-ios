//
//  AllPostsViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/23/17.
//
//

import UIKit

class AllPostsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    //Set this on segue
    var postsArray: [PostData]!
    
    let colors: Colors = Colors()
    var imageCache: ImageCache!
    var awsManager: AWSManager = AWSManager()
    
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
        
        switch postsArray[indexPath.row].category {
            
        case .Video:
                
            cell.borderView.layer.borderColor = colors.getPurpleColor().cgColor

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

            cell.borderView.layer.borderColor = colors.getMenuColor().cgColor
            
        case .Recording:
            print("Recording")
            cell.borderView.layer.borderColor = colors.getAudioColor().cgColor
            
        case .Text:
            print("Text")
            self.imageCache.getImage(urlString: postsArray[indexPath.row].data, completion: { image in
                
                cell.imageView.image = image
                cell.loadingIndicator.stopAnimating()
            })
            //default is photo for now
            
            cell.borderView.layer.borderColor = colors.getTextPostColor().cgColor
            
        case .Music:
            print("Music")
            
        case .Link:
            print("Link")
                
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
        
        postVC.imageCache = self.imageCache
        postVC.postData = postsArray[indexPath.row]
        
        addChildViewController(postVC)
        
        postVC.view.frame = view.bounds
        postVC.alphaView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        
        view.addSubview(postVC.view)
        postVC.didMove(toParentViewController: self)
        
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
