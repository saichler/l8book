# Mock Data Generation Rules

## Mock Data Generation for New ERP Modules

### Location
All mock data files live in `go/tests/mocks/`. The system generates phased, dependency-ordered mock data with realistic ("flavorable") distributions.

### Prerequisites
- Module protobuf types exist in `go/types/<module>/`
- Module service area number is known (HCM=10, FIN=40, SCM=50)

### Step-by-Step Process

#### Step 1: Read the new module's protobuf files
- Identify all structs (models), their exact field names/types, and enums
- Note cross-module references (fields pointing to HCM employees, FIN vendors, etc.)
- Pay close attention to actual field names — they often differ from what you'd guess (e.g., `RmaId` not `AuthorizationId`)

#### Step 2: Determine phase ordering
- Group models by dependency: foundation objects first, then objects that reference them
- Typically 5-10 phases per module
- Foundation (no deps) -> Core entities -> Dependent objects -> Transactions -> Planning/Analytics

#### Step 3: Add module data arrays to `data.go`
- Curated name arrays for realistic variety (category names, entity names, etc.)
- Place after existing module data with a comment header

#### Step 4: Add ID slices to `store.go`
- One `[]string` per model in the `MockDataStore` struct, grouped by phase with comments
- Use module prefix for names that could collide with other modules (e.g., `SCMWarehouseIDs`, `SCMCarrierIDs`)

#### Step 5: Create generator files (parallelizable)
- One file per logical group (e.g., `gen_<module>_foundation.go`, `gen_<module>_inventory.go`)
- Each file must stay under 500 lines
- Each function signature: `func generate<Models>(store *MockDataStore) []*<module>.<Model>`
  - Foundation generators with no store deps use: `func generate<Models>() []*<module>.<Model>`
- Patterns to follow:
  - Allocate slice, loop with flavorable distributions (e.g., 60% APPROVED status)
  - `createAuditInfo()` for all audit fields
  - `&erp.Money{Amount: <cents>, CurrencyCode: "USD"}` for monetary fields
  - `time.Unix()` / `.Unix()` for date fields
  - `&erp.DateRange{StartDate: ..., EndDate: ...}` for date ranges
  - Reference `store.*IDs` with modulo indexing for cross-model/cross-module links
  - ID format: `fmt.Sprintf("<prefix>-%03d", i+1)`
- These files can all be created in parallel since they have no interdependencies

#### Step 6: Create phase orchestration files
- `<module>_phases.go` (and `<module>_phases<N>_<M>.go` if needed to stay under 500 lines)
- Each phase function:
  1. Calls the generator function
  2. Posts to `/erp/<serviceArea>/<ServiceName>` using `client.post()` with the `*List` wrapper type
  3. Appends returned IDs to `store.*IDs`
  4. Prints count
- ServiceName must be 10 characters or less

#### Step 7: Update `main.go`
- Add phase calls after existing modules (with Printf headers)
- Add summary Printf section at the end showing key entity counts

#### Step 8: Build and verify
- `go build ./tests/mocks/` and `go vet ./tests/mocks/`
- Most common error: proto field names differ from expectations — always verify against the `.pb.go` files

### Key Patterns

#### Flavorable distributions
- Use proportional status assignment: e.g., first 60% get APPROVED, next 20% get IN_PROGRESS, rest cycle through remaining statuses
- Random but bounded values: `rand.Intn(max-min) + min`
- Money amounts in cents: `int64(rand.Intn(rangeSize) + minimum)`

#### Cross-module references
- HCM: `EmployeeIDs`, `ManagerIDs`, `DepartmentIDs` (for managers, requesters, assignees)
- FIN: `VendorIDs` (for procurement, suppliers), `CustomerIDs` (for shipments, returns)
- Always check `len(store.*IDs) > 0` before accessing when the dependency is optional

#### File naming convention
- Generator files: `gen_<module>_<group>.go`
- Phase files: `<module>_phases.go`, `<module>_phases<N>_<M>.go`

## Mock Endpoint Construction

### Endpoint Format
Mock endpoints must follow this exact format:
```
/erp/{ServiceArea}/{ServiceName}
```

### Finding the Correct ServiceName
The `ServiceName` constant is defined in each service's `*Service.go` file. Before writing a mock endpoint:

1. Locate the service file: `go/erp/{module}/{servicedir}/*Service.go`
2. Find the `ServiceName` constant (typically around line 30)
3. Use that exact value in the endpoint

### Example
For Sales Territory service:
```go
// In go/erp/sales/salesterritories/SalesTerritoryService.go
const (
    ServiceName = "Territory"  // <-- Use this value
    ServiceArea = byte(60)
)
```

