//
//  ImportExportBrain.swift
//  Manifesto
//
//  Created by Amos Deane on 20/01/2025.
//


import Foundation
import SwiftUI
import UniformTypeIdentifiers


class ImportExportBrain: ObservableObject {
    
    @Published var importedString: String = ""
    
    var selectedFilename = ""
    
    func separationLine() {
        print("------------------------------------------------------------------")
    }
    func doubleSeparationLine() {
        print("==================================================================")
    }
    
    func asteriskSeparationLine() {
        print("******************************************************************")
    }
    func atSeparationLine() {
        print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    }
    

    struct TextDocument: FileDocument {
        static var readableContentTypes: [UTType] {
            [.plainText, .xml]
        }
        
        var text = ""
        
        init(text: String) {
            self.text = text
        }
        
        init(configuration: ReadConfiguration) throws {
            if let data = configuration.file.regularFileContents {
                text = String(decoding: data, as: UTF8.self)
            } else {
                text = ""
            }
        }
        
        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            FileWrapper(regularFileWithContents: Data(text.utf8))
        }
    }
    
#if os(macOS)
    func showOpenPanel() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["txt", "xml","pkg","dmg"]
//        openPanel.allowedContentTypes = ["txt"]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        let response = openPanel.runModal()
        print("Response is:\(response)")
        let fileName = openPanel.url
        self.selectedFilename = fileName?.lastPathComponent ?? ""
        print("selectedFilename is:\(String(describing: selectedFilename))")
        return response == .OK ? openPanel.url : nil
    }
