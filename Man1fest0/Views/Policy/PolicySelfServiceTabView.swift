//
//  PolicySelfServiceTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 06/08/2025.
//

//
//  PolicySelfServiceTabView.swift
//  Man1fest0
//
//  Created by Amos Deane on 10/07/2024.
//

import SwiftUI
import AEXML

struct PolicySelfServiceTabView: View {
    
    var server: String
    var resourceType: ResourceType
    // Local snapshot to avoid following shared controller directly
    var localPolicyDetailed: PolicyDetailed? = nil
    
    //  #######u#################################################################################
    //    EnvironmentObject
    //  ########################################################################################
    
    @EnvironmentObject var networkController: NetBrain
    
    @EnvironmentObject var xmlController: XmlBrain
    
    @EnvironmentObject var progress: Progress
    
    @EnvironmentObject var layout: Layout
    
    @EnvironmentObject var scopingController: ScopingBrain
    
    @State private var selectedResourceType = ResourceType.policyDetail
    
    //  ########################################################################################
    //    Filters
    //  ########################################################################################
    
    @State var computerGroupFilter = ""
    
    @State var computerFilter = ""
    
    @State var iconFilter = ""
    
    //  ########################################################################################
    //    Policy
    //  ########################################################################################
    
    @State var policyName = ""
    
    var policyID: Int
    
    //  ########################################################################################
    //    SELECTIONS
    //  ########################################################################################
    
    //@Binding var computerGroupSelection: Set<ComputerGroup>
    
    @State private var selection: Package? = Package(jamfId: 0, name: "")
    
    @State var selectionComp: Computer = Computer(id: 0, name: "", jamfId: 0)
    
    @State var selectionCompGroup: ComputerGroup = ComputerGroup(id: 0, name: "", isSmart: false)
    
    @State  var selectionDepartment: Department = Department(jamfId: 0, name: "")
    
    @State  var selectionBuilding: Building = Building(id: 0, name: "")
    
    
    @State var selectedIcon: Icon? = nil
    
    @State var selectedIconList: Icon = Icon(id: 0, url: "", name: "")
    
    @State var iconMultiSelection = Set<String>()
    
    @State var selectedIconString = ""
    
    @State var newSelfServiceName = ""
    
    // Pan state for the horizontal icon strip
    @State private var iconStripOffset: CGFloat = 0
    @State private var iconStripStart: CGFloat = 0

    //  ########################################################################################
    //  LDAP
    //  ########################################################################################
    
    @State var ldapUserGroupName = ""
    
    @State var ldapUserGroupId = ""
    
    @State var ldapServerSelection: LDAPServer? = nil
    
    @State var ldapSearchCustomGroupSelection = LDAPCustomGroup(uuid: "", ldapServerID: 0, id: "", name: "", distinguishedName: "")
    
    @State var getDetailedPolicyHasRun = false
    
    @State var ldapSearch = ""
    
    @State var allComputersButton: Bool = true
    
    @State private var showingWarningDelete = false
    
    @State private var showingWarningClearScope = false
    
    @State private var showingWarningLimitScope = false
    
    @State private var showingWarningClearLimit = false

    // Show confirmation before downloading all icons (can take time)
    @State private var showingRefreshIconsWarning = false
    //  ########################################################################################
    
