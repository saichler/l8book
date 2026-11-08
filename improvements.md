# Improvements to Apply Across Layer 8 Projects

Source: l8erp, Sept–Nov 2026. Some items live in shared frameworks (l8ui, l8agent, l8web, l8common) and
come for free with a version bump; the rest are per-project changes.

## Quick order for another project

1. Bump l8ui, l8agent, l8web and l8common.
2. Switch the backend to `system.Activate`.
3. Update `AgentConfig`: local LLM, `help.md`, `WebToolsURL`.
4. Add the `AgntChat` timeout and the k8s `hostAliases`.
5. Put custom screens (dashboards) on a live slot.
6. Add `seed-mocks.sh` with the endpoint wait; set `imagePullPolicy: IfNotPresent` on kind/local.
7. Copy the `e2e/` skeleton: inventory generator, worker fixtures, lint scripts, page objects.
8. Run the shell-integrity spec first — it finds missing-script bugs fastest.

---

## 1. E2E testing (Playwright against a real KIND cluster)

### Setup (`e2e/`)
- Playwright drives the deployed app on KIND, with `desktop` and `mobile` projects. Mobile tests load
  the real `/m/app.html`, never a resized desktop viewport.
- Layout: `fixtures/` (env, API client, test fixture, inventory), `pages/` (page objects),
  `drivers/` (crud, forms, table), `tests/desktop|mobile/`, `tools/`.
- **Coverage is generated, not hand-written.** `tools/generate-inventory.js` loads `app.html` and
  `m/app.html` in a DOM stub, runs every script tag, and reads the real module configs into
  `fixtures/inventory.json`. Sweep specs iterate it. Re-run `npm run inventory` (and commit) after any
  `*-config.js`, nav config or shell script-list change.
- The generator doubles as an audit: it reports any script that throws at load.

### Spec phases worth copying
Shell integrity (every script resolves, no console errors, all globals defined), auth, dashboard and
navigation, every-service coverage, API contract, CRUD, table features, view system, system section,
permissions and theme, inline tables, exports, reference pickers, realtime, portals, auth screens.

### Rules that made the suite fast and stable
(l8erp: ~84 min / 2 failed / 13 flaky → 41.6 min / 725 passed)

- **No fixed sleeps.** Every `waitForTimeout` / `setTimeout` is a wait on an event or condition.
  The `rerender()` pattern: tag the current markup, act, wait for the tag to disappear.
  `npm run lint:sleep` fails on new sleeps:
  ```json
  "lint:sleep": "test -z \"$(grep -rnE 'waitForTimeout\\(|(^|[^.[:alnum:]_])setTimeout\\(' tests pages drivers fixtures)\" || (echo 'fixed sleeps found'; exit 1)"
  ```
- **One session per worker.** `api`, `app`, `mobile` fixtures are worker-scoped and boot once. Each
  test starts from a reset (popups closed, section tagged stale, mobile sent home). Tests that assert
  on boot, logout or theme use `freshApp` / `freshMobile`.
- `openSection()` skips a section that is already loaded.
- **Wait on the inline opacity**, not the computed one, when a section swaps — a 0.5s fade reads 1 at
  its start, so clicks land on the old, detached DOM.
- **Poll for the edited value after a PUT** (read-after-write lag).
- `retries: 1` separates cluster churn from real bugs; `workers: 2` matches a single-replica
  deployment; `video: 'on-first-retry'` avoids teardown timeouts.
- Clean up through the API in `afterEach`, keyed by a unique per-run code. Never assert exact counts
  against live data. Filter before asserting a row is visible.
- Scratch specs get a `zzz-` prefix; `npm run lint:scratch` catches leftovers.
- Known gaps are `test.fail()`, not skipped, so they fail loudly once implemented.
- Permission tests log in as a view-only `viewer` account and use the operator as a control.
- `DesktopNav.openModule` retries a swallowed tab click before asserting.
- Mobile nav matches the sub-module **label** (not key), and both card table components
  (`mobile-table-*` and `mobile-edit-table-*`).

### Supporting infrastructure
- `kind-start.sh` seeds mock data via `k8s/seed-mocks.sh`, which waits for `/login.json` and then
  **waits until a real service endpoint stops returning 404** — on a fresh cluster endpoints register
  late, which used to fail the whole seed.
