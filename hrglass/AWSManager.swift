//
//  AWSManager.swift
//  hrglass
//
//  Created by Justin Hershey on 7/17/17.
//
//

import Foundation
import AWSS3





/***********************************************************************************
 *
 *     AWS CONFIG VARIABLES and FUNCTIONS TO UPDATE AND RETRIEVE DATA AWS S3
 *
 *     -- additional functions to track upload status
 *
 ***********************************************************************************/

class AWSManager {

    let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast2,
                                                        identityPoolId:"us-east-2:b0f6fcd2-02c8-4034-917e-dc51e9771dc6")

    let configuration: AWSServiceConfiguration!
    
    
    let bucketName = "hrglass.east"
    var uid: String
    
    var transferManager: AWSS3TransferManager!
    
    var videoTransferRequest = AWSS3TransferManagerUploadRequest()
    var photoTransferRequest = AWSS3TransferManagerUploadRequest()
    var audioTransferRequest = AWSS3TransferManagerUploadRequest()
    
    var videoUploadProgress:Double = 0
    var photoUploadProgress:Double = 0
    var audioUploadProgress:Double = 0
    
    init(uid: String){
        
//     Initialize the Amazon Cognito credentials provider
        self.uid = uid
        configuration = AWSServiceConfiguration(region:.USEast2, credentialsProvider:credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }

    convenience init(){
        self.init(uid: "")
        
    }
    
    
    
    
    /*******************************************************
     *
     *     UPLOAD PHOTO TO S3
     *
     *     - Paramenters: String: filename, String: filetype
     *      -resource URL is the local url location
     *
     *******************************************************/

    func uploadPhotoAction(resourceURL: URL, fileName: String, type: String, completion:@escaping(Bool) -> ()){
        
        let key = "\(uid)/images/\(fileName).\(type)"
        
        self.photoTransferRequest = AWSS3TransferManagerUploadRequest()!
        self.photoTransferRequest?.bucket = self.bucketName
        self.photoTransferRequest?.key = key
        self.photoTransferRequest?.body = resourceURL
        self.photoTransferRequest?.acl = .publicReadWrite
        
        transferManager = AWSS3TransferManager.default()
        transferManager.upload(photoTransferRequest!).continueWith(executor: AWSExecutor.mainThread()) { (task) -> Any? in
            
            if let error = task.error {
                
                print(error)
                completion(false)
            }
            if task.result != nil{
                
                print("Uploaded \(key)")
                completion(true)
                
            }
            
         return nil
        }
    }

    
    /*******************************************
     *
     *     UPLOAD Video TO S3
     *
     *     - Parameters: String: filename, String: filetype
     *      -resource URL is the local url location
     *
     *******************************************/


    func uploadVideoAction(resourceURL: URL, fileName: String, type: String, completion:@escaping(Bool) -> ()){
        
        let key = "\(uid)/videos/\(fileName).\(type)"
    
        self.videoTransferRequest = AWSS3TransferManagerUploadRequest()!
        self.videoTransferRequest?.bucket = self.bucketName
        self.videoTransferRequest?.key = key
        self.videoTransferRequest?.body = resourceURL
        self.videoTransferRequest?.acl = .publicReadWrite
        self.videoTransferRequest?.contentType = "video/mp4"
        
        transferManager = AWSS3TransferManager.default()
        transferManager.upload(self.videoTransferRequest!).continueWith(executor: AWSExecutor.mainThread()) { (task) -> Any? in
            
            if let error = task.error {
                
                print(error)
                completion(false)
            }
            
            if task.result != nil{
                
                print("Uploaded \(key)")
                completion(true)

            }
            return nil
        }
    
    }
    
    
    
    /*******************************************
     *
     *     UPLOAD AUDIO TO S3
     *
     *     - takes filename, filetype string parameters
     *      -resource URL is the local url location
     *
     *******************************************/
    
    func uploadAudioAction(resourceURL: URL, fileName: String, type: String, completion:@escaping(Bool) -> ()){
        
        let key = "\(uid)/audio/\(fileName).\(type)"
        
        
        self.audioTransferRequest = AWSS3TransferManagerUploadRequest()!
        self.audioTransferRequest?.bucket = self.bucketName
        self.audioTransferRequest?.key = key
        self.audioTransferRequest?.body = resourceURL
        self.audioTransferRequest?.acl = .publicReadWrite
        
        
        transferManager = AWSS3TransferManager.default()
        transferManager.upload(self.audioTransferRequest!).continueWith(executor: AWSExecutor.mainThread()) { (task) -> Any? in
            if let error = task.error {
                
                print(error)
                completion(false)
            }
            
            if task.result != nil{
                
                print("Uploaded \(key)")
                completion(true)
            }
            
        
            return nil
        }

    }
    
    
    
    
    
    /*******************************************
     *
     *     VIDEO UPLOAD PROGRESS CHECK
     *******************************************/
    
    func videoUploadProgressCheck(){
        
        self.videoTransferRequest?.uploadProgress = {(bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) -> Void in
            DispatchQueue.main.async(execute: {() -> Void in
                //Update progress
                
                let percentDone:Double = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
                
                self.videoUploadProgress = percentDone
        
//                print(self.videoUploadProgress)
            })
        }
    }
    
    
    
    
    /*******************************************
     *
     *     PHOTO UPLOAD PROGRESS CHECK
     *******************************************/
    func photoUploadProgressCheck(){
        self.photoTransferRequest?.uploadProgress = {(bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) -> Void in
            DispatchQueue.main.async(execute: {() -> Void in
                //Update progress
                let percentDone:Double = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
                self.photoUploadProgress = percentDone
                    
//                    print(percentDone)

            })
        }
    }
    
    
    /*******************************************
     *
     *     AUDIO UPLOAD PROGRESS CHECK
     *******************************************/
    func audioUploadProgressCheck(){
        
        self.audioTransferRequest?.uploadProgress = {(bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) -> Void in
            DispatchQueue.main.async(execute: {() -> Void in
                //Update progress
                
                let percentDone:Double = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
                self.audioUploadProgress = percentDone
                
//                print(percentDone)
            })
        }
        
    }
    
    
    /*******************************************
     *        CANCEL/PAUSE/RESUME UPLOADS
     *******************************************/
    func cancelRequest(){
            
        self.transferManager.cancelAll()
    }
    
    func pauseRequest(){
        self.transferManager.pauseAll()
    }
    
    func resumeRequests(){
        
        self.transferManager.resumeAll { (request) in
            
            print(request)
        }
    }
    
    
    //returns the prefix of hrglass current S3 prefix
    func getS3Prefix() -> String{
        
        return "https://s3.us-east-2.amazonaws.com/hrglass.east"
    }
}