    var body: some View {
        
        ScrollView {
            
            VStack(alignment: .leading) {
                
     
                
                // ##########################################################################################
                //                        Icons
                // ##########################################################################################
                
                Divider()
                
                VStack(alignment: .leading) {
                    
                    HStack(spacing: 6) {
                        Text("Icons").bold()
                        Text("(")
                        Text(String(describing: networkController.allIconsDetailed.count)).font(.system(size: 12)).foregroundColor(.secondary)
                        Text(")")
                    }
                     
                     AsyncImage(url: URL(string: (localPolicyDetailed ?? networkController.policyDetailed)?.self_service?.selfServiceIcon?.uri ?? "")) { image in
                         image.resizable()
                     } placeholder: {
                         Color.red.opacity(0.1)
                     }
                     .frame(width: 50, height: 50)
                     .clipShape(.rect(cornerRadius: 25))
                    
#if os(macOS)
                    List(networkController.allIconsDetailed, selection: $selectedIcon) { icon in
                        HStack {
                            Image(systemName: "photo.circle")
                            Text(icon.name).font(.system(size: 12.0)).foregroundColor(.black)
                            AsyncImage(url: URL(string: icon.url)) { image in
                                image.resizable().frame(width: 15, height: 15)
                            } placeholder: {
                            }
                        }
                        .foregroundColor(.gray)
                        .listRowBackground(selectedIconString == icon.name
                                           ? Color.green.opacity(0.3)
                                           : Color.clear)
                        .tag(icon)
                    }
                    .cornerRadius(8)
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: 200, alignment: .leading)
#else
                    
                    List(networkController.allIconsDetailed) { icon in
                        HStack {
                            Image(systemName: "photo.circle")
                            Text(icon.name).font(.system(size: 12.0)).foregroundColor(.black)
                            AsyncImage(url: URL(string: icon.url)) { image in
                                image.resizable().frame(width: 15, height: 15)
                            } placeholder: {
                            }
                        }
                    }
#endif
                    //                                    .background(.gray)
                }
                
                // ##########################################################################################
                //                        Icons - picker
                // ##########################################################################################
                
                
                LazyVGrid(columns: layout.columns, spacing: 10) {
                    
                    // Single row: Filter | Icon strip (flexible, clipped) | Update | Refresh
                    HStack(alignment: .center, spacing: 8) {
                        TextField("Filter", text: $iconFilter)
                            .frame(minWidth: 140)
                            .padding(.trailing, 6)
                            .zIndex(2)
                        
                        // Icon strip occupies flexible middle space and will be clipped so it can't draw under the buttons
                        GeometryReader { geom in
                            let icons = networkController.allIconsDetailed.filter { iconFilter.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(iconFilter) }
                            // Larger icons and spacing for visibility
                            let iconSize: CGFloat = 36
                            let spacing: CGFloat = 10
                            let horizontalPadding: CGFloat = 8
                            let contentWidth = CGFloat(max(icons.count, 0)) * (iconSize + spacing) + horizontalPadding * 2
                            
                            HStack {
                                ZStack(alignment: .leading) {
                                    if icons.isEmpty {
                                        // Placeholder when no icons are available
                                        HStack {
                                            Text(networkController.allIconsDetailed.isEmpty ? "No icons" : "No matches")
                                                .foregroundColor(.secondary)
                                                .font(.system(size: 12))
                                        }
                                        .frame(height: 44)
                                    } else {
                                        HStack(spacing: spacing) {
                                            ForEach(icons) { icon in
                                                AsyncImage(url: URL(string: icon.url)) { phase in
                                                    switch phase {
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                            .transition(.opacity)
                                                    case .failure(_):
                                                        // Visible placeholder when image fails
                                                        Image(systemName: "photo.fill")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .foregroundColor(Color.secondary)
                                                    default:
                                                        ProgressView()
                                                    }
                                                }
                                                .frame(width: iconSize, height: iconSize)
                                                .background(Color.clear)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(selectedIcon?.id == icon.id ? Color.accentColor : Color.clear, lineWidth: 2))
                                                .onTapGesture { selectedIcon = icon; selectedIconString = icon.name }
                                                .help(icon.name)
                                            }
                                        }
                                        .padding(.horizontal, horizontalPadding)
                                        .frame(width: contentWidth, alignment: .leading)
                                        .offset(x: iconStripOffset)
                                        .gesture(DragGesture(minimumDistance: 8)
                                            .onChanged { value in
                                                let minOffset = min(0, geom.size.width - contentWidth)
                                                let newOffset = iconStripStart + value.translation.width
                                                iconStripOffset = max(min(newOffset, 0), minOffset)
                                            }
                                            .onEnded { _ in
                                                let minOffset = min(0, geom.size.width - contentWidth)
                                                iconStripStart = iconStripOffset
                                                if iconStripStart > 0 { iconStripStart = 0 }
                                                if iconStripStart < minOffset { iconStripStart = minOffset }
                                            }
                                        )
                                    }
                                }
                                // Constrain this strip to the GeometryReader width so content overflows are clipped
                                .frame(width: geom.size.width, height: 52)
                                .clipped()
                                // Stronger background + border to improve visibility
                                .background(Color(NSColor.controlBackgroundColor))
                                .contentShape(Rectangle())
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.18)))
                                .padding(.leading, 6)
                                .zIndex(0)
                             }
                         }
                         .frame(maxWidth: .infinity)
                        
