# Protobuf Rules (CRITICAL)

## Model Names Must Match Protobuf Types

### Rule
Everywhere a model name is used — L8Query strings, JS config, forms, columns, reference lookups, navigation — it MUST be the **protobuf type name**, NOT the ServiceName constant. These are often different.

### Why This Matters
The server resolves model names against the protobuf type registry. If the name doesn't match a registered protobuf type, the server returns `Cannot find node for table <wrong-name>`. The ServiceName is an HTTP routing label (max 10 chars); the protobuf type is the actual data model name.

### Common Mismatches

#### ServiceName vs Protobuf Type
| ServiceName (HTTP path) | Protobuf Type (use this) |
|------------------------|-----------------------------|
| `Sprint` | `BugsSprint` |
| `Project` | `BugsProject` |
| `Territory` | `SalesTerritory` |
| `DlvryOrder` | `ScmDeliveryOrder` |
| `MfgWorkOrd` | `MfgWorkOrder` |
| `ImprtTmpl` | `L8ImportTemplate` |

#### Module Prefix Omission (JS-specific)
Protobuf types often have a module prefix. Never omit it:

| Wrong (JS) | Correct (JS) |
|------------|--------------|
| `ReturnOrder` | `SalesReturnOrder` |
| `CustomerHierarchy` | `SalesCustomerHierarchy` |
| `PurchaseOrder` | `ScmPurchaseOrder` |
| `Warehouse` | `ScmWarehouse` |

### Where Model Names Are Used

#### In L8Query Strings
```javascript
// CORRECT — protobuf type name
const query = 'select * from SalesTerritory';

// WRONG — ServiceName
const query = 'select * from Territory';  // 400 Bad Request
```

#### In JavaScript UI Files
1. **Config files** (`*-config.js`): `{ model: 'SalesReturnOrder' }`
2. **Form definitions** (`*-forms.js`): `Module.forms = { SalesReturnOrder: { ... } }`
3. **Column definitions** (`*-columns.js`): `Module.columns = { SalesReturnOrder: [...] }`
4. **Primary key mappings**: `Module.primaryKeys = { SalesReturnOrder: 'returnOrderId' }`
5. **Reference lookups**: `{ lookupModel: 'ScmWarehouse' }`
6. **Navigation configs**: `{ model: 'SalesReturnOrder' }`

### Finding the Correct Names
ServiceName is in `*Service.go` files. Protobuf type is in `*.pb.go` files.

```bash
# Find protobuf types for a module
grep "type Sales" go/types/sales/*.pb.go | grep "struct {"

# List all type names
grep -oP "type \K\w+" go/types/sales/*.pb.go | grep -v "^is" | sort -u

# Confirm a specific type exists
grep "type.*struct {" go/types/<module>/*.pb.go | grep -i <keyword>
```

### Error Symptoms
- HTTP 400 Bad Request on a GET with `?body=` query parameter
- Server log: `Cannot find node for table <wrong-name>`
- `(Error) - Cannot find node for table ReturnOrder` (should be `SalesReturnOrder`)

### Files to Check When Adding a Module
- `*-config.js` — `model` property
- `*-forms.js` — form definition keys and `lookupModel` references
- `*-columns.js` — column definition keys
- `*-renderers.js` — model references
- `layer8m-nav-config.js` — mobile navigation
- `reference-registry*.js` — registry keys

## Enum Zero Value Convention

### Rule
Every protobuf enum MUST have an invalid/unspecified zero value as its first entry. The zero value MUST NOT represent a valid, meaningful state.

### Why This Matters
Protobuf defaults unset enum fields to 0. If 0 is a valid value (e.g., "Active"), then unset fields silently appear as "Active" instead of being detectable as missing. This makes it impossible to distinguish "explicitly set to the first value" from "never set."

### Naming Convention
The zero value name MUST follow this pattern:
```
[MODULE_PREFIX_]FIELD_NAME_UNSPECIFIED = 0
```

