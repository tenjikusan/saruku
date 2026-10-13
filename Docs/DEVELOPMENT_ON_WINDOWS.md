# Developing Native iOS Applications on Windows with Antigravity

This guide explains how to develop, maintain, and verify the native Swift/iOS codebase for **Waypoints** while working on a Windows workstation.

---

## 1. The Windows & Cloud macOS Synergy

While Apple does not distribute Xcode for Windows, you can write, refactor, and architect native Swift, SwiftUI, and iOS code on Windows, using cloud macOS runners for continuous compilation and device distribution:

```
[ Windows PC ]
  │
  ├─ Edit Swift & SwiftUI code using Antigravity
  ├─ Verify syntax, architectural contracts, and test specs
  ├─ Declarative XcodeGen configuration (`project.yml`)
  │
  └─ Git Push to GitHub (`main` or feature branch)
         │
         ▼
[ GitHub Actions Cloud macOS Runner (macOS 14 Sonoma) ]
  │
  ├─ Installs Xcode 15 / Xcode 16 & XcodeGen
  ├─ Generates `Waypoints.xcodeproj` from `project.yml`
  ├─ Runs `xcodebuild test` on iOS Simulator
  ├─ Codesigns with Apple Developer Certificate
  │
  └─ Uploads build to TestFlight or GitHub Releases
         │
         ▼
[ Your Physical iPhone ]
  │
  └─ Receives automatic TestFlight build notification
```

---

## 2. Project Generation with XcodeGen

Rather than checking binary or merge-conflict-prone `.xcodeproj` files into version control, Waypoints uses **XcodeGen**.
All target configurations, entitlements, frameworks, and source directories are declared in `project.yml`:

- When cloned on a Mac or CI runner:
  ```bash
  brew install xcodegen
  xcodegen generate
  ```
  This immediately produces a clean `Waypoints.xcodeproj` ready to compile.

---

## 3. Daily Workflow on Windows

1. **Making Code Changes**:
   - Write new views in `Waypoints/Views/`
   - Implement services in `Waypoints/Services/`
   - Write accompanying unit tests in `WaypointsTests/`

2. **Committing Changes**:
   ```powershell
   git status
   git add .
   git commit -m "Add feature or test"
   git push origin main
   ```

3. **Monitoring Builds**:
   - The GitHub Actions workflow in `.github/workflows/ios-build.yml` triggers immediately on push.
   - It runs all unit tests and reports pass/fail in under 3 minutes.
   - Any compiler issues or type mismatches are reported directly in the workflow logs.

4. **Testing on iPhone**:
   - Once ready for distribution, pushing a tag (e.g. `v1.0.0-build1`) triggers `.github/workflows/testflight-release.yml`.
   - The `.ipa` is uploaded to App Store Connect and appears in your TestFlight app.
