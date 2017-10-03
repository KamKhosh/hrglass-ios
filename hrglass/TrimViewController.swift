//
//  TrimViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 8/28/17.
//
//

import UIKit
import SwiftRangeSlider
import Photos
import AVFoundation
import MediaPlayer
import AVKit


class TrimViewController: UIViewController {
    
    typealias TrimCompletion = (NSError?) -> ()
    
    typealias TrimPoints = [(CMTime, CMTime)]
    
    
    let dataManager: DataManager = DataManager()
    let colors: Colors = Colors()
    
    @IBOutlet weak var thumbnailSlider: UISlider!
    @IBOutlet weak var bottomTrimImageView: UIImageView!
    @IBOutlet weak var topTrimImageView: UIImageView!
    @IBOutlet weak var setDataBtn: UIButton!
    @IBOutlet weak var trimRangeSlider: RangeSlider!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    var selectedObject: AnyObject! = nil
    var thumbnail: UIImage!
    var selectedVideoURL: URL!
    var selectedAVAsset: AVAsset!
    var assetImgGenerate: AVAssetImageGenerator!
    var loadingView: UILabel!
    var thmbnailValue: Int = 0
    var parentView: NSString = ""
    
    let thumbnailArray: NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        
        let video: PHAsset = selectedObject as! PHAsset
        let length: TimeInterval = video.duration
        
        print(length * 10)
        
        self.trimRangeSlider.maximumValue = Double(length) * 10.0
        self.thumbnailSlider.maximumValue = Float(length) * 10.0
        
        self.trimRangeSlider.minimumValue = 1
        self.thumbnailSlider.minimumValue = 1

        self.trimRangeSlider.lowerValue = Double(1)
        self.trimRangeSlider.upperValue = Double(length * 10.0)
        
        self.showLoadingView()
        self.dataManager.getURLForPHAsset(videoAsset: video, name: "mergeSlowMoVideo.mp4") { (url) in
            self.selectedVideoURL = url
            self.processVideo(url: url)
            
            var i: CGFloat = 0.1

            while i <= CGFloat(length){
                
                print(Float64(i))
                self.thumbnailArray.add(self.generateThumnail(fromTime: Float64(i)) as UIImage!)
                 i = i + 0.1
//                print(i)
            }

            
            self.bottomTrimImageView.image = self.thumbnailArray[0] as? UIImage
            self.topTrimImageView.image = self.thumbnailArray[self.thumbnailArray.count - 1] as? UIImage
            self.thumbnailImageView.image = self.thumbnailArray[Int(self.thumbnailSlider.value - 1)] as? UIImage
            self.thumbnailImageView.clipsToBounds = true
            self.thumbnailImageView.layer.borderColor = self.colors.getPurpleColor().cgColor
            self.thumbnailImageView.layer.borderWidth = 5.0
            self.thumbnailImageView.layer.cornerRadius = self.thumbnailImageView.frame.width / 2
            self.hideLoadingView()
        }
        
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    
    
    
    /*******************************
    *
    *           ACTONS
    *
    ********************************/
    
    
    
    
    @IBAction func thumbnailSliderAction(_ sender: Any) {
        
        self.thumbnailImageView.image = self.thumbnailArray[Int(self.thumbnailSlider.value - 1)] as? UIImage
    }
    
 
    @IBAction func setDataAction(_ sender: Any) {
        
//        let asset: PHAsset = self.selectedObject as! PHAsset
//        var path: String = ""
//        let destPath: URL = self.dataManager.documentsPathForFileName(name: "videos/mergeSlowMoVideo.mp4")
//        
//        self.dataManager.getURLForPHAsset(videoAsset: asset, name: "trimmedVideo.mp4", completion: { url in
//            
//            print(url.relativePath)
//            path = url.relativePath
//            let lowerTime = CMTimeMake(Int64(self.trimRangeSlider.lowerValue), 1000)
//            let upperTime = CMTimeMake(Int64(self.trimRangeSlider.upperValue), 1000)
//            
//            let trim: TrimPoints = [(lowerTime, upperTime)]
//            
//            self.trimVideo(sourceURL: URL(string: path)!, destinationURL: destPath, trimPoints: trim, completion: { (error) in
//                
//                if (error != nil){
//                    
//                    
//                }else{
//                    
//                    
//                    
//                }
//            })
//        })
        
        
        
    }
    
    
    
    @IBAction func rangeSliderChanged(_ sender: RangeSlider) {
        
        self.bottomTrimImageView.image = self.thumbnailArray[Int(sender.lowerValue)] as? UIImage
        self.topTrimImageView.image = self.thumbnailArray[Int(sender.upperValue - 1)] as? UIImage
        
    }
    
