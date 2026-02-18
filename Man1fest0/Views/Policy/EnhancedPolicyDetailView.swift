import SwiftUI
import Foundation

// MARK: - Simple Policy Cache
@MainActor
class SimplePolicyCache: ObservableObject {
    
    // MARK: - Published Properties
    @Published var cache: [String: SimpleCachedPolicy] = [:]
    @Published var isLoading: Bool = false
    @Published var loadingProgress: Double = 0.0
    @Published var cacheHits: Int = 0
    @Published var totalRequests: Int = 0
    @Published var lastUpdated: Date?
    
    struct SimpleCachedPolicy {
        let policy: PoliciesDetailed
        let cachedAt: Date
        let lastAccessed: Date
        
        init(policy: PoliciesDetailed) {
            let now = Date()
            self.policy = policy
            self.cachedAt = now
            self.lastAccessed = now
        }
    }
    
    // MARK: - Cache Configuration
    private let maxCacheSize = 20
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    // MARK: - Cache Methods
    func getCachedPolicy(for policyID: String) -> PoliciesDetailed? {
        totalRequests += 1
        
        if var cachedPolicy = cache[policyID] {
            // Check if cache is still valid
            let timeSinceCached = Date().timeIntervalSince(cachedPolicy.cachedAt)
            if timeSinceCached < cacheExpirationTime {
                cachedPolicy.lastAccessed = Date()
                cache[policyID] = cachedPolicy
                cacheHits += 1
                print("🎯 Cache HIT for policy \(policyID)")
                return cachedPolicy.policy
            } else {
                // Remove expired cache entry
                cache.removeValue(forKey: policyID)
            }
        }
        
        print("💾 Cache MISS for policy \(policyID)")
        return nil
    }
    
    func setCachedPolicy(_ policy: PoliciesDetailed, for policyID: String) {
        let cachedPolicy = SimpleCachedPolicy(policy: policy)
        cache[policyID] = cachedPolicy
        lastUpdated = Date()
        
        // Enforce cache size limit
        if cache.count > maxCacheSize {
            let oldestKey = cache.min { $0.value.cachedAt < $1.value.cachedAt }?.key
            cache.removeValue(forKey: oldestKey)
            print("🗑️ Evicted oldest policy from cache: \(oldestKey)")
        }
        
        print("💾 Cached policy \(policyID)")
    }
    
    func getCacheInfo() -> String {
        let hitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) * 100 : 0.0
        return "Cache: \(cache.count)/\(maxCacheSize) | Hit Rate: \(Int(hitRate))% | Updated: \(lastUpdated?.description ?? "Never")"
    }
    
    func clearCache() {
        cache.removeAll()
        cacheHits = 0
        totalRequests = 0
        lastUpdated = nil
        print("🗑️ Cache cleared")
    }
}

// MARK: - Enhanced Policy Detail View
struct EnhancedPolicyDetailView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject var networkController: NetBrain
    @StateObject private var policyCacheManager = SimplePolicyCache()
    
    // MARK: - Properties
    let server: String
    var policy: Policy
    var policyID: Int
    @State private var currentlyViewedPolicyDetails: PoliciesDetailed?
    @State private var shouldUseIncrementalLoadingMode: Bool = false
    
    // MARK: - Initialization
    init(server: String, policy: Policy) {
        self.server = server
        self.policy = policy
        self.policyID = policy.jamfId
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Cache status bar
            cacheStatusBar
            
            // Main content
            policyContentSection
            
            // Loading overlay
            if cacheManager.isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            loadPolicyWithIncrementalLoading()
        }
        .refreshable {
            await performFullRefresh()
        }
    }
    
