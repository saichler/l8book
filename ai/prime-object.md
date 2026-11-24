# Prime Object Guidelines

## Rule 1: What IS a Prime Object

Entity that can exist independently with its own identity and lifecycle. ALL four tests must pass:
1. **Independence**: exists without a parent
2. **Own lifecycle**: CRUD independent of parent
3. **Direct query need**: users query it across all parents
4. **No parent ID dependency**: identity stands alone

**NOT Prime Objects** (embed as `repeated` fields): line items, entries/details, components/operations, assignments/members, child records, config children, status/history records. Key indicator: has a required `parent_id` field.

```protobuf
message SalesOrder {
    string sales_order_id = 1;
    repeated SalesOrderLine lines = 20;      // Embedded child
}
message SalesOrderLine {
    string line_id = 1;
    string item_id = 2;    // Ref to Prime Object by ID
}
```

## Rule 2: Cross-References Between Prime Objects

Prime Objects MUST NEVER contain `*OtherPrimeType` or `[]*OtherPrimeType`. Reference other Prime Objects ONLY via string ID fields. Direct struct refs cause "Decorator Not Found" errors because introspector creates duplicate nodes.

Allowed: shared/common types (`common.Money`, `common.Address`, `common.ContactInfo`, `common.DateRange`, `common.AuditInfo`, defined in `prime-object-types.proto`), embedded child types, string ID fields.

## Rule 3: The Primary Key Is a String UUID

A Prime Object's ID/key field is ALWAYS `string` holding a UUID -- NEVER `int32`/`int64`. Generated on create (POST) as a new UUID when empty; a preset ID, e.g. on import, is kept. References to Prime Objects (Rule 2) are strings too. There are no numeric IDs anywhere in the model, so code must never convert an ID to a number (`parseInt`, `Number()`, `strconv.Atoi`) -- doing so once cut every digit-leading UUID to its leading number (`"4660db2e-..."` -> `4660`).

```protobuf
// CORRECT                          // WRONG
string sales_order_id = 1;          int64 sales_order_id = 1;
```

## Rule 4: Model Names Must Match Protobuf Types

Use the protobuf type name everywhere (queries, UI config, forms, columns, navigation), NOT the service name.

| Service name | Protobuf Type (use this) |
|---|---|
| `Territory` | `SalesTerritory` |
| `DlvryOrder` | `ScmDeliveryOrder` |
| `MfgWorkOrd` | `MfgWorkOrder` |

Never omit the module prefix: `SalesReturnOrder` not `ReturnOrder`, `ScmWarehouse` not `Warehouse`.

```bash
grep "type Sales" <generated-dir>/*.pb.go | grep "struct {"
```

## Rule 5: Enum Zero Value

Every enum MUST have `[PREFIX_]FIELD_NAME_UNSPECIFIED = 0`. Zero must NOT be a valid state.

```protobuf
enum AccountType {
  ACCOUNT_TYPE_UNSPECIFIED = 0;
  ACCOUNT_TYPE_ASSET = 1;
}
```

```bash
grep -A1 "^enum " proto/*.proto | grep "= 0" | grep -iv "unspecified\|invalid\|unknown"
```

## Rule 6: List Type Convention

Every Prime Object `SomeEntity` MUST have a matching `SomeEntityList` message.

```protobuf
message SomeEntityList {
  repeated SomeEntity list = 1;       // MUST be named "list"
  common.MetaData metadata = 2;       // MUST be field 2 (see prime-object-types.proto)
}
```

## Rule 7: Protobuf Generation

Regenerate the bindings with the project's single generation script after ANY `.proto` change. NEVER compile individual proto files manually. After generating, verify the generated files exist and the project builds.

```bash
grep -A 30 "type TypeName struct" <generated-dir>/*.pb.go | grep 'json:"'
```

## Rule 8: Annotate Sensitive Fields with `(l8ai.AIMask)`

A field whose value must never reach an LLM in clear text MUST be annotated `[(l8ai.AIMask) = true]`. The annotation is the **only** thing the l8ai chat agent (Tanto) masks by -- it does not guess from field names. Unannotated fields are sent as is, so a missing annotation leaks the value; and a name that only looks sensitive is not masked (guessing hid probler's `GpuDevice.deviceInfo` and made Tanto answer that the GPU count was hidden).

```protobuf
import "aimask.proto";

message Employee {
  string employee_id = 1;
  string national_id = 7 [(l8ai.AIMask) = true];
  common.Address home_address = 8 [(l8ai.AIMask) = true];   // the whole nested message
}
message Secret {                                            // probler, Kubernetes Secret
  map<string, bytes> data = 4 [(l8ai.AIMask) = true];
  map<string, string> string_data = 5 [(l8ai.AIMask) = true];
}
```

- Works on any field of a Prime Object or an embedded child: scalar, `repeated`, `map`, or a whole nested message.
- The agent replaces the value (and any aggregate over it) in every tool result with a token stable within the conversation, and restores it in the answer shown to the user, who is allowed to see it. Masking is for the LLM only -- it is not access control; field/row security stays in l8secure.
- Annotate secrets, credentials and key material, and personal identifiers (national ID, tax ID, bank account, home address, personal contact details). Do not annotate fields the agent must reason over (counts, statuses, names of things, metrics, IDs of Prime Objects) -- a masked field cannot be counted or compared meaningfully.
- Review every `.proto` when adding a model, and when adopting l8ai.

**Generation (Rule 7):** `aimask.proto` comes from l8ai, like `api.proto` from l8types. The generation script downloads it, removes it afterwards, and rewrites the generated import:

```bash
wget https://raw.githubusercontent.com/saichler/l8ai/refs/heads/main/proto/aimask.proto
# ... protoc runs ...
rm aimask.proto
find . -name "*.go" -type f -exec sed -i 's|"./types/l8ai"|"github.com/saichler/l8ai/go/types/l8ai"|g' {} +
```

```bash
grep -n "AIMask" proto/*.proto                                     # every sensitive field listed
grep -ln "AIMask" proto/*.proto | xargs grep -L 'import "aimask.proto"'   # expect empty
```

Reference: `l8ai/proto/aimask.proto`; worked example: probler `5d0c3de`.
