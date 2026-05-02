# Unity Preproduction Decision Guide

## Purpose

Lock the major product and technical decisions before creating a Unity project.

## Rules

- Define the game fantasy, genre, target player, and target platform first.
- Decide `2D` or `3D` before choosing the Unity template.
- Decide the render pipeline before project creation.
- Use `URP` as the safe default for cross-platform indie projects unless the visual target clearly requires `HDRP`.
- Use `HDRP` only when high-end PC or console visuals are a first-class requirement.
- Use the Built-in Render Pipeline only when a legacy dependency or migration constraint requires it.
- Prefer the current LTS release when stability matters.
- As of `2026-04-25`, the latest public LTS is `Unity 6.3 LTS`; re-check the official Unity release support page when the actual project starts.
- Record the expected control scheme, camera model, save strategy, networking scope, and content scope before environment bootstrap.
- Freeze the MVP slice before selecting packages, plugins, and third-party services.
- Write the preproduction docs in this order: requirements -> concept art brief -> design plan -> technical spike list -> project bootstrap.

## Checklist

- Is the target platform explicit?
- Is the intended `2D` or `3D` mode explicit?
- Is the render pipeline explicit?
- Is the MVP scope separated from stretch scope?
- Is the control scheme explicit?
- Is the camera style explicit?
- Is the save/load expectation explicit?
- Is the networking expectation explicit?
- Is the art direction brief explicit enough for concept work?
- Is the project ready to move from docs into repo/bootstrap?

## References

- [Unity release overview](https://unity.com/releases/release-overview)
- [Create your first project](https://docs.unity3d.com/Manual/create-first-project.html)
- [2D and 3D projects](https://docs.unity3d.com/Manual/2Dor3D.html)
- [Create a new project with URP](https://docs.unity3d.com/Manual/urp/creating-a-new-project-with-urp.html)
- [game-requirements-template.md](</C:/Users/imdls/workspace/Project Workspace/common/templates/game-requirements-template.md>)
- [game-concept-art-brief-template.md](</C:/Users/imdls/workspace/Project Workspace/common/templates/game-concept-art-brief-template.md>)
- [game-design-plan-template.md](</C:/Users/imdls/workspace/Project Workspace/common/templates/game-design-plan-template.md>)
