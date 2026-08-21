// MARK: - Best Practices for Descriptive Variable Names

## 🎯 **Why Descriptive Names Matter**

### **Benefits:**
- **Readability**: Code becomes self-documenting
- **Maintainability**: Easier to understand and modify
- **Debugging**: Clear purpose for each variable
- **Team Collaboration**: Faster onboarding for new developers
- **Code Reviews**: Fewer questions about implementation

## 🔍 **Examples of Good vs. Bad Naming**

### **❌ Bad Naming (What to Avoid)**
```swift
let a = 5                    // Single character, unclear purpose
let flag = true               // Generic, doesn't indicate what it's for
let temp = Date()             // "temp" is overused
let i = 0                      // Loop index variable with descriptive name
let data = String()             // Generic, unknown purpose
let isOK = false              // Boolean doesn't indicate what is OK
let arr = [String]()          // Abbreviation, unclear content type
```

### **✅ Good Naming (What to Do)**
```swift
let maximumRetryAttempts = 5                 // Clear: max retry count
let isUserAuthenticated = true               // Clear: authentication state
let policyLoadingStartTime = Date()          // Clear: when loading started
let cachedPolicyDetails = [String: PoliciesDetailed]() // Clear: what's stored
let selectedPolicyIdentifiers = Set<Int>()           // Clear: user selection
let currentIndex = 0                            // Acceptable: loop index
let networkRequestTimeoutInterval: TimeInterval = 30    // Clear: timeout duration
let isCacheRefreshInProgress = false               // Clear: background refresh state
```

## 📝 **Naming Conventions**

### **1. Boolean Variables**
```swift
// Prefix with `is`, `has`, `should`, `can`, `does`, `will`
let isUserLoggedIn = true           // ✅ State
let hasDataLoaded = false         // ✅ Possession
let shouldShowWarning = true        // ✅ Behavior
let canRetryOperation = false         // ✅ Capability
let willRefreshOnAppear = true     // ✅ Future action
let doesCacheDataLocally = true   // ✅ Behavior pattern
```

### **2. Numeric Variables**
```swift
// Use descriptive nouns and context
let maximumConcurrentDownloads = 3        // ✅ Limit description
let currentRetryAttemptCount = 1         // ✅ State tracking
let totalCacheMemoryUsage = 1024        // ✅ Measurement unit
let lastUpdatedTimestamp = Date()      // ✅ Time context
let preferredPageSize = 25                // ✅ User preference
let networkTimeoutDuration = 30          // ✅ Time duration
```

### **3. Collection Variables**
```swift
// Use plural nouns and indicate content type
let allCachedPolicyDetails = [String: PoliciesDetailed]()  // ✅ Clear content
let selectedPolicyIdentifiers = Set<Int>()           // ✅ Clear selection
let downloadedPackageNames = [String]()              // ✅ Clear purpose
let failedNetworkRequestURLs = [URL]()          // ✅ Error context
let visiblePolicyCategories = [Category]()           // ✅ UI state
let activeUserSessionTokens = [String]()           // ✅ Security context
```

### **4. Date/Time Variables**
```swift
// Use descriptive temporal context
let lastPolicyUpdateTime = Date()              // ✅ When updated
let cacheExpirationTimestamp = Date()             // ✅ When cache expires
let userSessionStartTime = Date()             // ✅ Session start
let nextRetryAttemptTime = Date()             // ✅ Next retry
let dataRefreshInterval = TimeInterval(300)   // ✅ Refresh frequency
let backgroundProcessingStartTime = Date()     // ✅ When background work started
```

### **5. Function/Method Names**
```swift
// Use verb-noun pattern, clear purpose
func validateUserCredentials()             // ✅ Clear purpose
func loadPolicyDetailsFromCache()          // ✅ Clear action
func refreshCachedPolicyData()             // ✅ Clear purpose
func calculateCacheHitRate()              // ✅ Clear calculation
func determinePolicyAccessLevel()          // ✅ Clear determination
func initiateBackgroundDataSync()           // ✅ Clear action
func handleNetworkRequestTimeout()          // ✅ Clear error handling
func checkIfCacheNeedsRefreshment()      // ✅ Clear condition checking
```

