//
//  File.swift
//  Man1fest0
//
//  Created by Amos Deane on 26/10/2023.
//

import Foundation
import SwiftUI
import AEXML


class ASyncFileDownloader {
    
    @EnvironmentObject var networkController: NetBrain
    
    @Published var url: URL? = nil
    
    static func separationLine() {
        print("------------------------------------------------------------------")
    }
    
//    Renamed funcs from original
    
    
    //   #################################################################################
    //   downloadFileSync
    //   #################################################################################
    
    
    static func downloadFileSync(url: URL, completion: @escaping (String?, Error?) -> Void)
    {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        if FileManager().fileExists(atPath: destinationUrl.path)
        {
            print("File already exists [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        }
        else if let dataFromURL = NSData(contentsOf: url)
        {
            if dataFromURL.write(to: destinationUrl, atomically: true)
            {
                print("file saved [\(destinationUrl.path)]")
                completion(destinationUrl.path, nil)
            }
            else
            {
                print("error saving file")
                let error = NSError(domain:"Error saving file", code:1001, userInfo:nil)
                completion(destinationUrl.path, error)
            }
        }
        else
        {
            let error = NSError(domain:"Error downloading file", code:1002, userInfo:nil)
            completion(destinationUrl.path, error)
        }
    }
    
    //   #################################################################################
    //   downloadFileAsync
    //   #################################################################################
    
    
    static func downloadFileAsync(url: URL, completion: @escaping (String?, Error?) -> Void)
    {
        
        print("Running downloadFileAsync")

        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        print("documentsUrl is:\(documentsUrl)")

        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        print("destinationUrl is:\(destinationUrl)")
        
        self.separationLine()
        print("url is:\(String(describing:url))")

        if FileManager().fileExists(atPath: destinationUrl.path)
        {
            print("File already exists [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        }
        else
        {
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let task = session.dataTask(with: request, completionHandler:
                                            {
                data, response, error in
                if error == nil
                {
                    if let response = response as? HTTPURLResponse
                    {
                        if response.statusCode == 200
                        {
                            if let data = data
                            {
                                if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic)
                                {
                                    completion(destinationUrl.path, error)
                                }
                                else
                                {
                                    completion(destinationUrl.path, error)
                                }
                            }
                            else
                            {
                                completion(destinationUrl.path, error)
                            }
                        }
                    }
                }
                else
                {
                    completion(destinationUrl.path, error)
                }
            })
            task.resume()
        }
    }
    
    //   #################################################################################
    //   downloadFileAsyncAuth
    //   #################################################################################
    
    static func downloadFileAsyncAuth(objectID: Int, resourceType: ResourceType, server: String, authToken: String, completion: @escaping (String?, Error?) -> Void) {
        
        print("Running downloadFileAsyncAuth")

        
        self.separationLine()
        print("Setting the URL for resource type: \(resourceType)")
        
        let resourcePath = getURLFormat(data: (resourceType))
        
        if let serverURL = URL(string: server) {
            
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent("\(objectID)")
            
//            self.separationLine()
            print("URL is set as:\(String(describing: url))")
            
            let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            print("documents Url is:\(documentsUrl)")
            
            let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent )
            print("destination Url is:\(destinationUrl)")
            
            if FileManager().fileExists(atPath: destinationUrl.path)
                
            {
                print("File already exists [\(destinationUrl.path)]")
                completion(destinationUrl.path, nil)
            }
            else
            {
                let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
                
                let headers = [
                    "Accept": "application/json",
                    "Authorization": "Bearer \(authToken)"
                ]
                
                var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
                request.allHTTPHeaderFields = headers
                request.httpMethod = "GET"
                
                
                let task = session.dataTask(with: request, completionHandler:
                                                {
                    data, response, error in
                    if error == nil
                    {
                        print("Running request")
                        
                        if let response = response as? HTTPURLResponse
                        {
                            if response.statusCode == 200
                                
                            {
                                print("StatusCode == 200")
                                
                                if let data = data
                                {
                                    
                                    print("Data has been received")
                                    
                                    if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic)
                                    {
                                        completion(destinationUrl.path, error)
                                    }
                                    else
                                    {
                                        completion(destinationUrl.path, error)
                                    }
                                }
                                else
                                {
                                    print("--------------------------------------------------")
                                    print("Data has not been received!")
                                    print(error ?? "Unknown error")
                                    completion(destinationUrl.path, error)
                                }
                                //                            }
                            }
                            else
                            {
                                print("StatusCode is not 200!")
                                print("StatusCode is:\(response.statusCode)")
                                print(error ?? "Unknown error")
                                
                                
                            }
                        }
                        else
                        {
                            print("Response is:\(String(describing: response))")
                            print(error ?? "Unknown error")
                            
                        }
                    }
                    else
                    {
                        
                        //                        separationLine()
                        print("--------------------------------------------------")
                        print("Error is not nil!")
                        print(error ?? "Unknown error")
                        
                        completion(destinationUrl.path, error)
                    }
                    
                })
                task.resume()
            }
            
        } else {
            print("No url has been supplied")
        }
    }
    
    
    //   #################################################################################
    //   downloadFileAsyncAuthUrl
    //   #################################################################################
    
    static func downloadFileAsyncAuthUrl(urlOveride: URL, objectID: Int, resourceType: ResourceType, server: String, authToken: String, completion: @escaping (String?, Error?) -> Void) {
        
        print("Running downloadFileAsyncAuth")

        
        self.separationLine()
        print("Setting the URL for resource type: \(resourceType)")
        
        let resourcePath = getURLFormat(data: (resourceType))
        
        if let serverURL = URL(string: server) {
            
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent("\(objectID)")
            
//            self.separationLine()
            print("URL is set as:\(String(describing: url))")
            
            let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            print("documents Url is:\(documentsUrl)")
            
            let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent )
            print("destination Url is:\(destinationUrl)")
            
            if FileManager().fileExists(atPath: destinationUrl.path)
                
            {
                print("File already exists [\(destinationUrl.path)]")
                completion(destinationUrl.path, nil)
            }
            else
            {
                let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
                
                let headers = [
                    "Accept": "application/json",
                    "Authorization": "Bearer \(authToken)"
                ]
                
                var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
                request.allHTTPHeaderFields = headers
                request.httpMethod = "GET"
                
                
                let task = session.dataTask(with: request, completionHandler:
                                                {
                    data, response, error in
                    if error == nil
                    {
                        print("Running request")
                        
                        if let response = response as? HTTPURLResponse
                        {
                            if response.statusCode == 200
                                
                            {
                                print("StatusCode == 200")
                                
                                if let data = data
                                {
                                    
                                    print("Data has been received")
                                    
                                    if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic)
                                    {
                                        completion(destinationUrl.path, error)
                                    }
                                    else
                                    {
                                        completion(destinationUrl.path, error)
                                    }
                                }
                                else
                                {
                                    print("--------------------------------------------------")
                                    print("Data has not been received!")
                                    print(error ?? "Unknown error")
                                    completion(destinationUrl.path, error)
                                }
                                //                            }
                            }
                            else
                            {
                                print("StatusCode is not 200!")
                                print("StatusCode is:\(response.statusCode)")
                                print(error ?? "Unknown error")
                                
                                
                            }
                        }
                        else
                        {
                            print("Response is:\(String(describing: response))")
                            print(error ?? "Unknown error")
                            
                        }
                    }
                    else
                    {
                        
                        //                        separationLine()
                        print("--------------------------------------------------")
                        print("Error is not nil!")
                        print(error ?? "Unknown error")
                        
                        completion(destinationUrl.path, error)
                    }
                    
                })
                task.resume()
            }
            
        } else {
            print("No url has been supplied")
        }
    }
}






