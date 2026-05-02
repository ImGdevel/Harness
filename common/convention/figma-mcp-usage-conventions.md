# Figma MCP Usage Conventions

## Purpose

Minimize Figma MCP tool calls and avoid exhausting plan-based limits during design, PDF source, and design-to-code work.

## Rules

- Treat every Figma MCP call as budgeted unless the official Figma documentation explicitly states that the tool is exempt.
- Check the target Figma plan and seat before starting heavy automation.
- Use `whoami` once per task only when the plan key is unknown.
- Prefer a known `planKey` and existing `fileKey` over exploratory discovery calls.
- Do not inspect a blank Figma file unless the result changes the next action.
- Do not run font discovery, page discovery, design-system search, or screenshot validation as separate habits.
- Build the intended document, page, or screen structure locally before the first write call.
- Batch canvas creation into one `use_figma` call when creating from scratch.
- Use one final `get_screenshot` call for visual verification only when the output must be checked inside the conversation.
- Avoid iterative "small visual tweak" loops through MCP on Starter plans.
- If expected calls exceed the safe budget, switch to local HTML/PDF generation, Canva, or manual Figma editing.
- Cache file keys, node ids, plan keys, and design-system findings in the task note or project docs.
- Reuse previous Figma file structure instead of re-discovering pages, components, variables, or styles.
- Use local browser screenshots, exported images, and generated HTML as the primary composition source for PDF-style documents.
- Insert screenshots in one bulk operation when possible.
- Prefer stable, built-in fonts when exact font discovery would cost another call.
- Do not call `search_design_system` for one-off submission PDFs unless reusable design-system fidelity is required.
- Do not use Figma MCP as a browser testing tool; use browser automation or local screenshot scripts first.
- Stop immediately on rate-limit errors and record the plan, seat, failed tool, and remaining fallback path.

## Call Budget Strategy

- Starter or View/Collab seat:
  - Target at most 3 calls for a complete output.
  - Hard stop before the 5th planned call.
  - Use Figma MCP only for final assembly or validation, not exploration.
- Paid Full/Dev seat:
  - Batch related reads and writes.
  - Keep design-system discovery to one planned discovery phase.
  - Validate once per milestone, not after every node mutation.
- Existing file update:
  - Use known page and node ids.
  - Write targeted changes in one call.
  - Validate only the changed frame.
- New PDF/source document:
  - Draft content and layout locally.
  - Prepare all screenshots and text before Figma access.
  - Create the file.
  - Run one bulk `use_figma` call to create all frames.
  - Run one screenshot check only if needed.

## Preferred Workflows

### New Submission PDF Source

1. Prepare Markdown/HTML content locally.
2. Capture application screenshots locally.
3. Decide page count, frame size, section order, and copy before opening Figma.
4. Create or reuse a Figma file with a known plan key.
5. Generate all pages, text, cards, diagrams, and screenshots in one `use_figma` call.
6. Use a single final screenshot or manual Figma review.
7. Export PDF from Figma manually if MCP export is unavailable.

### Existing Figma File Update

1. Use a stored file URL and known node ids.
2. Skip global page/component discovery.
3. Modify only the target frame or node subtree.
4. Return all mutated node ids from the write call.
5. Capture only the target frame if visual validation is required.

### Design-To-Code

1. Fetch only the exact selected node or frame.
2. If output is too large, fetch metadata once and narrow the node target.
3. Avoid repeated screenshots for variants that are not being implemented.
4. Cache downloaded assets and design context locally.
5. Use local implementation verification after the first design context read.

## Abort Conditions

- The target plan is `Starter` and the task needs exploratory design iteration.
- The user asks for more than one independent Figma artifact and no paid plan is available.
- A rate-limit error is returned.
- The planned flow requires repeated `search_design_system`, `get_design_context`, or `get_screenshot` calls without a known node target.
- The output can be created more reliably as local HTML/PDF without Figma-specific editing.

## Snippet

Use this call ledger before Figma MCP work:

```text
Figma MCP Call Ledger
- Task:
- Target team / plan:
- Seat:
- File key:
- Known node ids:
- Planned calls:
- Expected max calls:
- Abort threshold:
- Fallback:
- Actual calls:
```

## Checklist

- Is the target team/plan known before calling Figma?
- Is there a written call ledger?
- Can the output be prepared locally before Figma access?
- Are all screenshots and copy ready before `use_figma`?
- Is the first write call a bulk operation?
- Is visual validation limited to one final screenshot?
- Are discovered file keys and node ids stored for reuse?
- Is there a fallback if Figma MCP is rate-limited?

## References

- [Figma MCP Server plans, access, and permissions](https://developers.figma.com/docs/figma-mcp-server/plans-access-and-permissions/)
- [Figma REST API rate limits](https://developers.figma.com/docs/rest-api/rate-limits/)
- [Figma skills for MCP](https://help.figma.com/hc/en-us/articles/39166810751895-Figma-skills-for-MCP)
