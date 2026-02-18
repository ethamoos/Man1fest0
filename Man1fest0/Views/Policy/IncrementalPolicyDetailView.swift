import SwiftUI
import Foundation

// MARK: - Policy Cache Manager
@MainActor
class PolicyCacheManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var memoryCache: [String: PoliciesDetailed] = [:]
    @Published var diskCache: [String: Data] = [:]
    @Published var cacheMetadata: [String: CacheMetadata] = [:]
    @Published var isLoading: Bool = false
    @Published var loadingProgress: Double = 0.0
    @Published var loadingMessage: String = ""
    @Published var cacheHitRate: Double = 0.0
    @Published var totalRequests: Int = 0
    @Published var cacheHits: Int = 0
    
    // MARK: - Cache Metadata
    struct CacheMetadata {
        let cachedAt: Date
        let lastAccessed: Date
        let accessCount: Int
        let size: Int64
        
        init() {
            let now = Date()
            self.cachedAt = now
            self.lastAccessed = now
            self.accessCount = 1
            self.size = 0
        }
    }
    
    // MARK: - Cache Configuration
    private let maxMemoryItems = 50
    private let maxDiskItems = 200
    private let cacheExpirationTime: TimeInterval = 600 // 10 minutes
    
    // MARK: - Cache Management
    func getCachedPolicy(for policyID: String) -> PoliciesDetailed? {
        totalRequests += 1
        
        // Check memory cache first
        if var metadata = cacheMetadata[policyID] {
            metadata.lastAccessed = Date()
            metadata.accessCount += 1
            cacheMetadata[policyID] = metadata
            cacheHits += 1
            updateHitRate()
            return memoryCache[policyID]
        }
        
        // Check disk cache
        if let data = diskCache[policyID],
           let policy = try? JSONDecoder().decode(PoliciesDetailed.self, from: data) {
            var metadata = CacheMetadata()
            metadata.lastAccessed = Date()
            metadata.accessCount = 1
            cacheMetadata[policyID] = metadata
            cacheHits += 1
            updateHitRate()
            
            // Move to memory cache for faster access
            memoryCache[policyID] = policy
            return policy
        }
        
        return nil
    }
    
    func setCachedPolicy(_ policy: PoliciesDetailed, for policyID: String) {
        let metadata = CacheMetadata()
        metadata.size = estimateSize(policy)
        
        // Update memory cache
        memoryCache[policyID] = policy
        cacheMetadata[policyID] = metadata
        
        // Update disk cache for persistence
        if let data = try? JSONEncoder().encode(policy) {
            diskCache[policyID] = data
        }
        
        // Enforce cache limits
        enforceCacheLimits()
    }
    
    private func enforceCacheLimits() {
        // Remove oldest items if memory cache exceeds limit
        if memoryCache.count > maxMemoryItems {
            let sortedItems = cacheMetadata.sorted { $0.value.lastAccessed < $1.value.lastAccessed }
            let itemsToRemove = sortedItems.prefix(memoryCache.count - maxMemoryItems)
            
            for item in itemsToRemove {
                memoryCache.removeValue(forKey: item.key)
                diskCache.removeValue(forKey: item.key)
                cacheMetadata.removeValue(forKey: item.key)
            }
        }
    }
    
    private func updateHitRate() {
        cacheHitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) * 100 : 0.0
    }
    
    private func estimateSize(_ policy: PoliciesDetailed) -> Int64 {
        return 1024 // Rough estimate in bytes
    }
    
    func clearCache() {
        memoryCache.removeAll()
        diskCache.removeAll()
        cacheMetadata.removeAll()
        totalRequests = 0
        cacheHits = 0
        cacheHitRate = 0.0
    }
    
    func getCacheStatistics() -> CacheStats {
        return CacheStats(
            memoryCount: memoryCache.count,
            diskCount: diskCache.count,
            hitRate: cacheHitRate,
            totalRequests: totalRequests,
            totalHits: cacheHits
        )
    }
    
    struct CacheStats {
        let memoryCount: Int
        let diskCount: Int
        let hitRate: Double
        let totalRequests: Int
        let totalHits: Int
    }
}

// MARK: - Policy Preloader
@MainActor
class PolicyPreloader: ObservableObject {
    
    @Published var preloadingQueue: [String: Task<Void, Never>] = [:]
    @Published var preloadedPolicies: Set<String> = []
    private let prefetchRadius = 3
    private let maxConcurrentPreloads = 2
    
