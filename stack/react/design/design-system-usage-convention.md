# React Design System Usage Convention

## Purpose

Show where the design system lives, how a frontend session should read it, and how projects should consume it.

## Rules

### Reading Order

- Start every frontend design-related session from `stack/react/design/index.md`.
- Read `design-system-convention.md` first to understand the shared contract.
- Read `design-system-usage-convention.md` second to understand placement and consumption flow.
- Read `design-system-scope-convention.md` third to understand what values and behaviors belong to the system.
- If the target project has its own override doc under `<project-root>/docs/convention/`, read it after the framework docs and treat it as higher priority.

### Documentation Placement

- Keep framework-default design rules in `stack/react/design/`.
- Keep project-owned design overrides in `<project-root>/docs/convention/`.
- Keep project design plans in `<project-root>/docs/plan/` when the work is exploratory, staged, or migration-driven.
- Keep troubleshooting and deviation history in `<project-root>/docs/troubleshooting/` when a system rule was broken or intentionally bypassed.

### Runtime Code Placement

- Place reusable runtime design-system code under `<project-root>/src/design-system/`.
- Keep tokens and scales in `src/design-system/foundation/`.
- Keep theme files and theme bindings in `src/design-system/themes/`.
- Keep page-agnostic base components in `src/design-system/primitives/`.
- Keep higher-level reusable assemblies in `src/design-system/composites/`.
- Keep public exports in `src/design-system/index.ts` or `src/design-system/index.tsx`.
- Keep feature-specific components outside `src/design-system/`.

### Styling and Consumption

- Route all reusable styling through tokens first, then primitives, then composites.
- Keep the styling engine replaceable. The design-system contract must survive whether the project uses CSS Modules, Tailwind, CSS-in-JS, or another layer.
- Map the chosen styling engine to shared tokens instead of bypassing the token layer with arbitrary values.
- Prefer CSS variables or an equivalent theme layer for runtime theming and semantic token access.
- Let app screens consume design-system exports instead of rebuilding styles from raw values.
- Promote a repeated local pattern into the design system only after it proves reusable across screens or features.
- Keep one-off campaign, experiment, and feature styles local until they become stable shared patterns.

### Change Flow

- Start a new shared visual rule by checking whether an existing token or component already solves it.
- Add or update tokens before touching multiple component implementations.
- Add or update primitives before creating new composites.
- Add or update composites before spreading the same pattern across screens.
- Update design documentation in the same change when placement or usage rules change.

## Tree

- `<project-root>/docs/convention/`
  Project-owned design-system override docs
- `<project-root>/src/design-system/foundation/`
  Token, scale, and semantic mapping files
- `<project-root>/src/design-system/themes/`
  Theme definitions and theme bindings
- `<project-root>/src/design-system/primitives/`
  Button, Input, Text, Surface, Icon-like base components
- `<project-root>/src/design-system/composites/`
  FormField, Dialog, CardSection, AppHeader-like reusable assemblies
- `<project-root>/src/design-system/index.ts`
  Public entrypoint for app consumption

## Checklist

- Can a new session find the framework design docs first?
- Is the project override path explicit?
- Does reusable runtime code live under `src/design-system/`?
- Does feature code consume the design system instead of bypassing it?
- Is the styling engine mapped to tokens rather than raw values?
- Was repeated local styling promoted only after reuse was proven?

## References

- `design-system-convention.md`
- `design-system-scope-convention.md`
- `../../../common/convention/documentation-governance.md`
