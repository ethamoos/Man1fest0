import SwiftUI

struct PolicyRowView: View {
    
    // Accept a non-optional policy — parent views should unwrap optionals before passing.
    let policy: PolicyDetailed

    // Feature flags (disabled by default) so you can try each enhancement without changing callers
    var showDebug: Bool = false
    var showIcon: Bool = false
    var showLink: Bool = false

    @State private var isExpanded: Bool = false
    @State private var isHovering: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                // Manual disclosure: use a Button so it's focusable and keyboard-activatable
                // Label (no nested Button) — tapping toggles expansion
                Button(action: {
                    withAnimation(.easeInOut) { isExpanded.toggle() }
                    print("PolicyRowView: toggled isExpanded=\(isExpanded) for policy=\(policy.general?.name ?? "<nil>")")
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .foregroundColor(.secondary)
                        Text(policy.general?.name ?? "Detail")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 2)
                    .background(isHovering ? Color.primary.opacity(0.08) : Color.clear)
                    .cornerRadius(6)
                }
                .buttonStyle(BorderlessButtonStyle())
                .contentShape(Rectangle())
                .focusable(true)
                .onHover { hovering in isHovering = hovering }
                .help("Click or press Space/Return to expand/collapse")
                // Accessibility: announce name and expanded/collapsed state
                .accessibilityLabel("Policy: \(policy.general?.name ?? "Detail")")
                .accessibilityHint("Press to expand or collapse policy details")
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
                .accessibilityAddTraits(.isButton)

//                if isExpanded {
//                    VStack(alignment: .leading, spacing: 8) {
//                        // Optional: show icon (AsyncImage) when feature enabled and uri present
//                        if showIcon, let uriString = policy.self_service.flatMap({ $0.selfServiceIcon.uri }), let url = URL(string: uriString) {
//                            HStack(alignment: .top, spacing: 12) {
//                                AsyncImage(url: url) { phase in
//                                    switch phase {
//                                    case .empty:
//                                        ProgressView()
//                                            .frame(width: 48, height: 48)
//                                    case .success(let image):
//                                        image
//                                            .resizable()
//                                            .scaledToFit()
//                                            .frame(width: 48, height: 48)
//                                            .cornerRadius(6)
//                                    case .failure:
//                                        Image(systemName: "photo")
//                                            .resizable()
//                                            .scaledToFit()
//                                            .frame(width: 48, height: 48)
//                                            .foregroundColor(.secondary)
//                                    @unknown default:
//                                        EmptyView()
//                                    }
//                                }
//                                VStack(alignment: .leading, spacing: 6) {
//                                    if showDebug {
//                                        Text("DEBUG: Expanded content shown")
//                                            .font(.caption)
//                                            .foregroundColor(.secondary)
//                                            .accessibilityHidden(false)
//                                    }
//                                    HStack { Text("General Name:"); Text(policy.general?.name ?? "").foregroundColor(.primary) }
//                                        .accessibilityElement()
//                                        .accessibilityLabel("General Name")
//                                        .accessibilityValue(policy.general?.name ?? "")
//
//                                    HStack { Text("Name:"); Text(policy.general?.name ?? "").foregroundColor(.primary) }
//                                        .accessibilityElement()
//                                        .accessibilityLabel("Name")
//                                        .accessibilityValue(policy.general?.name ?? "")
//
//                                    HStack { Text("General ID:"); Text(policy.general?.jamfId.map { "\($0)" } ?? "").foregroundColor(.primary) }
//                                        .accessibilityElement()
//                                        .accessibilityLabel("General ID")
//                                        .accessibilityValue(policy.general?.jamfId.map { "\($0)" } ?? "")
//
//                                    HStack { Text("Self Service Display Name:"); Text(policy.self_service?.selfServiceDisplayName ?? "").foregroundColor(.primary) }
//                                        .accessibilityElement()
//                                        .accessibilityLabel("Self Service Display Name")
//                                        .accessibilityValue(policy.self_service?.selfServiceDisplayName ?? "")
//
//                                    HStack {
//                                        Text("Self Service Icon URI:")
//                                        if showLink {
//                                            // use the local uriString (in-scope) and explicit Link initializer to avoid generic inference issues
//                                            Link(destination: url) {
//                                                Text(uriString)
//                                            }
//                                            .accessibilityLabel("Open Self Service Icon URL")
//                                        } else {
//                                            Text(policy.self_service.flatMap { $0.selfServiceIcon.uri } ?? "")
//                                                .foregroundColor(.primary)
//                                        }
//                                    }
//                                    .accessibilityElement()
//                                    .accessibilityLabel("Self Service Icon URI")
//                                    .accessibilityValue(policy.self_service.flatMap { $0.selfServiceIcon.uri } ?? "")
//                                }
//                            }
//                        } else {
//                            // Default layout when icon feature is not enabled or uri missing
//                            if showDebug {
//                                Text("DEBUG: Expanded content shown")
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
//                                    .accessibilityHidden(false)
//                            }
//                            HStack { Text("General Name:"); Text(policy.general?.name ?? "").foregroundColor(.primary) }
//                                .accessibilityElement()
//                                .accessibilityLabel("General Name")
//                                .accessibilityValue(policy.general?.name ?? "")
//
//                            HStack { Text("Name:"); Text(policy.general?.name ?? "").foregroundColor(.primary) }
//                                .accessibilityElement()
//                                .accessibilityLabel("Name")
//                                .accessibilityValue(policy.general?.name ?? "")
//
//                            HStack { Text("General ID:"); Text(policy.general?.jamfId.map { "\($0)" } ?? "").foregroundColor(.primary) }
//                                .accessibilityElement()
//                                .accessibilityLabel("General ID")
//                                .accessibilityValue(policy.general?.jamfId.map { "\($0)" } ?? "")
//
//                            HStack { Text("Self Service Display Name:"); Text(policy.self_service?.selfServiceDisplayName ?? "").foregroundColor(.primary) }
//                                .accessibilityElement()
//                                .accessibilityLabel("Self Service Display Name")
//                                .accessibilityValue(policy.self_service?.selfServiceDisplayName ?? "")
//
//                            HStack {
//                                Text("Self Service Icon URI:")
//                                if showLink, let uriString = policy.self_service.flatMap({ $0.selfServiceIcon.uri }), let url = URL(string: uriString) {
//                                    Link(destination: url) {
//                                        Text(uriString)
//                                    }
//                                    .accessibilityLabel("Open Self Service Icon URL")
//                                } else {
//                                    Text(policy.self_service.flatMap { $0.selfServiceIcon.uri } ?? "")
//                                        .foregroundColor(.primary)
//                                }
//                            }
//                            .accessibilityElement()
//                            .accessibilityLabel("Self Service Icon URI")
//                            .accessibilityValue(policy.self_service.flatMap { $0.selfServiceIcon.uri } ?? "")
//                        }
//                    }
//                    .padding(.leading, 18)
//                    .padding(8)
//                    .background(showDebug ? Color.yellow.opacity(0.06) : Color.clear)
//                    .overlay(showDebug ? RoundedRectangle(cornerRadius: 6).stroke(Color.red.opacity(0.7), lineWidth: 1) : nil)
//                    .fixedSize(horizontal: false, vertical: true)
//                    .layoutPriority(1)
//                }
            }
         }
         .padding(.vertical, 4)
     }
 }

