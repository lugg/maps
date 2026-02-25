# Agent Instructions

## General Rules

1. YOU MUST NOT do builds unless you are told to.
2. YOU MUST NOT commit changes yourself until I explicitly tell you to.
3. YOU MUST NOT create summary documents unless you are told to.
4. YOU MUST NOT add code comments that are obvious.
5. Always update relevant docs in `docs/` when making changes to components or APIs.

## Project Overview

React Native Fabric (New Architecture) maps library for iOS and Android.

- **Fabric** - No bridge, direct C++ communication
- **Codegen** - Auto-generates native interfaces from TypeScript specs

## File Structure

```
src/                 # TypeScript components & types
src/fabric/          # Native component specs (Codegen)
ios/                 # iOS native (Objective-C)
android/             # Android native (Kotlin)
plugin/              # Expo config plugin
example/bare/        # Bare React Native example app
```

### Creating a Pull Request

When creating a PR, use the template from `.github/PULL_REQUEST_TEMPLATE.md`:

1. **Summary** - Describe what the PR does and why
2. **Type of Change** - Select one: Bug fix, New feature, Breaking change, or Documentation update
3. **Test Plan** - Explain how the changes were tested
4. **Screenshots / Videos** - Include if applicable
5. **Checklist** - Mark platforms tested (iOS, Android, Web) and documentation updates
