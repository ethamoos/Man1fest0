//
//  Progress.swift
//  Man1fest0
//
//  Created by Amos Deane on 24/10/2023.
//

import Foundation
import SwiftUI

class Progress: ObservableObject {
    
    @Published var showProgressView: Bool = false
    @Published var showExtendedProgressView: Bool = false
    @Published var currentProgress = 0.0
    @Published var debugMode = false

    func separationLine() {
        print("------------------------------------------------")
    }
    
    func showProgress() {
        self.showProgressView = true
        separationLine()
        print("Setting showProgress to true")
        print(self.showProgressView)
    }
    
    func endProgress() {
        self.showProgressView = false
        separationLine()
        print("Setting showProgress to false")
        print(self.showProgressView)
    }
    
    func showExtendedProgress() {
        self.showExtendedProgressView = true
        separationLine()
        print("Setting showExtendedProgressView to true")
        print(self.showExtendedProgressView)
    }
    
    func endExtendedProgress() {
        self.showExtendedProgressView = false
        separationLine()
        print("Setting endExtendedProgress to false")
        print(self.endExtendedProgress)
    }
    
    func waitForABit() {
        DispatchQueue.main.async {
            Task {
                try await Task.sleep(nanoseconds: 4000000000)
                self.showProgressView = false
                print(self.showProgressView)
                print("Finished awaiting")
            }
        }
    }
    
    func waitForNotVeryLong() {
        
        DispatchQueue.main.async {
            Task {
                try await Task.sleep(nanoseconds: 1000000000)
                self.showProgressView = false
                print(self.showProgressView)
                print("Finished awaiting")
            }
        }
    }
    
    func showCustomAlert(alertTitle: String, alertMessage: String ) -> Alert {
        print("Running showCustomAlert ")
        return Alert(
            title: Text(alertTitle),
            message: Text(alertMessage),
            dismissButton: .default(Text("OK"))
        )
    }
}
