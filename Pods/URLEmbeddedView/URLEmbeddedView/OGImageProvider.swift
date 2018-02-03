//
//  OGImageProvider.swift
//  URLEmbeddedView
//
//  Created by Taiki Suzuki on 2016/03/07.
//
//

import Foundation



public final class OGImageProvider: NSObject {
    
    private class TaskContainer: TaskContainable {
        typealias Completion = ((UIImage?, Error?) -> Void)
        
        let uuidString: String
        let task: URLSessionDataTask
        var completion: Completion?
        
        required init(uuidString: String, task: URLSessionDataTask, completion: Completion?) {
            self.uuidString = uuidString
            self.task = task
            self.completion = completion
        }
    }
    
    //MARK: - Static constants
    @objc(sharedInstance)
    public static let shared = OGImageProvider()
    
    //MARK: - Properties
    private let session = URLSession(configuration: URLSessionConfiguration.default)
    private var taskContainers: [String : TaskContainer] = [:]
    
    private override init() {
        super.init()
    }

    public func loadImage(urlString: String, completion: ((UIImage?, Error?) -> Void)? = nil) -> String? {
        guard let URL = URL(string: urlString) else {
            completion?(nil, NSError(domain: "can not create NSURL with \(urlString)", code: 9999, userInfo: nil))
            return nil
        }
        if !urlString.isEmpty {
            if let image = OGImageCacheManager.shared.cachedImage(urlString: urlString) {
                completion?(image, nil)
                return nil
            }
        }
        let uuidString = UUID().uuidString
        let task = session.dataTask(with: URL) { [weak self] data, response, error in
            let completion = self?.taskContainers[uuidString]?.completion
            _ = self?.taskContainers.removeValue(forKey: uuidString)
            
            if let error = error {
                completion?(nil,  error)
                return
            }
            guard let data = data else {
                completion?(nil, NSError(domain: "can not fetch image data with \(urlString)", code: 9999, userInfo: nil))
                return
            }
            guard let image = UIImage(data: data) else {
                completion?(nil, NSError(domain: "can not fetch image with \(urlString)", code: 9999, userInfo: nil))
                return
            }
            OGImageCacheManager.shared.storeImage(image, data: data, urlString: urlString)
            
            completion?(image, nil)
        }
        taskContainers[uuidString] = TaskContainer(uuidString: uuidString, task: task, completion: completion)
        task.resume()
        return uuidString
    }
    
    public func clearMemoryCache() {
        OGImageCacheManager.shared.clearMemoryCache()
    }
    
    public func clearAllCache() {
        OGImageCacheManager.shared.clearAllCache()
    }
    
    func cancelLoad(_ uuidString: String, stopTask: Bool) {
       taskContainers[uuidString]?.completion = nil
        if stopTask {
            taskContainers[uuidString]?.task.cancel()
        }
        taskContainers.removeValue(forKey: uuidString)
    }
}