//    #################################################################################
//    downloadFileAsync
//    #################################################################################


//        func downloadFileAsync(objectID: String, resourceType: ResourceType, server: String,  url: String, completion: @escaping (String?, Error?) -> Void) {
//
//        self.separationLine()
//        print("Setting the URL for resource type: \(resourceType)")
//        let resourcePath = getURLFormat(data: (resourceType))
//        if let serverURL = URL(string: server) {
//            let currentUrl = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent("\(objectID)")
//            self.separationLine()
//            print("currentUrl is set as:\(String(describing: currentUrl))")
//            let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//            print("documentsUrl is:\(documentsUrl)")
//            let destinationUrl = documentsUrl.appendingPathComponent(currentUrl.lastPathComponent )
//            print("destinationUrl is:\(destinationUrl)")
//            if FileManager().fileExists(atPath: destinationUrl.path)
//            {
//                print("File already exists [\(destinationUrl.path)]")
//                completion(destinationUrl.path, nil)
//            }
//            else
//            {
//                let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
//
//                let loginData = "\(username):\(password)".data(using: String.Encoding.utf8)
//                let base64LoginString = loginData!.base64EncodedString()
//                let headers = [
//                    "Accept": "application/json",
//                    "Authorization": "Basic \(base64LoginString)"
//                ]
//                var request = URLRequest(url: url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
//                request.allHTTPHeaderFields = headers
//                request.httpMethod = "GET"
//                let task = session.dataTask(with: request, completionHandler:
//                                                {
//                    data, response, error in
//                    if error == nil
//                    {
//                        print("Running task")
//
//                        if let response = response as? HTTPURLResponse
//                        {
//                            if response.statusCode == 200
//
//                            {
//                                print("StatusCode == 200")
//
//                                if let data = data
//                                {
//                                    print("data = data")
//                                    if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic)
//                                    {
//                                        completion(destinationUrl.path, error)
//                                    }
//                                    else
//                                    {
//                                        completion(destinationUrl.path, error)
//                                    }
//                                }
//                                else
//                                {
//                                    print("--------------------------------------------------")
//                                    print("data is not data!")
//                                    print(error ?? "Unknown error")
//                                    completion(destinationUrl.path, error)
//                                }
//                            }
//                            else
//                            {
//                                print("StatusCode is not 200!")
//                                print("StatusCode is:\(response.statusCode)")
//                                print(error ?? "Unknown error")
//                            }
//                        }
//                        else
//                        {
//                            print("Response is:\(String(describing: response))")
//                            print(error ?? "Unknown error")
//                        }
//                    }
//                    else
//                    {
//                        self.separationLine()
//                        print("Error is not nil!")
//                        print(error ?? "Unknown error")
//                        completion(destinationUrl.path, error)
//                    }
//
//                })
//                task.resume()
//            }
//
//        } else {
//            print("No url has been supplied")
//        }
//    }




