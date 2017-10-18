//
//  DataManager.swift
//  hrglass
//
//  Created by Justin Hershey on 6/18/17.
//
// Class containing Firebase Methods used throughout the Class Hierarchy

import Foundation
import URLEmbeddedView
import Firebase
import AVFoundation
import Photos
import AWSS3





/***********************************************************************************
 *
 *     FUNCTIONS TO UPDATE AND RETRIEVE DATA FROM FIREBASE/USERDEFAULTS/FILEMANAGER
 *
 *      - additional methods for data conversion, date formatting live here
 *
 *
 ***********************************************************************************/


struct Song {
    
    var title: String = ""
    var album: String = ""
    var artist: String = ""
    var source: String = ""
}

enum ExporterError: Error {
    case unableToCreateExporter

}


class DataManager {
    
    
    
    
    
    
    
    /******************************************
     *
     *  followedBy/following list update methods
     *
     ******************************************/
    
    
    func addToFollowerList(userId: String, privateAccount: Bool){
        let currentUserId: String = (Auth.auth().currentUser?.uid)!
        
        let followedByRef = Database.database().reference().child("Users").child(userId)
        let followingRef = Database.database().reference().child("Users").child(currentUserId)
        
        
        //Add the current user to the parameter's userId followedBy Dictionary
        //dictioary value of 0 means user is approved to follow, 1 means that user has yet to be approved
        
        
        followedByRef.observeSingleEvent(of: .value, with: { snapshot in
            
            //increment followed by count
            let userDict: NSMutableDictionary = (snapshot.value as? NSMutableDictionary)!
            let count: Int = userDict.value(forKey: "followed_by_count") as! Int
            let followedByCount: NSNumber = count + 1 as NSNumber
            
            userDict.setValue(followedByCount, forKey: "followed_by_count")
            
            if let followedByDict: NSMutableDictionary = userDict.value(forKey: "followed_by_list") as? NSMutableDictionary{
                    
                followedByDict.setObject(privateAccount ? 1 : 0, forKey: currentUserId as NSCopying)
                userDict.setValue(followedByDict, forKey: "followed_by_list")
                followedByRef.setValue(userDict)
                
            }else{
                
                print("FollowedBy dict doesn't yet exist, create it")
    
                let followedByDict: NSDictionary = [currentUserId:privateAccount ? 1 : 0]
                userDict.setValue(followedByDict, forKey: "followed_by_list")
                followedByRef.setValue(userDict)
                
            }
        })
        
        
        //Add the user to the current users' following dictionary and save in Firebase
        followingRef.observeSingleEvent(of: .value, with: { snapshot in
            
            //increment following by count
            let userDict: NSMutableDictionary = (snapshot.value as? NSMutableDictionary)!
            let count: Int = userDict.value(forKey: "following_count") as! Int
            let followingCount: NSNumber = count + 1 as NSNumber
            
            userDict.setValue(followingCount, forKey: "following_count")
            
            if let followingDict: NSMutableDictionary = userDict.value(forKey: "following_list") as? NSMutableDictionary{
                
                followingDict.setObject(privateAccount ? 1 : 0, forKey: userId as NSCopying)
                userDict.setValue(followingDict, forKey: "following_list")
                followingRef.setValue(userDict)
                
            }else{
                print("Following dict doesn't yet exist, create it")
                
                let followingDict: NSDictionary = [userId:privateAccount ? 1 : 0]
                userDict.setValue(followingDict, forKey: "following_list")
                followingRef.setValue(userDict)
                
            }
        })
    }
    

    
    //On UnFollow, remove user from corresponding dictionary's and update Firebase
    func removeFromFollowerList(userId: String){
        
        let currentUserId: String = (Auth.auth().currentUser?.uid)!
        let followedByRef = Database.database().reference().child("Users").child(userId)
        let followingRef = Database.database().reference().child("Users").child(currentUserId)
        
        //Add the current user to the desired users' followedBy Dictionary
        followedByRef.observeSingleEvent(of: .value, with: { snapshot in
            
            //decrement followed by count
            let userDict: NSMutableDictionary = (snapshot.value as? NSMutableDictionary)!
            let count: Int = userDict.value(forKey: "followed_by_count") as! Int
            let followedCount: NSNumber = count - 1 as NSNumber
            
            userDict.setValue(followedCount, forKey: "followed_by_count")
            
            if let followedByDict: NSMutableDictionary = userDict.value(forKey: "followed_by_list") as? NSMutableDictionary{
                
                followedByDict.removeObject(forKey: currentUserId)
                userDict.setValue(followedByDict, forKey: "followed_by_list")
                followedByRef.setValue(userDict)
                
            }
        })
        
        
        //Add the user to the current users' following dictionary and save in Firebase
        followingRef.observeSingleEvent(of: .value, with: { snapshot in
            
            let userDict: NSMutableDictionary = (snapshot.value as? NSMutableDictionary)!
            let count: Int = userDict.value(forKey: "following_count") as! Int
            let followingCount: NSNumber = count - 1 as NSNumber
            
            userDict.setValue(followingCount, forKey: "following_count")
            
            if let followingDict: NSMutableDictionary = userDict.value(forKey: "following_list") as? NSMutableDictionary{
                
                followingDict.removeObject(forKey: userId)
                userDict.setValue(followingDict, forKey: "following_list")
                followingRef.setValue(userDict)
                
            }
        })
    }
    
    
    
    
    
