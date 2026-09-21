# Agent Instructions

## General Rules

1. YOU MUST NOT do builds unless you are told to.
2. YOU MUST NOT commit changes yourself until I explicitly tell you to.
3. YOU MUST NOT create summary documents unless you are told to.
4. YOU MUST NOT add code comments that are obvious.
5. Always update relevant docs in `docs/content/docs/` (MDX) when making changes to components or APIs.

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
example/expo/        # Expo example app
example/shared/      # Screens and components shared by both example apps
skills/maps-usage/   # Consumer-facing AI skill (npx skills add lugg/maps)
docs/                # Documentation site (Next.js + Fumadocs), deployed to maps.lodev09.com
docs/content/docs/   # MDX documentation pages
```

### Updating the AI skill

`skills/maps-usage/` is the consumer-facing skill installed via `npx skills add lugg/maps`. Whenever `docs/content/docs/` changes (new prop, event, method, platform limitation, or pattern), update the skill to match in the same PR:

- `SKILL.md` - quick start, recipes, "Rules That Save Debugging Time", platform table
- `references/configuration.md` - setup snippets and props (mirror `installation.mdx`, `components/*.mdx`, `types.mdx`)
- `references/api.md` - ref methods, events, payload types
- `references/advanced-patterns.md` - patterns from `example/shared/`
- `references/troubleshooting.md` - symptom → cause → fix entries

The skill summarizes the docs and the source, it does not copy them. Keep entries terse and code-first. When docs and `src/` disagree, follow `src/` and fix the docs.

### Creating a Pull Request

When creating a PR, use the template from `.github/PULL_REQUEST_TEMPLATE.md`:

1. **Summary** - Describe what the PR does and why
2. **Type of Change** - Select one: Bug fix, New feature, Breaking change, or Documentation update
3. **Test Plan** - Explain how the changes were tested
4. **Screenshots / Videos** - Include if applicable
5. **Checklist** - Mark platforms tested (iOS, Android, Web) and documentation updates
