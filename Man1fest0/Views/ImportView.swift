//
//  ImportView.swift
//  Man1fest0
//
//  Created by Amos Deane on 30/01/2025.
//

import Foundation
import SwiftUI

struct ImportView: View {
    
    
    @EnvironmentObject var importExportBrain: ImportExportBrain

    var openURL = ""
    
    @State var path: String = ""
    @State var allItemsList = [""]
    
    @State var filename = ""
    @State var stdout = ""
    @State var showList = false
    @State var selectedItem = ""

    var body: some View {
        
        
        VStack {
   
            Text("File Contents")
            Text(importExportBrain.importedString)
            
            Button(action: {
                let openURL = importExportBrain.showOpenPanel()
                print("openURL is:\(String(describing: openURL?.path ?? ""))")
                if (openURL != nil) {
                    path = openURL!.path
                    allItemsList.insert(path,at: 0)
                    selectedItem = path
                    self.showList.toggle()
                    do {
                        importExportBrain.importedString = try String(contentsOfFile: path, encoding: .ascii)
                        print("Data imported")
                        print(importExportBrain.importedString)
                    }
                    catch let error {
                        print("Something went wrong: \(error)")
                    }
                }
            }, label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Import")
                }
            })
        }
    }
}
