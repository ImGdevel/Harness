# Next.js App Router And Client Boundary Convention

## Purpose

Keep Next.js App Router code server-first and client boundaries explicit.

## Rules

- Use the `app/` directory as the default routing root.
- Keep layout, page, loading, and error files near the route they own.
- Default to Server Components unless the code needs browser-only state, effects, or event handlers.
- Add `'use client'` only at the narrowest component boundary that needs it.
- Do not push data fetching into client components when the same data can be fetched on the server.
- Keep route metadata in route files or the nearest layout instead of scattering head logic.
- Keep shared UI primitives framework-agnostic when possible, but keep route-aware composition inside the Next.js app.
- Treat `app/api/` or external backend calls as transport boundaries, not as a place to duplicate domain rules.

## Checklist

- Is this route using App Router conventions?
- Is the component server-first by default?
- Is `'use client'` applied only where interactivity truly starts?
- Is data fetched on the server when possible?
- Is route metadata kept near the route owner?

## References

- `../index.md`
- `../../../common/convention/documentation-governance.md`
