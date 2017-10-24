//
//  UserData.swift
//  hrglass
//
//  Created by Justin Hershey on 5/12/17.
//
//

import Foundation
import UIKit


//User Data Object
class User
{
    
    var name: String!
    var isPrivate: Bool
    var userID: String
//    var followedByCount: Int
    var bio: String
//    var followingCount: Int
    var username: String!
    var profilePhoto: String!
    var coverPhoto: String!

    //followers dictionary's
//    var followedByDict: NSMutableDictionary!
//    var followingDict: NSMutableDictionary!
    
    
    init(withUserID:String, username: String, bio:String, profilePhoto:String, coverPhoto:String, name: String, isPrivate: Bool){
        
        self.userID = withUserID
//        self.followedByCount = followedByCount
        self.bio = bio
//        self.followingCount = followingCount
        self.profilePhoto = profilePhoto
        self.coverPhoto = coverPhoto
        self.name = name
        self.isPrivate = isPrivate
        self.username = username
        
        //empty for now
//        followedByDict = ["":""]
//        followingDict = ["":""]
        
        
    }
    
    
    //initialize
    convenience init(){
        
        self.init(withUserID: "", username: "", bio: "", profilePhoto: "", coverPhoto: "", name: "", isPrivate: false)
        
    }
    
}