    /*************************************
     *
     *  Determine if FollowedBy/Following
     *
     *************************************/
    
    
    //Uses a Boolean Completion to determine if the current user is followed by the parameter userId
    func isFollowedBy(userId: String, completion:@escaping (Bool) -> ()){
        let currentUserId: String = Auth.auth().currentUser!.uid
        
        let followedByRef = Database.database().reference().child("Users").child(currentUserId).child("followed_by_list")
        
        followedByRef.observeSingleEvent(of: .value, with: { snapshot in
            
            if let followedByDict = snapshot.value as? NSDictionary{
                
                if(followedByDict.value(forKey: userId) != nil){
                    
                    completion(true)
                }else{
                    
                    completion(false)
                }

            }else{
                completion(false)
            }
        })
    }
    
    
    
    //Return Dicionary of Follow Requests
    func getFollowRequests(userId: String, completion:@escaping (NSDictionary) -> ()){
        
        let followedByRef = Database.database().reference().child("Users").child(userId).child("followed_by_list")
        let requests: NSMutableDictionary = [:]
        
        
        followedByRef.observeSingleEvent(of: .value, with: { snapshot in
            
            if let followedByDict: NSDictionary = snapshot.value as? NSDictionary{
                
                for key in followedByDict.allKeys{
                    
                    if (followedByDict.value(forKey: key as! String) as! Int == 1){
                        requests.setValue(1, forKey: key as! String)

                    }
                }
                
                completion(requests)
                
            }else{
                completion(requests)
            }
        })
    }
    
    
    
    
    /****************************************************
     *
     *  Return Array of PostData
     *  - checks for blocked users and removes
     *
     ***************************************************/
    
    
    func getFeedPosts(userId: String, completion:@escaping (NSArray) -> ()){
        
        let currentUserId: String = Auth.auth().currentUser!.uid
        
        self.getFollowingList(userId: currentUserId, completion: { followingDictionary in
            
            //returns dictionary with uids as keys
            self.getBlockedUsers(completion: { (blockedUsers) in
                
                let count = followingDictionary.count
                
                var i = 0
                let dataArray: NSMutableArray = NSMutableArray()
                
                for (key, _) in followingDictionary{
                    
                    let isPrivate: Int = followingDictionary.value(forKey: key as! String) as! Int
                    
                    if (blockedUsers.value(forKey: key as! String) == nil && isPrivate == 0){
                        
                        let postRef = Database.database().reference().child("Posts").child(key as! String)
                        
                        postRef.observeSingleEvent(of: .value, with: { snapshot in
                            
                            
                            if let postDict = snapshot.value as? NSDictionary{
                                
                                
                                let postData: PostData = self.getPostDataFromDictionary(postDict: postDict, uid: key as! String)
                                if (Double(postData.expireTime)! > Date().millisecondsSince1970) {
                                    
                                    dataArray.add(postData)
                                }
                            }
                            
                            i += 1
                            //Once we've run through all posts
                            if i == count{
                                
                                completion(dataArray)
                            }
                        })
                    }else{
                        i += 1
                        //Once we've run through all posts
                        if i == count{
                            
                            completion(dataArray)
                        }
                    }
                    
                }

            })
            
        })
    }
    
    
    
    
    
    /******************************************************************************
     *
     *          GET POST DATA OBJECT FROM FIREBASE POST SNAPSHOT DICTIONARY
     *          - dictionary parameter: NSDictionary, uid parameter: String
     *          - returns a PostData object
     *******************************************************************************/
    
    
    
    
    
    func getPostDataFromDictionary(postDict: NSDictionary, uid: String) -> PostData{
        
        let category: Category = Category(rawValue: postDict.value(forKey: "category") as! String)!
        let mood: Mood = Mood(rawValue: postDict.value(forKey: "mood") as! String)!
        var usersWhoLiked: NSDictionary = [:]
        
        if let likedDict: NSDictionary = postDict.value(forKey: "users_who_liked") as? NSDictionary{
            usersWhoLiked = likedDict;
        }
        
        
        let cd: String = postDict.value(forKey: "creation_date") as! String
        let et: String = postDict.value(forKey: "expire_time") as! String
        let creationDate: String = NSString(format: "%@", cd as CVarArg) as String
        let expireTime: String = NSString(format: "%@", et as CVarArg) as String
        
//        var postData: PostData!
        
//        if let secondDict: NSDictionary = postDict.value(forKey: "secondaryPost") as? NSDictionary{
//            
//            postData = PostData.init(withDataString: postDict.value(forKey: "data") as! String, postId: postDict.value(forKey: "postID") as! String , likes:  postDict.value(forKey: "likes") as! Int, views:  postDict.value(forKey: "views") as! Int, category: category , mood: mood.rawValue, user: postDict.value(forKey: "user") as! NSDictionary, usersWhoLiked: usersWhoLiked, creationDate: creationDate, expireTime: expireTime, postShape: postDict.value(forKey: "post_shape") as! String, secondaryPost: secondDict,commentThread: postDict.value(forKey: "postID") as! String)
//            
//        }else{
        
        let postData: PostData = PostData.init(withDataString: postDict.value(forKey: "data") as! String, postId: postDict.value(forKey: "postID") as! String , likes:  postDict.value(forKey: "likes") as! Int, views:  postDict.value(forKey: "views") as! Int, category: category , mood: mood.rawValue, user: postDict.value(forKey: "user") as! NSDictionary, usersWhoLiked: usersWhoLiked, creationDate: creationDate, expireTime: expireTime, commentThread: postDict.value(forKey: "postID") as! String, songString: postDict.value(forKey: "extraData") as! String)
            
//        }

        print(postDict.value(forKey: "likes") as! Int)
        print(postDict.value(forKey: "views") as! Int)
        print(postDict.value(forKey: "user")  as! NSDictionary)
        
        return postData
    }
    
    
    
    
    //Removes Key/Object Pair from dictionary where the object(milliseconds since 1970)that is passed now  
    func postsCleanup(dictionary: NSDictionary) -> NSDictionary{
        
        let mutDict: NSMutableDictionary = dictionary.mutableCopy() as! NSMutableDictionary
        
        for (key, _) in dictionary{
            
            let now: Double = Date().millisecondsSince1970
            let expString: String = mutDict.value(forKey: key as! String) as! String
            let expTime: Double = Double(expString)!
            if(now > expTime){
                mutDict.removeObject(forKey: key)
            }
        }

        return mutDict
    }
    
    
    
