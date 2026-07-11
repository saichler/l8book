# Plan Requirements (CRITICAL)

## Approval Workflow

### Rule
When a plan is created, it MUST be written to the `./plans` directory in the project root. Do NOT ask the user for approval directly — the user needs to share the plan with their peers first. Wait for the user to explicitly confirm that the plan has been approved before implementing it.

### Process
1. Write the plan to `./plans/<descriptive-name>.md`
2. Inform the user that the plan is ready at that path
3. **Stop and wait** — do not implement, do not ask "should I proceed?", do not call ExitPlanMode
4. Only begin implementation after the user explicitly says the plan is approved

## Duplication Audit

### Rule
Before writing any implementation plan to `./plans/`, you MUST audit the plan for duplicate behavioral code. If the plan creates 2+ files with the same behavioral logic (differing only in configuration values like namespaces, field names, or labels), the plan MUST include an extraction phase BEFORE the implementation phases.

### The Audit Process

#### Step 1: Identify the pattern source
If the plan says "follow the pattern from X" or "replicate X for Y", read X completely. Categorize every line as either:
- **Behavioral**: Logic that would be identical across all instances (auth, rendering, event handling, data fetching, DOM manipulation)
- **Configuration**: Data that is unique per instance (namespaces, field names, endpoint paths, labels, column definitions)

#### Step 2: Calculate duplication
```
Duplicated lines = behavioral_lines × (number_of_new_instances)
```
If `duplicated_lines > 100`, extraction is MANDATORY.

#### Step 3: Design the shared abstraction
The shared component should accept configuration and handle all behavioral logic. Each instance should be config-only (~30-50 lines). The abstraction should be created as Phase 0 of the plan, and the source pattern (X) should be refactored to use it before building new instances.

#### Step 4: Refactor the original first
The pattern source (X) must be refactored to use the shared abstraction in the same Phase 0. This proves the abstraction works before it's used by new instances, and prevents drift between the original and the new instances.

### What Counts as Behavioral (Must Be Extracted)
- Authentication / authorization flows
- Navigation rendering and event wiring
- Table initialization and configuration
- Form rendering, data collection, and submission
- Detail popup opening and closing
- Section/tab loading and switching
- Data fetching patterns (L8Query construction, fetch calls)
- Sidebar toggle, responsive layout logic
- CSS layout and component styles (extract to shared CSS file)
- HTML shell structure (header, sidebar, content area)

### What Counts as Configuration (Stays Per-Instance)
- Namespace / window object name
- Section-to-service mappings
- Column definitions
- Form definitions
- Enum definitions
- Primary key mappings
- Nav menu items
- Dashboard card definitions and data loaders
- Scope field name and value resolver
- Module includes in HTML `<script>` tags
- Portal-specific actions

### Error Pattern This Prevents
```
WRONG:  5 portals × ~520 behavioral lines each = 2,600 lines of copy-pasted code
CORRECT: Shared framework (~500 lines) + 5 × config (~50 lines) = 750 lines total
```