// Small interactive demo so you can toggle each feature live in the Preview
struct PolicyRowFeatureDemo: View {
    @State private var showDebug = true
    @State private var showIcon = true
    @State private var showLink = true

    var body: some View {
        let sampleIcon = SelfService.SelfServiceIcon(filename: "icon.png", id: 1, uri: "https://developer.apple.com/assets/elements/icons/core-graphics/core-graphics-128x128_2x.png")
        let sampleSelfService = SelfService(useForSelfService: true,
                                           selfServiceDisplayName: "Sample Display",
                                           installButtonText: nil,
                                           reinstallButtonText: nil,
                                           selfServiceDescription: "",
                                           forceUsersToViewDescription: false,
                                           selfServiceIcon: sampleIcon)
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

        VStack(alignment: .leading, spacing: 12) {
            Form {
                Toggle("Show Debug Visuals", isOn: $showDebug)
                Toggle("Show Icon (AsyncImage)", isOn: $showIcon)
                Toggle("Make URI a Link", isOn: $showLink)
            }
            .frame(maxWidth: 420)

            Divider()

            PolicyRowView(policy: samplePolicy, showDebug: showDebug, showIcon: showIcon, showLink: showLink)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.windowBackgroundColor))
        }
        .padding()
    }
}

#if DEBUG
struct PolicyRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PolicyRowFeatureDemo()
                .previewLayout(.sizeThatFits)
                .frame(width: 600)

            // Also keep a simple preview of the default compact row
            let sampleIcon = SelfService.SelfServiceIcon(filename: "icon.png", id: 1, uri: "https://example.com/icon.png")
            let sampleSelfService = SelfService(useForSelfService: true,
                                               selfServiceDisplayName: "Sample Display",
                                               installButtonText: nil,
                                               reinstallButtonText: nil,
                                               selfServiceDescription: "",
                                               forceUsersToViewDescription: false,
                                               selfServiceIcon: sampleIcon)
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

            PolicyRowView(policy: samplePolicy)
                .previewDisplayName("Compact row (defaults)")
                .previewLayout(.sizeThatFits)
        }
    }
}
#endif
