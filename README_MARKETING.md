# Man1fest0 — Product Summary (Marketing)

Manifesto (Man1fest0) is a multi-purpose macOS utility for Jamf Pro administrators that accelerates large-scale policy, package and script management while enforcing a security-first workflow.

## Key Capabilities

### Mass Actions — bulk operations across many objects
- Move multiple devices, scripts or policies to a different category (e.g., Deprecated).
- Disable multiple devices, scripts or policies in a single action.
- Delete multiple devices, scripts or policies in bulk.
- One-step disable-and-move: disable selected objects and move them to a new category.
- Bulk-add packages to policies (multi-select packages when creating or editing policies).
- Batch script operations: multi-select scripts for batch download, batch delete, and batch save.
- Batch analysis helpers, e.g. find packages not referenced in any policies and clean them up.

### Individual Actions — single-object management
- Inspect and remove packages not used by any policies.
- Find scripts not referenced by policies and remove or archive them.
- Add a device to a static group.
- Disable a policy and move it to another category (e.g., deprecated).
- Create new policies and attach packages or scripts via an integrated UI.
- Manage prestages (create, edit, assign targets).
- View and edit detailed script and package metadata; inline editing of script names and content.
- Open Jamf web UI pages directly from resource views (Open in Browser).

## Modern Jamf API & Performance
- Compatible with both classic Jamf Pro API styles:
  - Legacy: `/JSSResource/...`
  - Modern REST: `/api/v1/...` and other `/api/vN/...` endpoints
- `RequestSender` supports flexible base URL patterns (.jssResource, .api(version:), .full(URL)) and optional headers.
- Major network fetches use Swift's `async/await` for responsive UI and safer concurrency.
- Bounded concurrency and rate-limiting (AsyncSemaphore) prevent overwhelming Jamf servers in large environments.
- Backwards-compatible wrappers (e.g., `getAllPackagesSend`) preserve older integration points.

## Security & Platform
- Secure lock screen with inactivity monitor to protect data when the admin steps away.
- Keychain integration for safer credential handling.
- Global security settings and a `SecureAppWrapper` for credential/lock flows.
- Jamf token expiration tracking and automatic refresh.

## User Experience & Admin Productivity
- Revamped Welcome/onboarding experience and clearer app headers and navigation.
- Incremental policy detail loading: fetch large policy details progressively to keep UI responsive.
- Policy delay preferences: configure delays for large policy requests to avoid server overload.
- Improved package and script UIs with sortable tables, selection synchronization across views, and unsorted/backup package views.
- Image/icon caching to speed detail screens and reduce repeated network requests.
- Debounced search fields and better list filtering for snappy UX.

## Developer & Integrator Notes
- Use `RequestSender` to build API calls with flexible base patterns and optional headers.
- `NetBrain` exposes async APIs across the codebase — prefer `async` callers when integrating.
- `getAllPackagesSend(server:)` and similar thin wrappers are present for backward compatibility.

---

## Suggested release blurb (short)

Man1fest0 streamlines Jamf Pro administration by combining safe large-scale mass actions with powerful single-object tools. With async Jamf API integrations, lock-screen security and keychain support, incremental policy loading for large fleets, and productivity-focused UI (multi-select batch actions and Open in Browser), Man1fest0 cuts admin time and increases confidence managing policies, packages and scripts.

## One-line tagline

Man1fest0 — faster Jamf Pro administration: secure, async, and built for large environments.

---

If you'd like this exported as HTML for your website, I can produce an `README_MARKETING.html` alongside this file (or a styled snippet you can copy into your site).