// MARK: - View Components
    private var cacheStatusDisplayBar: some View {
        HStack {
            Image(systemName: policyCacheManager.cachedPolicies.count > 0 ? "internaldrive.fill" : "externaldrive.connected.to.line")
                .foregroundColor(.blue)
            
            Text(policyCacheManager.getCacheStatisticsInformation())
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if policyCacheManager.cachedPolicies.count > 0 {
                Button("Clear Cache") {
                    policyCacheManager.clearAllCachedPolicies()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            Toggle("Incremental Loading", isOn: $shouldUseIncrementalLoadingMode)
                .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            Toggle("Incremental Loading", isOn: $isIncrementalLoading)
                .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
    
    private var policyContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Policy header
                policyHeaderSection
                
// Main policy details
                if let currentlyViewedPolicyDetails = currentlyViewedPolicyDetails {
                    policyDetailsSection(currentlyViewedPolicyDetails)
                } else {
                    // Loading skeleton
                    loadingSkeletonSection
                }
                
                // Cache statistics (for debugging)
                if policyCacheManager.totalPolicyRequests > 0 {
                    cacheStatisticsSection
                }
            }
            .padding()
        }
    }
    
    private var policyHeaderSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(policy.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    // Cache status
                    if let cachedPolicy = cacheManager.getCachedPolicy(for: String(policyID)) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Cached \(timeAgo(cachedPolicy.cachedAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "clock.circle")
                            .foregroundColor(.orange)
                        Text("Not cached")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Loading controls
                    if isIncrementalLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            
                            Text("Loading incrementally...")
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Progress bar for incremental loading
            if isIncrementalLoading && networkController.allPolicies.count > 0 {
                let progress = Double(networkController.allPoliciesDetailed.count) / Double(networkController.allPolicies.count)
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 3)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func policyDetailsSection(_ policy: PoliciesDetailed) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // Status indicator
            HStack {
                Image(systemName: policy.general.enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(policy.general.enabled ? .green : .red)
                Text(policy.general.enabled ? "Enabled" : "Disabled")
                    .fontWeight(.medium)
            }
            
            // Policy information
            detailRow(title: "Name", value: policy.general.name)
            detailRow(title: "Enabled", value: policy.general.enabled.description)
            
            if let trigger = policy.general.triggerOther {
                detailRow(title: "Trigger", value: trigger)
            }
            
            // Additional fields would go here
            // Scope, Self Service, Package Configuration, etc.
            
            Spacer()
        }
    }
    
    private var loadingSkeletonSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Status skeleton
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 20)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 20)
            }
            
            // Content skeletons
            ForEach(0..<4) { _ in
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 16)
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 16)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
    }
    
    private var detailRow: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .font(.caption)
                .frame(width: 100, alignment: .leading)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                if isIncrementalLoading {
                    Text("Loading policies incrementally...")
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .font(.headline)
                } else {
                    Text("Loading policy details...")
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .font(.headline)
                }
            }
        }
    }
    
    // MARK: - Loading Methods
    private func loadPolicyWithIncrementalLoading() {
        // First, try cache
        if let cachedPolicy = cacheManager.getCachedPolicy(for: String(policyID)) {
            currentDetailedPolicy = cachedPolicy
            return
        }
        
        guard isIncrementalLoading else {
            // Fallback to normal loading
            Task {
                await loadSinglePolicy()
            }
            return
        }
        
        // Incremental loading
        Task {
            await performIncrementalLoading()
        }
    }
    
    private func loadSinglePolicy() async {
        cacheManager.isLoading = true
        cacheManager.loadingProgress = 0.5
        
        do {
            await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: String(describing: policyID))
            currentDetailedPolicy = networkController.policyDetailed
            
            // Cache the loaded policy
            if let policy = networkController.policyDetailed {
                cacheManager.setCachedPolicy(policy, for: String(policyID))
            }
            
        } catch {
            print("Failed to load policy \(policyID): \(error)")
        }
        
        cacheManager.isLoading = false
        cacheManager.loadingProgress = 1.0
    }
    
    private func performIncrementalLoading() async {
        cacheManager.isLoading = true
        
        let allPolicies = networkController.allPolicies
        let currentPolicyIndex = allPolicies.firstIndex(where: { $0.jamfId == policyID })
        
        guard let startIndex = currentPolicyIndex else {
            await loadSinglePolicy()
            return
        }
        
        // Load in chunks around the current policy
        let loadRadius = 5 // Load 5 policies before and after current
        let start = max(0, startIndex - loadRadius)
        let end = min(allPolicies.count - 1, startIndex + loadRadius)
        
        print("🔄 Incremental loading: policies \(start)...\(end) around current policy \(policyID)")
        
        for i in start...end {
            let policy = allPolicies[i]
            let policyIDString = String(describing: policy.jamfId)
            
            // Check cache first
            if cacheManager.getCachedPolicy(for: policyIDString) == nil {
                do {
                    await networkController.getDetailedPolicy(server: server, authToken: networkController.authToken, policyID: policyIDString)
                    
                    // Cache loaded policy
                    if let detailedPolicy = networkController.policyDetailed {
                        cacheManager.setCachedPolicy(detailedPolicy, for: policyIDString)
                    }
                    
                    // Update progress
                    let progress = Double(i - start + 1) / Double(end - start + 1)
                    cacheManager.loadingProgress = progress
                    
                    // Check if this is our target policy
                    if policy.jamfId == policyID {
                        currentDetailedPolicy = networkController.policyDetailed
                    }
                    
                    // Small delay to show progress
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    
                } catch {
                    print("Failed to load policy \(policyIDString): \(error)")
                }
            } else {
                print("⚡ Cache hit for policy \(policyIDString)")
            }
        }
        
        cacheManager.isLoading = false
        cacheManager.loadingProgress = 1.0
        
        print("✅ Incremental loading completed. Cache size: \(cacheManager.cache.count)")
    }
    
    private func performFullRefresh() async {
        cacheManager.clearCache()
        await loadSinglePolicy()
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
struct EnhancedPolicyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedPolicyDetailView(
            server: "https://jamf.example.com",
            policy: Policy(jamfId: 123, name: "Test Policy", enabled: true)
        )
        .environmentObject(SimplePolicyCache())
        .preferredColorScheme(.dark)
    }
}