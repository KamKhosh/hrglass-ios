//
//  VideoStore.swift
//  hrglass
//
//  Created by Justin Hershey on 7/19/17.
//
//

import Foundation


/************************************************************************************
 *
 *  VIDEO CACHE/STORE
 
 * - implements Cache Directory with S3 download URLS as KEYS and the
 * - locally stored video in FileManager as the Object
 * 
 * --Functionality, will download and store the video if one doesn't already exist
 *
 *
 * NOTE: THIS IS NOT TESTED OR KNOWN TO BE WORKING
 *
 *************************************************************************************/

public enum Result<T> {
    case success(T)
    case failure(String)
}



class VideoStore{
    
    
//    let dataManager: DataManager = DataManager()
//    var task: URLSessionDownloadTask!
//    var session: URLSession!
//    var cache: NSCache<NSString, NSString>!
    
    
    
//    init() {
//        
//        session = URLSession.shared
//        task = URLSessionDownloadTask()
//        self.cache = NSCache()
//        
//    }
    
    static let shared = VideoStore()
    
    private let fileManager = FileManager.default
    
    private lazy var mainDirectoryUrl: URL = {
        
        let documentsUrl = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return documentsUrl
    }()
    
    func getFileWith(stringUrl: String, completionHandler: @escaping (Result<URL>) -> Void ) {
        
        
        let file = directoryFor(stringUrl: stringUrl)
        
        //return file path if already exists in cache directory
        guard !fileManager.fileExists(atPath: file.path)  else {
            completionHandler(Result.success(file))
            return
        }
        
        DispatchQueue.global().async {
            
            if let videoData = NSData(contentsOf: URL(string: stringUrl)!) {
                videoData.write(to: file, atomically: true)
                
                DispatchQueue.main.async {
                    completionHandler(Result.success(file))
                }
            } else {
                DispatchQueue.main.async {
//                    print("failure")
                    completionHandler(Result.failure("nope"))
                }
            }
        }
    }
    
    private func directoryFor(stringUrl: String) -> URL {
        
        let fileURL = URL(string: stringUrl)!.lastPathComponent
        
        let file = self.mainDirectoryUrl.appendingPathComponent(fileURL)
        
        return file
    }
}