Examples:
```protobuf
// CORRECT
enum AccountType {
  ACCOUNT_TYPE_UNSPECIFIED = 0;
  ACCOUNT_TYPE_ASSET = 1;
  ACCOUNT_TYPE_LIABILITY = 2;
}

enum MfgBomStatus {
  MFG_BOM_STATUS_UNSPECIFIED = 0;
  MFG_BOM_STATUS_DRAFT = 1;
  MFG_BOM_STATUS_ACTIVE = 2;
}

// WRONG - 0 is a valid value
enum Priority {
  LOW = 0;      // BAD: unset fields appear as LOW
  MEDIUM = 1;
  HIGH = 2;
}

// WRONG - no zero value
enum Status {
  ACTIVE = 1;   // BAD: no 0 value defined
  INACTIVE = 2;
}
```

### Verification
After creating or modifying any proto file with enums:
```bash
# Check all enums have a 0 value containing UNSPECIFIED, INVALID, or UNKNOWN
grep -A1 "^enum " proto/*.proto | grep "= 0" | grep -iv "unspecified\|invalid\|unknown"
```
If any results appear, those enums need a proper zero value.

### Current Compliance
All 289 ERP enums across 12 modules follow this convention (verified Feb 2026).

## List Type Convention

### Rule
All protobuf list/collection message types must follow this exact pattern:

```protobuf
message SomeEntityList {
  repeated SomeEntity list = 1;
  l8api.L8MetaData metadata = 2;
}
```

### Key Points
- The repeated field MUST be named `list` (not `items`, `entries`, `data`, etc.)
- The `l8api.L8MetaData metadata` field MUST be included as field 2
- This pattern is required by the Layer8 framework for proper serialization and iteration

### Why This Matters
The Layer8 framework expects the `list` field name when iterating over collection types. Using a different field name (like `items`) will cause runtime errors such as:
```
invalid <TypeName> type
```

### Verification
Before creating new proto files, verify the pattern against existing modules:
```bash
grep -A3 "List {" proto/*.proto | head -20
```

### Example
```protobuf
// CORRECT
message EcomCategoryList {
  repeated EcomCategory list = 1;
  l8api.L8MetaData metadata = 2;
}

// WRONG - will cause runtime errors
message EcomCategoryList {
  repeated EcomCategory items = 1;
}
```

## Protobuf Generation

### Rule
Whenever ANY `.proto` file is created, modified, or removed, you **MUST** run `make-bindings.sh` to regenerate ALL protobuf bindings. **NO EXCEPTIONS.**

**NEVER attempt to compile individual proto files manually.** Do NOT run individual `docker run` commands or `protoc` commands. The ONLY way to generate bindings is via `make-bindings.sh`. This is a hard requirement — violating it wastes time and produces errors.

### How to Run

```bash
cd proto && ./make-bindings.sh
```

**Before running**, check that `make-bindings.sh` uses `-i` (not `-it`) on all `docker run` commands. The `-t` flag requires a TTY and will fail when run from Claude Code or other non-interactive environments. If you see `-it`, change it to `-i`.

**What will break if you try other methods:**
- Running individual `docker run` commands manually — misses dependency ordering, move steps, and sed fixups
- Running `wget` + `protoc` commands manually — misses the full pipeline
- Running from any directory other than `proto/` — paths break

The script handles everything automatically:
1. Downloads `api.proto` dependency
2. Compiles ALL proto files in the correct order
3. Moves generated `.pb.go` files to `/go/types/`
4. Fixes import paths

### When to Run
- After ANY change to ANY `.proto` file (add field, remove field, add message, remove message, add import, etc.)
- After adding a new `.proto` file (also update `make-bindings.sh` to include it)
- After removing a `.proto` file (also update `make-bindings.sh` to remove it)

### Why This Matters
- Generated .pb.go files contain the actual Go struct definitions
- Field names in generated code may differ from what you expect
- Building code that uses these types before generation will fail
- Mock data generators, services, and UI code all depend on these types
- The script handles cross-file imports, dependency ordering, and path fixups that manual compilation misses

### After Running
1. Verify `.pb.go` files exist in `/go/types/<module>/`
2. Build dependent code to ensure types are correct: `go build ./...`

### Field Name Verification
After generation, verify field names by checking the .pb.go files:
```bash
grep -A 30 "type TypeName struct" go/types/<module>/*.pb.go | grep 'json:"'
```
