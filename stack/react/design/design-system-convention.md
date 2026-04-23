# React Design System Convention

## Purpose

Keep React UI consistent, token-driven, and reusable across screens.

## Rules

- Treat the design system as a shared contract between design, frontend, QA, and documentation.
- Define reusable visual decisions as tokens before defining component styles.
- Prefer semantic token names such as `surface-primary`, `border-muted`, or `text-danger` over raw palette names.
- Expose tokens through one theme layer such as CSS variables or a theme object.
- Keep the design-system code path separate from feature and screen code.
- Split system responsibility into `foundation`, `primitive`, `composite`, and `screen`.
- Keep `foundation` limited to tokens, scales, and theme mappings.
- Keep `primitive` components presentation-focused and page-agnostic.
- Build `composite` components by composing primitives instead of duplicating visual rules.
- Keep `screen` concerns outside the design-system folder unless the pattern is reused broadly enough to be promoted.
- Keep component APIs explicit. Standardize visual inputs around `variant`, `size`, `tone`, `emphasis`, and `state` when needed.
- Add a new token, variant, or component only when the rule is reused or must stay consistent across multiple flows.
- Define interaction states consistently across components: `default`, `hover`, `focus-visible`, `active`, `disabled`, `loading`, `selected`, `error`, `success` when applicable.
- Ensure every interactive component has keyboard access, visible focus styling, and semantic disabled behavior.
- Treat responsive behavior and theme behavior as part of the component contract, not as screen-only afterthoughts.
- Prefer extending tokens or primitives before adding one-off style exceptions.
- Keep project-specific overrides in the project documentation scope and state the override explicitly.
- Update the relevant design doc in the same change when tokens, variants, component contracts, or placement rules change.

## Checklist

- Is the design decision expressed as a shared contract instead of a local shortcut?
- Is a reusable visual value defined as a token first?
- Is the token name semantic instead of palette-driven?
- Is the component placed in the correct tier?
- Is the new variant or component truly reusable?
- Are required interaction states and accessibility behaviors covered?
- Was the relevant design doc updated in the same change?

## References

- `design-system-usage-convention.md`
- `design-system-scope-convention.md`
- `../convention/component-and-state-convention.md`
- `../../../common/convention/documentation-governance.md`
