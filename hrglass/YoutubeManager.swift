//
//  YoutubeManager.swift
//  hrglass
//
//  Created by Justin Hershey on 2/23/18.
//

import UIKit



struct YoutubeVideoData{
    
    var title: String
    var id: String
    var channel: String
    var thumbnail: String
    
    init(){
        
        self.title = ""
        self.id = ""
        self.channel = ""
        self.thumbnail = ""
    }
    
    init(title: String, id: String, channel: String, thumbnail: String){
        
        self.title = title
        self.id = id
        self.channel = channel
        self.thumbnail = thumbnail
    }
    
}



class YoutubeManager: NSObject {
    
    
    var apiKey = "AIzaSyBWlPFL78GP6rOyXo3Gkzq-_GYiODbyzew"
    
    var desiredChannelsArray = ["Apple", "Google", "Microsoft"]
    
    var channelIndex = 0
    
    var videosArray: Array<YoutubeVideoData> = []
    
    var videoData: YoutubeVideoData = YoutubeVideoData.init()
    
    
    
    func performGetRequest(targetURL: URL!, completion: @escaping (_ data: Data?, _ HTTPStatusCode: Int, _ error: Error?) -> Void) {
        
        
        var request = URLRequest(url: targetURL)
        request.httpMethod = "GET"
        
        let sessionConfiguration = URLSessionConfiguration.default
        
        let session = URLSession(configuration: sessionConfiguration)
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data!, response: URLResponse!, error: Error!) -> Void in
            
            DispatchQueue.main.async {
                completion(data, (response as! HTTPURLResponse).statusCode, error)
            }
        })
        
        task.resume()
    }
    
    
    
    
    func youtubeVideoSearch(text: String, completion: @escaping (_ success: Bool, _ data: Array<YoutubeVideoData>) -> Void) {
        
    
        // Specify the search type (channel, video).
        let type = "video"
        
        if videosArray.count > 0{
            videosArray.removeAll()
        }
        
        let results = 8
        
        
        // Form the request URL string.
        var urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(text)&type=\(type)&key=\(apiKey)&chart=mostPopular&maxResults=\(results)"
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        
        // Create a NSURL object based on the above string.
        let targetURL = URL(string: urlString)
        
        performGetRequest(targetURL: targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
            
            if HTTPStatusCode == 200 && error == nil {
                // Convert the JSON data to a dictionary.
                do{
                    let resultsDict = try JSONSerialization.jsonObject(with: data!, options:[]) as! [String: Any]
                    let items: Array<Dictionary<String, Any>> = resultsDict["items"] as! Array<Dictionary<String, Any>>

                     for item in items {
                        
                        // Get the snippet dictionary that contains the desired data.
                        let snippetDict = item["snippet"] as! Dictionary<String, Any>
                        print(snippetDict)
                        
                        // Create a new videoData object to store only the values we care about.

                        let videoDetails: YoutubeVideoData = YoutubeVideoData.init(title: snippetDict["title"] as! String, id: (item["id"] as! Dictionary<String, Any>)["videoId"] as! String, channel: snippetDict["channelTitle"] as! String, thumbnail: ((snippetDict["thumbnails"] as! Dictionary<String, Any>)["default"] as! Dictionary<String, Any>)["url"] as! String)

                    // Append the desiredValuesDict dictionary to the following array.
                        self.videosArray.append(videoDetails)
                        
                    }
                    completion(true, self.videosArray)
                } catch{
                    completion(false, [])
                    return
                }
                
                
                // Get the first dictionary item from the returned items (usually there's just one item).
                
            }else {
                print("HTTP Status Code = \(HTTPStatusCode)")
                print("Error while loading channel details: \(String(describing: error))")
                completion(false,[])
            }
        })
    }
    
    
    
    
    //Takes the video id as a string argument and returns the data snippet of the video
    func videoSnippetFrom(Id: String, completion: @escaping (_ success: Bool, _ data: YoutubeVideoData) -> Void){
        
        
        // Form the request URL string.
        var urlString = "https://www.googleapis.com/youtube/v3/videos?part=snippet&id=\(Id)&key=\(apiKey)"
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        
        // Create a NSURL object based on the above string.
        let targetURL = URL(string: urlString)
        
        performGetRequest(targetURL: targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
            
            if HTTPStatusCode == 200 && error == nil {
                // Convert the JSON data to a dictionary.
                do{
                    
                    print(data ?? "")
                    let resultsDict = try JSONSerialization.jsonObject(with: data!, options:[]) as! [String: Any]
                    let items: Array<Dictionary<String, Any>> = resultsDict["items"] as! Array<Dictionary<String, Any>>
                    
                    //should only be one result?
                    let item = items[0]
                    //                    for item in items {
                    
                    // Get the snippet dictionary that contains the desired data.
                    let snippetDict = item["snippet"] as! Dictionary<String, Any>
                    print(snippetDict)
                    
                    // Create a new VideoData object to store only the values we care about.
                    
                    let videoDetails: YoutubeVideoData = YoutubeVideoData.init(title: snippetDict["title"] as! String, id: Id, channel: snippetDict["channelTitle"] as! String, thumbnail: ((snippetDict["thumbnails"] as! Dictionary<String, Any>)["high"] as! Dictionary<String, Any>)["url"] as! String)
                    
                    
                    // Append the desiredValuesDict dictionary to the following array.
                    self.videoData = videoDetails
                    
                    //                    }
                    completion(true, self.videoData)
                } catch{
                    completion(false, self.videoData)
                    return
                }
                
                // Get the first dictionary item from the returned items (usually there's just one item).
                
            }else {
                print("HTTP Status Code = \(HTTPStatusCode)")
                print("Error while loading channel details: \(String(describing: error))")
                completion(false,self.videoData)
            }
        })
    }
    
    
    
    
    //creates an itunes query based on the song data the user has selected
    func parseYoutubeSongString(songData: String) -> YoutubeVideoData{
        //song data is in format title:artist:album so we just separate by : and use those terms in our itunes search query
        
        var videoID: String = ""
        var title: String = ""
        var channel: String = ""
        var thumbnail: String = ""
        
        let strings = songData.components(separatedBy: "::")
        
        if strings.count > 1 {
            videoID = strings[0]
            title = strings[1]
            channel = strings[2]
            thumbnail = strings[3]
        }else{
          let oldStrings = songData.components(separatedBy: ":")
            videoID = oldStrings[0]
            title = oldStrings[1]
            channel = oldStrings[2]
            thumbnail = oldStrings[3]
        }
        
        
        let data: YoutubeVideoData = YoutubeVideoData.init(title: title, id: videoID, channel: channel, thumbnail: thumbnail)

        return data
        
    }
    
    
    
    //for youtube links posted by user, video id needs to be extracted
    func getIdFromUrlString(string: String) -> String{
        
        var id: String = ""
        
        let strings = string.components(separatedBy: "=")
        
        let count = strings.count
        
        id = strings[count - 1]
        
        return id
    }
    
    
}