### Checklist Before Writing Plan to ./plans/
- [ ] I have read the source pattern completely
- [ ] I have categorized every line as behavioral vs. configuration
- [ ] If creating 2+ instances: behavioral code is extracted to a shared component
- [ ] Phase 0 refactors the original pattern to use the shared component
- [ ] Each new instance's app/init file is config-only (~30-50 lines)
- [ ] Shared CSS is extracted (not duplicated in each HTML file's `<style>` block)

### Relationship to Existing Rules
Extends `maintainability.md`'s Second Instance Rule to the planning phase.

## Platform Completeness

### Rule
When a project has multiple platforms (desktop and mobile, or any other parallel UI surfaces), every implementation plan MUST:

1. **Audit components on ALL platforms** — not just the one being changed
2. **Include platform-specific phases** for every platform affected
3. **Add a Platform column** to the traceability matrix
4. **Include per-platform verification items** in the verification phase

A plan that covers only one platform when the project has multiple is incomplete and MUST NOT be written to `./plans/`.

### Why This Matters
Root cause of past failures: the audit inventoried files by component type (tables, popups, dashboard) but never by platform (desktop vs. mobile). The gap was invisible because nobody asked "does a mobile equivalent exist for each of these?"

### The Audit Must Be Two-Dimensional

#### Wrong: Component-only audit
```markdown
| Component | File | Status |
|-----------|------|--------|
| Network Device Detail | js/network-device-modal.js | Needs LivePopup |
| GPU Detail | js/gpu-modal.js | Needs LivePopup |
```

#### Correct: Component x Platform audit
```markdown
| Component | Desktop File | Desktop Status | Mobile File | Mobile Status |
|-----------|-------------|----------------|-------------|---------------|
| Network Device Detail | js/network-device-modal.js | Needs LivePopup | m/js/details/network-device-detail.js | Needs LivePopup |
| GPU Detail | js/gpu-modal.js | Needs LivePopup | m/js/details/gpu-detail.js | Needs LivePopup |
| Dashboard Stats | dashboard/dashboard-init.js | Needs WS subscription | m/sections/dashboard.html | Needs WS subscription |
```

### Traceability Matrix Must Include Platform

#### Wrong: Platform-blind matrix
```markdown
| # | Component | Gap | Phase |
|---|-----------|-----|-------|
| 1 | Network Device popup | No live refresh | Phase 3a |
```

#### Correct: Platform-aware matrix
```markdown
| # | Component | Platform | Gap | Phase |
|---|-----------|----------|-----|-------|
| 1 | Network Device popup | Desktop | No live refresh | Phase 3a |
| 2 | Network Device popup | Mobile | No live refresh | Phase 3a-m |
```

### Verification Must Cover All Platforms

#### Wrong: Desktop-only verification
```markdown
- [ ] Network Device detail popup refreshes when device changes
- [ ] Dashboard cards update on WebSocket notification
```

#### Correct: Cross-platform verification
```markdown
- [ ] Desktop: Network Device detail popup refreshes when device changes
- [ ] Mobile: Network Device detail popup refreshes when device changes
- [ ] Desktop: Dashboard cards update on WebSocket notification
- [ ] Mobile: Dashboard stats update on WebSocket notification
```

### Rule Compliance Must Be Exhaustive

The plan's "Rule Compliance Notes" section MUST systematically check ALL applicable rules — at minimum the project's CLAUDE.md, which contains the most specific and binding requirements. Cherry-picking rules that happen to be top-of-mind is insufficient.

### Checklist Before Writing Plan to ./plans/
- [ ] I have read the project's CLAUDE.md for platform-specific rules
- [ ] The audit enumerates components on ALL platforms, not just the primary target
- [ ] Every desktop file in scope has a corresponding mobile row (or explicit "no mobile equivalent" note)
- [ ] The traceability matrix has a Platform column
- [ ] The verification phase has per-platform items for every testable feature
- [ ] Mobile phases are included in the phase breakdown, not deferred as a follow-up

## Traceability and Verification

### Rule
Every implementation plan MUST include:

1. **A traceability matrix** at the end of the analysis sections, before the phase breakdown. This is a table mapping every identified gap, MISSING item, or action item to the specific phase that will address it. Any gap without a corresponding phase is a planning error that must be resolved before the plan is written to `./plans/`.

2. **A final verification phase** as the last implementation phase. This phase smoke-tests every affected section end-to-end: navigate to each section, verify data loads in tables, verify row clicks open details, verify forms submit correctly. No plan is complete without it.

### Why This Matters
Analysis and implementation phases are often written separately. Thorough analysis can identify 50+ gaps, but if the phase breakdown is written without back-referencing those gaps, some will fall through the cracks. The traceability matrix forces a cross-check: every finding must land somewhere, and any orphan is visible immediately.

The verification phase catches integration issues that per-phase testing misses — blank tables, broken click handlers, missing transforms, wrong container IDs — problems that only surface when the full system is exercised.

### Traceability Matrix Format

After all analysis sections and before the phase breakdown:

```markdown
## Traceability Matrix

| # | Section | Gap / Action Item | Phase |
|---|---------|-------------------|-------|
| 1 | 1.3 Data Transform | Add transformDeviceData to mobile | Phase 2 |
| 2 | 1.4 Overview | Add System Name, Last Seen, Coordinates | Phase 1 |
| 3 | 4.1 K8s Columns | Add Namespace, NetworkPolicy column defs | Phase 2 |
| ...| ... | ... | ... |
```

Every row in every "Actions" or "MISSING" note from the analysis MUST appear in this table. If a gap is intentionally deferred, mark it as "Deferred — {reason}" instead of a phase number.

### Verification Phase Format

```markdown
## Phase N: End-to-End Verification

For every section affected by this plan:
1. Navigate to the section
2. Verify table data loads (not blank)
3. Verify row click opens detail/modal
4. Verify detail content is populated (not empty)
5. Verify CRUD operations work (if applicable)
6. Verify on both desktop and mobile (if both are in scope)

Sections to verify:
- [ ] Section A
- [ ] Section B
- [ ] ...
```

### Process
1. Write analysis sections with gaps and action items
2. Write the traceability matrix — one row per gap
3. Write the phase breakdown
4. Cross-check: every matrix row has a valid phase number
5. Add the verification phase as the final phase
6. Only then write the plan to `./plans/`