    func preloadAdjacent(to currentPolicyID: String, in policies: [Policy], cacheManager: PolicyCacheManager) {
        guard let currentIndex = policies.firstIndex(where: { $0.jamfId == Int(currentPolicyID) }) else { return }
        
        let start = max(0, currentIndex - prefetchRadius)
        let end = min(policies.count - 1, currentIndex + prefetchRadius)
        
        for i in start...end {
            let policyID = String(describing: policies[i].jamfId)
            
            // Skip if already cached or preloading
            if cacheManager.getCachedPolicy(for: policyID) != nil || preloadingQueue[policyID] != nil || preloadedPolicies.contains(policyID) {
                continue
            }
            
            // Limit concurrent preloads
            if preloadingQueue.count >= maxConcurrentPreloads {
                break
            }
            
            preloadingQueue[policyID] = Task {
                do {
                    let policy = try await fetchPolicyDetail(policyID: policyID)
                    await MainActor.run {
                        cacheManager.setCachedPolicy(policy, for: policyID)
                        preloadedPolicies.insert(policyID)
                    }
                } catch {
                    print("Failed to preload policy \(policyID): \(error)")
                }
            }
        }
    }
    
    private func fetchPolicyDetail(policyID: String) async throws -> PoliciesDetailed {
        // This would be implemented to fetch from network
        // For now, return a placeholder
        return PoliciesDetailed(
            general: PoliciesDetailed.General(name: "Preloaded Policy \(policyID)", enabled: true),
            // ... other fields
            scope: nil,
            selfService: nil,
            packageConfiguration: nil
        )
    }
}

// MARK: - Loading State Manager
@MainActor
class PolicyLoadingStateManager: ObservableObject {
    
    @Published var loadingState: LoadingState = .idle
    @Published var loadedPolicyIDs: Set<String> = []
    @Published var currentPolicyID: String = ""
    @Published var totalPolicies: Int = 0
    @Published var loadedPolicies: Int = 0
    
    enum LoadingState {
        case idle, loading, loaded, error(String)
        
        var isLoading: Bool {
            switch self {
            case .loading: return true
            default: return false
            }
        }
    }
    
    func startLoading(totalPolicies: Int, currentPolicyID: String) {
        self.totalPolicies = totalPolicies
        self.currentPolicyID = currentPolicyID
        self.loadedPolicyIDs.removeAll()
        self.loadedPolicies = 0
        self.loadingState = .loading
    }
    
    func addLoadedPolicy(_ policyID: String) {
        loadedPolicyIDs.insert(policyID)
        loadedPolicies += 1
        
        if loadedPolicies >= totalPolicies {
            loadingState = .loaded
        }
    }
    
    func setError(_ error: String) {
        loadingState = .error(error)
    }
    
    var loadingProgress: Double {
        guard totalPolicies > 0 else { return 0.0 }
        return Double(loadedPolicies) / Double(totalPolicies)
    }
}

