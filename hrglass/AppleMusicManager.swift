//
//  MusicManager.swift
//  hrglass
//
//  Created by Justin Hershey on 10/16/17.
//
//

import UIKit
import StoreKit
import MediaPlayer




public enum SearchError: Error {
    case unknown
    case invalidSearchTerm
    case invalidURL
    case invalidServerResponse
    case serverError(Int)
    case invalidJSON
}




//ENUM for song result.
public enum SongResult<T, U> {
    case success(T)
    case failure(U)
    
    public var value: T? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
    
    public var error: U? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}


/// Each network request returns a Result which contains either a decoded json or an `SearchError`.
public typealias NetworkResponse = SongResult<Any, SearchError>


class AppleMusicManager {

    var storefrontId: String = ""

    // Request permission from the user to access the Apple Music library
    func appleMusicRequestPermission() {
        
        switch SKCloudServiceController.authorizationStatus() {
            
        case .authorized:
            
            print("The user's already authorized - we don't need to do anything more here, so we'll exit early.")
            return
            
        case .denied:
            
            print("The user has selected 'Don't Allow' in the past - so we're going to show them a different dialog to push them through to their Settings page and change their mind, and exit the function early.")
            
            // Show an alert to guide users into the Settings
            
            return
            
        case .notDetermined:
            
            print("The user hasn't decided yet - so we'll break out of the switch and ask them.")
            break
            
        case .restricted:
            
            print("User may be restricted; for example, if the device is in Education mode, it limits external Apple Music usage. This is similar behaviour to Denied.")
            
            
            
            return
            
        }
        
        SKCloudServiceController.requestAuthorization { (status:SKCloudServiceAuthorizationStatus) in
            
            switch status {
                
            case .authorized:
                
                print("All good - the user tapped 'OK', so you're clear to move forward and start playing.")
                
            case .denied:
                
                print("The user tapped 'Don't allow'. Read on about that below...")
                
            case .notDetermined:
                
                print("The user hasn't decided or it's not clear whether they've confirmed or denied.")
                
            default: break
                
            }
            
        }
        
    }
    
    
    
    func showWarningDialouge(reason: String){
        
        
        
        
    }
    
    
    //Retrieve the trimmed user's storefront id based on the current user region
    func appleMusicFetchStorefrontRegion(completion: @escaping (String) -> ()){
        
        let serviceController = SKCloudServiceController()
        serviceController.requestStorefrontIdentifier { (storefrontId:String?, err:Error?) in
            
            guard err == nil else {
                
                print("An error occured. Handle it here.")
                return
            }
            
            guard let storefrontId = storefrontId, storefrontId.characters.count >= 6 else {
                
                print("Handle the error - the callback didn't contain a valid storefrontID.")
                return
            }
            
            //trim string to get storefrontID
            let startIndex = storefrontId.startIndex
            let stopIndex = storefrontId.index(startIndex, offsetBy: 5)
            let indexRange = Range(uncheckedBounds: (startIndex, stopIndex))
            let trimmedId = storefrontId.substring(with: indexRange) as String
            print("Success! The user's storefront ID is: \(trimmedId)")

            let defaults: UserDefaults = UserDefaults.standard
            defaults.set(trimmedId, forKey: "appleStorefrontId")
            defaults.synchronize()
            
            
            completion(trimmedId)
        }
        
    }
    
    //builds a download task using the URL passed that contains the desired data
    func buildTask(withURL url: URL, completion: @escaping (NetworkResponse) -> Void) -> URLSessionDataTask {
        
        let session: URLSession = URLSession.shared
        
        return session.dataTask(with: url) { data, response, error in
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidServerResponse))
                }
                return
            }
            
            // check for successful status code
            guard 200...299 ~= httpResponse.statusCode else {
                DispatchQueue.main.async {
                    completion(.failure(.serverError(httpResponse.statusCode)))
                }
                return
            }
            
            // try to decode the response json
            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidJSON))
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(json))
            }
        }
    }
    
    
    
    //creates an itunes query based on the song data the user has selected
    func createItunesQuery(songData: String, completion: @escaping (_ storeId: String) -> ()){
        //song data is in format title:artist:album so we just separate by : and use those terms in our itunes search query
        
        var artist: String = ""
        var title: String = ""
        var album: String = ""
        var storefrontId: String = ""

        let strings = songData.components(separatedBy: ":")
        
        title = strings[0]
        artist = strings[1]
        album = strings[2]

        //joining search terms
        if(title != ""){
            title = title.replacingOccurrences(of: " ", with: "+")
        }
        if(artist != ""){
            artist = artist.replacingOccurrences(of: " ", with: "+")
            artist = "+" + artist
        }
        if(album != ""){
            album = album.replacingOccurrences(of: " ", with: "+")
            album = "+" + album
        }

        let termString: String = "term=" + title + artist + album
        
        
        
        //if the storefront id is saved locally use it
        if let id: String = UserDefaults.standard.value(forKey: "appleStorefrontId") as? String{
            storefrontId = id
        }
        
        
        //if no local storefront id, retrieve and use it
        if (storefrontId != ""){
            
            let queryString: String = String(format: "https://itunes.apple.com/search?%@&entity=song&limit=1&s=%@", termString, storefrontId)
            completion(queryString)
            
        }else{
            
            appleMusicFetchStorefrontRegion(completion: { (storeId) in
                let queryString: String = String(format: "https://itunes.apple.com/search?%@&entity=song&limit=1&s=%@", termString, storeId)
                completion(queryString)
            })
        }

    }
    
    
    
    
    
}
