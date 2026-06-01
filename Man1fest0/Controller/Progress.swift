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

    // Optional link to the global MessageStore so progress can show a persistent
    // message + spinner in the shared message area. This is set from the App init.
    weak var messageStore: MessageStore?

    func separationLine() {
        print("------------------------------------------------------------------")
    }
    
    func showProgress() {
        self.showProgressView = true
        separationLine()
        print("Setting showProgress to true")
        print(self.showProgressView)
        // If a global message store is available, show a spinner message there as well.
        messageStore?.show("Working…", level: .info, details: nil, showSpinner: true)
    }
    
    func endProgress() {
        self.showProgressView = false
        separationLine()
        print("Setting showProgress to false")
        print(self.showProgressView)
        // Hide the global message area spinner when progress ends
        messageStore?.hide()
    }
    
    func showExtendedProgress() {
        self.showExtendedProgressView = true
        separationLine()
        print("Setting showExtendedProgressView to true")
        print(self.showExtendedProgressView)
        messageStore?.show("Working…", level: .info, details: nil, showSpinner: true)
    }
    
    func endExtendedProgress() {
        self.showExtendedProgressView = false
        separationLine()
        print("Setting endExtendedProgress to false")
        print(self.endExtendedProgress)
        messageStore?.hide()
    }
    
    func waitForABit() {
        DispatchQueue.main.async {
            Task {
                try await Task.sleep(nanoseconds: 4000000000)
                self.showProgressView = false
                // Also hide the global message spinner
                self.messageStore?.hide()
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
                // Also hide the global message spinner
                self.messageStore?.hide()
                print(self.showProgressView)
                print("Finished awaiting")
            }
        }
    }

    // Called by the App initializer to connect the shared MessageStore
    func bindMessageStore(_ store: MessageStore) {
        self.messageStore = store
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