    /******************************************************************************
     *
     *  GET COMMENT DATA OBJECT FROM FIREBASE COMMENT SNAPSHOT DICTIONARY
     *     - uid parameter
     *     - completion yields a Dictionary of dictionary's containing comment data
     *******************************************************************************/
    
    func getCommentDataFromFirebase(uid: String, completion:@escaping (NSDictionary) -> ()){
        
        let commentsRef: DatabaseReference = Database.database().reference().child("Comments").child(uid)
        
        commentsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let commentDict = snapshot.value as? NSDictionary{
                
                completion(commentDict)
            }else{
                completion([:])
            }
        })
    }
    
    
    
    /******************************************************************************
     *
     *   GET X NUMBER OF COMMENT DATA OBJECT FROM FIREBASE COMMENT SNAPSHOT DICTIONARY
     *          - dictionary parameter: num parameter: Int
     *          - returns a Dictionary of dictionary's containing comment data
     *******************************************************************************/
    
    func getXCommentsFromFirebase(uid: String, num: Int, completion:@escaping (NSDictionary) -> ()){
        
        let commentsRef: DatabaseReference = Database.database().reference().child("Comments").child(uid)

        commentsRef.queryLimited(toLast: UInt(num)).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let commentDict = snapshot.value as? NSDictionary{
                
                completion(commentDict)
            }else{
                completion([:])
            }
        })
    }
    
    
    
    /*************************************************
     *
     *     SAVE COMMENT DATA TO THREADID CHILD
     *
     *************************************************/
    
    func writeCommentData(threadId: String, commentorUid: String, comment: String, created: String, username:String){
        
        let dictionary: NSMutableDictionary = NSMutableDictionary()
        
        dictionary.setValue(commentorUid, forKey: "commentorUid")
        dictionary.setValue(comment, forKey: "comment")
        dictionary.setValue(created, forKey: "created")
        dictionary.setValue(username, forKey: "username")
        
        let newCommentRef: DatabaseReference = Database.database().reference().child("Comments").child(threadId).childByAutoId()
        newCommentRef.setValue(dictionary)
    }
    
    
    
    
    /************************************************************
     *
     *     Get List of Users the Current User is Following
     *
     ***********************************************************/
    
    func getFollowingList(userId: String, completion:@escaping (NSDictionary) -> ()){
        
        let currentUserId: String = Auth.auth().currentUser!.uid
        let followingRef = Database.database().reference().child("Users").child(currentUserId).child("following_list")
        
        followingRef.observeSingleEvent(of: .value, with: { snapshot in
            
            if let followingDict = snapshot.value as? NSDictionary{
        
                completion(followingDict)
            }else{
                completion([:])
            }
        })
    }
    
    
    
    
    /*****************************************
     *
     *  Get Current List of Followers
     *
     ****************************************/
    
    func getFollowedByList(userId: String, completion:@escaping (NSDictionary) -> ()){
        
        let followingRef = Database.database().reference().child("Users").child(userId).child("followed_by_list")
        
        followingRef.observeSingleEvent(of: .value, with: { snapshot in
            
            if let followingDict = snapshot.value as? NSDictionary{
                
                completion(followingDict)
                
            }else{
                
                // if no followers, pass back empty Dictionary
                completion([:])
            }
        })
    }
    
    
    
    /***********************************************************
     *
     *    Get Liked Posts Dictionary
     *  userId(uid) as parameter, 
     *  completion: yields a dictionary of post dictionaries
     **********************************************************/
    
    func getLikedPostsList(userId: String, completion:@escaping (NSDictionary) -> ()){
        
        let likedRef = Database.database().reference().child("Users").child(userId).child("liked_posts")
        
        likedRef.observeSingleEvent(of: .value, with: { snapshot in
            
            if let likedDict = snapshot.value as? NSDictionary{
                
                completion(likedDict)
                
            }else{
                
                // if no followers, pass back empty Dictionary
                completion([:])
            }
        })
    }
    
    
    
    
    /*****************************************
     *
     *    MARK: INCREMENT VIEWS METHODS
     *  -- IncrementViewsCount, adds 1 to post view count
     *  -- addToDidViewList, add postID to my view list
     
     *  IncrementViewsCount()
     *  --Will update and maintain view list 
     *  -- Won't increment if user has already viewed
     *************************************************/
    
    func incrementViewsCount(post:PostData, completion:@escaping(Int) -> ()){
        
        let uid = post.user.value(forKey: "uid") as! String
        let postId = post.postId
        let postExpireDate = post.expireTime!
        
        let viewsRef: DatabaseReference = Database.database().reference().child("Posts").child(uid).child("views")
        
        self.getViewedPostList(completion: { dict in
            
            if let _ = dict.value(forKey: postId){
                
                //do nothing -- completion with same number of views
                completion(post.views)
                
            }else{
                
                self.addToDidViewList(postId: postId, postExpireDate: postExpireDate)
                
                let views = post.views
                let tempNum = views + 1
                viewsRef.setValue(tempNum)
                completion(tempNum)
            }
        })
    }
    
    
    
    /*****************************************
     *  Add Current Post to Viewed Post List
     ****************************************/
    func addToDidViewList (postId: String, postExpireDate: String){
        
        self.getViewedPostList(completion: { dict in
            
            if let _ = dict.value(forKey: postId){
                
                //do nothing, postId is already in the list
            }else{
                let uid = Auth.auth().currentUser?.uid
                let viewsRef: DatabaseReference = Database.database().reference().child("Users").child(uid!).child("viewed_posts_list")
                let mutDict: NSMutableDictionary = dict.mutableCopy() as! NSMutableDictionary
                
                
                mutDict.setValue(postExpireDate, forKey: postId)
                viewsRef.setValue(mutDict)
            }
        })
    }
    
    
    
    /*****************************************
     *  Get Current Viewed Post List
     ****************************************/
    
    func getViewedPostList(completion:@escaping(NSDictionary) -> ()){
        
        let followingRef = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("viewed_posts_list")
        
        followingRef.observeSingleEvent(of: .value, with: { snapshot in
            
            if let viewedDict: NSMutableDictionary = snapshot.value as? NSMutableDictionary{
                
                let temp: NSDictionary = self.postsCleanup(dictionary: viewedDict)
                completion(temp)
                
            }else{
                
                // if no viewed posts, pass back empty Dictionary
                completion([:])
            }
        })
    }
    
    
    
    /*****************************************
     *  Get Current Inbox List
     ****************************************/
    func getInboxList(completion:@escaping(NSDictionary) -> ()){
        
        let inboxRef = Database.database().reference().child("Inbox").child((Auth.auth().currentUser?.uid)!)
        
        inboxRef.observeSingleEvent(of: .value, with: { snapshot in
            
            if let viewedDict: NSMutableDictionary = snapshot.value as? NSMutableDictionary{
                
                completion(viewedDict)
                
            }else{
                
                // if no viewed posts, pass back empty Dictionary
                completion([:])
            }
        })
    }
    
    /*****************************************
     *  Update Inbox List
     ****************************************/
    func updateInboxList(withUid: String, forUser:User, completion:@escaping(String) -> ()){
        
        let myInboxRef: DatabaseReference = Database.database().reference().child("Inbox").child(forUser.userID).child(withUid)
        let theirInboxRef: DatabaseReference = Database.database().reference().child("Inbox").child(withUid).child(forUser.userID)
        
        self.getInboxList { (list) in
            
            if(list.object(forKey: withUid) == nil){
                
                //get their userdata
                self.getUserDataFrom(uid: withUid as String, completion: { (user) in
                    
                    let now: TimeInterval = Date().timeIntervalSince1970
                    let objectId: String = String(format:"%.0f", now)
                    
                    let them: NSMutableDictionary = NSMutableDictionary()
                    them.setValue(user.name, forKey: "name")
                    them.setValue(user.profilePhoto, forKey: "photoUrl")
                    them.setValue(objectId, forKey: "objectId")
                    them.setValue(withUid, forKey: "uid")
                    
                    let me: NSMutableDictionary = NSMutableDictionary()
                    me.setValue(forUser.name, forKey: "name")
                    me.setValue(forUser.profilePhoto, forKey: "photoUrl")
                    me.setValue(objectId, forKey: "objectId")
                    me.setValue(forUser.userID, forKey: "uid")
                    
                    myInboxRef.setValue(them)
                    theirInboxRef.setValue(me)
                    
                    completion(objectId)
                
                })

            }
        }
    }
    
    /*********************************
     *
     *  URL PREVIEW SETUP
     *
     ********************************/
    
    func setURLView(urlString: String, completion:@escaping (UIImage, String) -> ()){
        
        OGDataProvider.shared.updateInterval = 10
        
        OGDataProvider.shared.fetchOGData(urlString: urlString, completion: { data, error in
            let urlData: OGData = data

            if error == nil{
                
                _ = OGImageProvider.shared.loadImage(urlString: urlData.imageUrl, completion: { image, error in
                    
                    if error == nil{
                        if (image != nil){
                            DispatchQueue.main.async {
                                var label: String = ""
                                
                                if (urlData.pageTitle != ""){
                                    
                                    label = urlData.pageTitle
                                }else if(urlData.siteName != ""){
                                    
                                    label = urlData.siteName
                                }else if (urlData.url != ""){
                                    
                                    label = urlData.url
                                }
                                print("Set Image Preview")
                                completion(image!, label)
                            }
                        }else{
                            print("Website Preview Cannot be retrieved")
                        }
                    }else{
                        print(error?.localizedDescription ?? "")
                    }
                })
            }else{
                print(error?.localizedDescription ?? "")
            }
        })
        
    }
    
    
    
    /*********************************
     *
     * LOCAL DATA DELETION METHODS
     *
     *********************************/
    
    func deleteLocalVideosCache(){
        
        let fm = FileManager()
        let error: NSErrorPointer = nil

        let dirPath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let tempDirPath = dirPath.appendingPathComponent("videos")
        
        
        var directoryContents: NSArray? = nil
        
        do{
            
            directoryContents = try fm.contentsOfDirectory(atPath: tempDirPath.absoluteString) as NSArray
        }catch{
            
            print("Could not retrieve directory: \(String(describing: error))")
        }
        
        
        if directoryContents != nil {
            
            for path in directoryContents! {
                
                let fullPath = dirPath.appendingPathComponent(path as! String)
                
                do{
                    try fm.removeItem(atPath: fullPath.absoluteString)
                    
                }catch{
                    
                    print("Could not delete file: \(String(describing: error))")
                }
            }
        } else {
            print("Could not retrieve directory: \(String(describing: error))")
        }
    }
    
    
    func deleteFileAt(path: String){
        
        let fileManager = FileManager()
        let path = self.documentsPathForFileName(name: path)
        
        var success: Bool = false
        do {
            try fileManager.removeItem(at: path)
            success = true
        } catch _ {
            success = false
        }
        if (!success) {
            
            print("delete failed")
        }
    }
    
    
    
    /*************************************
     *
     * LOCAL IMAGE/AUDIO/VIDEO SAVING
     *
     ************************************/
    
    
    func saveVideoToNewPath(path: String, newName: String){
        
        let data: Data = FileManager.default.contents(atPath: path)!
        
        let localUrl: URL = self.documentsPathForFileName(name: newName)
        
        do {
            try data.write(to: localUrl, options: .atomic)
            print(localUrl)
            
        } catch {
            print(error)
        }
    }
    
    func saveVideoForPath(videoData: Data, name: String){
        
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(name).mp4")
        
        do {
            try videoData.write(to: fileURL, options: .atomic)
        } catch {
            print(error)
        }
    }
    
    
    func saveAudioForPath(audioData: Data, name: String){
        
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(name).m4a")
        
        do {
            try audioData.write(to: fileURL, options: .atomic)
        } catch {
            print(error)
        }
    }
    

    func saveImageForPath(imageData: Data, name: String){
        
        
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(name).jpg")
        
        do {
            try imageData.write(to: fileURL, options: .atomic)
        } catch {
            print(error)
        }
        
        UserDefaults.standard.set(fileURL, forKey: "\(name)")
        UserDefaults.standard.synchronize()
    }
    

    
    
    
    /*************************************
     *
     * LOCAL IMAGE/AUDIO/VIDEO RETRIEVAL
     *
     ************************************/
    
    

    func documentsPathForFileName(name: String) -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDir = paths[0] as URL;
        
        let path = docsDir.appendingPathComponent("\(name)")
        
        return path
    }
    
    
    func getImageForPath(path: String) -> UIImage{
        
        let imagePath = UserDefaults.standard.object(forKey: "\(path)") as! String?
        
        if let _ = imagePath {
            
            let fullPath = self.documentsPathForFileName(name: "\(path).jpg")
            
            let imageData = NSData(contentsOf: fullPath)
            let image = UIImage(data: imageData! as Data)
            return image!
        }
        
        return defaultsUserPhoto
    }
    
    
    func getAudioForPath(path: String) -> AVAsset{
        
        let audioPath = UserDefaults.standard.object(forKey: "\(path)") as! String?
        
        if let _ = audioPath {
            
            let fullPath = self.documentsPathForFileName(name: "\(path).m4a")
            
            let audio = AVAsset(url: fullPath)
            return audio
        }
        
        return AVAsset()
    }
    
    
    func getVideoForPath(path: String) -> AVAsset{
        
        let videoPath = UserDefaults.standard.object(forKey: "\(path)") as! String?
        
        if let _ = videoPath {
            
            let fullPath = self.documentsPathForFileName(name: "\(path).mp4")
            
            let video = AVAsset(url: fullPath)
            return video
        }
        
        return AVAsset()
    }
    
    
    
    
    /************************************************
     *
     *          SAVED POST DATA SAVE/RETRIEVAL
     *
     ************************************************/
    
    //parameters: Category, data, primary post boolean, completion: String
    func savePostData(category: Category, data: AnyObject, primary: Bool, completion:@escaping (String) -> ()){
        var dataKey: String = ""
        let assetIdKey: String = "localVideoAssetId"
        
//        if primary{
            dataKey = "savedPostData"
//        }
        
//        else{
//            dataKey = "secondarySavedPostData"
//        }
        
        switch category{
            
        case .Photo:
            
            let iData: Data = UIImageJPEGRepresentation(data as! UIImage, 0.8)!
            let dataPath: URL = documentsPathForFileName(name: String(format:"%@.jpg",dataKey))
            saveImageForPath(imageData: iData, name: dataKey)
            
            completion(dataPath.absoluteString)
            
        case .Video:
            let asset: PHAsset = data as! PHAsset
            let identifier: String = asset.localIdentifier
            
            UserDefaults.standard.set(identifier, forKey: assetIdKey)
            UserDefaults.standard.synchronize()
            completion(identifier)

        case .Recording:
            
            saveAudioForPath(audioData: data as! Data, name: dataKey)
            let dataPath = documentsPathForFileName(name: String(format:"%@.m4a",dataKey))
            completion(dataPath.absoluteString)
            
        case .Text:
            let iData: Data = UIImageJPEGRepresentation(data as! UIImage, 0.8)!
            let dataPath: URL = documentsPathForFileName(name: String(format:"%@.jpg",dataKey))
            saveImageForPath(imageData: iData, name:dataKey)
            
            completion(dataPath.absoluteString)
        case .Link:
            //nothing, just useText from PostData
            print("Link, no saved Data")
            completion(data as! String)
        case .Music:
            print("Music, no saved Data")
            
            completion("")
            
        case .None:
            print("None, no saved Data")
            completion("")
        }
    }
    
    
    
    
    //retrieves saved post data in the format required by addPostViewController
    func getSavedPostData(category: Category, primary: Bool) -> AnyObject{
        var object: AnyObject? = nil
        
        var dataKey: String = ""
        let assetIdKey: String = "localVideoAssetId"
        let postKey: String = "savedPost"
        
//        if primary{
            dataKey = "savedPostData"
//        }else{
//            dataKey = "secondarySavedPostData"
//        }
        
        switch category{
        case .Photo:
            object = getImageForPath(path: dataKey)
            
        case .Video:
            
            let id: String = UserDefaults.standard.string(forKey: assetIdKey)!
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
            object = assets[0] as PHAsset
        
        case .Recording:
            
            object = getAudioForPath(path: dataKey)
            
        case .Text:

            object = getImageForPath(path: dataKey)
            
        case .Link:

            let postDict: NSDictionary = UserDefaults.standard.dictionary(forKey: postKey)! as NSDictionary
            let text: String = postDict.value(forKey: "data") as! String
            
            object = text as AnyObject
        case .Music:
            print("Music, no saved Data")
            
        case .None:
            print("None, no saved Data")
        }
        return object!
    }
    
    
    //Check local doc paths if data for a key exists
    func localPhotoExists(atPath: String) -> Bool{
        let path = UserDefaults.standard.object(forKey: atPath) as! String?
        
        if let _ = path{
            return true
        }else{
            return false
        }
    }
    
    
    
    //On new install called when user has existing data in backend and profile pictures need to be saved locally
    func syncProfilePhotosToDevice(user: User, path: String, completion:@escaping (UIImage) -> ()){
        
        let imageCache: ImageCache = ImageCache()
        var imagePathString: String = ""
        
        if path == "coverPhoto"{
            
            imagePathString = user.coverPhoto
            
        }else if (path == "profilePhoto"){
            
            imagePathString = user.profilePhoto
        }
        
        if !(localPhotoExists(atPath: path)){
            //do nothing

            if (imagePathString != ""){
                
                imageCache.getImage(urlString: imagePathString, completion: { image in
                    
                    let data: Data = UIImageJPEGRepresentation(image, 0.8)! as Data
                    self.saveImageForPath(imageData: data, name: path)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        completion(image)
                    })
                })
            }
        }
    }
    
    
    
    
    /*********************************************
     *
     *  CLEAR LOCAL SAVED ITEMS IN DOMAIN PATH
     *
     *********************************************/
    
    func deleteLocalDocuments(){
        
        let fileManager = FileManager.default
        let tempFolderPath = NSTemporaryDirectory()
        
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: tempFolderPath)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: NSTemporaryDirectory() + filePath)
            }
        } catch let error as NSError {
            print("Could not clear temp folder: \(error.debugDescription)")
        }
    }
    
    
    
    //returns a clear UIImage
    var clearImage : UIImage {
        
        let size = CGSize(width:50, height:50)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let rectanglePath = UIBezierPath(rect: CGRect(x:0, y:0, width:size.width, height:size.height))
        let color = UIColor.clear
        color.setFill()
        rectanglePath.fill()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    
    //return default photo
    var defaultsUserPhoto : UIImage {
        return UIImage(named: "defaultUser")!
    }
    
    
    /******************************************************************************
     *
     *          GET USER DATA OBJECT USING FIREBASE UID
     *          - uid parameter: String
     *          - completion returns a User object or empty User if empty
     *******************************************************************************/
    
    func getUserDataFrom(uid: String, completion:@escaping (User) -> ()){
        
        let userRef: DatabaseReference = Database.database().reference().child("Users").child(uid)
        
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let userDict: NSMutableDictionary = snapshot.value as? NSMutableDictionary{
                
                completion(self.setupUserData(data: userDict, uid: uid))
            }else{
                
                completion(User.init())
            }
        })
    }
    
    
    /*******************************************************************************
     *
     *  SETUP USER DATA METHOD
     *
     * - parameters: NSMutableDictionary of user attributes from Firebase, UID: String
     * - Returns a USER Object
     *
     ******************************************************************************/
    
    
    func setupUserData(data: NSMutableDictionary, uid: String) -> User{
        
        let user:User = User()
        
        user.userID = uid
        
        if let username: String = data.value(forKey: "username") as? String{
            
            if username == ""{
                
            }else{
                user.username = username
            }
        }
        
        if let followedByCount: Int = data.value(forKey: "followed_by_count") as? Int{
            user.followedByCount = followedByCount
        }
        if let followingCount: Int = data.value(forKey: "following_count") as? Int{
            user.followingCount = followingCount
        }
        
        if let bio: String = data.value(forKey: "bio") as? String{
            user.bio = bio
        }
        
        if let name: String = data.value(forKey: "name") as? String{
            user.name = name
        }
        
        if let isPrivate: Bool = data.value(forKey: "isPrivate") as? Bool{
            user.isPrivate = isPrivate
        }
        
        if let profilePhotoURLString: String = data.value(forKey: "profilePhoto") as? String{
            user.profilePhoto = profilePhotoURLString
        }
        
        if let coverPhotoURLString: String = data.value(forKey: "coverPhoto") as? String{
            user.coverPhoto = coverPhotoURLString
        }
        
        //GET FOLLOWING LIST CONSTANT
        if let temp: NSDictionary = data.value(forKey: "following_list") as? NSDictionary{
            user.followingDict = temp as! NSMutableDictionary
        }else{
            user.followingDict = [:]
        }
        
        return user
        
    }
    
    
    /*******************************************************************************
     *
     *  GET URL FOR PHASSET =- VIDEO ONLY
     *
     * - parameters: PHASSET, NAME, completion
     * -completion returns a URL
     *
     ******************************************************************************/
    

    func getURLForPHAsset(videoAsset: PHAsset, name: String, completion:@escaping (URL) -> ()){
        
        let dataManager = DataManager()
        
        PHImageManager().requestAVAsset(forVideo: videoAsset, options: nil) { (asset, audioMix, args) in
            
            if let vAsset: AVURLAsset = asset as? AVURLAsset{

                let fileManager = FileManager()
                let path = dataManager.documentsPathForFileName(name: name)
                
                var success: Bool = false
                do {
                    try fileManager.removeItem(at: path)
                    success = true
                } catch _ {
                    success = false
                }
                if (!success) {
                    
                    print("delete failed")
                    
                }
                let exporter: AVAssetExportSession = AVAssetExportSession.init(asset:vAsset, presetName:AVAssetExportPresetHighestQuality)!;
                exporter.outputURL = path;
                exporter.outputFileType = AVFileTypeMPEG4;
                exporter.shouldOptimizeForNetworkUse = true;
                
                exporter.exportAsynchronously(completionHandler: {
                    
                    DispatchQueue.main.async {
                        
                        if (exporter.status == AVAssetExportSessionStatus.completed) {
                            
                            let URL: URL = exporter.outputURL!;
                            completion(URL)
                            
                        }
                    }
                })
                

            //Handle Slow-Mo Video
            }else if let vAsset: AVComposition = asset as? AVComposition{
                
                //Output URL
                let fileManager = FileManager()
                let path = dataManager.documentsPathForFileName(name: name)
                
                var success: Bool = false
                do {
                    try fileManager.removeItem(at: path)
                    success = true
                } catch _ {
                    success = false
                }
                if (!success) {
                    
                    print("delete failed")
                    
                }
                
                let exporter: AVAssetExportSession = AVAssetExportSession.init(asset:vAsset, presetName:AVAssetExportPresetHighestQuality)!;
                exporter.outputURL = path;
                exporter.outputFileType = AVFileTypeMPEG4;
                exporter.shouldOptimizeForNetworkUse = true;
                
                exporter.exportAsynchronously(completionHandler: {
                    
                    DispatchQueue.main.async {
                        
                        if (exporter.status == .completed) {
                            
                            let URL: URL = exporter.outputURL!;
                            completion(URL)
                        }
                    }
                })
            }
        }
    }
    
    
    
    
    /****************************************
     *
     *         BLOCK USERS METHODS
     *
     ****************************************/
    
    
    func blockUser(postData: PostData){
        
        let toBlockData: NSDictionary = postData.user
        let toBlockUser: String = toBlockData.value(forKey: "uid") as! String
        
        let cuid: String = (Auth.auth().currentUser?.uid)!
        
        let blockRef: DatabaseReference = Database.database().reference().child("BlockedUsers").child(cuid).child(toBlockUser)
        
        blockRef.setValue(toBlockData)
    }
    
    
    
    
    func getBlockedUsers(completion:@escaping (NSDictionary) -> ()){
        
        let cuid: String = (Auth.auth().currentUser?.uid)!
        
        let blockRef: DatabaseReference = Database.database().reference().child("BlockedUsers").child(cuid)
        
        blockRef.observeSingleEvent(of: .value, with: { snapshot in
            
            if let blockedDict: NSDictionary = snapshot.value as? NSDictionary{
                
                completion(blockedDict)
            }else{
                
                completion([:])
            }
        })
    }
    
    
    
    
    /****************************************************
     *
     *  FOLLOW REQUESTS METHOD
     * - completion -> NSARRAY of user uid's
     *
     ****************************************************/
    
    
    func getRequests(completion:@escaping (NSArray) -> ()){
        
        let uid: String = (Auth.auth().currentUser?.uid)!
        let requestRef: DatabaseReference = Database.database().reference().child("Users").child(uid).child("followed_by_list")
        let requestArray: NSMutableArray = []
        
        requestRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let users: NSDictionary = snapshot.value as? NSDictionary{
                
                for key in users.allKeys{
                    
                    let requested: Int = users.value(forKey: key as! String) as! Int
                    
                    if requested == 1{
                        
                        requestArray.add(key as! String)
                    }
                }
                
                completion(requestArray)
                
            }else{
                
                completion(requestArray)
            }
        })
    }
    
    
    
    /****************************************************
     *
     *  MESSAGING METHODs
     *
     ****************************************************/
    
    func getMessages(completion:@escaping (NSDictionary) -> ()){
        
        let uid: String = (Auth.auth().currentUser?.uid)!
        let inboxRef: DatabaseReference = Database.database().reference().child("Messages").child(uid)
        
        inboxRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let users: NSDictionary = snapshot.value as? NSDictionary{
                
                for key in users.allKeys{
                    
                    let messagesRef: DatabaseReference = inboxRef.child(key as! String)
                    
                    messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        
                        if let _: NSDictionary = snapshot.value as? NSDictionary{
                            //will return a dictionary of dictionaries of messages with the user UID as the key
                            // UID key contains dictionary with keys: message, timestamp
                            
                        }else{
                            
                            
                            
                        }
                    })
                }
                
            }else{
                
                
            }
        })
    }
    
    
    
    
    //get latest, used for retreiving the latest for the inbox view
    //parameter: objectId(convoId)
    // completion, message text as String
    
    func getLatestMessageText(objectId: String, completion:@escaping (String) -> ()){
        
        let messageRef: DatabaseReference = Database.database().reference().child("Messages").child(objectId)
        
        messageRef.queryOrderedByKey().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let users: NSDictionary = snapshot.value as? NSDictionary{
                
                for (key, _) in users{
                    
                    let dict: NSDictionary = users.value(forKey: key as! String) as! NSDictionary
                    completion(dict.value(forKey: "body") as! String)
                }
            
            }else{
                
                completion("")
            }
        })
    }

    
  
    
