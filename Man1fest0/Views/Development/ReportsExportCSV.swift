//
//  ReportsExportCSV.swift
//  Man1fest0
//
//  Created by Amos Deane on 20/01/2025.
//

import SwiftUI

struct ReportsExportCSV: View {
    
    @EnvironmentObject var networkController: NetBrain

    var body: some View {
        
        VStack {
            ShareLink(item:generateCSV()) {
                Label("Export CSV", systemImage: "list.bullet.rectangle.portrait")
            }
        }
        .padding()
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
        print("Returning fileURL")
        return fileURL
    }
}

//struct MyData{
//    var day: String
//    var expense: Double
//}

//#Preview {
//    ContentView()
//}
