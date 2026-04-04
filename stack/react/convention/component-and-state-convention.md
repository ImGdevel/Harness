# React Component and State Convention

## Purpose

Keep React render pure, state minimal, and `Effect` explicit.

## Rules

- Keep component and hook render pure.
- Do not create side effects during render.
- Do not duplicate the same state in multiple owners.
- Derive computable values from existing props or state.
- Keep array and object updates immutable.
- Call hooks only at top level of component or custom hook.
- Do not call hooks inside condition, loop, event handler, or nested callback.
- Extract repeated reusable logic into custom hooks.
- Use `useEffect` only for external system synchronization.
- Put event-driven logic in the event handler, not in `useEffect`.
- Split unrelated effects.
- Do not suppress dependency tracking.
- Keep one primary responsibility per component.
- Avoid premature memoization until a real performance problem is observed.

## Checklist

- Is render pure?
- Is state owned by the nearest valid owner?
- Are hook rules preserved?
- Is each effect justified by external synchronization?
- Is component responsibility narrow enough?

## References

- React project architecture doc
