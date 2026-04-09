//
//  ComputerSearchesDetailView.swift
//  Man1fest0
//
//  Created by Amos Deane on 09/04/2026.
//

import SwiftUI

struct ComputerSearchesDetailView: View {
    
    var server: String
    var search: AdvancedComputerSearch
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var xmlController: XmlBrain
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Search Details")
                    .font(.title2)
                    .bold()
                
                Divider()
                
                HStack {
                    Text("Name:")
                        .bold()
                    Spacer()
                    Text(search.name)
                }
                
                HStack {
                    Text("ID:")
                        .bold()
                    Spacer()
                    Text(search.id)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("More details about this search can be viewed in the Jamf console.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
