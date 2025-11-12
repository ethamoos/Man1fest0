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

        // New extracted properties
        let scripts = policy.scripts ?? []
        let packages = policy.package_configuration?.packages ?? []
        let scope = policy.scope
        let printers = policy.printers

        VStack(alignment: .leading, spacing: 6) {
            Group {
                // Manual disclosure: plain tappable label + explicit content
                // Label (no nested Button) — tapping toggles expansion
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(.secondary)
                    Text(generalName)
                        .font(.headline)
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
                        HStack { Text("General Name:"); Text(generalName).foregroundColor(.primary) }
                        HStack { Text("Name:"); Text(generalName).foregroundColor(.primary) }
                        HStack { Text("General ID:"); Text(generalJamfIdString).foregroundColor(.primary) }
                        HStack { Text("Self Service Display Name:"); Text(selfServiceDisplayName).foregroundColor(.primary) }
                        HStack { Text("Self Service Icon URI:"); Text(selfServiceIconURI).foregroundColor(.primary) }

                        // Scripts Disclosure
                        DisclosureGroup("Scripts (\(scripts.count))") {
                            if scripts.isEmpty {
                                Text("No scripts").foregroundColor(.secondary)
                            } else {
                                ForEach(scripts, id: \.id) { script in
                                    HStack {
                                        Text(script.name ?? "Unnamed script")
                                            .font(.subheadline)
                                        Spacer()
                                        if let jamfId = script.jamfId {
                                            Text("id: \(jamfId)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .padding(.top, 6)

                        // Packages Disclosure
                        DisclosureGroup("Packages (\(packages.count))") {
                            if packages.isEmpty {
                                Text("No packages").foregroundColor(.secondary)
                            } else {
                                ForEach(packages, id: \.id) { pkg in
                                    HStack {
                                        Text(pkg.name)
                                            .font(.subheadline)
                                        Spacer()
                                        Text("id: \(pkg.jamfId)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .padding(.top, 6)

                        // Scope Disclosure
                        DisclosureGroup("Scope") {
                            if scope == nil {
                                Text("No scope").foregroundColor(.secondary)
                            } else {
                                HStack { Text("All Computers:"); Text(scope?.allComputers.map { String($0) } ?? "?").foregroundColor(.primary) }
                                HStack { Text("Computers:"); Text("\(scope?.computers?.count ?? 0)").foregroundColor(.primary) }
                                HStack { Text("Computer Groups:"); Text("\(scope?.computerGroups?.count ?? 0)").foregroundColor(.primary) }
                                HStack { Text("Buildings:"); Text("\(scope?.buildings?.count ?? 0)").foregroundColor(.primary) }
                                HStack { Text("Departments:"); Text("\(scope?.departments?.count ?? 0)").foregroundColor(.primary) }
                                // Optionally list group names
                                if let groups = scope?.computerGroups, !groups.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Groups:").font(.caption)
                                        ForEach(groups, id: \.id) { g in
                                            Text(g.name ?? "Unnamed group")
                                                .font(.caption2)
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.top, 6)

                        // Printers Disclosure
                        DisclosureGroup("Printers") {
                            if printers == nil {
                                Text("No printers").foregroundColor(.secondary)
                            } else {
                                if let printer = printers?.printer {
                                    VStack(alignment: .leading) {
                                        Text(printer.name ?? "Unnamed printer").font(.subheadline)
                                        if let id = printer.jamfId { Text("id: \(id)").font(.caption).foregroundColor(.secondary) }
                                    }
                                } else {
                                    Text(String(describing: printers)).font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 6)

                    }
                    .padding(.leading, 18)
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                }
            }
         }
         .padding(.vertical, 4)
     }
 }

#if DEBUG
struct PolicyRowView_Previews: PreviewProvider {
    static var previews: some View {
        // Use the SelfService nested icon type to match the `SelfService` model's property type
        let sampleIcon = SelfService.SelfServiceIcon(filename: "icon.png", id: 1, uri: "https://example.com/icon.png")
        let sampleSelfService = SelfService(useForSelfService: true,
                                           selfServiceDisplayName: "Sample Display",
                                           installButtonText: nil,
                                           reinstallButtonText: nil,
                                           selfServiceDescription: "",
                                           forceUsersToViewDescription: false,
                                           selfServiceIcon: sampleIcon)
        // Provide the trigger boolean parameters (optional) required by the memberwise initializer
        let sampleGeneral = General(jamfId: 123,
                                    name: "Sample Policy",
                                    enabled: true,
                                    trigger: "manual",
                                    triggerCheckin: nil,
                                    triggerEnrollmentComplete: nil,
                                    triggerLogin: nil,
                                    triggerLogout: nil,
                                    triggerNetworkStateChanged: nil,
                                    triggerStartup: nil,
                                    triggerOther: nil,
                                    category: nil,
                                    mac_address: nil,
                                    ip_address: nil)

        // Build sample scripts / packages / scope / printers for preview
        let sampleScript = PolicyScripts(jamfId: 100, name: "set_time", priority: "After", parameter4: nil, parameter5: nil, parameter6: nil, parameter7: nil, parameter8: nil, parameter9: nil, parameter10: nil)
        let samplePolicyScriptsArray = [sampleScript]

        let samplePackage = Package(jamfId: 1207, name: "1Password_8.pkg", udid: nil)
        let samplePackageConfig = PackageConfiguration(packages: [samplePackage])

        let sampleGroup = ComputerGroups(jamfId: 379, name: "ABBA")
        let sampleScope = Scope(allComputers: false, all_jss_users: nil, computers: nil, computerGroups: [sampleGroup], buildings: nil, departments: nil, limitToUsers: nil, limitations: nil, exclusions: nil)

        let samplePrinterResult = Printers.Result(jamfId: 122, name: "Colour", makeDefault: false)
        let samplePrinters = Printers(any: nil, printer: samplePrinterResult)

        let samplePolicy = PolicyDetailed(general: sampleGeneral, scope: sampleScope, package_configuration: samplePackageConfig, scripts: samplePolicyScriptsArray, printers: samplePrinters, self_service: sampleSelfService)

        return Group {
            PolicyRowView(policy: samplePolicy)
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}

#endif
