# Events Service Required for Every Project (CRITICAL)

## Rule
Every Layer 8 project that implements a PRD MUST include the `l8events` events service. This is required infrastructure, not optional — same as log services, the vnet, and the web server.

## What Must Be Done

### 1. Backend main.go — Activate the events service
Add the import and activation call in the project's backend main entry point:

```go
import (
    evtservices "github.com/saichler/l8events/go/services"
)

func main() {
    // ... existing setup ...
    services.ActivateAllServices(dbcred, dbname, nic)
    evtservices.ActivateEvents(dbcred, dbname, nic)
    // ...
}
```

The `ActivateEvents` call goes after `ActivateAllServices` and before any signal wait.

### 2. UI main.go — Register the EventRecord type
Add the type registration so the UI introspection system knows about events:

```go
import (
    l8events "github.com/saichler/l8types/go/types/l8events"
)

func registerTypes(resources ifs.IResources) {
    // ... existing type registrations ...
    l8c.RegisterType(resources, &l8events.EventRecord{}, &l8events.EventRecordList{}, "EventId")
}
```

### 3. Re-vendor dependencies
After adding the import, run the full vendor refresh to pull in `l8events`:
```bash
cd go && rm -rf go.sum go.mod vendor && go mod init && GOPROXY=direct GOPRIVATE=github.com go mod tidy && go mod vendor
```

## Canonical Reference
- **l8erp backend**: `../l8erp/go/erp/main/erp_main.go` — `evtservices.ActivateEvents(dbcred, dbname, nic)`
- **l8erp UI**: `../l8erp/go/erp/ui/shared_other.go` — `RegisterType(resources, &l8events.EventRecord{}, ...)`

## PRD Requirement
Every PRD MUST include an "Events Service" item in its implementation checklist. If the PRD omits it, add it before approval.

## Verification
After implementation:
```bash
# Backend activates events
grep -n "ActivateEvents" go/<project>/main/*.go
# UI registers EventRecord
grep -n "EventRecord" go/<project>/ui/*.go
# l8events is vendored
ls go/vendor/github.com/saichler/l8events/
```
All three checks must pass.
