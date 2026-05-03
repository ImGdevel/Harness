# Spring Clean Architecture Guide

## Purpose

Keep dependency direction and module boundary stable in Spring projects.

## Rules

- Keep dependency direction inward.
- Use `application -> domain`, `application -> infra`, `domain -> common`, `infra -> domain`.
- Do not let `domain` depend on `application` or `infra`.
- Do not let `infra` depend on `application`.
- Keep `Controller`, web DTO, security config in `application` or presentation-side modules.
- Keep use-case orchestration and transaction boundary in `application`.
- Keep entity, value object, policy, and repository port in `domain`.
- Keep adapter, repository implementation, and external client in `infra`.
- Keep `common` limited to real cross-cutting concerns.
- Keep repository interface in `domain` and implementation in `infra`.
- Do not let domain objects know web DTO or adapter types.

## Checklist

- Do dependencies point inward?
- Is `application` focused on orchestration?
- Is `domain` free from outward dependency?
- Is `infra` limited to implementation detail?
- Is `common` small and actually cross-cutting?

## References

- [layer-and-naming-convention.md](../convention/layer-and-naming-convention.md)
- [3-devon-woo-community-BE docs/architecture](https://github.com/100-hours-a-week/3-devon-woo-community-BE/tree/main/docs/architecture)
