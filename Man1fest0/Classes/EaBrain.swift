//
//  EaBrain.swift
//  Man1fest0
//
//  Created by Amos Deane on 05/02/2025.
//


import Foundation
import SwiftUI
import AEXML


@MainActor class EaBrain: ObservableObject {

    //    #################################################################################
    //    ############ Computer Extension Attributes
    //    #################################################################################
    
    @Published var allComputerExtensionAttributes: ComputerExtensionAttributes = ComputerExtensionAttributes(computerExtensionAttributes:  [ ComputerExtensionAttribute(id: 0, name: "", enabled: true ) ] )
    @Published var computerExtensionAttributeDetailed: ComputerExtensionAttributeDetailed = ComputerExtensionAttributeDetailed(id: 0, name: "", enabled: true, description: "", dataType: "", inputType: InputType(type: "", platform: "", script: ""), inventoryDisplay: "" )
    
    @Published var allComputerExtensionAttributesDict = [ComputerExtensionAttribute]()
    @Published var allComputerExtensionAttributesArray = [ComputerExtensionAttribute]()
    
    @Published var currentResponseCode = ""
    @Published var currentResponseStatus = ""
    @Published var hasError = false
    
    enum NetError: Error {
        case couldntEncodeNamePass
        case badResponseCode
    }
    
    func separationLine() {
        print("------------------------------------------------------------------")
    }
    
    //    #################################################################################
    //    getComputerExtAttributes
    //    #################################################################################
    
    func getComputerExtAttributes(server: String, authToken: String) async throws {
        let jamfURLQuery = server + "/JSSResource/computerextensionattributes"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getComputerExtAttributes")
        print("jamfURLQuery is: \(jamfURLQuery)")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            self.hasError = true
            
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            self.currentResponseCode = String(describing: statusCode)
            print("getComputerExtAttributes Status code is:\(statusCode)")
            throw JamfAPIError.http(statusCode)
        }

        separationLine()
        print("getComputerExtAttributes - Json data as text is:")
        print(String(data: data, encoding: .utf8)!)
        let decoder = JSONDecoder()
        separationLine()
        do {
            let response = try decoder.decode(ComputerExtensionAttributes.self, from: data)
            self.allComputerExtensionAttributesDict = response.computerExtensionAttributes
            separationLine()
            print("allComputerExtensionAttributes Decoding succeeded")
            
        } catch {
            self.separationLine()
            print("allComputerExtensionAttributes Decoding failed - error is:")
            print(error)
        }
    }
    
    //    #################################################################################
    //    getComputerExtAttributeDetailed
    //    #################################################################################
    
    func getComputerExtAttributeDetailed(server: String, authToken: String, compExtAttId: String) async throws {
        
        let jamfURLQuery = server + "/JSSResource/computerextensionattributes/id/" + compExtAttId
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getComputerExtAttributeDetailed")
        print("jamfURLQuery is: \(jamfURLQuery)")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw JamfAPIError.http(statusCode)
        }
        separationLine()
        print("getComputerExtAttributeDetailed - Json data as text is:")
        print(String(data: data, encoding: .utf8)!)
        let decoder = JSONDecoder()
        separationLine()
        do {
            let response = try decoder.decode(ComputerExtensionAttributeDetailedResponse.self, from: data)
            self.computerExtensionAttributeDetailed = response.computerExtensionAttribute
            separationLine()
            print("ComputerExtensionAttributeDetailed Decoding succeeded")
            print("computerExtensionAttributeDetailed is:\(self.computerExtensionAttributeDetailed)")
        } catch {
            self.separationLine()
            print("computerExtensionAttributeDetailed Decoding failed - error is:")
            print(error)
            throw JamfAPIError.decode
        }
    }
    
    func deleteComputerEA(server: String,resourceType: ResourceType, itemID: String, authToken: String) async throws {
        let resourcePath = getURLFormat(data: (resourceType))
        if let serverURL = URL(string: server) {
            let url = serverURL.appendingPathComponent("JSSResource").appendingPathComponent(resourcePath).appendingPathComponent(itemID)
            separationLine()
            print("Running deleteComputerEA function - url is set as:\(url)")
            print("resourceType is set as:\(resourceType)")
            var request = URLRequest(url: url,timeoutInterval: Double.infinity)
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.addValue("application/xml", forHTTPHeaderField: "Accept")
            request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "DELETE"
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                print("Code not 200")
                self.hasError = true
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                self.currentResponseCode = String(describing: statusCode)
                print("getComputerExtAttributes Status code is:\(statusCode)")
                throw JamfAPIError.http(statusCode)
            }
            print("deleteComputerEA has finished successfully")
        }
    }
    
    func batchDeleteComputerEA(selection:  Set<ComputerExtensionAttribute>, server: String, authToken: String, resourceType: ResourceType) async throws {
        
        self.separationLine()
        print("Running: batchDeleteComputerEA")
        print("Set processingComplete to false")

        for eachItem in selection {
            self.separationLine()
            print("Items as Dictionary is \(eachItem)")
            let computerEaId = String(describing:eachItem.id)
            let jamfID: String = String(describing:eachItem.id)
            print("Current computerEaId is:\(computerEaId)")
            print("Current jamfID is:\(String(describing: jamfID))")
            
            do {
               try await self.deleteComputerEA(server: server, resourceType: resourceType, itemID: jamfID, authToken: authToken )
            } catch {
                throw JamfAPIError.badURL
            }
        }
        self.separationLine()
        print("Finished - Set processingComplete to true")
    }
}
