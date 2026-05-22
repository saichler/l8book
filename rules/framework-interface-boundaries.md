# Never Modify Framework Interfaces for Feature Work (CRITICAL)

## Rule
When implementing a feature in a consuming project (e.g., probler, l8erp), you MUST NOT add methods, types, or interfaces to the framework's contract layer (`l8types/go/ifs/`) to support that feature. Framework interfaces are stable contracts that change only when the fundamental model of the system changes — not when a consumer needs a new capability.

## Three Sub-Rules

### 1. Feature hooks belong in the implementation layer, not the contract layer

If a feature needs a hook (before/after interceptor, notification listener, modifier pattern), the hook lives in the implementation package (`l8services`, `l8web`, project-specific code) — not in the interface definitions (`l8types/go/ifs/`).

```go
// WRONG — adding a new interface to l8types/go/ifs/Services.go for a feature
type IServiceHandlerModifier interface {
    Before(IElements, Action, IVNic) (IElements, error)
    After(IElements, Action, IVNic) (IElements, error)
}

// CORRECT — the implementation layer already handles this internally
// ServiceManager.delegateNotification() in l8services routes notifications
// without any new interface contract
```

### 2. Refactor before abstracting

When existing code is messy (e.g., a 35-line switch statement embedded in a 200-line file), the fix is almost always extraction and reorganization — not a new abstraction layer. Ask:

- Can I extract this into its own file? (Usually yes)
- Can I extract this into its own function? (Usually yes)
- Do I need a new interface/type to make this work? (Usually no)

If the code works correctly but is just poorly organized, refactoring is the answer. A new interface is only warranted when the existing contracts cannot express the needed behavior at all.

### 3. Understand existing extension points before creating new ones

The Layer 8 framework has established extension points:
- `IServiceHandler` — CRUD operations
- `IServiceCacheListener` — cache change notifications
- `ITransactionConfig` — transaction behavior
- `IWebService` — web endpoint configuration
- `ServiceCallback` — per-service Before/After hooks

Before proposing a new extension point, verify the existing ones cannot solve the problem. The answer is almost always that they can — the feature just needs to be wired through the existing architecture differently.

## The Anti-Pattern

```
1. Working on feature X in probler/l8erp
2. Encounter framework code that doesn't have the exact hook I need
3. Add a new interface/method to l8types/go/ifs/ "to support" the feature
4. Wire the feature through the new interface
```

This is wrong because:
- Every project consuming `l8types` now sees the new interface, polluting the contract surface
- The interface was motivated by one consumer's one feature — it's not a general-purpose contract
- The framework owner has to maintain, document, and support the new interface forever
- There's almost certainly a way to solve it within the existing implementation layer

## The Correct Pattern

```
1. Working on feature X in probler/l8erp
2. Encounter framework code that needs modification
3. ASK: Can this be solved in the implementation layer (l8services, l8web, project code)?
4. If yes: refactor/extend the implementation, leave interfaces untouched
5. If genuinely no: flag to the framework owner — "I need capability Y, 
   the current interfaces don't support it" — and let them decide how to add it
```

## When Interface Changes ARE Appropriate
- The fundamental model of the system changes (e.g., adding transaction support as a concept)
- A new category of service behavior is needed across ALL projects (not just one)
- The framework owner initiates the change after understanding the cross-project impact

## Historical Context
This rule was created after an `IServiceHandlerModifier` interface was added to `l8types/go/ifs/Services.go` to support WebSocket notification hooks. It was reverted within 90 minutes. The framework owner then solved the same problem by refactoring `ServiceManager.go` — extracting notification handling into `ServiceNotifications.go` and `ServiceHandle.go` — with zero interface changes. The existing architecture was sufficient; it just needed reorganization.
