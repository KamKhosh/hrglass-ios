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
}