### **6. Class/Struct Names**
```swift
// Use descriptive, purposeful names
class PolicyCacheManager                  // ✅ Clear responsibility
class NetworkRequestCoordinator            // ✅ Clear coordination
class UserAuthenticationManager             // ✅ Clear responsibility
struct CacheStatistics                    // ✅ Clear data structure
struct PolicyLoadingState                 // ✅ Clear state machine
enum CacheRefreshStrategy                  // ✅ Clear options
```

## 🎨 **Real-World PolicyDetailView Example**

### **❌ Before (Hard to Read)**
```swift
struct PolicyDetailView: View {
    @State var a = 0.0
    @State var b = true
    @State var temp = Date()
    @State var i = 0
    @State var data = String()
    @State var isOK = false
    @State var arr = [String]()
    
    func doStuff() {
        for i in 0..<a {
            print("Processing \(i)")
        }
    }
}
```

### **✅ After (Self-Documenting)**
```swift
struct PolicyDetailView: View {
    @State var maximumRetryAttempts = 3
    @State var isUserAuthenticated = true
    @State var policyLoadingStartTime = Date()
    @State var cachedPolicyDetails = [String: PoliciesDetailed]()
    @State var currentIndex = 0
    @State var lastPolicyUpdateTime = Date()
    @State var willRefreshOnAppear = true
    
    private func processPolicyRequestBatch() {
        let batchSize = 10
        let endIndex = min(currentIndex + batchSize, cachedPolicyDetails.count)
        
        for batchIndex in currentIndex..<endIndex {
            print("Processing batch \(batchIndex) through \(endIndex - 1)")
            // Process each policy in batch
        }
    }
    
    private func refreshExpiredCacheEntries() {
        let expirationThreshold = Date().addingTimeInterval(-300) // 5 minutes ago
        
        for (policyID, cachedPolicy) in cachedPolicyDetails {
            if cachedPolicy.timestampWhenCached < expirationThreshold {
                cachedPolicyDetails.removeValue(forKey: policyID)
                print("Refreshed expired policy: \(policyID)")
            }
        }
        
        lastPolicyUpdateTime = Date()
    }
}
```

## 🎯 **Key Principles**

### **1. Be Explicit**
```swift
// ❌ Ambiguous
let flag = true

// ✅ Clear
let isUserSessionActive = true
let shouldShowAuthenticationWarning = false
let hasCompletedDataLoading = true
```

### **2. Use Full Words**
```swift
// ❌ Too abbreviated
let pol = Policy()
let cfg = Configuration()
let tmp = String()
let req = URLRequest()

// ✅ Descriptive
let currentPolicy = Policy()
let appConfiguration = Configuration()
let temporaryStorageDirectory = String()
let networkRequest = URLRequest()
```

### **3. Include Units When Appropriate**
```swift
// ❌ Generic time
let timeout = 30

// ✅ Clear duration
let networkRequestTimeoutSeconds = 30
let cacheExpirationDurationMinutes = 5
let backgroundProcessingIntervalSeconds = 60
let userSessionTimeoutMinutes = 15
```

### **4. Be Consistent**
```swift
// Choose one convention and stick to it
let lastUpdatedTimestamp = Date()      // ✅ Past tense, clear
let timeOfLastAccess = Date()       // ✅ Past tense, clear
let wasCacheUpdated = true           // ✅ Past tense, clear

// Avoid mixing
let lastUpdate = Date()              // ❌ Inconsistent
let accessTime = Date()             // ❌ Inconsistent
let updated = true                  // ❌ Inconsistent
```

## 📋 **Quick Reference Card**

### **Common Variable Names to Use**

#### **Boolean States**
- `isUserLoggedIn`, `isDataLoaded`, `isLoading`, `hasError`, `shouldShowWarning`
- `canEditPolicy`, `canDeletePolicy`, `canRefreshCache`
- `willDisplayDetails`, `willNavigateToNext`, `willRetryRequest`
- `doesSupportOfflineMode`, `hasBackgroundRefreshEnabled`, `isCacheValid`

