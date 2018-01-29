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
    var bio: String
    var username: String!
    var profilePhoto: String!
    var coverPhoto: String!
    

    init(withUserID:String, username: String, bio:String, profilePhoto:String, coverPhoto:String, name: String, isPrivate: Bool){
        
        self.userID = withUserID
        self.bio = bio
        self.profilePhoto = profilePhoto
        self.coverPhoto = coverPhoto
        self.name = name
        self.isPrivate = isPrivate
        self.username = username
    }
    
    
    
    //initialize
    convenience init(){
        
        self.init(withUserID: "", username: "", bio: "", profilePhoto: "", coverPhoto: "", name: "", isPrivate: false)
    }
    
    
    
    func dictionaryToUser(dictionary: NSDictionary){
        
        self.name = dictionary.value(forKey: "name") as! String
        self.isPrivate = (dictionary.value(forKey: "isPrivate") != nil)
        self.bio = dictionary.value(forKey: "email") as! String
        self.username = dictionary.value(forKey: "username") as! String
        self.profilePhoto = dictionary.value(forKey: "profilePhoto") as! String
        self.coverPhoto = dictionary.value(forKey: "coverPhoto") as! String
        
    }
    
    
    
    
}
