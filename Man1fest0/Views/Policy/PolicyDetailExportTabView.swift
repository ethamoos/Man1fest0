//
//  PolicyDetailExportTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 19/08/2025.
//


import SwiftUI

struct PolicyDetailExportTabView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var scopingController: ScopingBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    
    var server: String
    var selectedPoliciesInt: [Int?]
    
    //  ####################################################################################
    //  BOOLS
    //  ####################################################################################
    
    @State var status: Bool = true
    @State private var showingWarning = false
    @State private var showingWarningDelete = false
    
    @State var enableDisable: Bool = true
    @State private var showingWarningClearPackages = false
    @State private var showingWarningClearScripts = false
    //    @State private var showingWarningDelete = false
    
    //  ####################################################################################
    //    Category SELECTION
    //  ####################################################################################
    
    @State var categories: [Category] = []
    @State  var selectedCategory: Category = Category(jamfId: 0, name: "")
    
    
    var body: some View {
        
        VStack {
            
            //            Text("General").bold()
            
            //  ############################################################################
            //  Category
            //  ############################################################################
            
            LazyVGrid(columns: layout.columnsFlexMedium, spacing: 20) {
                
                HStack(spacing: 20) {
                    
                    //  ####################################################################
                    //              DOWNLOAD OPTION
                    //  ####################################################################
                    
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        for eachItem in selectedPoliciesInt {
                            
                            let currentPolicyID = (eachItem ?? 0)
                            
                            print("jamfId is \(String(describing: eachItem ?? 0))")
                            
                            ASyncFileDownloader.downloadFileAsyncAuth( objectID: currentPolicyID, resourceType: ResourceType.policies, server: server, authToken: networkController.authToken) { (path, error) in}
                        }
                        
                    }) {
                        Image(systemName: "plus.square.fill.on.square.fill")
                        Text("Download")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    
                    VStack {
                        
                        ShareLink(item:generateCSV()) {
                            Label("Export CSV", systemImage: "list.bullet.rectangle.portrait")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    }
                }
            }
        }
    }
    
    
    func generateCSV() -> URL {
        
        let myData: [General] =  networkController.allPoliciesDetailedGeneral
        
        
        var fileURL: URL!
        // heading of CSV file.
        let heading = "Name, Category, Status, ID, Trigger\n"
        
        // file rows
        let rows = myData.map { "\(String(describing: $0.name ?? "")),\($0.category!.name),\(String(describing: $0.enabled ?? false )),\($0.jamfId!),\($0.triggerOther!)" }
        
        // rows to string data
        let stringData = heading + rows.joined(separator: "\n")
        
        do {
            
            let path = try FileManager.default.url(for: .documentDirectory,
                                                   in: .allDomainsMask,
                                                   appropriateFor: nil,
                                                   create: false)
            
            fileURL = path.appendingPathComponent("Policy-Data.csv")
            
            // append string data to file
            try stringData.write(to: fileURL, atomically: true , encoding: .utf8)
            print(fileURL!)
            
        } catch {
            print("error generating csv file")
        }
        return fileURL
    }
    
}
