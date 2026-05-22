# Plans Must Audit and Trace Across All Platforms (CRITICAL)

## Rule
When a project has multiple platforms (desktop and mobile, or any other parallel UI surfaces), every implementation plan MUST:

1. **Audit components on ALL platforms** — not just the one being changed
2. **Include platform-specific phases** for every platform affected
3. **Add a Platform column** to the traceability matrix
4. **Include per-platform verification items** in the verification phase

A plan that covers only one platform when the project has multiple is incomplete and MUST NOT be written to `./plans/`.

## Why This Matters
The live-ui-components plan went through full review — it cited 4 rules, had a 12-row traceability matrix, and identified what was NOT applicable. But it completely omitted mobile parity, despite the CLAUDE.md rule requiring it. All desktop phases were implemented before anyone noticed. The fix required a follow-up pass across 7 files.

Root cause: the audit phase ("Current State Audit") inventoried files by component type (tables, popups, dashboard) but never by platform (desktop vs. mobile). The gap was invisible because nobody asked "does a mobile equivalent exist for each of these?"

## The Audit Must Be Two-Dimensional

### Wrong: Component-only audit
```markdown
| Component | File | Status |
|-----------|------|--------|
| Network Device Detail | js/network-device-modal.js | Needs LivePopup |
| GPU Detail | js/gpu-modal.js | Needs LivePopup |
```

### Correct: Component × Platform audit
```markdown
| Component | Desktop File | Desktop Status | Mobile File | Mobile Status |
|-----------|-------------|----------------|-------------|---------------|
| Network Device Detail | js/network-device-modal.js | Needs LivePopup | m/js/details/network-device-detail.js | Needs LivePopup |
| GPU Detail | js/gpu-modal.js | Needs LivePopup | m/js/details/gpu-detail.js | Needs LivePopup |
| Dashboard Stats | dashboard/dashboard-init.js | Needs WS subscription | m/sections/dashboard.html | Needs WS subscription |
```

## Traceability Matrix Must Include Platform

### Wrong: Platform-blind matrix
```markdown
| # | Component | Gap | Phase |
|---|-----------|-----|-------|
| 1 | Network Device popup | No live refresh | Phase 3a |
```

### Correct: Platform-aware matrix
```markdown
| # | Component | Platform | Gap | Phase |
|---|-----------|----------|-----|-------|
| 1 | Network Device popup | Desktop | No live refresh | Phase 3a |
| 2 | Network Device popup | Mobile | No live refresh | Phase 3a-m |
```

## Verification Must Cover All Platforms

### Wrong: Desktop-only verification
```markdown
- [ ] Network Device detail popup refreshes when device changes
- [ ] Dashboard cards update on WebSocket notification
```

### Correct: Cross-platform verification
```markdown
- [ ] Desktop: Network Device detail popup refreshes when device changes
- [ ] Mobile: Network Device detail popup refreshes when device changes
- [ ] Desktop: Dashboard cards update on WebSocket notification
- [ ] Mobile: Dashboard stats update on WebSocket notification
```

## Rule Compliance Must Be Exhaustive

The plan's "Rule Compliance Notes" section MUST systematically check ALL applicable rules — at minimum the project's CLAUDE.md, which contains the most specific and binding requirements. Cherry-picking rules that happen to be top-of-mind is insufficient.

### Checklist Before Writing Plan to ./plans/
- [ ] I have read the project's CLAUDE.md for platform-specific rules
- [ ] The audit enumerates components on ALL platforms, not just the primary target
- [ ] Every desktop file in scope has a corresponding mobile row (or explicit "no mobile equivalent" note)
- [ ] The traceability matrix has a Platform column
- [ ] The verification phase has per-platform items for every testable feature
- [ ] Mobile phases are included in the phase breakdown, not deferred as a follow-up

## Historical Context
This rule was created after the live-ui-components plan (May 2026) was implemented across 5 desktop phases without any mobile coverage. The CLAUDE.md mobile parity rule ("After ANY change to a desktop section, JS file, or modal... the mobile equivalent MUST be created or updated") was violated at the planning stage, not the implementation stage. The fix required a follow-up pass that should have been part of the original plan.
