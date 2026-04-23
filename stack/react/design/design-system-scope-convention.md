# React Design System Scope Convention

## Purpose

Define what must belong to the design system, what should stay local, and how shared visual and interaction values should be standardized.

## Rules

### Foundation Coverage

- Include color, typography, spacing, radius, border width, shadow, opacity, z-index, breakpoint, motion duration, motion easing, and layout container scales in the design system.
- Define semantic background, text, border, icon, status, and action tokens instead of using raw palette tokens directly in components.
- Keep token scales small, named, and reusable.
- Use a 4px-based spacing scale and keep layout rhythm aligned to the shared spacing scale.
- Let reusable components own internal padding rules through tokens and component contracts.
- Let layout primitives and screen composition own outer spacing. Do not bake page-specific margin into reusable primitives.
- Keep radius on a constrained scale and reuse the same radius tiers across controls and containers.

### Surface and Elevation Policy

- Define surface roles such as `canvas`, `surface`, `surface-raised`, `surface-overlay`, and `inverse`.
- Use a border-first separation policy for default surfaces.
- Reserve shadows for raised cards, overlays, popovers, dialogs, sticky layers, and other elevation-sensitive surfaces.
- Do not stack strong border treatment and strong shadow treatment on the same ordinary surface without a documented reason.
- Define background, border, and shadow as a single surface recipe instead of styling them independently per component.

### Component and Layout Coverage

- Standardize shared primitives such as text, button, input, textarea, select trigger, checkbox, radio, switch, badge, icon wrapper, divider, and surface.
- Standardize shared composites such as field group, form field, dialog shell, dropdown panel, card section, empty state, toast shell, and navigation item when reused.
- Standardize layout primitives such as stack, cluster, inline, grid wrapper, section container, and page container when repeated across screens.
- Keep screen-only composition, feature business logic, and one-off marketing art direction outside the core design system until reuse is proven.

### State and Interaction Coverage

- Define shared behavior for `hover`, `focus-visible`, `active`, `pressed`, `disabled`, `loading`, `selected`, `expanded`, `error`, `warning`, and `success` states when relevant.
- Keep focus-visible styling consistent across all interactive primitives.
- Define pointer, keyboard, and touch interaction feedback through the same tokenized motion and state rules.
- Restrict routine interaction animation to opacity, transform, background-color, border-color, and shadow.
- Do not use unrestricted `transition: all` style rules in shared components.
- Avoid layout-shifting animation for common hover and press feedback.
- Keep default interaction motion short and restrained. Use one shared timing scale for hover, enter, exit, and emphasis transitions.

### Promotion and Exclusion Rules

- Promote a value to a token when it expresses a reusable semantic meaning or must stay consistent across multiple components.
- Promote a pattern to a primitive or composite when it appears in multiple product areas or must stay visually identical.
- Keep temporary experiments, campaign-only visuals, and feature-unique exceptions local until they stabilize.
- Do not put business copy, data formatting, feature logic, or API-specific states into the design-system layer.
- When a project intentionally departs from this scope, document the exception in project docs instead of silently forking the system.

## Checklist

- Does the system cover all shared visual scales, not just color?
- Is the surface policy clear enough to answer border vs shadow vs background decisions?
- Are spacing, radius, and motion standardized instead of arbitrary?
- Are repeated layout and interaction patterns included when reuse exists?
- Are business-only or temporary exceptions kept outside the core system?
- Is every scope exception documented explicitly?

## References

- `design-system-convention.md`
- `design-system-usage-convention.md`