- No `run-local.sh` / `start-db.sh`; local testing is KIND only.
- `imagePullPolicy: IfNotPresent` on kind/local manifests. `Always` silently discards images loaded
  with `kind load`, so you test a stale build.
- Images build on local base images and push to Harbor (`registry.layer-8.dev:44443/<proj>`);
  `k8s/secrets.sh` creates the `harbor-pull` Secret.
- `erp-web` reads web assets into memory at startup: editing a file under `web/` changes nothing until
  the image is rebuilt and the pod replaced.

### Bugs the suite found that likely exist elsewhere
- Shells missing shared scripts (`layer8-query-builder.js`, `layer8-form-chips.js`,
  `layer8-field-parsers.js`, `layer8-period-selector.js`, `layer8-inline-table-state.js`,
  `layer8-reference-config-resolver.js`, `layer8-datepicker-grid.js`). Missing the query builder makes
  every table fail silently; missing form chips breaks mobile portal shells. Reported in fmc,
  l8stocks, l8rubi, l8learn, l8vibe, l8id, l8vendingmachine, secscan-mobile.
- Wrong namespace casing in `app.js` `nsMap`, which disables permission filtering.
- Enum part files missing from `m/app.html`, so services fall back to `DEFAULT_COLUMNS`.

---

## 2. Web UI realtime notifications ("live screens")

### Framework (l8ui `45a3b4a`, `d703fcc`, `b65b787`) — bump the submodule
- Every table and data-source view (desktop and mobile) is **live by default**: pushed add / update /
  delete are applied in place, no toast, no re-fetch. `realtime: false` opts out.
- Registration uses query-body fields (`register: 'L8_REGISTER_REGISTER'`, `registerId`) instead of
  appending `register=true` to the query text.
- **Five live slots**: opening a sixth live component evicts and unregisters the least recently used.
  Switching back to a view counts as use. Listener leak fixed.

### Per project
- **Custom screens** that build their own queries (dashboards) must join a live slot:
  ```js
  // on each entry: a new owner takes the slot over and drops the old listeners
  DashboardStats.liveOwner = {};

  const query = Layer8DWebSocket.registerQuery('dashboard', owner, endpoint, kpi.query,
                  { onReconnect: () => this.loadAll() });
  Layer8DWebSocket.listen('dashboard', owner, kpi.model, debouncedReload);
  ```
  Group all of a screen's queries under one slot.
- Backend: activate l8events + l8notify with l8common's `system.Activate(dbcred, dbname, nic)` —
  never the individual `Activate*` functions. Register `NotifyRecord` and `IntegrationConfig` types in
  the UI.
- Realtime e2e spec checks: the websocket client connects; register → mutate from a second client →
  callback fires; an open table shows another client's add and delete; only the 5 most recently used
  components stay live. Always register before mutating; use an ordinary ORM-backed model
  (`L8ImportTemplate` pushes nothing).

---

## 3. l8agent with the local LLM

All in the project's `AgentConfig` (l8erp: `go/erp/aia/activate.go`):

```go
//go:embed help.md
var helpDocs string

agent.AgentConfig{
    // ...
    LLMCreds:    "TestLLM",
    LLMProvider: "openai",   // local OpenAI-compatible model instead of Anthropic
    LLMCredKey:  "chat",
    HelpDocs:    helpDocs,   // answers '@help' prompts
    WebToolsURL: "https://tools.test-llm.dev", // live '@web' search/fetch
}
```

- **`@help`**: write `help.md` as screen paths ("Section > Module > Service") plus step-by-step tasks.
- **`@web`**: without `WebToolsURL`, `@web` answers from model knowledge only (no weather, news,
  prices). Needs the l8agent version that has `WebToolsURL`.
- **Chat timeout** in the web server main (new in l8web) — the first message is ~14.5k prompt tokens
  and tool rounds add more, so the default 30s returned empty responses:
  ```go
  server.SetServiceTimeout("AgntChat", 120, 300)
  ```
- **k8s `hostAliases`** on the pod that calls the LLM (kind, local, baremetal — not GKE). Inside the LAN
  the public IP does not loop back:
  ```yaml
  hostAliases:
    - ip: "192.168.1.121"
      hostnames: ["llm.test-llm.dev", "embed.test-llm.dev", "muse.test-llm.dev", "tools.test-llm.dev"]
  ```
- Wire the persisted conversations service (`L8AgentConversation` at `/<area>/AgntConvo`) into the
  desktop config, not only mobile.
