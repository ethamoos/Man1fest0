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
                        Text("DEBUG: Expanded content shown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack { Text("General Name:"); Text(generalName).foregroundColor(.primary) }
                        HStack { Text("Name:"); Text(generalName).foregroundColor(.primary) }
                        HStack { Text("General ID:"); Text(generalJamfIdString).foregroundColor(.primary) }
                        HStack { Text("Self Service Display Name:"); Text(selfServiceDisplayName).foregroundColor(.primary) }
                        HStack { Text("Self Service Icon URI:"); Text(selfServiceIconURI).foregroundColor(.primary) }
                    }
                    .padding(.leading, 18)
                    .padding(8)
                    .background(Color.yellow.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red.opacity(0.7), lineWidth: 1))
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
        let samplePolicy = PolicyDetailed(general: sampleGeneral, scope: nil, package_configuration: nil, scripts: nil, self_service: sampleSelfService)

        return Group {
            PolicyRowView(policy: samplePolicy)
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}

#endif
