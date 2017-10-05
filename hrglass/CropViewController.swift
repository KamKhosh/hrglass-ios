//
//  CropViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 8/20/17.
//
//

import UIKit

class CropViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var cropBtn: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    var originalImage: AnyObject!
    var cropView: UIView!
    
    var parentView: NSString = "addPost"
    
    //LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.bringSubview(toFront: self.imageView)
        self.imageView.image = originalImage as? UIImage
        self.imageView.clipsToBounds = false
        self.imageView.isUserInteractionEnabled = true
        
        self.setupCropView()

    }
    
    
    
    func setupCropView(){
    
        cropView = UIView(frame: CGRect.zero)
        cropView.frame.size = CGSize(width: self.imageView.frame.width,height: self.imageView.frame.width)
        cropView.center = self.imageView.center
        cropView.layer.borderColor = UIColor.white.cgColor
        cropView.layer.borderWidth = 3.0
        
        let panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        self.cropView.addGestureRecognizer(panGesture)
        
        panGesture.minimumNumberOfTouches = 1
        panGesture.delegate = self
        
        let pinchGesture: UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture))
        self.cropView.addGestureRecognizer(pinchGesture)
        pinchGesture.scale = 1
        
        pinchGesture.delegate = self
        
        self.imageView.addSubview(cropView)
    
    }
    
    
    func addLines(){
        
        let vert1: UIView = UIView(frame:CGRect(x: self.cropView.frame.width / 3,y: 0, width: 1,height:self.cropView.frame.height))
        
        let vert2: UIView = UIView(frame:CGRect(x: 2 * self.cropView.frame.width / 3, y:0, width: 1, height: self.cropView.frame.height))
        
        let hor1: UIView = UIView(frame:CGRect(x:0,y: self.cropView.frame.height / 3,width: self.cropView.frame.width,height:1))
        
        let hor2: UIView = UIView(frame:CGRect(x:0,y: 2 * self.cropView.frame.height / 3,width: self.cropView.frame.width,height:1))
        
        
        vert1.layer.borderColor = UIColor.white.cgColor
        vert1.layer.borderWidth = 1.0
        vert2.layer.borderColor = UIColor.white.cgColor
        vert2.layer.borderWidth = 1.0
        hor1.layer.borderColor = UIColor.lightGray.cgColor
        hor1.layer.borderWidth = 1.0
        hor2.layer.borderColor = UIColor.lightGray.cgColor
        hor2.layer.borderWidth = 1.0
        
        self.cropView.addSubview(vert1)
        self.cropView.addSubview(vert2)
        self.cropView.addSubview(hor1)
        self.cropView.addSubview(hor2)
        
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    /************************
     *
     * GESTURE DELEGATES
     *
     ***********************/

    
    //PAN GESTURE
    func handlePanGesture(panGesture: UIPanGestureRecognizer){
        
        // get translation
        let translation = panGesture.translation(in: self.view)
        
        
        if panGesture.state == UIGestureRecognizerState.ended {
            
            panGesture.setTranslation(CGPoint.zero, in: self.view)
        }
        
        if panGesture.state == UIGestureRecognizerState.changed {
            
            let minCenterX = self.cropView.frame.size.width / 2
            let maxCenterX = self.imageView.frame.width - self.cropView.frame.size.width / 2
            let minCenterY = self.imageView.bounds.minY + self.cropView.frame.size.height / 2
            let maxCenterY = self.imageView.bounds.maxY - self.cropView.frame.size.height / 2
            
            let newCenterX = cropView.center.x + translation.x
            let newCenterY = cropView.center.y + translation.y
            
            cropView.center = CGPoint(x: min(maxCenterX, max(minCenterX, newCenterX)),y: min(maxCenterY, max(minCenterY, newCenterY)))
            panGesture.setTranslation(CGPoint.zero, in: self.cropView)
            
        }
    }

    
    //PINCH GESTURE
    func handlePinchGesture(pinchGesture: UIPinchGestureRecognizer){
        
        self.cropView.layer.borderWidth = 3.0
        
        if (pinchGesture.state == UIGestureRecognizerState.changed){
            
            if(self.cropView.frame.width <= self.view.frame.width){
                
                if (self.cropView.frame.width >= self.view.frame.width / 2){
                    
                    self.cropView.transform = self.cropView.transform.scaledBy(x: pinchGesture.scale * 0.2, y: pinchGesture.scale * 0.2)
                    
                }
            }
            
        }else if (pinchGesture.state == UIGestureRecognizerState.ended){
            
            if(self.cropView.frame.width > self.view.frame.width){
                self.cropView.frame.size = CGSize(width: self.imageView.frame.width,height: self.imageView.frame.size.width)
                self.cropView.center.x = self.imageView.center.x
            }
            
            if (self.cropView.frame.width <= self.view.frame.width / 2){
                
                self.cropView.frame.size = CGSize(width: self.view.frame.width / 2,height: self.view.frame.size.width / 2)
                
            }
        }
    }
    
    
    
    
    
    func cropImage(frame: CGRect) -> UIImage{
        
        let image: UIImage = (self.originalImage as? UIImage)!
        
        self.imageView.contentMode = .scaleAspectFit
        
        let widthScale: CGFloat = self.imageView.bounds.size.width / image.size.width;
        let heightScale: CGFloat = self.imageView.bounds.size.height / image.size.height;
        
        let x, y, w, h, offset: CGFloat
        if (widthScale<heightScale) {
            offset = (self.imageView.bounds.size.height - (image.size.height*widthScale))/2;
            x = frame.origin.x / widthScale;
            y = (frame.origin.y-offset) / widthScale;
            w = frame.size.width / widthScale;
            h = frame.size.height / widthScale;
        } else {
            offset = (self.imageView.bounds.size.width - (image.size.width*heightScale))/2;
            x = (frame.origin.x-offset) / heightScale;
            y = frame.origin.y / heightScale;
            w = frame.size.width / heightScale;
            h = frame.size.height / heightScale;
        }
        
        
        let imageRef: CGImage = self.imageView.image!.cgImage!.cropping(to: CGRect(x:x, y:y, width:w, height:h))!;
        let croppedImage: UIImage = UIImage(cgImage: imageRef)
        
        return croppedImage

        
        
    }

    

    @IBAction func cropAction(_ sender: Any) {
        
        if (self.cropBtn.title(for: .normal) == "Crop"){
            
            self.cropBtn.setTitle("Undo", for: .normal)
            self.cancelBtn.setTitle("Done", for: .normal)
            self.imageView.image = self.cropImage(frame: self.cropView.frame)
            self.cropView.isHidden = true
            
            
        }else{
            
            self.cropBtn.setTitle("Crop", for: .normal)
            self.cancelBtn.setTitle("Cancel", for: .normal)
            self.imageView.image = self.originalImage as? UIImage
            self.cropView.isHidden = false
            
        }
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
    
    
    
    
    
    //NAVIGATION
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "unwindToAddPost"){
            
            let addVC: AddPostViewController = segue.destination as! AddPostViewController
            
            addVC.selectedObject = self.imageView.image
            addVC.postPhotoView.image = self.imageView.image
            
        }
        else if (segue.identifier == "unwindToSecondPost"){
            
            let addVC: AddSecondaryPostViewController = segue.destination as! AddSecondaryPostViewController
            
            addVC.selectedObject = self.imageView.image
            addVC.postPhotoView.image = self.imageView.image
        }
    }
}