Mock endpoint should be:
```go
client.post("/erp/60/Territory", &sales.SalesTerritoryList{...})
```

**NOT** `/erp/60/SalesTerritory` (incorrect - doesn't match ServiceName)

### ServiceName Constraint
ServiceName must be 10 characters or less (per maintainability.md). This is why names are abbreviated:
- `Territory` not `SalesTerritory`
- `DlvryOrder` not `DeliveryOrder`
- `CustSegmt` not `CustomerSegment`

### Verification Checklist
Before creating mock phase files:
1. Run: `grep "ServiceName = " go/erp/{module}/**/*Service.go` to list all service names
2. Cross-reference each mock endpoint against the grep output
3. Ensure exact match between endpoint path segment and ServiceName constant

### Common Mistakes to Avoid
- Using the type name (e.g., `SalesTerritory`) instead of ServiceName (`Territory`)
- Guessing abbreviated names instead of checking the actual constant
- Forgetting that ServiceName has a 10-character limit

## Mock Phase Ordering: Cross-Module Dependencies

### Rule
When adding server-side validation (e.g., `ValidateRequired`) for a foreign key field, you MUST verify that the mock data phase ordering ensures the referenced entity's IDs are populated BEFORE any generator that uses them.

### Why This Matters
Mock generators use `pickRef(store.XxxIDs, index)` to reference entities from other modules. If `store.XxxIDs` is empty (because the referenced module hasn't run yet), `pickRef` returns `""`, and any `ValidateRequired` check on that field will fail with "XxxId is required".

### The `pickRef` Trap
```go
func pickRef(ids []string, index int) string {
    if len(ids) == 0 {
        return ""  // Silent empty string, not an error!
    }
    return ids[index%len(ids)]
}
```

`pickRef` does NOT panic or warn when the slice is empty. It silently returns an empty string, which passes Go compilation but fails server validation at runtime.

### Current Module Phase Order (in `main_phases.go`)

FIN and HCM have a circular dependency, resolved by splitting FIN:
```
1. FIN Foundation (Phases 1-3) — CurrencyIDs, FiscalYearIDs, Accounts, Vendors, Customers
2. HCM (all phases)            — EmployeeIDs, DepartmentIDs (needs CurrencyIDs)
3. FIN Remaining (Phases 4-9)  — Budgets, AP, AR, GL, Assets, Tax (needs DepartmentIDs, EmployeeIDs)
4. SCM
5. Sales
6. MFG
7. CRM
8. PRJ
9. BI
10. DOC
11. ECOM
12. COMP
```

### Why FIN is Split
- FIN Phases 1-3: No HCM dependency. Provides CurrencyIDs needed by ALL modules.
- FIN Phase 4 (`gen_fin_config.go`): Uses `store.DepartmentIDs` for Budgets.
- FIN Phase 8 (`gen_fin_assets.go`): Uses `store.EmployeeIDs` and `store.DepartmentIDs`.
- HCM: Uses `store.CurrencyIDs` in gen_compensation.go, gen_payroll.go, gen_benefits.go, gen_employee_data.go.

**When splitting modules like this, use `runXxxFoundation()` and `runXxxRemaining()` in `main_phases_modules*.go`.**

### Checklist When Adding Required Validation

Before adding `common.ValidateRequired(entity.SomeId, "SomeId")` to a service callback:

1. **Identify which module generates the referenced IDs** (e.g., CurrencyIDs come from FIN)
2. **Check `main_phases.go`** to confirm that module runs BEFORE the module being validated
3. **Check mock generators** for the validated entity — verify they set the field using `pickRef(store.XxxIDs, ...)`
4. **If the referenced module runs AFTER**, either:
   - Reorder modules in `main_phases.go` (preferred if no circular dependency)
   - Move the referenced entity generation to an earlier cross-module bootstrap phase

### Common Cross-Module Dependencies
| Field | Source Module | Source Phase | Used By |
|-------|-------------|-------------|---------|
| CurrencyIDs | FIN | Phase 1 | ALL modules (via Money fields) |
| EmployeeIDs | HCM | Phase 1-3 | FIN 8, CRM, PRJ, MFG, Sales |
| DepartmentIDs | HCM | Phase 1 | FIN 4+8, PRJ, MFG |
| VendorIDs | FIN | Phase 2 | SCM, MFG |
| CustomerIDs | FIN | Phase 2 | Sales, ECOM, CRM |
| ItemIDs | SCM | Phase 1 | Sales, MFG, ECOM |

### Direct Index Access Trap
Some generators use `store.XxxIDs[i]` or `store.XxxIDs[0]` (direct index, not `pickRef`). These will **panic** with "index out of range" if the slice is empty, rather than silently returning "". Both patterns are dangerous but panics are at least immediately visible.
