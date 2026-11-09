# Security and Privacy

## Privacy

- No network requests or network entitlements
- No analytics, telemetry, or advertising SDKs
- `PrivacyInfo.xcprivacy` declares no tracking and no collected data types
- Tasks live in the sandboxed Application Support directory for `app.dailytodo.macos`
- Older unsandboxed builds stored data in `~/Library/Application Support/DailyTodo/`; on launch the app migrates and merges that file into the sandbox container
- Task titles are plain local JSON — do not store passwords or tokens in tasks
- Directory permissions `0700`, file permissions `0600`
- Notifications include only the pending-task count

## Distribution

- This repo is source and CI only — never commit task data, certificates, `.env` files, or release ZIPs
- Release builds are produced by GitHub Actions from version tags
- Binaries are ad-hoc signed with App Sandbox and are not notarized
- Workflows use least-privilege permissions and the built-in `GITHUB_TOKEN`; no secrets are required for test, Pages, or source-built releases

## Reporting a vulnerability

Use **Report a vulnerability** under the repository **Security** tab. Do not open a public issue.
