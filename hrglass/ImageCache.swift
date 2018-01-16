//
//  ImageCache.swift
//  hrglass
//
//  Created by Justin Hershey on 5/31/17.
//
//  cached images instance,
// getImage: string -> will return image without downloading if the image is cached. Otherwise it will download the image than perform a completion to return that image to sender

import Foundation
import UIKit


class ImageCache {
    
    var task: URLSessionDownloadTask!
    var session: URLSession!
    var cache: NSCache<NSString, AnyObject>!
    
    
    //initialize
    init() {

        session = URLSession.shared
        task = URLSessionDownloadTask()
        self.cache = NSCache()
    }
 

    //getImage
    //
    // --Parameters: url as String, Completion with UIImage
    // -- if the image has been cached it will be returned, otherwise it will be dowloaded with a URLSession and returned
    func getImage(urlString:String, completion:@escaping (UIImage) -> ()){
        
        if (self.cache.object(forKey:urlString as NSString) != nil){
            //if the image is cached
            
            print("Cached image used, no need to download it")
            let image = (self.cache.object(forKey:urlString as NSString) as? UIImage)!
            
            DispatchQueue.main.async(execute: { () -> Void in
                completion(image)
            })
            
        }else{
            //if the image is not cached
            if let url:URL = URL(string:urlString as String){
                
                task = session.downloadTask(with: url, completionHandler: { (location, response, error) -> Void in
                    
                    if let data = try? Data(contentsOf: url){
                        
                        let img:UIImage! = UIImage(data: data)
                        self.cache.setObject(img, forKey:urlString as NSString)
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            completion(img)
                        })
                    }
                })
                task.resume()
            }else{
                
                let img:UIImage! = UIImage(named: "clearPlaceholderImage")
                
                DispatchQueue.main.async(execute: { () -> Void in
                    completion(img)
                })
            }
        }
    }
    
    
    
    func replacePhotoForKey(url: String, image: UIImage){
        
        self.cache.setObject(image, forKey: url as NSString)
        
    }
}
