//
//  ErrorView.swift
//  Man1fest0
//
//  Created by Amos Deane on 04/03/2025.
//

import SwiftUI


struct ErrorView: View {
    
    @EnvironmentObject var networkController: NetBrain
    
var currentResponseCode: String
    var body: some View {
        Text("Error is:\(currentResponseCode) ")
    }
}
