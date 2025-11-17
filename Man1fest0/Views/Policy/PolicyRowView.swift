//
//  PolicyRowView.swift
//  Man1fest0
//
//  Created by jamf on 11/1/23.
//

import SwiftUI

// A compact, tappable policy row which expands to show extra details when tapped.
// This was accidentally overwritten with `PolicyListView` content; restore a focused, self-contained row view.

struct PolicyRowView: View {
    let policy: PolicyDetailed

    @State private var isExpanded: Bool = false

    // Convenience accessors
    private var generalName: String { policy.general?.name ?? "(no name)" }
    private var jamfID: Int { policy.general?.jamfId ?? 0 }
    private var enabledString: String {
        if let e = policy.general?.enabled { return String(describing: e) }
        return "-"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                // Chevron button — keep as a button so taps are intentional and accessible
                Button(action: {
                    withAnimation(.easeInOut) { isExpanded.toggle() }
                    print("PolicyRowView: toggled isExpanded=\(isExpanded) for policy=\(generalName)")
                }) {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(.secondary)
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(PlainButtonStyle())

                // Main title + meta
                VStack(alignment: .leading, spacing: 2) {
                    Text(generalName)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    HStack(spacing: 10) {
                        Text("id: \(jamfID)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Enabled: \(enabledString)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let ss = policy.self_service?.selfServiceDisplayName, !ss.isEmpty {
                            Text("Self Service: \(ss)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
            // Also allow tapping the whole header HStack to toggle expansion for convenience
            .onTapGesture {
                withAnimation(.easeInOut) { isExpanded.toggle() }
            }

            if isExpanded {
                // Expanded details — keep concise to avoid massive rows; callers can navigate to full detail view
                VStack(alignment: .leading, spacing: 6) {
                    // Note: `General` model doesn't include a `description` field. Prefer self-service description below.

                    // Show a compact scope summary if available
                    if let scope = policy.scope {
                        HStack(spacing: 8) {
                            if scope.allComputers == true { Text("Scope: All Computers").font(.caption).foregroundColor(.secondary) }
                            if scope.all_jss_users == true { Text("Scope: All JSS Users").font(.caption).foregroundColor(.secondary) }
                            if let comps = scope.computers, !comps.isEmpty { Text("Computers: \(comps.count)").font(.caption).foregroundColor(.secondary) }
                            if let groups = scope.computerGroups, !groups.isEmpty { Text("Groups: \(groups.count)").font(.caption).foregroundColor(.secondary) }
                        }
                    }

                    // Show scripts if present
                    if let scripts = policy.scripts, !scripts.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scripts (\(scripts.count))")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ForEach(scripts) { s in
                                HStack(spacing: 8) {
                                    Text(s.name ?? "(no name)")
                                        .font(.caption2)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Spacer()
                                    if let pri = s.priority, !pri.isEmpty {
                                        Text("Priority: \(pri)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    // Self-service description and icon URI (if present)
                    if let sdesc = policy.self_service?.selfServiceDescription, !sdesc.isEmpty {
                        Text(sdesc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let uri = policy.self_service?.selfServiceIcon?.uri, !uri.isEmpty {
                        Text("Icon: \(uri)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.leading, 26)
                .padding(.top, 6)
            }
        }
        .padding(.vertical, 8)
        .padding(.trailing)
        .background(Color.clear)
    }
}

// NOTE: preview provider intentionally omitted in the active project to avoid build noise
