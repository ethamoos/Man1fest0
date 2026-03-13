# Man1fest0 — Release Notes

This file summarizes changes between v1.52.2 and the current HEAD (v1.61.1).

Generated: 2026-03-13

---

## Release highlights (v1.52.2 → v1.61.1)

- Modernized API usage: introduced a flexible `RequestSender` capable of building requests for legacy `/JSSResource` endpoints and newer `/api/vN/` endpoints. Many network calls were converted to async/await for non-blocking behavior.
- Policy improvements: incremental policy detail loading, bounded concurrency, rate-limiting, and policy delay/preferences UI.
- Packages & Scripts: richer package listing and selection UX, multi-select and batch actions for scripts, Open in Browser shortcuts, and package/script detail/UI refinements.
- Security & platform: inactivity lock, secure lock screen, keychain integration, global security settings and inactivity monitor UI.
- UX & performance: onboarding/welcome screen, image/icon caching, list/table UI improvements, search & debounce helpers, and many small UX polish items.

---

## Per-version short summaries

### v1.52.3 (2026-01-28)
- Maintenance & usability fixes: searchable lists in Computer views, script removal bug fixes, small README revisions.

### v1.54 (2026-02-10)
- Security & reliability: inactivity lock, lock screen and keychain integration; token expiration handling and automatic refresh; bounded concurrency (AsyncSemaphore) and rate-limiting for detailed policy fetches.

### v1.54.1 (2026-02-16)
- Media performance: add image caching (CachedAsyncImage) for icon/detail views.

### v1.55 (2026-02-20)
- UX polish and tweaks; policy request delay default (0s) tuned for typical installs.

### v1.56.1 (2026-02-26)
- Packages & Scripts focus: table-style package lists, selection sync, sorting controls, multi-select packages for policy creation; scripts: batch download, batch delete, and improved save/download UX.

### v1.57 / v1.57.1 (2026-02-27 → 2026-03-02)
- Project / marketing version updates and continued package/script refinements.

### v1.58 / v1.58.1 (2026-03-06 → 2026-03-09)
- Policy detail UX overhaul: incremental policy loading and new policy detail views; policy delay preferences UI. Big onboarding and Welcome view improvements. Added Open-in-Browser shortcuts across several detail views.

### v1.59 (2026-03-11)
- Stability and data modeling: improved startup/inactivity flow, delay lock check and reset inactivity on launch; async category/department fetches added with models and previews.

### v1.60 / v1.60.1 (2026-03-13)
- Async API modernization: replaced legacy synchronous `connect()` patterns with `async` API methods; RequestSender updated to support different base URL patterns and additional headers.

### v1.61.1 (2026-03-13)
- Packages async fetch & polishing: `getAllPackages()` uses async RequestSender; added `getAllPackagesSend` wrapper for backward compatibility; version bump to `1.61.1`.

---

## Notable technical changes (developer summary)

- `RequestSender.swift`
  - Added `BaseURLPattern` support (.jssResource, .api(version:), .full(URL)) and `resultFor(...)` overload supporting `base:` and `headers:`.
  - Centralized URL construction and robust error mapping for common HTTP statuses.

- `NetBrain.swift`
  - Updated callers to use the new `RequestSender` where applicable (scripts, packages, categories, departments, etc.).
  - Added a thin wrapper `getAllPackagesSend(server:)` for backward compatibility.
  - Many network-related functions moved toward `async` flows.

- UI
  - Large set of UI changes across Views (Policies, Packages, Scripts, Groups, Welcome) with new components, refactors, and improved user flows.

- Security
  - Added `SecureAppWrapper` and `LockScreenView` assets, plus `InactivityMonitor` and `SecuritySettingsManager` files.

---

## Upgrade notes for integrators

- If you were calling legacy synchronous network helpers, prefer the new `async` methods exposed by `NetBrain` and `RequestSender`.
- When building custom requests with `RequestSender`, you can now control the base with `BaseURLPattern` and pass extra headers (for example `User-Agent`) when required.
- Backwards compatibility: `getAllPackagesSend(server:)` is available to match older method names; prefer `getAllPackages(server:)` to use the new RequestSender path.

---

## Suggested marketing blurb

Man1fest0 v1.61.1 — Faster, safer Jamf management for macOS

Delivering faster, more secure workflows, Man1fest0 v1.61.1 modernizes Jamf interactions with async API integrations, a refreshed onboarding experience, and advanced policy & package management tools. Highlights include non-blocking package/script fetching, incremental policy loading for large environments, secure lock screen and inactivity protection, and productivity-boosting UI improvements such as multi-select batch actions and Open in Browser shortcuts.

---

## Where to look for details

- Commit history between `v1.52.2` and current HEAD contains detailed messages; use `git log --oneline v1.52.2..HEAD` to inspect.
- Core files to review: `Classes/RequestSender.swift`, `Classes/NetBrain.swift`, `Views/Policy/*`, `Views/Packages/*`, `Views/Scripts/*`, and the new `Classes/Security/*` files.

-- End of release notes
