//
//  SelectThumbnailViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 8/29/17.
//
//

import UIKit
import AVFoundation
import CoreMedia
import Photos

class SelectThumbnailViewController: UIViewController {

    
    let dataManager: DataManager = DataManager()
    let colors: Colors = Colors()
    
    var thumbnailArray: NSMutableArray = NSMutableArray()
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    @IBOutlet weak var setThumbnailBtn: UIButton!
    @IBOutlet weak var thumbnailSlider: UISlider!
    
    var selectedObject: AnyObject! = nil
    var thumbnail: UIImage!
    var selectedVideoPath: String!
    var parentView: NSString = "addPost"
    
    
    var selectedAVAsset: AVAsset!
    var assetImgGenerate: AVAssetImageGenerator!
    var loadingView: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.showLoadingView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        if selectedObject != nil{
            
            let video: PHAsset = selectedObject as! PHAsset
            
            self.dataManager.getURLForPHAsset(videoAsset: video, name: "savedPostData.mp4") { (url) in
                self.selectedVideoPath = url.relativeString
                let asset: AVAsset = AVAsset(url:url)
                
                self.processVideo(asset: asset)

                let duration = asset.duration
                let durationTime = CMTimeGetSeconds(duration)
                print(durationTime)
                
                var i: CGFloat = 0.1
                
                while i <= CGFloat(durationTime){
                    
                    print(Float64(i))
                    self.thumbnailArray.add(self.generateThumnail(fromTime: Float64(i)) as UIImage!)
                    i = i + 0.1
                }
                
                self.thumbnailSlider.maximumValue = Float(durationTime) * 10.0 - 1
                self.thumbnailSlider.minimumValue = 1
                self.hideLoadingView()
                self.thumbnailImageView.image = self.thumbnailArray[Int(self.thumbnailSlider.value - 1)] as? UIImage
                
            
            }
            
        }else if (self.selectedVideoPath != ""){
            
            
            var i: CGFloat = 0.1
            let asset: AVAsset = AVAsset(url:URL(fileURLWithPath: self.selectedVideoPath))
            self.processVideo(asset: asset)
            
            let duration = asset.duration
            let durationTime = CMTimeGetSeconds(duration)
            print(durationTime)
            
            while i <= CGFloat(durationTime){
//                print(Float64(i))
                self.thumbnailArray.add(self.generateThumnail(fromTime: Float64(i)) as UIImage!)
                i = i + 0.1
            }
            
            self.thumbnailSlider.maximumValue = Float(durationTime) * 10.0 - 1
            self.thumbnailSlider.minimumValue = 1
            self.hideLoadingView()
            self.thumbnailImageView.image = self.thumbnailArray[Int(self.thumbnailSlider.value - 1)] as? UIImage

        }
        
        
        
        self.thumbnailImageView.clipsToBounds = true
        self.thumbnailImageView.layer.borderColor = self.colors.getPurpleColor().cgColor
        self.thumbnailImageView.layer.borderWidth = 5.0
        self.thumbnailImageView.layer.cornerRadius = self.thumbnailImageView.frame.width / 2
        
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func processVideo(asset: AVAsset){
        
        self.selectedAVAsset = asset
        self.assetImgGenerate = AVAssetImageGenerator(asset: asset)
        self.assetImgGenerate.maximumSize = CGSize(width:300, height:300);
        self.assetImgGenerate.appliesPreferredTrackTransform = true
        self.assetImgGenerate.requestedTimeToleranceAfter = kCMTimeZero;
        self.assetImgGenerate.requestedTimeToleranceBefore = kCMTimeZero;
        
    }
    
    
    fileprivate func generateThumnail(fromTime:Float64) -> UIImage? {
        
        let time: CMTime = CMTimeMakeWithSeconds(fromTime, 100)
        var img: CGImage?
        do {
            img = try self.assetImgGenerate.copyCGImage(at:time, actualTime: nil)
        } catch {
            print("Error info: \(error)")
        }
        if img != nil {
            let frameImg    : UIImage = UIImage(cgImage: img!)
            return frameImg
        } else {
            return nil
        }
    }
    
    
    func showLoadingView(){
        
        self.loadingView = UILabel(frame: CGRect(x: self.view.frame.width/2 - self.view.frame.width/4 - 25, y:self.view.frame.height/2 - 25, width: self.view.frame.width/2 + 50, height: 50))
        print(self.loadingView.frame)
        
        self.loadingView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.loadingView.textColor = UIColor.white
        self.loadingView.textAlignment = .center
        self.loadingView.text = "Processing Thumbnails..."
        self.loadingView.layer.cornerRadius = 2.0
        self.loadingView.clipsToBounds = true
        self.loadingView.layer.shadowColor = UIColor.black.cgColor
        self.loadingView.layer.shadowOffset = CGSize(width: 0,height: 0)
        
        self.view.addSubview(loadingView)
        self.view.bringSubview(toFront: self.loadingView)
    }
    
    
    func hideLoadingView(){
        
        self.loadingView.removeFromSuperview()
        
    }
    
    
    @IBAction func setThumbnailAction(_ sender: Any) {
        
        if (parentView == "addPost"){
            
            self.performSegue(withIdentifier: "unwindToAddPost", sender: self)
        }else if (parentView == "editProfilePics"){
            
            self.performSegue(withIdentifier: "unwindToEditProfile", sender: self)
        }else if (parentView == "secondaryPostView"){
            
            self.performSegue(withIdentifier: "unwindToSecondPost", sender: self)
        }
        
    }


    @IBAction func thumbnailSliderAction(_ sender: Any) {
        
        self.thumbnail = self.thumbnailArray[Int(self.thumbnailSlider.value - 1)] as? UIImage
        self.thumbnailImageView.image = self.thumbnailArray[Int(self.thumbnailSlider.value - 1)] as? UIImage
        
    }
    

    
    @IBAction func cancelAction(_ sender: Any) {
        
        if (parentView == "addPost"){
            
            self.performSegue(withIdentifier: "unwindToAddPost", sender: self)
        }else if (parentView == "editProfilePics"){
            
            self.performSegue(withIdentifier: "unwindToEditProfile", sender: self)
        }else if (parentView == "secondaryPostView"){
            
            self.performSegue(withIdentifier: "unwindToSecondPost", sender: self)
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "unwindToAddPost"){
            
            let addVC: AddPostViewController = segue.destination as! AddPostViewController
            
            if self.thumbnail != nil{
                addVC.selectedThumbnail = self.thumbnail
                addVC.postPhotoView.image = self.thumbnail
            }
        }else if (segue.identifier == "unwindToSecondPost"){
            
            let addVC: AddSecondaryPostViewController = segue.destination as! AddSecondaryPostViewController
            
            if self.thumbnail != nil{
                addVC.selectedThumbnail = self.thumbnail
                addVC.postPhotoView.image = self.thumbnail
            }

        }
        
    }
    

}
