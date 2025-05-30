//
//  ReportsExport.swift
//  Man1fest0
//
//  Created by Amos Deane on 20/01/2025.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor

struct ReportsExport: View {
    
    var server: String { UserDefaults.standard.string(forKey: "server") ?? "" }
    var username: String { UserDefaults.standard.string(forKey: "username") ?? "" }
    var password = ""
    
    //    ########################################################################################
    //    EnvironmentObject
    //    ########################################################################################
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var backgroundTasks: BackgroundTasks
    
 // // @EnvironmentObject var controller: JamfController
    
    @EnvironmentObject var exportController: ImportExportBrain
    
    @EnvironmentObject var policyController: PolicyBrain
    
    @EnvironmentObject var scopingController: ScopingBrain
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var layout: Layout
    
    //    ########################################################################################
    
    @State private var sortOrder = [KeyPathComparator(\Policy.jamfId)]
    @State private var selection = Set<Policy.ID>()
    
    //    ########################################################################################
    //    Text exporting
    //    ########################################################################################
    
    @State private var exporting = false
    
    
    var body: some View {
        
        
        let text = String(describing: networkController.allPackages)
//        let document = TextDocument(text: text)
        
        Form {
            
            Group {
                
                if networkController.allPoliciesDetailed.count > 0 {
                    
                    VStack(alignment: .leading, spacing: 5) {
                        ShareLink("Export PDF", item: render())
                    }
                    .padding()
                    .border(.blue)
                }
            }
        }
    }
    
    func render() -> URL {
            
        let renderer = ImageRenderer(content:
                                        
                                        VStack(alignment: .leading, spacing: 5) {
            
            Text("Jamf server is:\t\t\t\t\t\t\(server)")
                .fontWeight(.bold)
            Divider()
            Text("Total policies in Jamf:\t\t\t\t\(networkController.allPoliciesConverted.count)")
                .fontWeight(.bold)
            Text("Policy records downloaded:\t\t\t\(networkController.allPoliciesDetailed.count)")
                .fontWeight(.bold)
            Divider()
            Text("Total Packages in Jamf:\t\t\t\t\(networkController.allPackages.count )")
                .fontWeight(.bold)
            Text("Packages in a policy:\t\t\t\t\t\(backgroundTasks.assignedPackagesByNameDict.count)")
                .fontWeight(.bold)
            Text("Packages not in a policy :\t\t\t\t\(backgroundTasks.unassignedPackagesArray.count)")
                .fontWeight(.bold)
            Divider()
            Text("Total Scripts in Jamf:\t\t\t\t\t\(networkController.scripts.count)")
                .fontWeight(.bold)
            Text("Scripts in a policy:\t\t\t\t\t\(policyController.assignedScriptsByNameDict.count)")
                .fontWeight(.bold)
            Text("Scripts not in a policy:\t\t\t\t\(policyController.unassignedScriptsArray.count)")
                .fontWeight(.bold)
            Divider()
            Text("Current date is:\t\t\t\t\t\t\(layout.date)")
                .fontWeight(.bold)
        }
                                     
        )
        
        // 2: Save it to our documents directory
        let url = URL.documentsDirectory.appending(path: "output.pdf")
        
        // 3: Start the rendering process
        renderer.render { size, context in
            // 4: Tell SwiftUI our PDF should be the same size as the views we're rendering
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            // 5: Create the CGContext for our PDF pages
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                return
            }
            
            // 6: Start a new PDF page
            pdf.beginPDFPage(nil)
            
            // 7: Render the SwiftUI view data onto the page
            context(pdf)
            
            // 8: End the page and close the file
            pdf.endPDFPage()
            pdf.closePDF()
        }
        return url
    }
}
