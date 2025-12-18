//
//  PrestageBrain.swift
//  Man1fest0
//
//  Created by Amos Deane on 26/01/2024.
//

import Foundation
import SwiftUI

    
@MainActor class PrestageBrain: ObservableObject {

    enum NetError: Error {
        case couldntEncodeNamePass
        case badResponseCode
    }
    
    struct JamfProAuth: Decodable {
        let token: String
        let expires: String
    }
    
    @Published var searchText = ""
    @Published var status: Status = .none

    @AppStorage("needsLogin") var needsLogin = true
    @AppStorage("server") var server = ""
    @AppStorage("username") var username = ""
    @AppStorage("password") var password = ""
    @AppStorage("serial") var serial = ""
    
    // The basic container for all prestages
    @Published var prestages: [PreStagesResponse] = []
    // The property to contain all prestages
    @Published var allPrestages: [PreStage] = []
    // The property to contain all devices for a specific prestage - by ID
    @Published var serialPrestageAssignment: [String: String] = [:]
    // The property to contain all prestages by scope - eg. each device, and which prestage it is scoped to
    @Published var allPrestagesScope: DevicesAssignedToAPrestage?
    // The current scope for the selected prestage
    @Published var selectedPrestageScope: ComputerPrestageCurrentScope? = nil
    
    //  Variables to hold the status response codes of the requests
    @Published var tokenComplete: Bool = false
    @Published var tokenStatusCode: Int = 0
    @Published var allPsStatusCode: Int = 0
    @Published var allPsScStatusCode: Int = 0
    @Published var allPsComplete: Bool = false
    @Published var allPsScComplete: Bool = false
    // The version lock for changes to prestages
    var depVersionLock = 0
    @Published var authToken = ""
    
//    #########################################################################
    
    enum Status {
        case none
        case fetching
        case badServer
        case badResponse(URLResponse?, Error?)
        case corruptData(Error)
    }
    
//    #########################################################################
    
// ##################################
// UNUSED
// ##################################
    func updateStatus(_ status: Status) {
        DispatchQueue.main.async {
            withAnimation {
                self.processStatus(status)
            }
        }
    }
    
    func processStatus(_ status: Status) {
        assert(Thread.isMainThread)

        switch status {
            case .badServer, .badResponse:
                needsLogin = true
                
            default:
                break
        }
        self.status = status
    }
    

    
    
    
    func separationLine() {
        print("-----------------------------------")
    }
    func doubleSeparationLine() {
        print("===================================")
    }
    func asteriskSeparationLine() {
        print("***********************************")
    }
    func atSeparationLine() {
        print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    }
    
    
    
    // #######################################################################################
    // LIST ALL PRESTAGES
    // #######################################################################################
    // This just lists all prestages. For: PreStagesView
    
    func getAllPrestages(server: String, authToken: String) async throws {

        self.allPsComplete = false
        print("Setting allPsComplete to:\(self.allPsComplete)")
//        let jamfURLQuery = server + "/api/v2/computer-prestages?page=0&page-size=100&sort=id%3Adesc"
        let jamfURLQuery = server + "/api/v3/computer-prestages"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running func: getAllPrestages")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - response is:\(response)")
            throw JamfAPIError.badResponseCode
        }
        
        let decoder = JSONDecoder()
        
        if let decodedPrestages = try? decoder.decode(PreStagesResponse.self, from: data) {

            self.allPrestages = decodedPrestages.results
            self.allPsComplete = true
            
        }
    }
    
    
    
    // #######################################################################################
    // GET ALL DEVICES' PRESTAGE SCOPE - For: PrestageScopeView
    // #######################################################################################
    // Function to show which prestage each individual device is assigned to - using serial number and id of prestage
    
    func getAllDevicesPrestageScope(server: String, prestageID: String, authToken: String) async throws {

//    func getAllDevicesPrestageScope(server: String, authToken: String, callback: @escaping () -> ()){
        
        self.allPsScComplete = false

        let jamfURLQuery = server + "/api/v2/computer-prestages/scope"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.timeoutIntervalForResource = 60.0
        
        separationLine()
        print("Running func: getAllDevicesPrestageScope")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - response is:\(response)")
            throw JamfAPIError.badResponseCode
        }
        
        let decoder = JSONDecoder()
        
        if let decodedPrestages = try? decoder.decode(DevicesAssignedToAPrestage.self, from: data) {

            self.serialPrestageAssignment = decodedPrestages.serialsByPrestageID
            self.allPsScComplete = true
            
        }
    }
    
    
    // #######################################################################################
    // GET DEVICES ASSIGNED TO SPECIFIC PRESTAGE
    // #######################################################################################
    // Function to get the devices assigned to the specitfied computer pre-stage, which is specified by id
    
    func getPrestageCurrentScope(jamfURL: String, prestageID: String, authToken: String) async throws {
        
        let jamfURLQuery = jamfURL + "/api/v2/computer-prestages/" + prestageID + "/scope"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        separationLine()
        print("Running:getPrestageCurrentScope for prestage id:\(prestageID)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - response is:\(response)")
            throw JamfAPIError.badResponseCode
        }
        
        let decoder = JSONDecoder()
        
        if let decodedPrestages = try? decoder.decode(ComputerPrestageCurrentScope.self, from: data) {
    
            self.depVersionLock = decodedPrestages.versionLock
            self.selectedPrestageScope = decodedPrestages
        }
    }

    // #######################################################################################
    // GET DEVICES ASSIGNED TO SPECIFIC PRESTAGE TO ADD DEVICE TO PRESTAGE
    // #######################################################################################
    // Function to get the devices assigned to the specitfied computer pre-stage in preparation for adding
    // This sets the property selectedPrestageScope to contain these pre-stages
    