// MARK: - Incremental Policy Detail View
struct IncrementalPolicyDetailView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var cacheManager: PolicyCacheManager
    @EnvironmentObject var preloader: PolicyPreloader
    @EnvironmentObject var loadingState: PolicyLoadingStateManager
    
    // MARK: - Properties
    let server: String
    var policy: Policy
    @State var policyID: String = ""
    @State private var currentDetailedPolicy: PoliciesDetailed?
    
    // MARK: - Initialization
    init(server: String, policy: Policy) {
        self.server = server
        self.policy = policy
        self.policyID = String(describing: policy.jamfId)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Main content
            policyContent
                .disabled(loadingState.loadingState.isLoading)
                .opacity(loadingState.loadingState.isLoading ? 0.6 : 1.0)
            
            // Loading overlay
            if loadingState.loadingState.isLoading {
                LoadingOverlay(
                    progress: loadingState.loadingProgress,
                    message: loadingState.loadingState.isLoading ? "Loading policies..." : loadingState.currentPolicyID == policyID ? "Updating current policy..." : "Loading policy details..."
                )
            }
        }
        .onAppear {
            loadPolicyIfNeeded()
        }
        .refreshable {
            await performRefresh()
        }
    }
    
    // MARK: - Policy Content
    private var policyContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Policy header with cache status
                policyHeaderSection
                
                // Main policy details
                if let detailedPolicy = currentDetailedPolicy {
                    policyDetailsSection(detailedPolicy)
                } else {
                    // Skeleton loader while data loads
                    PolicyDetailSkeleton()
                        .onAppear {
                            loadCurrentPolicy()
                        }
                }
                
                // Cache statistics (for debugging)
                if cacheManager.totalRequests > 0 {
                    cacheStatsSection
                }
            }
            .padding()
        }
    }
    
    // MARK: - View Sections
    private var policyHeaderSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(policy.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    // Cache status indicator
                    Image(systemName: cacheIndicatorIcon)
                        .foregroundColor(cacheIndicatorColor)
                    
                    Text(cacheStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Refresh button
                    Button(action: {
                        Task {
                            await loadCurrentPolicy()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                    }
                }
            }
            
            // Loading progress bar
            if loadingState.loadingState.isLoading && loadingState.totalPolicies > 0 {
                ProgressView(value: loadingState.loadingProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 2)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func policyDetailsSection(_ policy: PoliciesDetailed) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // Status section
            HStack {
                Image(systemName: policy.general.enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(policy.general.enabled ? .green : .red)
                Text(policy.general.enabled ? "Enabled" : "Disabled")
                    .fontWeight(.medium)
            }
            
            // General information
            detailRow(title: "Name", value: policy.general.name)
            detailRow(title: "Enabled", value: policy.general.enabled.description)
            
            // Other policy sections would go here
            // This is where you'd expand with the actual policy details
        }
    }
    
    private var cacheStatsSection: some View {
        let stats = cacheManager.getCacheStatistics()
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Cache Statistics")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                StatCard(title: "Memory Cache", value: "\(stats.memoryCount)", icon: "memorychip")
                StatCard(title: "Disk Cache", value: "\(stats.diskCount)", icon: "externaldrive")
                StatCard(title: "Hit Rate", value: "\(Int(stats.hitRate))%", icon: "speedometer")
                StatCard(title: "Total Requests", value: "\(stats.totalRequests)", icon: "arrow.up.arrow.down.circle")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var detailRow: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Computed Properties
    private var cacheIndicatorIcon: String {
        if let _ = cacheManager.getCachedPolicy(for: policyID) {
            return "checkmark.circle.fill"
        } else {
            return "clock.circle"
        }
    }
    
    private var cacheIndicatorColor: Color {
        if let _ = cacheManager.getCachedPolicy(for: policyID) {
            return .green
        } else {
            return .orange
        }
    }
    
    private var cacheStatusText: String {
        if let _ = cacheManager.getCachedPolicy(for: policyID) {
            let metadata = cacheManager.cacheMetadata[policyID] ?? CacheMetadata()
            return "Cached \(timeAgo(metadata.cachedAt))"
        } else {
            return "Not cached"
        }
    }
    
    // MARK: - Loading Methods
    private func loadPolicyIfNeeded() {
        // Check cache first
        if let cachedPolicy = cacheManager.getCachedPolicy(for: policyID) {
            currentDetailedPolicy = cachedPolicy
            return
        }
        
        // Load from network
        Task {
            await loadCurrentPolicy()
        }
    }
    
    private func loadCurrentPolicy() async {
        cacheManager.isLoading = true
        cacheManager.loadingProgress = 0.0
        cacheManager.loadingMessage = "Loading policy details..."
        
        do {
            // This would call the actual network request
            // For demonstration, we'll simulate loading
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            
            // Simulate getting policy data
            let mockPolicy = PoliciesDetailed(
                general: PoliciesDetailed.General(
                    name: policy.name,
                    enabled: true,
                    trigger: "Manual"
                ),
                scope: nil,
                selfService: nil,
                packageConfiguration: nil
            )
            
            await MainActor.run {
                currentDetailedPolicy = mockPolicy
                cacheManager.setCachedPolicy(mockPolicy, for: policyID)
                
                // Preload adjacent policies
                if let allPolicies = networkController.allPolicies {
                    preloader.preloadAdjacent(to: policyID, in: allPolicies, cacheManager: cacheManager)
                }
            }
            
        } catch {
            await MainActor.run {
                loadingState.setError("Failed to load policy: \(error.localizedDescription)")
            }
        }
        
        cacheManager.isLoading = false
        cacheManager.loadingProgress = 1.0
    }
    
    private func performRefresh() async {
        cacheManager.clearCache()
        await loadCurrentPolicy()
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views
struct LoadingOverlay: View {
    let progress: Double
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text(message)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .font(.headline)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct PolicyDetailSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Skeleton loading animation
            ForEach(0..<5) { _ in
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 16)
                        .shimmer(.active())
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 16)
                        .shimmer(.active())
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
    }
}

// MARK: - Shimmer Effect
extension View {
    func shimmer(_ active: Bool) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.4), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(active ? 45 : 0))
                .offset(x: active ? 200 : -200)
        )
    }
}

// MARK: - Preview
struct IncrementalPolicyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            IncrementalPolicyDetailView(
                server: "https://jamf.example.com",
                policy: Policy(jamfId: 123, name: "Test Policy", enabled: true)
            )
            .environmentObject(PolicyCacheManager())
            .environmentObject(PolicyPreloader())
            .environmentObject(PolicyLoadingStateManager())
            .preferredColorScheme(.dark)
        }
    }
}