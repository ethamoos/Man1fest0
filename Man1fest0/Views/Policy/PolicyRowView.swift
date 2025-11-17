import SwiftUI

struct PolicyRowView: View {
    
    // Accept a non-optional policy — parent views should unwrap optionals before passing.
    let policy: PolicyDetailed
    @State private var isExpanded: Bool = false
    @State private var isHovering: Bool = false

    var body: some View {
        // Hoist repeated optional lookups into local constants to simplify view code
        let generalName = policy.general?.name ?? "Detail"
        let generalJamfIdString = policy.general?.jamfId.map { "\($0)" } ?? ""
        let selfServiceDisplayName = policy.self_service?.selfServiceDisplayName ?? ""
        let selfServiceIconURI = policy.self_service?.selfServiceIcon?.uri ?? ""

        // --- Additional fields ---
        let enabledString: String = {
            if let enabled = policy.general?.enabled { return enabled ? "Enabled" : "Disabled" }
            return "Unknown"
        }()
        let triggerString = policy.general?.trigger ?? ""
        let categoryName = policy.general?.category?.name ?? ""
        let macAddress = policy.general?.mac_address ?? ""
        let ipAddress = policy.general?.ip_address ?? ""
        let packageCount = policy.package_configuration?.packages.count ?? 0
        let scriptsCount = policy.scripts?.count ?? 0
        let selfServiceDescription = policy.self_service?.selfServiceDescription ?? ""
        let selfServiceIconFilename = policy.self_service?.selfServiceIcon?.filename ?? ""
        let selfServiceIconID = policy.self_service?.selfServiceIcon?.id.map { "\($0)" } ?? ""

        // Scope summary: either All Computers or counts of different scope types
        let scopeSummary: String = {
            guard let s = policy.scope else { return "No scope" }
            if s.allComputers == true { return "Scope: All Computers" }

            var parts: [String] = []
            if let comps = s.computers, comps.count > 0 { parts.append("Computers: \(comps.count)") }
            if let groups = s.computerGroups, groups.count > 0 { parts.append("Computer Groups: \(groups.count)") }
            if let buildings = s.buildings, buildings.count > 0 { parts.append("Buildings: \(buildings.count)") }
            if let depts = s.departments, depts.count > 0 { parts.append("Departments: \(depts.count)") }
            if let lt = s.limitToUsers?.users, lt.count > 0 { parts.append("LimitToUsers: \(lt.count)") }
            if parts.isEmpty { return "Scope: (empty)" }
            return "Scope: " + parts.joined(separator: ", ")
        }()

        VStack(alignment: .leading, spacing: 6) {
            Group {
                // Manual disclosure: plain tappable label + explicit content
                // Label (no nested Button) — tapping toggles expansion
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(generalName)
                            .font(.headline)
                        // compact subtitle line showing a couple of summary properties
                        HStack(spacing: 8) {
                            if !enabledString.isEmpty { Text(enabledString).font(.caption).foregroundColor(.secondary) }
                            if !categoryName.isEmpty { Text("Category: \(categoryName)").font(.caption).foregroundColor(.secondary) }
                            if !triggerString.isEmpty { Text("Trigger: \(triggerString)").font(.caption).foregroundColor(.secondary) }
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 2)
                .background(isHovering ? Color.primary.opacity(0.08) : Color.clear)
                .cornerRadius(6)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut) { isExpanded.toggle() }
                    print("PolicyRowView: toggled isExpanded=\(isExpanded) for policy=\(generalName)")
                }
                .onHover { hovering in isHovering = hovering }
                .help("Click to expand/collapse")

                if isExpanded {
                    VStack(alignment: .leading, spacing: 6) {
//                        Text("DEBUG: Expanded content shown")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
                        HStack { Text("General Name:"); Text(generalName).foregroundColor(.primary) }
                        HStack { Text("General ID:"); Text(generalJamfIdString).foregroundColor(.primary) }
                        HStack { Text("Enabled:"); Text(enabledString).foregroundColor(.primary) }
                        HStack { Text("Trigger:"); Text(triggerString).foregroundColor(.primary) }
                        HStack { Text("Category:"); Text(categoryName).foregroundColor(.primary) }
                        HStack { Text("MAC Address:"); Text(macAddress).foregroundColor(.primary) }
                        HStack { Text("IP Address:"); Text(ipAddress).foregroundColor(.primary) }
                        HStack { Text("Package count:"); Text("\(packageCount)").foregroundColor(.primary) }
                        HStack { Text("Scripts count:"); Text("\(scriptsCount)").foregroundColor(.primary) }
                        HStack { Text("Self Service Display Name:"); Text(selfServiceDisplayName).foregroundColor(.primary) }
                        if !selfServiceDescription.isEmpty { HStack { Text("Self Service Description:"); Text(selfServiceDescription).foregroundColor(.primary) } }
                        HStack { Text("Self Service Icon:"); Text(selfServiceIconFilename).foregroundColor(.primary) }
                        if !selfServiceIconID.isEmpty { HStack { Text("Self Service Icon ID:"); Text(selfServiceIconID).foregroundColor(.primary) } }
                        HStack { Text("Self Service Icon URI:"); Text(selfServiceIconURI).foregroundColor(.primary) }

                        // Scope summary
                        HStack { Text(scopeSummary).foregroundColor(.secondary).font(.caption) }

                    }
                    .padding(.leading, 18)
                    .padding(8)
                    .background(Color.white.opacity(0.06))
//                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red.opacity(0.7), lineWidth: 1))
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                }
            }
         }
         .padding(.vertical, 4)
     }
 }

 #if DEBUG
 //struct PolicyRowView_Previews: PreviewProvider {
 //    static var previews: some View {
 //        // Use the SelfService nested icon type to match the `SelfService` model's property type
 //        let sampleIcon = SelfService.SelfServiceIcon(filename: "icon.png", id: 1, uri: "https://example.com/icon.png")
 //        let sampleSelfService = SelfService(useForSelfService: true,
 //                                           selfServiceDisplayName: "Sample Display",
 //                                           installButtonText: nil,
 //                                           reinstallButtonText: nil,
 //                                           selfServiceDescription: "",
 //                                           forceUsersToViewDescription: false,
 //                                           selfServiceIcon: sampleIcon)
 //        // Provide the trigger boolean parameters (optional) required by the memberwise initializer
 //        let sampleGeneral = General(jamfId: 123,
 //                                    name: "Sample Policy",
 //                                    enabled: true,
 //                                    trigger: "manual",
 //                                    triggerCheckin: nil,
 //                                    triggerEnrollmentComplete: nil,
 //                                    triggerLogin: nil,
 //                                    triggerLogout: nil,
 //                                    triggerNetworkStateChanged: nil,
 //                                    triggerStartup: nil,
 //                                    triggerOther: nil,
 //                                    category: nil,
 //                                    mac_address: nil,
 //                                    ip_address: nil)
 //        let samplePolicy = PolicyDetailed(general: sampleGeneral, scope: nil, package_configuration: nil, scripts: nil, self_service: sampleSelfService)
 //
 //        return Group {
 //            PolicyRowView(policy: samplePolicy)
 //                .padding()
 //                .previewLayout(.sizeThatFits)
 //        }
 //    }
 //}

 #endif
