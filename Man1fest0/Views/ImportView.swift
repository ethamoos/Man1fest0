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
//    @State var myURLString = ""
    @State var stdout = ""
//    @State var scriptOutput = ""
    @State var showList = false
    @State var selectedItem = ""
//    @State var contents = ""

    var body: some View {
        
//        let importedString
        
        VStack {
   
            Text("File Contents")
//            Text(contents)
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
//                        contents = try String(contentsOfFile: path, encoding: .ascii)
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
