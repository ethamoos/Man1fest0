//
//  CommandBrain.swift
//  Man1fest0
//
//  Created by Amos Deane on 04/09/2024.
//

import Foundation



//    #################################################################################
//    COMMANDS
//    #################################################################################
//
//    Button("Disable Bluetooth") {
//        print("I have been clicked off")
//        //            sendCommandBluetoothOff(id: computer.id)
//        sayHello(to: "Amos")
//
//    }
//    .frame(width: 200, height: 20, alignment: .leading )
//    .foregroundColor(.white)
//    .padding()
//    .background(Color.blue)
//    .cornerRadius(15)
//
//    Button("Enable Bluetooth") {
//        print("I have been clicked on")
//        //            sendCommandBluetoothOn(id: computer.id)
//        sayHello(to: "Amos")
//
//
//    }
//    .frame(width: 200, height: 20, alignment: .leading )
//    .foregroundColor(.white)
//    .padding()
//    .background(Color.blue)
//    .cornerRadius(15)
//    //        Spacer()
//
//
//
//    Button("Enable Remote Desktop") {
//        //            print("Sending command:EnableRemoteDesktop to device\(computer.id)")
//        //            sendCommandGeneric(id: computer.id, command: "EnableRemoteDesktop")
//
//    }
//    .frame(width: 200, height: 20, alignment: .leading )
//    .foregroundColor(.white)
//    .padding()
//    .background(Color.blue)
//    .cornerRadius(15)
//
//
//    Button("Disable Remote Desktop") {
//        //            print("Sending command:EnableRemoteDesktop to device\(computer.id)")
//        //            sendCommandGeneric(id: computer.id, command: "DisableRemoteDesktop")
//    }
//    .frame(width: 200, height: 20, alignment: .leading )
//    .foregroundColor(.white)
//    .padding()
//    .background(Color.blue)
//    .cornerRadius(15)
//
//    Button("Erase Device") {
//        //            print("Sending command:SettingsEnableBluetooth to device\(computer.id)")
//        //            sendCommandGeneric(id: computer.id, command: "SettingsDisableBluetooth")
//
//    }
//    .frame(width: 200, height: 20, alignment: .leading )
//    .foregroundColor(.white)
//    .padding()
//    .background(Color.red)
//    .cornerRadius(15)
//}

import Foundation
import SwiftUI
import AEXML


@MainActor class CommandBrain: ObservableObject {
    
    
    
    let product_name = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
    let product_version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    //    let buildString = "Version: \(appVersion ?? "").\(build ?? "")"
    
    //    #################################################################################
    //    ############ Login
    //    #################################################################################
    
    var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }
    var username: String { UserDefaults.standard.string(forKey: "username") ?? "" }
    
    //    #################################################################################
    //    ############ Login and Tokens Confirmations
    //    #################################################################################
    
    @Published var status: String = ""
    var tokenComplete: Bool = false
    var tokenStatusCode: Int = 0
    var authToken = ""
    var encoded = ""
    var initialDataLoaded = false
    
    //    #################################################################################
    //    Alerts
    @Published var showAlert = false
    var alertMessage = ""
    var alertTitle = ""
    var showActivity = false
    
    
    //    #################################################################################
    //    Error Codes
    //    #################################################################################
    
    @Published var currentResponseCode: String = ""
    
    func sendCommandGeneric (id: Int, command: String, authorisation: String, server: String )  {
        
        print("Sending MDM command:\(command) for id:\(id)")
        
        let semaphore = DispatchSemaphore (value: 0)
        
        let parameters = "<computer_command>\n\t<general>\n\t\t<command>\(command)</command>\n\t</general>\n\t<computers>\n\t\t<computer>\n\t\t\t<id>\(id)</id>\n\t\t</computer>\n\t</computers>\n</computer_command>"
        let postData = parameters.data(using: .utf8)
        var request = URLRequest(url: URL(string: "\(server)/JSSResource/computercommands/command/\(command)")!,timeoutInterval: Double.infinity)
        
        request.httpMethod = "POST"
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("application/xml", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let config = URLSessionConfiguration.default
        let authString = "Bearer \(self.authToken)"
        
        config.httpAdditionalHeaders = ["Authorization" : authString]
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                semaphore.signal()
                return
            }
            //            print("Returning data:")
            print(String(data: data, encoding: .utf8)!)
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
    }
    
}