    func processVideo(url: URL){
        
        let asset: AVAsset = AVAsset(url: self.selectedVideoURL)
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
        
        self.loadingView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.loadingView.textColor = UIColor.white
        self.loadingView.textAlignment = .center
        self.loadingView.text = "Processing Thumbnails..."
        self.loadingView.layer.cornerRadius = 2.0
        self.loadingView.clipsToBounds = true
        self.loadingView.layer.shadowColor = UIColor.black.cgColor
        self.loadingView.layer.shadowOffset = CGSize(width: 3.0,height: 3.0)
        
        self.view.addSubview(loadingView)
    }
    
    
    func hideLoadingView(){
        
        self.loadingView.removeFromSuperview()
        
    }
    

    
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        
        if (segue.identifier == "unwindToAddPost") {
            
//            let addVC: AddPostViewController = segue.destination as! AddPostViewController
            
//            addVC.selectedObject = self.imageView.image
//            addVC.postPhotoView.image = self.imageView.image
            
            
        }
        
    }
    
//    func verifyPresetForAsset(preset: String, asset: AVAsset) -> Bool {
//        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset) 
//        let filteredPresets = compatiblePresets.filter { $0 == preset }
//        
//        return filteredPresets.count > 0 || preset == AVAssetExportPresetPassthrough
//    }
//    
//    func removeFileAtURLIfExists(url: URL) {
//        
//        if let filePath = url.path as? String{
//            let fileManager = FileManager.default
//            if fileManager.fileExists(atPath: filePath) {
//                let error: NSError?
//                do{
//                    try fileManager.removeItem(atPath: filePath)
//                
//                }catch{
//                    NSLog("Couldn't remove existing destination file: \(String(describing: error))")
//                }
//            }
//        }
//    }
//    
//    func trimVideo(sourceURL: URL, destinationURL: URL, trimPoints: TrimPoints, completion: TrimCompletion?) {
//        assert(sourceURL.isFileURL)
//        assert(destinationURL.isFileURL)
//        
//        let options = [ AVURLAssetPreferPreciseDurationAndTimingKey: true ]
//        
//        let asset = AVURLAsset(url: sourceURL, options: options)
//
//        let preferredPreset = AVAssetExportPresetPassthrough
//        if verifyPresetForAsset(preset: preferredPreset, asset: asset) {
//            let composition = AVMutableComposition()
//            let videoCompTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
//            let audioCompTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
//            
//            let assetVideoTrack: AVAssetTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first!
//            let assetAudioTrack: AVAssetTrack = asset.tracks(withMediaType: AVMediaTypeAudio).first!
//            
//            let compError: NSError! = nil
//            
//            var accumulatedTime = kCMTimeZero
//            for (startTimeForCurrentSlice, endTimeForCurrentSlice) in trimPoints {
//                let durationOfCurrentSlice = CMTimeSubtract(endTimeForCurrentSlice, startTimeForCurrentSlice)
//                let timeRangeForCurrentSlice = CMTimeRangeMake(startTimeForCurrentSlice, durationOfCurrentSlice)
//                do{
//                    try videoCompTrack.insertTimeRange(_:timeRangeForCurrentSlice, of: assetVideoTrack, at: accumulatedTime)
//                }catch{
//                    print(error)
//                    
//                }
//                
//                do{
//                    try audioCompTrack.insertTimeRange(_:timeRangeForCurrentSlice, of: assetAudioTrack, at: accumulatedTime)
//                }catch{
//                    print(error)
//                    
//                }
//                
//                if compError != nil {
//                    NSLog("error during composition: \(String(describing: compError))")
//                    if let completion = completion {
//                        completion(compError)
//                    }
//                }
//                
//                accumulatedTime = CMTimeAdd(accumulatedTime, durationOfCurrentSlice)
//            }
//            
//            let exportSession = AVAssetExportSession(asset: composition, presetName: preferredPreset)
//            exportSession?.outputURL = destinationURL
//            exportSession?.outputFileType = AVFileTypeAppleM4V
//            exportSession?.shouldOptimizeForNetworkUse = true
//            
//            self.removeFileAtURLIfExists(url: destinationURL)
//            
//            exportSession?.exportAsynchronously(completionHandler: { () -> Void in
//                if let completion = completion {
//                    completion(exportSession?.error! as! NSError)
//                }
//            })
//        } else {
//            NSLog("Could not find a suitable export preset for the input video")
//            let error = NSError(domain: "org.linuxguy.VideoLab", code: -1, userInfo: nil)
//            if let completion = completion {
//                completion(error)
//            }
//        }
//    }

}
