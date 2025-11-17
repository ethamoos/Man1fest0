//
//  PolicyRowView.swift
//  Man1fest0
//
//  Created by Your Name on Date.
//
//  Compact row view for a policy that expands to show details and has a collapsible Scripts section.
//

import SwiftUI

// PolicyRowView: compact row that expands to show details and has a collapsible Scripts section.
struct PolicyRowView: View {
    let policy: PolicyDetailed

    @State private var isExpanded: Bool = false
    @State private var scriptsExpanded: Bool = false
    @State private var packagesExpanded: Bool = false

    private var generalName: String { policy.general?.name ?? "(no name)" }
    private var jamfID: Int { policy.general?.jamfId ?? 0 }
    private var enabledString: String { policy.general?.enabled.map { String(describing: $0) } ?? "-" }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Button(action: { withAnimation(.easeInOut) { isExpanded.toggle() } }) {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(.secondary)
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(PlainButtonStyle())

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
            .onTapGesture { withAnimation(.easeInOut) { isExpanded.toggle() } }

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    if let scope = policy.scope {
                        HStack(spacing: 8) {
                            if scope.allComputers == true { Text("Scope: All Computers").font(.caption).foregroundColor(.secondary) }
                            if scope.all_jss_users == true { Text("Scope: All JSS Users").font(.caption).foregroundColor(.secondary) }
                            if let comps = scope.computers, !comps.isEmpty { Text("Computers: \(comps.count)").font(.caption).foregroundColor(.secondary) }
                            if let groups = scope.computerGroups, !groups.isEmpty { Text("Groups: \(groups.count)").font(.caption).foregroundColor(.secondary) }
                        }
                    }

                    if let scripts = policy.scripts, !scripts.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Button(action: { withAnimation(.easeInOut) { scriptsExpanded.toggle() } }) {
                                    Image(systemName: "chevron.right")
                                        .rotationEffect(.degrees(scriptsExpanded ? 90 : 0))
                                        .foregroundColor(.secondary)
                                        .frame(width: 14, height: 14)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Text("Scripts (\(scripts.count))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()
                            }

                            if scriptsExpanded {
                                VStack(alignment: .leading, spacing: 4) {
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
                                .padding(.leading, 12)
                            }
                        }
                    }

                    // Packages subsection (collapsible) — uses package_configuration.packages
                    if let pkgs = policy.package_configuration?.packages, !pkgs.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Button(action: { withAnimation(.easeInOut) { packagesExpanded.toggle() } }) {
                                    Image(systemName: "chevron.right")
                                        .rotationEffect(.degrees(packagesExpanded ? 90 : 0))
                                        .foregroundColor(.secondary)
                                        .frame(width: 14, height: 14)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Text("Packages (\(pkgs.count))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()
                            }

                            if packagesExpanded {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(pkgs) { pkg in
                                        HStack(spacing: 8) {
                                            Text(pkg.name)
                                                .font(.caption2)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            Spacer()
                                            Text("id: \(pkg.jamfId)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.leading, 12)
                            }
                        }
                    }

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