// ##################################
// UNUSED
// ##################################
    func getPrestageCurrentScopeToAdd(jamfURL: String, prestageID: String, authToken: String) async throws {
        
        let jamfURLQuery = jamfURL + "/api/v2/computer-prestages/" + prestageID + "/scope"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        separationLine()
        print("Running:getPrestageCurrentScopeToAdd for prestage id:\(prestageID)")
        //        print("Get devices assigned to prestage id:\(prestageID)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - response is:\(response)")
            throw JamfAPIError.badResponseCode
        }
        
        let decoder = JSONDecoder()
        
        //        if let decodedPrestages = try? decoder.decode(ComputerPrestageCurrentScope.self, from: data) {
        if let decodedPrestages = try? decoder.decode(ComputerPrestageCurrentScope.self, from: data) {
            self.depVersionLock = decodedPrestages.versionLock
            self.selectedPrestageScope = decodedPrestages
            
            self.depVersionLock = decodedPrestages.versionLock
            print("depVersionLock is now set to:\(self.depVersionLock)")
            self.selectedPrestageScope = decodedPrestages
            
            
        }
    }
    
    // #######################################################################################
    // ADD DEVICE TO PRESTAGE
    // #######################################################################################
    

    func addDeviceToPrestage(server: String, prestageID: String, serial: String, authToken: String, depVersionLock: Int) async throws {

        let jamfURLQuery = server + "/api/v2/computer-prestages/" + prestageID + "/scope"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let json: [String: Any] = ["serialNumbers": [serial],
                                   "versionLock": depVersionLock]
        // ################################################
        //        TURN ON DEBUGGING
        // ################################################
        //        debugFunc(server: server, url: url, jamfURLQuery: jamfURLQuery, request: request, authToken: authToken)
        separationLine()
        print("Adding device to prestage:\(serial)")
        print("versionLock is:\(depVersionLock)")
        print("json is:\(json)")
        print("prestageID is:\(prestageID)")
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        if let jsonData = jsonData {
            request.httpBody = jsonData
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - response is:\(response)")
            throw JamfAPIError.badResponseCode
        }
    }
    
    
//  Function to remove the computer from a specified computer pre-stage

    func removeDeviceFromPrestage(server: String, removeComputerPrestageID: String, serial: String, authToken: String, depVersionLock: Int) async throws {
        
        let jamfURLQuery = server + "/api/v2/computer-prestages/" + removeComputerPrestageID + "/scope/delete-multiple"
        let url = URL(string: jamfURLQuery)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let json: [String: Any] = ["serialNumbers": [serial],
                                   "versionLock": depVersionLock]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        if let jsonData = jsonData {
            request.httpBody = jsonData
        }
        separationLine()
        print("Removing device:\(serial)")
        print("Removing from prestageID:\(removeComputerPrestageID)")
        print("versionLock is:\(depVersionLock)")
        print("json is:\(json)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200 - response is:\(response)")
            throw JamfAPIError.badResponseCode
        }
    }
    
// ##################################
// UNUSED
// ##################################
    func printAllPrestages() {
        separationLine()
        print("Running func: printAllPrestages")
        //        print("Printing all prestages:")
        //        for prestage in allPrestages {
        //            print("name: \(prestage.displayName)")
        //            print("id: \(prestage.id)")
        //        }
    }
    
// ##################################
// UNUSED
// ##################################
    func printSerialsByPrestageID() {
        separationLine()
        print("Running func: printSerialsByPrestageID")
        //        print("Printing all PrestagesAssignmentScope:")
        //        for (serial, id) in serialsByPrestageID {
        //            print("Serial: \(serial), prestageID: \(id)")
        //        }
    }
    
// ##################################
// UNUSED
// ##################################
    func printSpecificPrestage() {
        separationLine()
        print("Running: printSpecificPrestage")
    }
    
    func debugFunc(server: String, authToken: String, url: URL, jamfURLQuery: String, request: URLRequest) {
        separationLine()
        print("DEBUGGING ###########################")
        separationLine()
        print("server is:\(server)")
        print("username is:\(username)")
        print("jamfURLQuery is:\(jamfURLQuery)")
        print("url is:\(url)")
        print("request is:\(request)")
        separationLine()
        print("DEBUGGING END #######################")
        separationLine()
    }
}


