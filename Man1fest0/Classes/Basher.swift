//
//  Man1fest0
//
//  Created by Amos Deane on 26/10/2023.
//

import Foundation

#if os(macOS)

class Basher: ObservableObject {
    

 
    
    @Published var scripts = [ "", "", "" ]
        
    @Published var selectedScript = ""
    
    @Published var scriptArgument = ""
    
    @Published var selectedScriptIndex = 0
    
    @Published var stdout = ""
    
    @Published var sterr: String = ""
    
    @Published var stdoutData = ""
    
    @Published var stderrData = ""
    
    @Published var arguments = [""]

    @Published var showProgressView: Bool = false
    
    @Published var scriptCompletedStatus = false

    
    func separationLine() {
        print("-----------------------------------")
    }
    
// ##################################
// UNUSED
// ##################################
    func runScript(filePath: String, argument1: String, argument2: String, argument3: String, scriptArgument: String) {
        
        self.showProgressView = true
        separationLine()
        print("Running runScript")
        print("Script: \(filePath)")
        print(showProgressView)
        
        let scriptPath = Bundle.main.path(forResource: filePath, ofType: "sh")
        let arguments = [ argument1, argument2, argument3, scriptArgument ]
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: scriptPath ?? "test.sh" )
        process.arguments = arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.launch()
        process.waitUntilExit()
        
        scriptCompletedStatus = true
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        separationLine()
        print("stderr is: \n\(stderr)")
        separationLine()
        print("End of script")
        separationLine()
        print("Turning off progress")
        self.showProgressView = false
        print(showProgressView)
        
    }
    
// ##################################
// UNUSED
// ##################################
    func resetView() {
        
        print("Reseting View")
        self.stdout = ""
        self.showProgressView = false
        print(showProgressView)
        
    }
    
    func showProgress() {
        
        self.showProgressView = true
        print("Showing progress")
        print(showProgressView)
        
    }
    
// ##################################
// UNUSED
// ##################################
    func hideProgress() {
        
        self.showProgressView = false
        print("Hiding progress")
        
    }
}

#endif
