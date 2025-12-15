//
//  File.swift
//  Man1fest0
//
//  Created by Amos Deane on 26/10/2023.
//

import Foundation
import SwiftUI
import AEXML
import AppKit


class ASyncFileDownloader {
    
    @EnvironmentObject var networkController: NetBrain
    
    @Published var url: URL? = nil
    
    static func separationLine() {
        print("------------------------------------------------------------------")
    }

    // Destination helper: prefer Downloads, fall back to Documents
    static func destinationBaseURL() -> URL {
        return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    // Ensure filename ends with .xml
    static func ensureXMLExtension(_ filename: String) -> String {
        if filename.lowercased().hasSuffix(".xml") {
            return filename
        } else {
            return filename + ".xml"
        }
    }

    // MARK: - Sandbox / Bookmark helpers
    private static let bookmarkDefaultsKey = "ASyncFileDownloader.downloadFolderBookmark"

    // Persist a security-scoped bookmark for a folder
    static func storeBookmark(for folderURL: URL) -> Bool {
        do {
            let bookmark = try folderURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmark, forKey: bookmarkDefaultsKey)
            return true
        } catch {
            print("Failed to create bookmark: \(error)")
            return false
        }
    }

    // Resolve saved bookmark to URL (starts access if security-scoped)
    static func resolveSavedBookmark() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkDefaultsKey) else { return nil }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                // Try to recreate
                _ = storeBookmark(for: url)
            }
            return url
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }

    // Present an NSOpenPanel to let the user choose a downloads folder (returns the selected folder URL or nil)
    static func askUserForDownloadFolder() -> URL? {
        var selectedURL: URL?
        let runPanel = {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.prompt = "Choose"
            panel.title = "Choose folder to save downloads"
            if panel.runModal() == .OK {
                selectedURL = panel.url
            }
        }

        if Thread.isMainThread {
            runPanel()
        } else {
            DispatchQueue.main.sync {
                runPanel()
            }
        }

        if let url = selectedURL {
            _ = storeBookmark(for: url)
        }
        return selectedURL
    }

    // Attempt to write data to a writable folder: Downloads preferred; if not writable, try saved bookmark; if still not, present a panel and save bookmark.
    static func saveDataToUserDownloads(data: Data, filename: String) -> (String?, Error?) {
        let safeFilename = ensureXMLExtension(filename)

        // 1) Try default destination (Downloads or Documents)
        let defaultBase = destinationBaseURL()
        let defaultURL = defaultBase.appendingPathComponent(safeFilename)
        do {
            try data.write(to: defaultURL, options: .atomic)
            return (defaultURL.path, nil)
        } catch {
            print("Direct write to default destination failed: \(error)")
        }

        // 2) Try resolved bookmark folder (security-scoped)
        if let bookmarkFolder = resolveSavedBookmark() {
            var didStart = false
            if bookmarkFolder.startAccessingSecurityScopedResource() { didStart = true }
            let targetURL = bookmarkFolder.appendingPathComponent(safeFilename)
            do {
                try data.write(to: targetURL, options: .atomic)
                if didStart { bookmarkFolder.stopAccessingSecurityScopedResource() }
                return (targetURL.path, nil)
            } catch {
                print("Write to bookmarked folder failed: \(error)")
                if didStart { bookmarkFolder.stopAccessingSecurityScopedResource() }
            }
        }

        // 3) Ask the user to choose a folder
        if let chosen = askUserForDownloadFolder() {
            var didStart = false
            if chosen.startAccessingSecurityScopedResource() { didStart = true }
            let targetURL = chosen.appendingPathComponent(safeFilename)
            do {
                try data.write(to: targetURL, options: .atomic)
                if didStart { chosen.stopAccessingSecurityScopedResource() }
                return (targetURL.path, nil)
            } catch {
                print("Write to user-chosen folder failed: \(error)")
                if didStart { chosen.stopAccessingSecurityScopedResource() }
                return (targetURL.path, error)
            }
        }

        // All attempts failed
        return (defaultURL.path, NSError(domain: "ASyncFileDownloader", code: 2001, userInfo: [NSLocalizedDescriptionKey: "Failed to save file to Downloads or user-selected folder"]))
    }
    
    //   #################################################################################
    //   downloadFileSync
    //   #################################################################################
    
    static func downloadFileSync(url: URL, completion: @escaping (String?, Error?) -> Void)
    {
        let filename = ensureXMLExtension(url.lastPathComponent)
        let destinationUrl = destinationBaseURL().appendingPathComponent(filename)
        
        if FileManager().fileExists(atPath: destinationUrl.path) {
            print("File already exists [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        } else if let dataFromURL = NSData(contentsOf: url) {
            // Use sandbox-friendly save helper
            let data = dataFromURL as Data
            let (path, writeError) = saveDataToUserDownloads(data: data, filename: filename)
            if let p = path, writeError == nil {
                showDownloadCompletedNotification(savedPath: p)
            }
            completion(path, writeError)
        } else {
            let error = NSError(domain: "Error downloading file", code: 1002, userInfo: nil)
            completion(destinationUrl.path, error)
        }
    }
     
     //   #################################################################################
     //   downloadFileAsync
     //   #################################################################################
     
     
     static func downloadFileAsync(url: URL, completion: @escaping (String?, Error?) -> Void)
     {
         
         print("Running downloadFileAsync")

         let filename = ensureXMLExtension(url.lastPathComponent)
         let destinationUrl = destinationBaseURL().appendingPathComponent(filename)
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
                             if let data = data {
                                 // Try sandbox-friendly save
                                 let (path, writeError) = saveDataToUserDownloads(data: data, filename: filename)
                                 if let p = path, writeError == nil {
                                     showDownloadCompletedNotification(savedPath: p)
                                 }
                                 completion(path, writeError)
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
            
            let filename = ensureXMLExtension(url.lastPathComponent)
            let destinationUrl = destinationBaseURL().appendingPathComponent(filename )
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
                                
                                if let data = data {
                                    print("Data has been received")
                                    let (path, writeError) = saveDataToUserDownloads(data: data, filename: filename)
                                    if let p = path, writeError == nil {
                                        showDownloadCompletedNotification(savedPath: p)
                                    }
                                    completion(path, writeError)
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
            
            let filename = ensureXMLExtension(url.lastPathComponent)
            let destinationUrl = destinationBaseURL().appendingPathComponent(filename )
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
                                
                                if let data = data {
                                    print("Data has been received")
                                    let (path, writeError) = saveDataToUserDownloads(data: data, filename: filename)
                                    if let p = path, writeError == nil {
                                        showDownloadCompletedNotification(savedPath: p)
                                    }
                                    completion(path, writeError)
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
    
    // Show a UI alert after a successful download, offering "Open in Finder"
    static func showDownloadCompletedNotification(savedPath: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Download Complete"
            alert.informativeText = "Saved to: \(savedPath)"
            alert.addButton(withTitle: "Open in Finder")
            alert.addButton(withTitle: "OK")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: savedPath)])
            }
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
