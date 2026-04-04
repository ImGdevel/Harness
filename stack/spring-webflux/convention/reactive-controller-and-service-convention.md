# Spring WebFlux Reactive Controller and Service Convention

## Purpose

Keep request flow reactive end to end in WebFlux code.

## Rules

- Keep controller focused on HTTP mapping only.
- Return `Mono<T>`, `Flux<T>`, or `Mono<ResponseEntity<T>>` directly from controller methods.
- Do not call `block()`, `blockFirst()`, or `blockLast()` in request flow.
- Keep service and repository boundaries reactive.
- Compose with Reactor operators instead of imperative extraction.
- Do not call `subscribe()` manually in application flow.
- Isolate blocking or legacy APIs behind a separate adapter boundary.
- Use reactive composition such as `zip` or `zipWhen` when combining async sources.
- Keep `map` for sync transform and `flatMap` for async chaining.
- Keep error signaling inside the reactive chain.
- Prefer shared WebFlux error policy over per-controller ad hoc handling.

## Checklist

- Does controller return reactive type directly?
- Is blocking absent from request flow?
- Is manual `subscribe()` absent?
- Are multiple async calls composed reactively?
- Is error handling aligned with the shared policy?

## References

- WebFlux project architecture doc