#### **Numeric Values**
- `maximumRetryAttempts`, `currentRetryCount`, `totalItemsCount`
- `selectedPolicyID`, `currentPageIndex`, `itemsPerPage`
- `cacheSizeLimit`, `memoryUsageBytes`, `networkTimeoutSeconds`
- `processingProgressPercentage`, `completionPercentage`, `estimatedTimeRemaining`

#### **Collections**
- `allPolicyDetails`, `cachedPolicyItems`, `selectedPolicyIdentifiers`
- `failedRequestURLs`, `successfulRequestURLs`, `pendingOperations`
- `userPreferences`, `policyCategories`, `availablePackageNames`

#### **Time/Date**
- `lastUpdatedTimestamp`, `cacheExpirationTimestamp`, `sessionStartTime`
- `nextRetryAttemptTime`, `backgroundProcessingStartTime`, `lastAccessTimestamp`

#### **Functions/Methods**
- `loadPolicyDetailsFromCache`, `refreshExpiredCacheEntries`
- `validateUserAuthenticationCredentials`, `initiatePolicyUpdateProcess`
- `calculateCacheHitRate`, `determineCacheRefreshStrategy`
- `handleNetworkRequestFailure`, `processPolicyRequestBatch`

This approach makes your code **significantly more readable**, **easier to debug**, and **faster for team members** to understand and maintain! 🎯

---

## 🔁 **Overloads & Duplicated Function Bodies**

A subtle-but-costly class of bug in this codebase has come from having **two functions with the same name** that each contain their **own copy of the logic**. Over time the copies drift apart, and callers can't tell which one they're getting.

> **Real example:** there were two `getAllPolicies` functions — `getAllPolicies(server:)` and `getAllPolicies(server:authToken:)`. Only one of them set `self.policies`, so the toolbar **Refresh** button appeared to do nothing (the list is bound to `policies`), while navigating away and back — which called the *other* overload — worked. The two bodies had silently diverged.

### **✅ Rules of thumb**

**1. Prefer optional / default parameters over a second overload.**
```swift
// ❌ Two overloads, two copies of the body that can drift apart
func getAllPolicies(server: String) async throws { /* body A */ }
func getAllPolicies(server: String, authToken: String) async throws { /* body B */ }

// ✅ One implementation; the token is optional and falls back to self
func getAllPolicies(server: String, authToken: String? = nil) async throws {
    let token = authToken ?? self.authToken
    // ...single body...
}
```

**2. Never duplicate a body. If you must keep overloads, have one real implementation and let the others delegate to it.**
```swift
// ✅ Convenience overload delegates — no duplicated logic
func updateComputerUsername(from computerFull: ComputerFull, server: String, authToken: String) {
    updateComputerUsername(server: server, authToken: authToken,
                           computerID: computerFull.general.id,
                           newUsername: computerFull.general.username)
}
```

**3. Only overload when it's genuinely the *same operation* over different inputs** (e.g. a convenience wrapper, a generic variant, or a `Codable` conformance). Overloads are fine here — they give callers one memorable name.

**4. Give *distinct* names when the functions do *different things***. Sharing a verb by coincidence causes confusion.
```swift
// ❌ Same name, different behaviour — reader must open both to tell them apart
func connect(server: String, resourceType: ResourceType, authToken: String) // fetches a resource
func connect() async                                                          // establishes the session

// ✅ Intention-revealing names
func loadResource(server: String, resourceType: ResourceType, authToken: String)
func establishSession() async
```

### **🧭 When you spot duplicate function names**
- Confirm whether it's a **legitimate overload** (same operation, delegates to one body / protocol conformance / different type) or an **accidental duplicate** (two copies of the logic).
- For accidental duplicates: merge into a single implementation (optional params), update call sites, and comment out the loser with a dated note before deleting.
- Quick scan for same-named functions within a single file:
  ```bash
  grep -oE '^[[:space:]]*func[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' File.swift \
    | sed -E 's/^[[:space:]]*func[[:space:]]+//' | sort | uniq -d
  ```
