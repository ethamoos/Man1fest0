//
//  PolicySearchToolsView.swift
//  Man1fest0
//
//  Created by Amos Deane on 08/07/2026.
//


import SwiftUI

struct PolicySearchToolsView: View {
    
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var scopingController: ScopingBrain
    @EnvironmentObject var xmlController: XmlBrain
    @EnvironmentObject var progress: Progress
    @EnvironmentObject var layout: Layout
    
    var server: String
    var selectedPoliciesInt: [Int?]
    @Binding var policiesSelection: Set<Policy>
    @State var iconFilter = ""
    
    
    //  ####################################################################################
    //  BOOLS
    //  ####################################################################################
    
    @State var status: Bool = true
    @State private var showingWarning = false
    @State private var showingWarningDelete = false
    
    @State var enableDisable: Bool = true
    @State private var showingWarningClearPackages = false
    @State private var showingWarningClearScripts = false
    
    //  ####################################################################################
    //    Category SELECTION (use jamfId Int for Picker tags)
    //  ####################################################################################
    
    @State var categories: [Category] = []
    // Bind pickers to the stable integer jamfId to avoid UUID identity mismatches
    @State var selectedCategoryId: Int? = nil
    private var selectedCategory: Category? {
        networkController.categories.first(where: { $0.jamfId == selectedCategoryId })
    }
    
    //  ########################################################################################
    //  SELECTIONS
    //  ########################################################################################
    
    @State var computerGroupSelection = ComputerGroup(id: 0, name: "", isSmart: false)
    
    @State var iconMultiSelection = Set<String>()
    
    @State var selectedIconString = ""
    
    @State var selectedIcon: Icon? = nil
    
    //  ############################################################################
    //  Sort order
    //  ############################################################################
    
    
    @State private var sortOption: SortOption = .alphabetical
    
    enum SortOption: String, CaseIterable, Identifiable {
        case alphabetical = "Alphabetical"
        case reverseAlphabetical = "Reverse Alphabetical"
        
        var id: String { self.rawValue }
    }
    
    var sortedIcons: [Icon?] {
        switch sortOption {
        case .alphabetical:
            return networkController.allIconsDetailed.sorted { $0.name < $1.name }
        case .reverseAlphabetical:
            return networkController.allIconsDetailed.sorted { $0.name > $1.name}
        }
    }
    
    
    var body: some View {
        
        //  ############################################################################
        //  Category - update
        //  ############################################################################
        
        VStack(alignment: .leading) {
            
            Text("Tools")
            
            
            
//            }
            Spacer()
        }
        .padding()
    }
}
