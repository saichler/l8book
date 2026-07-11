# Main Package Must Be Minimal (CRITICAL)

## Rule
The `main` package (`package main`) must contain ONLY the entry point logic — creating resources, starting the vnic, and calling into other packages. All business logic, services, and domain code MUST live in their own dedicated packages.

## Why This Matters
The `main` package is special in Go — it cannot be imported by other packages. Putting logic in `main` makes it untestable, unreusable, and violates separation of concerns. The `main` function should be a thin orchestrator that wires together components from other packages.

## Correct Pattern
```go
// go/<project>/<binary>/main.go — ONLY entry point
package main

import (
    "github.com/saichler/<project>/go/<project>/engine"
    "github.com/saichler/<project>/go/<project>/common"
)

func main() {
    res := common.CreateResources("engine")
    nic := startVnic(res)
    engine.NewEngine(nic, res).Run()
    common.WaitForSignal(res)
}
```

```go
// go/<project>/engine/engine.go — business logic in its own package
package engine

type Engine struct { ... }
func NewEngine(...) *Engine { ... }
func (e *Engine) Run() { ... }
```

## Wrong Pattern
```go
// WRONG — hundreds of lines of logic in package main
package main

type Engine struct { ... }
func (e *Engine) analyzeSymbol(...) { ... }
func (e *Engine) generatePredictions(...) { ... }
func (e *Engine) executeTrades(...) { ... }
// ... 800+ lines of business logic
```

## What Belongs in main
- Resource/config creation
- Vnic initialization and connection
- Calling `Activate` functions from other packages
- Starting the database (if applicable)
- Signal wait / graceful shutdown

## What Does NOT Belong in main
- Structs with methods (business logic types)
- Data processing, analysis, or transformation
- Service callbacks or handlers
- Helper/utility functions
- Constants beyond simple config values
