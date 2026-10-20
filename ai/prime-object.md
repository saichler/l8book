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
