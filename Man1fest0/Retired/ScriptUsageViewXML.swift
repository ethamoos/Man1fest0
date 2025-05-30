//
//  ScriptUsageView.swift
//  Manifesto
//
//  Created by Amos Deane on 15/10/2023.
//

import SwiftUI


import SwiftUI
import SWXMLHash



//class Item: Identifiable
//{
//    var name = ""
//    var category = ""
//}





struct ScriptUsageView: View {
    
    
    
    @EnvironmentObject var networkController: NetBrain
    
    @State var scripts: [Script] = []
    
    @State var path: String = ""
    @State var contents: String = ""
    
    @State private var showList = false
    @State var category = ""
    
    @State var items = [""]
    //    @State var allScriptsFound = [Item]()
    @State var readItems: String = ""
    
    @State private var selectedItem = ""
    @State var selectedFile = ""
    
    var openURL = ""
    
    @State var policyName = ""
    @State var policyID = ""
    @State var eachPolicy = ""
    @State var allPolicies = [""]
    
    @State var script_configuration = ""
    @State var policyScripts: [String: String] = [:]
    @State var allScriptsThisMac = ""
    @State var allScripts = [""]
    @State var allScriptsFound = [Item]()
    @State var allScriptsPolicy = ""
    
    @State var searchText = ""
    @State var selection = Set<Script>()
    
    
    
    var body: some View {
        
        
        
        VStack(alignment: .leading, spacing: 30) {
            
            Text("All Scripts In Use:\(allScriptsFound.count)")
                .fontWeight(.bold)
                .padding()
            
            if networkController.scripts.count > 0 {
                
                Text("Total Scripts in Jamf: \(networkController.scripts.count )")
                    .fontWeight(.bold)
                
                
                List(searchResults, id: \.self, selection: $selection) { script in
                        HStack {
                            Image(systemName: "applescript")
                            Text(script.name ).font(.system(size: 12.0))
                        }
//                    }
                }
                .navigationTitle("Scripts")
                .foregroundColor(.blue)

                
            }
            
            if allScriptsFound.count > 0 {
                @State var allScriptsNotUsed = allScripts.count - allScriptsFound.count
                Text("\(allScriptsNotUsed) Scripts are not in use")
                
                List(allScriptsFound) { eachItem in
                    HStack {
                        Image(systemName: "suitcase")
                        Text(eachItem.name)
                    }
                }
            }
            
            Text("Policies Containing Scripts:\(allScriptsFound.count)")
                .fontWeight(.bold)
            
            List {
                ForEach(policyScripts.sorted(by: >), id: \.key) { key, value in
                    Section(header: Text("Policy:\t\t\t\t\t\t\t\tScript").bold()) {

                        HStack {
                            Text(value)
//                            Text("\t\t\t")
                            Text(key)
                        }
                        .frame(width: 500, height: 100 , alignment: .leading)
                    }
                }
            }
            
        }
        .padding(.all)
        .frame(alignment: .leading)
        
        
        VStack() {
            
            Form {
                
                VStack {
                    Section {
                        HStack {
                            Text("Source Folder:")
                            Text(path)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.1))
                    
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                Color.black.opacity(0.4),
                                style: StrokeStyle()
                            )
                    )
                }
            }
            .padding()
            
            
            HStack {
                
                Button(action: {
                    let openURL = showOpenPanel()
                    print("openURL is:\(String(describing: openURL))")
                    if (openURL != nil) {
                        path = openURL!.path
                        //                    allScriptsFound.insert(path,at: 0)
                        selectedItem = path
                        self.showList.toggle()
                    }
                    
                }, label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Open")
                    }
                })
                .padding()
                
                
                Button(action: {
                    readFiles(selectedFolder: selectedItem)

                }) {
                    HStack() {
                        Image(systemName: "play")
                        Text("Process")
                    }
                }
            }
            .padding(.all)
            
            
        }.onAppear(){
            //            loadDataFileAuto()
            loadXMLDataFileScripts()
            //            loadXMLDataFileManual(selectedFile: selectedFile)
        }
        
    }
    
    var searchResults: [Script] {
        
        if searchText.isEmpty {
            networkController.separationLine()
            print("Search is empty")
            //            print(networkController.allScripts)
            return networkController.scripts
        } else {
            print("Search Added")
            //            print(networkController.allScripts)
            return networkController.scripts
            
            //          return networkController.allScripts.filter { $0.id.contains(searchText) }
            //            return networkController.allScripts.filter { $0.name?.contains(searchText) }
            //            return hand.filter({ (card: Card) -> Bool in return card.type == .Red })
        }
    }
    
    
    
    func loadXMLDataFileManual(selectedFile: String) {
        
        let url = URL(fileURLWithPath: selectedFile)
        
        do {
            let xmlData = try Data(contentsOf: url)
            
            if let feed = NSString(data: xmlData, encoding: String.Encoding.utf8.rawValue) as? String {
                
                let xml = XMLHash.parse(feed)
                
                eachPolicy = xml["policy"].element?.text ?? ""
                allPolicies.append(eachPolicy)
                policyName = xml["policy"]["general"]["name"].element?.text ?? ""
                policyID = xml["policy"]["general"]["id"].element!.text
                print("--------------------------------------------------------")
                //                    print("All policies are:\(allPolicies)")
                category = xml["policy"]["general"]["category"].element!.text
                allScriptsPolicy = xml["policy"]["scripts"].element!.text
                
                for elem in xml["policy"]["scripts"]["script"].all
                {
                    var item = Item()
                    item.name = elem["name"].element?.text ?? "blank"
                    allScriptsFound.append(item)
                    policyScripts.updateValue(policyName, forKey: item.name)
                }
            }
            
        } catch {
            print("Script failed with error: \(error)")
        }
    }
    
    func loadXMLDataFileScripts() {
        
        if let url = Bundle.main.url(forResource: "allScripts", withExtension: "xml") {
            
            //            let url = URL(fileURLWithPath: selectedFile)
            
            do {
                let xmlData = try Data(contentsOf: url)
                
                if let feed = NSString(data: xmlData, encoding: String.Encoding.utf8.rawValue) as? String {
                    
                    let xml = XMLHash.parse(feed)
                    
                    //                    allScripts = xml["scripts"]["script"]["scripts"].element!.text
                    
                    for elem in xml["scripts"]["script"].all
                    {
                        var item = Item()
                        item.name = elem["name"].element?.text ?? "blank"
                        allScripts.append(item.name)
                        print("Processing:\(item.name)")
                    }
                    
                    print("All scripts are:")
                    print(allScripts)
                }
                
            } catch {
                print("Script failed with error: \(error)")
            }
        } else {
            print("No XML file found")
        }
    }
    
    
    func readFiles(selectedFolder: String) {
        
        print("Running:readFiles")
        
        let path = selectedFolder
        
        print("path: \(path)")
        
        let enumerator = FileManager.default.enumerator(atPath: path)
        
        while let element = enumerator?.nextObject() as? String {
            
            print("Element is: \(element)")
            print("enumerator is: \(String(describing: enumerator))")
            
            let combinedPath = (path + "/" + element)
            print("Combined path is:\(combinedPath)")
            
            loadXMLDataFileManual(selectedFile: combinedPath)
            
            if let fileType = enumerator?.fileAttributes?[FileAttributeKey.type] as? FileAttributeType {
                
                switch fileType{
                case .typeRegular:
                    print("Is a file")
                case .typeDirectory:
                    print("Is a directory")
                default:
                    print("default")      }
            }
        }
    }
    
    func showOpenPanel() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.directory]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = true
        let response = openPanel.runModal()
        print("Response is:\(response)")
        return response == .OK ? openPanel.url : nil
    }
}






