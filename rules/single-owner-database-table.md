# Single Owner per Database Table (CRITICAL)

## Rule
Only ONE process may activate the ORM service for a given Prime Object. That process is the **sole owner** of the database table — the only process that reads from or writes to it directly. Every other process that needs to create, read, update, or delete that data MUST interact with the owning service over the vnet, not activate its own local ORM handler.

## Why This Matters
When two processes both activate the same ORM service (via `ActivateAllServices` or similar), each gets its own in-memory cache and its own direct connection to the database table. Writes from process A go to the DB and update A's cache, but process B's cache never hears about them. Once B's cache is populated from a partial DB read, it never falls back to the DB again — B's view of the data is permanently frozen. The database is consistent, but the caches diverge silently. No errors, no warnings, just stale data served to users.

## The Rule
1. **One owner**: Each Prime Object's ORM service is activated in exactly one process (or one logical service group).
2. **Remote access**: Any other process that needs that data calls the owning service via vnic/vnet RPC — POST, GET, PUT, DELETE over the service mesh.
3. **No local shortcuts**: A process MUST NOT activate a local ORM handler for a table it doesn't own, even if it has database connectivity and the activation API makes it easy.

## The Anti-Pattern
```go
// Process A (physio_demo) — owns PhyClient
services.ActivateAllServices(...)  // activates PhyClient ORM locally ✓

// Process B (boostapp_demo) — also activates PhyClient
services.ActivateAllServices(...)  // activates PhyClient ORM locally ✗
// B now writes directly to the physioclient table
// A's cache never sees B's writes → stale data served to users
```

## The Correct Pattern
```go
// Process A (physio_demo) — owns PhyClient
services.ActivateAllServices(...)  // activates PhyClient ORM locally ✓

// Process B (boostapp_demo) — needs PhyClient data
// Does NOT activate PhyClient locally
// Instead, calls the owning service over vnet:
vnic.Post("PhyClient", 50, clientData)  // routed to process A via service mesh
vnic.Get("PhyClient", 50, query)        // routed to process A via service mesh
```

## What `ActivateAllServices` Must NOT Do
If a process calls `ActivateAllServices`, it must only activate services that it owns. Services owned by another process must be excluded. Either:
- Use selective activation (activate only owned services)
- Or ensure `ActivateAllServices` skips services that are already active on another node in the mesh

## Applies To
- Any Layer 8 project with multiple processes sharing a database
- Any use of `l8orm` ORM services
- Any HA/replication deployment where multiple nodes handle the same service area

## Historical Context
Discovered in l8physio where two processes both activated PhyClient ORM. One cache froze on initial partial read. Root cause: dual ownership, not missing sync.
