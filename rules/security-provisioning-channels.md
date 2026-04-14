# Security Provisioning: Only Config JSON or Security API (CRITICAL)

## Rule
Users, roles, and credentials for any Layer 8 project MUST NEVER be created programmatically (from mock generators, tests, setup scripts, or bespoke helper code). They must be provisioned through exactly one of two channels:

1. **A security config JSON file** consumed by the project's `ISecurityProvider` implementation at startup.
2. **The Security API** — the same endpoints the l8ui "Security" section uses (the Users / Roles / Credentials CRUD flows under the SYS module).

No other path is acceptable. This applies to:
- Mock data generators (`go/tests/mocks/`)
- Integration and unit tests
- `run-local.sh` and other setup scripts
- Any Go code or tooling that might be tempted to POST directly to a users/roles/credentials endpoint

## Why This Matters
All AAA (Authentication, Authorization, Accounting) flows through `ISecurityProvider` — see `security-provider-interface.md`. Bypassing it with direct POSTs to a users service:
- Duplicates the security contract and lets seeded accounts drift from what the UI/provider expect
- Skips validation, password hashing, and role-assignment logic the provider enforces
- Creates records the provider did not author, which may be invisible to permission checks or produce inconsistent identity state
- Makes the seeded state non-reproducible outside the seeding code path (the config JSON and Security API are both inspectable and replayable)

## The Anti-Pattern
```go
// WRONG — POSTing to a bespoke, project-specific users endpoint that bypasses ISecurityProvider
client.Post("/<project>/<projectServiceArea>/users", userData)
```

Writing a custom users service in the project's own service area (so the project owns the identity store) is the violation. The payload shape is not the issue — the endpoint and owner are.

## Canonical Correct Example
`go/tests/mocks/physio_phases.go` — `runPhysioPhase6` / `createUsersFromService` in l8physio POSTs to `/physio/73/users`, where **service area 73 is the shared Security users service** (the same endpoint the l8ui Security section uses). This is the correct pattern: seeding through the Security API, not a project-owned users service.

## The Correct Pattern

### Option A — Security config JSON
Add the user/role/credential definitions to the security config JSON that the project's `ISecurityProvider` loads at startup. The provider is responsible for creating them (with proper hashing, validation, role linkage).

### Option B — Security API
Call the same endpoints the l8ui Security section uses — for example, the Users, Roles, and Credentials CRUD flows exposed by the SYS module. Payload shape and field semantics should match what the UI sends, not a hand-rolled shape.

## When Mock/Test Data Needs Users
If a mock generator or test needs per-entity user accounts (e.g., a user per client, per employee):
1. Prefer seeding those users in the security config JSON so they exist before any mock data runs.
2. If they must be created at runtime, call the Security API endpoints — not a project-specific users service.

## Verification
Before approving any code that creates users/roles/credentials:
```bash
# Look for POSTs to users/roles/credentials endpoints
grep -rn 'Post.*"/[^"]*/users"\|Post.*"/[^"]*/roles"\|Post.*"/[^"]*/credentials"' go/tests/ go/*/main/ go/*/ui/ 2>/dev/null
```
Each match must target the shared Security API service area (the same one l8ui's Security section uses). A match pointing at a project-specific, project-owned users/roles/credentials service is a violation.

## Relationship to Other Rules
- Extends `security-provider-interface.md`: all security goes through `ISecurityProvider`, and this rule names the only two legitimate ways to feed it data.
- Works with `mock-data-generation.md`: mock generators seed business data, not identity.