                        // Buttons on the right (compact icon buttons)
                        Button(action: {
                            progress.showProgress()
                            progress.waitForABit()
                            xmlController.updateIcon(server: server,authToken: networkController.authToken, policyID: String(describing: policyID), iconFilename: String(describing: selectedIcon?.name ?? ""), iconID: String(describing: selectedIcon?.id ?? 0), iconURI: String(describing: selectedIcon?.url ?? ""))
                        }) {
                            Image(systemName: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.blue)
                        .frame(width: 28, height: 24)
                         .help("Set the selected icon as the policy's Self Service icon.")
                         .zIndex(2)
                          
                        Button(action: { showingRefreshIconsWarning = true }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .frame(width: 28, height: 24)
                         .help("Download the latest icon set from the server (can take a long time).")
                        .alert("Warning", isPresented: $showingRefreshIconsWarning) {
                            Button("Proceed") {
                                progress.showProgress(); progress.waitForABit(); networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 20000)
                            }
                            Button("Cancel", role: .cancel) { }
                        } message: { Text("please note downloading all the icons can take some time") }
                        .zIndex(2)
                    }
                    // Keep icons selection and offset in a sane default when the icon list updates
                    .onChange(of: networkController.allIconsDetailed) { newIcons in
                        if selectedIcon == nil, let first = newIcons.first {
                            selectedIcon = first
                            selectedIconString = first.name
                        }
                        // Reset strip offset to show start of list
                        iconStripOffset = 0
                        iconStripStart = 0
                    }
                 }
                HStack {
                    Button(action: {
                        
                        progress.showProgress()
                        progress.waitForABit()
                        
                        networkController.enableSelfService(server: server, authToken: networkController.authToken, resourceType: selectedResourceType, itemID: policyID, selfServiceToggle: true)
                    }) {
                        Text("Enable Self-Service")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .help("Enable Self Service for this policy so it appears to users.")
//                    HStack {
                        TextField((localPolicyDetailed ?? networkController.policyDetailed)?.general?.name ?? policyName, text: $newSelfServiceName)
                            .textSelection(.enabled)
                        Button(action: {
                            
                            progress.showProgress()
                            progress.waitForABit()
                            networkController.updateSSName(server: server,authToken: networkController.authToken, resourceType: ResourceType.policyDetail, providedName: newSelfServiceName, policyID: String(describing: policyID))
                            
                            networkController.separationLine()
                            print("Name Self-Service to:\(newSelfServiceName)")
                        }) {
                            Text("Set Name")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .help("Set the Self Service display name for this policy.")
                }
            }
            .frame(minHeight: 1)
            .padding()
            
            
            
        }
        .onAppear{
            if networkController.allIconsDetailed.count <= 1 {
                print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
                Task {
                    networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 2000)
                }
            } else {
                print("getAllIconsDetailed has already run")
                print("getAllIconsDetailed is:\(networkController.allIconsDetailed.count) - running")
            }
        }
//        .onChange(of: networkController.allIconsDetailed) { newIcons in
//            // If no icon is currently selected, pick the first available icon so Picker has a valid selection
//            if selectedIcon == nil, let first = newIcons.first {
//                selectedIcon = first
//            }
//        }
//        .onChange(of: selectedIcon) { newSelection in
//            // Keep the string in sync for row highlighting and other uses
//            selectedIconString = newSelection?.name ?? ""
//        }
    }
}





//#Preview {
//    PolicyScopeTabView()
//}