/****************************************************
 *
 *  NON - FIREBASE
 *
 ****************************************************/
    
    func getUIColorForCategory(category: Category) -> UIColor{
        let colors: Colors = Colors()
        var color: UIColor = UIColor.black
        
        switch category {
            
        case .Photo:
            
            color = colors.getMenuColor()
            
        case .Video:
            
            color = colors.getPurpleColor()
            
        case .Text:

            color = UIColor.black
            
        case .Recording:

            color = colors.getAudioColor()
            
        case .Music:
            
             color = colors.getMusicColor()
            
        case .Link:

            color = UIColor.black
            
        default:
            print("")
        }
        
        return color
    }
    
    
    //pass full name as parameter to get first name
    func getFirstName(name: String) -> String{
        var names: [String] = []
        
        names = name.components(separatedBy: " ") as [String]
        return names[0]
        
    }
    
    //pass full name as parameter to get last name
    func getLastName(name: String) -> String{
        var names: [String] = []
        names = name.components(separatedBy: " ")
        
        let count: Int = names.count
        return names[count - 1]
        
    }

    
    //get now in millis, returns double
    func nowInMillis() -> Double{
        
        let date: Date = Date.init()
        let millis = date.timeIntervalSince1970
        
        return millis
    }
    
    
    //gets one day from now in millis, returns double
    func oneDayFromNow() -> Double {
    
        let date: Date = Date.init()
        let expireTime = date.addingTimeInterval(24.0 * 60.0 * 60.0)
        let millis = expireTime.timeIntervalSince1970
    
        return millis
    }
    
    
    //Translates a time in milliseconds as a string to an easy readable time remaining format
    func getTimeString(expireTime: String) -> String{
        
        //Calculate and Set Time Remaining Lbl
        let timeRemaining: Int = Int(Double(expireTime)! - Date().millisecondsSince1970)
        var timeString: String = ""
        var timelbl: String = ""
        var finalString: String = ""
        
        if(timeRemaining / (60*60*1000) >= 2){
            timeString = String(format: "%d", timeRemaining / (60*60*1000))
            timelbl = "hours"
            finalString = String(format:"%@ %@ left", timeString, timelbl)
            
        }else if(timeRemaining / (60*60*1000) >= 1){
            
            timeString = "1"
            timelbl = "hour"
            finalString = String(format:"%@ %@ left", timeString, timelbl)
            
        }
        else if(((timeRemaining / (1000*60)) % 60) > 0){
            
            timeString = String(format:"%d", ((timeRemaining / (1000*60)) % 60))
            timelbl = "mins"
            finalString = String(format:"%@ %@ left", timeString, timelbl)
            
        }
        else{
            
            finalString = "expired"
        }

        return finalString
    }
    
    
    
    
    func export(_ assetURL: URL, completionHandler: @escaping (_ fileURL: URL?, _ error: Error?) -> ()) {
        
        let asset = AVURLAsset(url: assetURL)
        
        
        if asset.isExportable{
            print("exportable")
        }else{
            print("Not exportable")
            completionHandler(nil, nil)
        }
        
        let fileManager = FileManager()
        let path = self.documentsPathForFileName(name: "exportSong.m4a")
        
        var success: Bool = false
        do {
            try fileManager.removeItem(at: path)
            success = true
        } catch _ {
            success = false
        }
        if (!success) {
            
            print("delete failed")
        }
        
        let exporter: AVAssetExportSession = AVAssetExportSession.init(asset:asset, presetName:AVAssetExportPresetAppleM4A)!;
        exporter.outputURL = path;
        exporter.outputFileType = AVFileTypeAppleM4A;
        exporter.shouldOptimizeForNetworkUse = true;
        
        exporter.exportAsynchronously(completionHandler: {
            
            DispatchQueue.main.async {
                
                if (exporter.status == AVAssetExportSessionStatus.completed) {
                    
                    let URL: URL = exporter.outputURL!;
                    completionHandler(URL, nil)
                    
                }else{
                    completionHandler(nil, exporter.error)
                }
            }
        })
    }
    
    
    
    func extrapolate(songData:String) -> Song{
        
        let strings = songData.components(separatedBy: ":")
        let title = strings[0]
        let artist = strings[1]
        let album = strings[2]
        let source = strings[3]
        
        var songInfo = Song.init(title: "", album: "", artist: "", source: "")
        songInfo.title = title
        songInfo.artist = artist
        songInfo.album = album
        songInfo.source = source
        
        return songInfo
    }

    
}