#endif
    
    //    #################################################################################
    //    uploadPackage
    //    #################################################################################
    
    func uploadPackage(authToken: String, server: String, packageId: String, pathToFile: String) {
        self.atSeparationLine()
        print("Running:uploadPackage")
        print("pathToFile is:\(pathToFile)")
        print("packageId is:\(packageId)")
        print("server is:\(server)")
        
        let url = URL(string: "\(server)/api/v1/packages/\(packageId)/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        let fileURL = URL(fileURLWithPath: pathToFile)
        print("fileURL is:\(fileURL)")
        let fileData = try! Data(contentsOf: fileURL)
        print("fileData is:\(fileData)")

        // Adding file data to the request body
        body += Data("--\(boundary)--\r\n".utf8);
        body += Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".utf8);
        body += Data("Content-Type: application/octet-stream\r\n\r\n".utf8);
        body += Data(fileData)
        body += Data ("\r\n".utf8)
        body += Data ("--\(boundary)--\r\n".utf8)

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            let responseCode = (response as? HTTPURLResponse)?.statusCode
            print("Response code is:\(String(describing: responseCode ?? 0))")
            
            guard data != nil else {
                print("Error is:\(String(describing: error))")
                return
            }
            print("Request is:\(String(describing: request))")
//            print("Data is:\(String(data: data ?? "", encoding: .utf8)!)")
            print("Error is:\(String(describing: error))")
            print("Task succeeded")
        }
        task.resume()
    }
    
    
    func uploadPackage2(authToken: String, server: String, packageId: String, pathToFile: String) {
        
        let parameters = [
          [
            "key": "file",
            "src": "\(pathToFile)",
            "type": "file"
          ]] as [[String: Any]]

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
//        var error: Error? = nil
        for param in parameters {
          if param["disabled"] != nil { continue }
          let paramName = param["key"]!
          body += Data("--\(boundary)\r\n".utf8)
          body += Data("Content-Disposition:form-data; name=\"\(paramName)\"".utf8)
          if param["contentType"] != nil {
            body += Data("\r\nContent-Type: \(param["contentType"] as! String)".utf8)
          }
          let paramType = param["type"] as! String
          if paramType == "text" {
            let paramValue = param["value"] as! String
            body += Data("\r\n\r\n\(paramValue)\r\n".utf8)
          } else {
            let paramSrc = param["src"] as! String
            let fileURL = URL(fileURLWithPath: paramSrc)
            if let fileContent = try? Data(contentsOf: fileURL) {
              body += Data("; filename=\"\(paramSrc)\"\r\n".utf8)
              body += Data("Content-Type: \"content-type header\"\r\n".utf8)
              body += Data("\r\n".utf8)
              body += fileContent
              body += Data("\r\n".utf8)
            }
          }
        }
        body += Data("--\(boundary)--\r\n".utf8);
        let postData = body


        var request = URLRequest(url: URL(string: "https://\(server)/api/v1/packages/0/upload")!,timeoutInterval: Double.infinity)
        request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("••••••", forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        request.httpMethod = "POST"
        request.httpBody = postData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          guard let data = data else {
            print(String(describing: error))
            return
          }
          print(String(data: data, encoding: .utf8)!)
        }
        task.resume()
    }
   
        
    func uploadPackage3(authToken: String, server: String, packageId: String, pathToFile: String) {
                
        self.atSeparationLine()
        print("Running:uploadPackage3")
        print("pathToFile is:\(pathToFile)")
        print("packageId is:\(packageId)")
        print("server is:\(server)")
        
        let parameters = [
          [
            "key": "file",
            "src": "\(pathToFile)",
            "type": "file"
          ]] as [[String: Any]]
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
//        var error: Error? = nil
        for param in parameters {
            if param["disabled"] != nil { continue }
            let paramName = param["key"]!
            body += Data("--\(boundary)\r\n".utf8)
            body += Data("Content-Disposition:form-data; name=\"\(paramName)\"".utf8)
            if param["contentType"] != nil {
                body += Data("\r\nContent-Type: \(param["contentType"] as! String)".utf8)
            }
            let paramType = param["type"] as! String
            if paramType == "text" {
                let paramValue = param["value"] as! String
                body += Data("\r\n\r\n\(paramValue)\r\n".utf8)
            } else {
                let paramSrc = param["src"] as! String
                let fileURL = URL(fileURLWithPath: paramSrc)
                if let fileContent = try? Data(contentsOf: fileURL) {
                    body += Data("; filename=\"\(paramSrc)\"\r\n".utf8)
                    body += Data("Content-Type: \"content-type header\"\r\n".utf8)
                    body += Data("\r\n".utf8)
                    body += fileContent
                    body += Data("\r\n".utf8)
                }
            }
        }
        print("body is currently:\(String(describing: body).utf8))")
        //        print(String(data: body, encoding: .utf8)!)
        body += Data("--\(boundary)--\r\n".utf8);
        let postData = body
        var request = URLRequest(url: URL(string: "\(server)/api/v1/packages/\(packageId)/upload")!,timeoutInterval: Double.infinity)
        print("request is:\(request)")
        print("Data is:")
        print(String(data: body, encoding: .utf8) ?? "empty")
        //        print(String(data: postData, encoding: .utf8)!)
        request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            let responseCode = (response as? HTTPURLResponse)?.statusCode
            print("Response code is:\(String(describing: responseCode ?? 0))")
//            guard let data = data else {
//                print("Error is:\(String(describing: error))")
//                return
//            }
            //          print("Data is:\(String(data: data, encoding: .utf8)!)")
            print("Task succeeded")
        }
        task.resume()
    }
    
    func uploadPackage4(url: URL, authToken: String, parameters: String ) {
            
        atSeparationLine()
        print("Running uploadPackage4 function")
        print("url is:\(url)")
        self.atSeparationLine()
            
            let headers = [
                "Accept": "application/json",
                "Content-Type": "application/json",
                "Authorization": "Bearer \(authToken)"
            ]
            
            let postData = parameters.data(using: .utf8)
            
            var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
            request.allHTTPHeaderFields = headers
            request.httpMethod = "PUT"
            request.httpBody = postData
            
            let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
                if let data = data, let response = response {
//                    print("Doing processing of sendRequestAsXML:\(httpMethod)")
                    print("Data is:\(data)")
                    print("Data is:\(response)")
                    
                } else {
                    print("Error encountered")
                    var text = "\n\nFailed."
                    if let error = error {
                        text += " \(error)."
                    }
                    print(text)
                }
            }
        dataTask.resume()
    }
    
    func createPackage(server: String, authToken: String, resourceType: ResourceType, httpMethod: String, parameters: String, serialNumber: String, categoryId: Int, parentPackageId: Int, packageName: String, fillUserTemplate: String, priority: String, info: String, notes: String, manifestFileName: String, fileName: String ) {

        print("Running is:\(String(describing: uploadPackage))")

        let parameters = "{\n  \"categoryId\": \(String (describing: categoryId)),\n  \"fileName\": \(fileName),\n  \"fillUserTemplate\": \"false\",\n  \"osInstall\": \"false\",\n  \"packageName\": \(packageName),\n  \"priority\": \"0\",\n  \"rebootRequired\": \"false\",\n  \"suppressEula\": \"false\",\n  \"suppressFromDock\": \"false\",\n  \"suppressRegistration\": \"false\",\n  \"suppressUpdates\": \"false\",\n  \"info\": \"\",\n  \"notes\": \"\",\n  \"osRequirements\": \"\",\n  \"fillExistingUsers\": \"false\",\n  \"swu\": \"false\",\n  \"selfHealNotify\": \"false\",\n  \"selfHealingAction\": \"\",\n  \"serialNumber\": \"\",\n  \"parentPackageId\": \"\",\n  \"basePath\": \"\",\n  \"ignoreConflicts\": \"false\",\n  \"installLanguage\": \"\",\n  \"md5\": \"\",\n  \"sha256\": \"\",\n  \"hashType\": \"\",\n  \"hashValue\": \"\",\n  \"osInstallerVersion\": \"\",\n  \"manifest\": \"\",\n  \"manifestFileName\": \"\",\n  \"format\": \"\"\n}"
        
        let postData = parameters.data(using: .utf8)

        var request = URLRequest(url: URL(string: "\(server)/api/v1/packages")!,timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = postData
        print("Request is:\(request)")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          guard let data = data else {
            print(String(describing: error))
            return
          }
          print(String(data: data, encoding: .utf8)!)
        }
        task.resume()
    }
}
