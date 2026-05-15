Agent Guidelines — Working Practices

Purpose
-------
These guidelines are intended for automated agents and human reviewers who edit the repository. They describe preferred working practices for making safe, readable, and testable changes to this codebase.

High-level rules
----------------
- Make the smallest set of changes necessary to solve the task. Prefer incremental, well-scoped edits.
- Do not change unrelated files or reformat entire files unless explicitly requested.
- When in doubt, ask for clarification before making large structural changes.

Before changing code
--------------------
- Read the relevant files and follow symbols (types, global state, environment objects) to understand dependencies.
- Locate and examine any tests or helper utilities that exercise the paths you will modify.
- If a requested change affects UI, verify platform differences (macOS vs iOS) and adapt with #if os(macOS) where appropriate.

Making edits
------------
- Use the repo's patch tooling (apply_patch) and follow file-edit conventions:
  - Limit each apply_patch call to a single file.
  - Keep changes minimal and localized.
  - Use existing indentation and style.
- When adding helper functions keep them inside the appropriate scope (e.g., inside a View struct if they access @State), unless intentionally made global.
- Add import statements only when needed.

Safety checks after editing
--------------------------
- Run the repository-level error check (get_errors) for any files you modified.
- Fix any compile-time or obvious logical errors reported by the static checks before finishing.
- If you modify the UI or public API, search for other call sites that might be affected and update them as necessary.

Testing and validation
----------------------
- Where unit tests exist, run them after the edit; if no tests exist, run targeted checks (build the modified target if possible).
- For Swift UI views, prefer running small runtime tests or validating with preview where feasible.
- When adding networking behavior, ensure timeouts and error handling are present.

Network and external requests
-----------------------------
- When making HTTP probes or network checks, keep operations non-blocking and add appropriate timeout values.
- Avoid sending any credentials or tokens to third-party services; use the repo's networkController/authToken patterns when contacting the Jamf server.

User experience and progress
---------------------------
- Preserve existing UX patterns: progress indicators, disabling controls during async work, and lightweight feedback messages.
- Prefer non-blocking background tasks for network operations; use Task/async where appropriate.

Commit messages and PRs
-----------------------
- Use clear, one-line subject lines that summarize the change, followed by optional body lines for rationale.
- Reference issue/bug IDs if available.
- Keep each commit focused on one logical change.

Communication and confirmation
------------------------------
- If a change could alter behavior in production, mention it explicitly in the commit message / PR.
- When uncertain about semantics (e.g., whether Jamf reuses IDs), prefer conservative behavior and ask the repository owner.

Examples / Templates
---------------------
Change checklist (for each edit):
- [ ] Read related files and search for call sites
- [ ] Propose minimal patch
- [ ] Apply patch to one file per apply_patch
- [ ] Run get_errors on modified files
- [ ] Fix reported issues
- [ ] Run any relevant tests or manual checks
- [ ] Push and document changes

Pull request title template:
- Short: "<area>: <short description>"
- Body: "What changed, why, and any migration notes or follow-ups"

Contact and escalation
----------------------
- If making a change that could be destructive (delete data, change external APIs), stop and ask the repo owner before proceeding.

Notes for automated agents
--------------------------
- Prefer built-in helpers over ad-hoc parsing; e.g., use existing XmlBrain, NetBrain helpers rather than re-implementing network logic.
- Use the repo's conventions: Application Support for persistent data, EnvironmentObjects for controllers, and platform checks for UI.
- Always call get_errors on files you edited and fix errors locally; do not leave broken patches.

Naming, sensitive paths & ephemeral output
-----------------------------------------
- Use descriptive variable and identifier names. Avoid single-letter names except for very short-lived loop indices (e.g., `i`, `j`) where the meaning is obvious. Names should convey purpose (for example `packageId` rather than `p`, `policyName` rather than `n`).
- Do not include real external URLs, hostnames, or user-specific filesystem paths in repository files, code, or tools. Examples to avoid (do not include in repo files):
  - `https://myserv.jamfcloud.com`
  - `/Users/jsmith/JamfFolder/Files`

  Instead, use variables or environment variables. Examples:
  - Use environment variables in code/text: `/Users/$USER/` or `${HOME}`
  - Read precise paths from the user at runtime (prompt or config) and keep them only in memory during the session; do not persist them to files in the repository.

- If an agent needs to write an artifact summarizing "Next steps", as well as displaying it to the user also write the file to the user's Desktop with a timestamped filename and a very short description in the title. Use the user's locale-safe ISO-like timestamp to name the file so files are easily sorted. Example filename pattern:
  - `13-05-2026-17.20_agent_guidelines.txt`

  The content should be minimal and not include any secrets or absolute personal paths. Do not commit these Desktop artifacts to the repository. If persistence is required, request explicit permission and a secure storage location from the repo owner.

Revision history
----------------
- 2026-05-13 — Initial guidelines file created.


If you'd like, I can add this file to the repo now or adjust any of these rules to match your preferences (e.g., stricter verification of UI pages, different commit message style, or additional conventions).
