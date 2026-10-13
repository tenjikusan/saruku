# Cloud iOS Compilation & TestFlight Distribution

This document details the CI/CD pipeline configured for compiling Waypoints on Apple silicon cloud runners without requiring a physical Mac.

---

## 1. Workflows Included in the Project

The repository contains two automated GitHub Actions workflows in `.github/workflows/`:

1. **`ios-build.yml` (Continuous Integration & Test Runner)**:
   - Triggers on every `push` and `pull_request` to `main`.
   - Runs on `macos-14` (Apple Silicon M2 runner).
   - Installs `xcodegen` via Homebrew.
   - Generates the Xcode project: `xcodegen generate`.
   - Runs unit tests and UI tests on `iPhone 15 (iOS 17.5)` simulator:
     ```bash
     xcodebuild test -scheme Waypoints -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
     ```
   - Verifies the compilation of both the main app target and the native `WaypointsShare` extension.

2. **`testflight-release.yml` (Automated TestFlight Deployment)**:
   - Triggers on version tags (e.g. `v1.*`).
   - Imports Apple Developer signing credentials and provisioning profiles from GitHub repository secrets.
   - Archives and exports the signed `.ipa`.
   - Uploads directly to App Store Connect / TestFlight via `xcrun altool` or Fastlane.

---

## 2. Secrets Configuration for TestFlight

To enable automated TestFlight distribution, add the following secrets to your GitHub repository (**Settings > Secrets and variables > Actions**):

| Secret Name | Description |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded Apple Distribution `.p12` certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Password for the `.p12` certificate |
| `PROVISIONING_PROFILE_APP_BASE64` | Base64-encoded mobileprovision profile for `com.waypoints.atlas` |
| `PROVISIONING_PROFILE_SHARE_BASE64` | Base64-encoded mobileprovision profile for `com.waypoints.atlas.ShareExtension` |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API Key ID (from Apple Developer account) |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect Issuer UUID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Contents of the `.p8` API key file |

---

## 3. Ad-Hoc / Direct iPhone Testing (Without Paid Apple Developer Account)

If you do not yet have a paid \$99/year Apple Developer account:
1. You can build and run unit tests on simulator runners for free using GitHub Actions.
2. The CI workflow generates an unsigned `.xcarchive` artifact.
3. Free personal signing allows installing on a tethered iPhone via AltStore, Sideloadly, or a colleague's Mac with Xcode using your free Apple ID.
