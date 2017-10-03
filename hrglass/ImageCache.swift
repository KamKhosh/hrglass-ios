//
//  ImageCache.swift
//  hrglass
//
//  Created by Justin Hershey on 5/31/17.
//
//

import Foundation
import UIKit


class ImageCache {
    
    var task: URLSessionDownloadTask!
    var session: URLSession!
    var cache: NSCache<NSString, AnyObject>!
    
    
    
    init() {

        session = URLSession.shared
        task = URLSessionDownloadTask()
        self.cache = NSCache()
        
    }
 


    func getImage(urlString:String, completion:@escaping (UIImage) -> ()){
        
        if (self.cache.object(forKey:urlString as NSString) != nil){
            
            print("Cached image used, no need to download it")
            let image = (self.cache.object(forKey:urlString as NSString) as? UIImage)!
            
            DispatchQueue.main.async(execute: { () -> Void in
                completion(image)
            })
            
        }else{
            
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
}
