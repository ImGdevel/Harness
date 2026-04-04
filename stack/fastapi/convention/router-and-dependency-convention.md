# FastAPI Router and Dependency Convention

## Purpose

Keep FastAPI router, dependency, and response boundaries explicit.

## Rules

- Split `APIRouter` by feature or domain.
- Keep `main.py` focused on app bootstrap and router registration.
- Bind shared `prefix`, `tags`, `responses`, and auth dependencies at router level.
- Extract reusable request context, auth, DB session, and shared params into dependencies.
- Prefer `Annotated[..., Depends(...)]`.
- Use `yield` dependencies when cleanup is required.
- Do not create DB session or external client inside the route handler.
- Keep route handlers focused on HTTP parsing and service call.
- Keep business branching out of the route handler.
- Declare request and response schema explicitly.
- Use return type or `response_model` to lock the response shape.
- Do not expose ORM or persistence objects directly as API response.
- Keep async flow consistent when async I/O is used.
- Do not call blocking I/O directly inside `async def`.

## Checklist

- Is router split by feature or domain?
- Are shared dependencies reused instead of copied?
- Is business logic kept out of the handler?
- Is response shape explicit?
- Is blocking I/O absent from `async def`?

## References

- FastAPI project docs or architecture doc
