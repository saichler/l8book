# Verify PRD Completeness Before Reporting Done (CRITICAL)

## Rule
After implementing a PRD, you MUST NOT report the work as complete until every component, service, layer, and data flow defined in the PRD has been verified as implemented. Walk the PRD section by section and confirm each item exists in the codebase. A missing implementation is not "done" — it is unfinished work.

## Why This Is Critical
This rule was created after the l8stocks PRD was reported as "completely finished implementation" while two critical components were never built:
1. The **Persist layer** (`SPersist` service) — defined in the PRD with service names, service areas, and file I/O behavior. `Links.go` had the constants, but no service implementation existed.
2. The **Startup warm-up** — the PRD specified that the parser reads `./base-data` files on boot to populate the inventory cache. No such code was written.

The result: the UI loaded with zero data. The base data (4,149 stocks, 730 days of prices, news articles) sat on disk unused because nothing loaded it into memory.

## The Verification Process
After implementing a PRD, before reporting done:

### Step 1: Extract every deliverable from the PRD
Walk the PRD and list every:
- Service (service name, service area, what it does)
- Binary / process (main.go entry points)
- Data flow path (source → transform → destination)
- Startup behavior (warm-up, initialization, bootstrap)
- Integration point (what calls what, what feeds what)

### Step 2: Verify each deliverable exists in code
```bash
# Does the service implementation exist?
grep -rn "ServiceName" go/<project>/ --include="*.go" | grep -v vendor/

# Does the main.go activate it?
grep -rn "Activate\|service\." go/<project>/*/main.go | grep -v vendor/

# Does the data flow code exist?
grep -rn "<key function or type>" go/<project>/ --include="*.go" | grep -v vendor/
```

### Step 3: Trace data end-to-end
For each data type the PRD defines:
1. Where does it originate? (file, API, database) — does that code exist?
2. How does it get transformed? — does that code exist?
3. Where does it land? (cache, database, file) — does that code exist?
4. How does the UI read it? (service endpoint) — does that service serve data from the right source?

If any link in the chain is missing, the data will not appear in the UI.

### Step 4: Verify the UI can display data
If the PRD includes a UI:
1. Does the data source (inventory, ORM, service) have data in it?
2. Can the UI endpoint actually reach the data?
3. Open the UI in a browser and confirm data appears — not just that the page loads

## Checklist Before Reporting PRD Complete
- [ ] Every service defined in the PRD has an implementation (not just constants/config)
- [ ] Every binary/process defined in the PRD has a main.go that activates all required services
- [ ] Every data flow path has code for every step (source → transform → cache → persist)
- [ ] Startup behaviors (warm-up, bootstrap, seed data) are implemented
- [ ] The UI displays actual data, not empty tables

## Common Gaps
| PRD defines | What gets missed |
|------------|-----------------|
| Persist/storage layer | Constants defined in config, but no read/write implementation |
| Startup warm-up / bootstrap | Service activates but never loads initial data |
| Data pipeline stage | Upstream and downstream exist, but middle stage is hollow |
| Scheduled/periodic tasks | Service exists but the timer/cron trigger is never started |
| Integration between services | Each service works in isolation but they never connect |
