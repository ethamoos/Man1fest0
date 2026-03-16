# Release Marketing Mapping

This file maps marketing features called out in the product summary to concrete commits and files touched in the codebase (useful for engineering validation and release notes).

Generated: 2026-03-16

---

## API & RequestSender
- Commits:
  - 787a774 — Use API v1 scripts endpoint and update RequestSender (2026-03-13)
  - e89b451 — Improve error handling in RequestSender (2026-01-13)
  - 63d698e — Add API request and HTTP method models (2026-01-09)
- Key files:
  - `Man1fest0/Classes/RequestSender.swift`
  - `Man1fest0/Classes/NetBrain.swift`
  - Script & policy UIs updated to use the new RequestSender paths (see `Views/Scripts/*`, `Views/Policy/*`).

## Packages fetching & UI
- Commits:
  - 081dd1b — Use async getAllPackages() to fetch packages (2026-03-13)
  - 42cbde0 — Add 'Open in Browser' for package views (2026-03-06)
  - 7aea33d — Add unsorted Packages views and register in project (2026-02-27)
  - 0e7c6d6 / a5ea014 / 568d91c — Package list refactors, selection sync, multi-select in policy creation (Feb 26–27, 2026)
- Key files:
  - `Man1fest0/Views/Packages/PackagesView.swift`
  - `Man1fest0/Views/Packages/PackagesDetailView.swift`
  - `Man1fest0/Views/Create/CreatePolicyView.swift`
  - `Man1fest0/Classes/XmlBrain.swift` (package decode/handling)

## Scripts features & batch actions
- Commits:
  - 787a774 — Use API v1 scripts endpoint and update RequestSender (2026-03-13)
  - 3bc90c5 — Refactor ScriptUsageView layout and UI (2026-02-25)
  - 909c9e2 — Add batch download button for scripts (2026-02-25)
  - fe09c78 — Add multi-select UI and batch delete for scripts (2026-02-25)
  - 659e7fb — Add local save for scripts and update save flow (2026-02-24)
- Key files:
  - `Man1fest0/Views/Scripts/ScriptUsageView.swift`
  - `Man1fest0/Views/Scripts/ScriptDetailTableView.swift`
  - `Man1fest0/Views/Scripts/ScriptsView.swift`
  - `Man1fest0/Classes/NetBrain.swift` (script fetches)

## Security, Lock Screen & Inactivity
- Commits:
  - 27f6a2a — Add inactivity lock, keychain & lock screen (2026-02-10)
  - d75e6ff / dbfabdb / d8c3437 — Add global security settings, inactivity monitor, restore lockscreen files (Mar 2026)
  - f23d0cc — Delay lock check and reset inactivity on launch (2026-03-11)
- Key files:
  - `Man1fest0/Classes/Security/InactivityMonitor.swift`
  - `Man1fest0/Views/Security/LockScreenView.swift`
  - `Man1fest0/Views/Security/SecureAppWrapper.swift`
  - `Man1fest0/Classes/Security/SecuritySettingsManager.swift`

## Concurrency, rate limiting & policy loading
- Commits:
  - 01f835c — Add AsyncSemaphore and bounded policy fetching (2026-02-10)
  - 0fab453 — Add incremental policy loading and cache views (2026-02-12)
  - 60a3592 — Bounded concurrency and rate-limited policy fetch (2026-02-10)
- Key files:
  - `Man1fest0/Classes/NetBrain.swift`
  - `Man1fest0/Classes/XmlBrain.swift`
  - Files under `Views/Policy/*` for incremental loading UI

## Welcome / Onboarding & UX
- Commits:
  - c0af232 — Add WelcomeToMan1fest0 onboarding view (2026-02-13)
  - 713926e — Show welcome screen conditionally; widen sidebar (2026-02-13)
  - a491e03 — Inline subfeatures and add export/report button (2026-02-16)
- Key files:
  - `Man1fest0/Views/Welcome/WelcomeToMan1fest0.swift`
  - `Man1fest0/Views/Shared/*` and various layout files

## Image caching & UI performance
- Commits:
  - 6b152ee — Add CachedAsyncImage and integrate in IconDetailedView (2026-03-04)
- Key files:
  - `Man1fest0/Views/Shared/CachedAsyncImage.swift`
  - `Man1fest0/Views/Structures/IconDetailedView.swift`

## Search, debounce & helpers
- Commits:
  - 3e0fb92 / dcf570f — Add Debouncer and debounce script search (2026-02-17)
- Key files:
  - `Man1fest0/Helpers/Debouncer.swift`

## Open-in-Browser shortcuts
- Commits:
  - 02dfe85 — Open script pages in browser and translate URLs (2026-02-06)
  - 1bc01e8 — Add Open in Browser button to Scripts view (2026-02-27)
  - 42cbde0 / 62e5143 / 291b9cb — Add Open in Browser to Package/Group/EA detail views (Mar 2026)
- Key files:
  - `Man1fest0/Classes/NetBrain+Translate.swift` (URL translation)
  - Various detail views under `Views/Scripts`, `Views/Packages`, `Views/Computers/Groups`

---

Notes:
- This mapping lists representative commits and the primary files changed for each feature area. Some features were developed incrementally across multiple commits; review the full commit range (`git log v1.52.2..HEAD`) for deeper traceability.
- If you want I can expand each feature's section with a short list of the top 3–5 commits (with short descriptions) that implemented the core parts of the feature.

---

Generated from repository history and filenames on: 2026-03-16