//        func loadDataFileAuto(){
//
//            if let url = Bundle.main.url(forResource: "Policy", withExtension: "xml") {
//                do {
//                    let xmlData = try Data(contentsOf: url)
//                    let feed = NSString(data: xmlData, encoding: String.Encoding.utf8.rawValue)! as String
//                    let xml = XMLHash.parse(feed)
//                    policyName = xml["policy"]["general"]["name"].element!.text
//                    policyID = xml["policy"]["general"]["id"].element!.text
//                    category = xml["policy"]["general"]["category"].element!.text
//                    allScripts = xml["policy"]["script_configuration"]["scripts"].element!.text
//
//                    for elem in xml["policy"]["script_configuration"]["scripts"]["script"].all
//                    {
//                        let item = Item()
//                        item.name = elem["name"].element?.text ?? "blank"
//                        allScriptsFound.append(item)
//                        policyScripts.updateValue(policyName, forKey: item.name)
//                        //                        policy.category = elem["category"].element!.text
//                    }
//
//                } catch {
//                    print("Script failed with error: \(error)")
//                }
//            }
//        }




//    func loadData(){
//        let url = NSURL(string: "https://www.nytimes.com/svc/collections/v1/publish/https://www.nytimes.com/section/world/rss.xml")
//
//        let task = URLSession.shared.dataTask(with: url! as URL) {(data, response, error) in
//            if data != nil
//            {
//                let feed=NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
//                let xml = SWXMLHash.parse(feed)
//
//                channelName = xml["rss"]["channel"]["title"].element!.text
//                channelURL = xml["rss"]["channel"]["link"].element!.text
//                imageURL = xml["rss"]["channel"]["image"]["url"].element!.text
//
//                for elem in xml["rss"]["channel"]["item"].all
//                {
//                    let item = Item()
//                    item.title = elem["title"].element!.text
//                    item.url = elem["link"].element!.text
//                    item.pubDate = cleanDate(date: elem["pubDate"].element!.text)
//                    newsItems.append(item)
//
//                    //Sort the news items by publication date
//                    newsItems = newsItems.sorted{$0.pubDate.compare($1.pubDate) == .orderedDescending}
//                }
//            }
//        }
//        task.resume()
//    }
//