extension TimeInterval {
    var minuteSecondMS: String {
        return String(format:"%d:%02d.%03d", minute, second, millisecond)
    }
    var minuteSecond: String {
        return String(format:"%d:%02d", minute, second)
    }
    var minute: Int {
        return Int((self/60).truncatingRemainder(dividingBy: 60))
    }
    var second: Int {
        return Int(truncatingRemainder(dividingBy: 60))
    }
    var millisecond: Int {
        return Int((self*1000).truncatingRemainder(dividingBy: 1000))
    }
}

extension Int {
    var msToSeconds: Double {
        return Double(self) / 1000
    }
}

//UIImage Extension to Crop the image, not used currently
extension UIImage {
    
    func crop(to:CGSize) -> UIImage {
        
        guard let cgimage = self.cgImage else { return self }
        let contextImage: UIImage = UIImage(cgImage: cgimage)
        let contextSize: CGSize = contextImage.size
        
        //Set to square
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        let cropAspect: CGFloat = to.width / to.height
        
        var cropWidth: CGFloat = to.width
        var cropHeight: CGFloat = to.height
        
        if to.width > to.height { //Landscape
            cropWidth = contextSize.width
            cropHeight = contextSize.width / cropAspect
            posY = (contextSize.height - cropHeight) / 2
        } else if to.width < to.height { //Portrait
            cropHeight = contextSize.height
            cropWidth = contextSize.height * cropAspect
            posX = (contextSize.width - cropWidth) / 2
        } else { //Square
            if contextSize.width >= contextSize.height { //Square on landscape (or square)
                cropHeight = contextSize.height
                cropWidth = contextSize.height * cropAspect
                posX = (contextSize.width - cropWidth) / 2
            }else{ //Square on portrait
                cropWidth = contextSize.width
                cropHeight = contextSize.width / cropAspect
                posY = (contextSize.height - cropHeight) / 2
            }
        }
        
        let rect: CGRect = CGRect(x:posX, y:posY, width:cropWidth, height:cropHeight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let cropped: UIImage = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        
        UIGraphicsBeginImageContextWithOptions(to, true, self.scale)
        cropped.draw(in: CGRect(x:0, y:0, width:to.width, height:to.height))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resized!
    }
    

    convenience init(view: UIView) {
            
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: (image?.cgImage!)!)
        
    }
}
