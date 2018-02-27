//
//  PostData.swift
//  hrglass
//
//  Created by Justin Hershey on 4/27/17.
//
//  ENUM to define a post category Video, Photo, link...etc
// 
// Inititalized with an image(or video, link, etc based on category), id, likes, views, category, post label, user who posted

import Foundation
import UIKit
import URLEmbeddedView





//Primary Post Category ENUM
enum Category: String{
    
    case Video = "Video"
    case Photo = "Photo"
    case Link = "Link"
    case Music = "Music"
    case Text = "Text"
    case Recording = "Recording"
    case None = "None"
    case Youtube = "Youtube"

}


//Post Mood ENUM
enum Mood: String {
    
    case Funny = "😂"
    case Fire = "🔥"
    case Love = "😍"
    case Sad = "😔"
    case Shocked = "😱"
    case Afraid = "😨"
    case Cool = "😎"
    case Bravo = "👏"
    case Silly = "😋"
    case Angry = "😡"
    case Ok = "👌"
    case Blessed = "🙏"
    case None = "🚫"

}




//Post Data, data object

class PostData: NSObject{
    
    let postId: String
    var likes: Int
    var category: Category
    var views: Int
    let data: String
    let user: NSDictionary!
    let mood: String
    var usersWhoLiked: NSDictionary!
    var creationDate: String!
    var expireTime: String!
//    var secondaryPost: NSDictionary!
    var usersWhoViewed: NSDictionary!
    var commentThread: String!
    var songString: String!
    var nsfw: String!
    
    

    init(withDataString:String, postId:String, likes:Int, views:Int, category:Category, mood: String, user: NSDictionary, usersWhoLiked:NSDictionary, creationDate: String!, expireTime: String!, commentThread: String!, songString: String!, usersWhoViewed: NSDictionary!, nsfw:String!){
        
        self.postId = postId
        self.likes = likes
        self.views = views
        self.category = category
        self.data = withDataString
        self.user = user
        self.mood = mood
        self.usersWhoLiked = usersWhoLiked
        self.creationDate = creationDate
        self.expireTime = expireTime
//        self.secondaryPost = nil
        self.usersWhoViewed = usersWhoViewed
        self.commentThread = commentThread
        self.songString = songString
        self.nsfw = nsfw
        
    }
    
    
    
    
    func postDataAsDictionary() -> NSDictionary{
        let postDictionary: NSDictionary = ["postID":self.postId,"likes":self.likes,"views":self.views,"category":self.category.rawValue,"data":self.data,"user":self.user,"mood":self.mood,"users_who_liked":self.usersWhoLiked,"users_who_viewed":self.usersWhoViewed,"creation_date":self.creationDate,"expire_time":self.expireTime,"songString":self.songString,"nsfw":self.nsfw]
        
        
        return postDictionary
    }
    
    
//    
//    
//    init(withDataString:String, postId:String, likes:Int, views:Int, category:Category, mood: String, user: NSDictionary, usersWhoLiked:NSDictionary, creationDate: String!, expireTime: String!, postShape: String!, secondaryPost: NSDictionary!, commentThread: String){
//        
//        self.postId = postId
//        self.likes = likes
//        self.views = views
//        self.category = category
//        self.data = withDataString
//        self.user = user
//        self.mood = mood
//        self.usersWhoLiked = usersWhoLiked
//        self.creationDate = creationDate
//        self.expireTime = expireTime
//        self.postShape = postShape
//        self.secondaryPost = secondaryPost
//        self.commentThread = commentThread
//        
//    }
    
    
//    init(withDataString:String, postId:String, likes:Int, views:Int, category:Category, mood: String, user: NSDictionary, usersWhoLiked:NSDictionary, creationDate: String!, expireTime: String!, postShape: String!, secondaryPost: NSDictionary!, commentThread: String, musicData: NSDictionary){
//    
//            self.postId = postId
//            self.likes = likes
//            self.views = views
//            self.category = category
//            self.data = withDataString
//            self.user = user
//            self.mood = mood
//            self.usersWhoLiked = usersWhoLiked
//            self.creationDate = creationDate
//            self.expireTime = expireTime
//            self.postShape = postShape
////            self.secondaryPost = secondaryPost
//            self.commentThread = commentThread
//            self.musicData = musicData
//            
//        }
    
    
}



//EMOJI STRING TO IMAGE
extension String {
    
    func image() -> UIImage {
        let size = CGSize(width: 30, height: 35)
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        UIColor.clear.set()
        let rect = CGRect(origin: CGPoint.zero, size: size)
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        (self as NSString).draw(in: rect, withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 30)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
