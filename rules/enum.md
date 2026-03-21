# Enum, Renderer, and Column Factory Rules (CRITICAL)

All three rules below cause the same silent cascading failure: a TypeError during module initialization → `Module.render` or `Module.columns` remains `undefined` → ALL tables fall back to DEFAULT_COLUMNS (`id`, `name`, `status`). No console error unless DevTools is open.

---

## Rule 1: Renderer API — Use renderEnum, Not createEnumRenderer

`createEnumRenderer` does NOT exist in `Layer8DRenderers`. Never use it.

### Available Functions in Layer8DRenderers

| Function | Type | Usage |
|----------|------|-------|
| `renderEnum(value, enumMap)` | Direct renderer | Wrap: `(v) => renderEnum(v, map)` |
| `renderStatus(value, enumMap, classMap)` | Direct renderer | Wrap: `(v) => renderStatus(v, map, classes)` |
| `createStatusRenderer(enumMap, classMap)` | Factory (returns function) | Call directly: `createStatusRenderer(map, classes)` |
| `renderDate` | Function reference | Assign directly: `date: renderDate` |
| `renderBoolean(value, options)` | Direct renderer | Wrap: `(v) => renderBoolean(v, opts)` |

### Correct Patterns
```javascript
// Plain enum — wrap renderEnum in an arrow function
myField: (value) => renderEnum(value, MY_ENUM.enum),

// Status enum — createStatusRenderer exists and returns a function
myStatus: createStatusRenderer(MY_STATUS.enum, MY_STATUS.classes),

// Correct destructuring
const { createStatusRenderer, renderEnum, renderDate } = Layer8DRenderers;
```

### Wrong Patterns
```javascript
// WRONG — createEnumRenderer does not exist, yields undefined
myField: createEnumRenderer(MY_ENUM.enum),

// WRONG — calls renderEnum immediately with wrong args
assigneeType: renderEnum(ASSIGNEE_TYPE.enum),

// CORRECT alternative — use arrow wrapper
assigneeType: (value) => renderEnum(value, ASSIGNEE_TYPE.enum),
```

---

## Rule 2: Every f.select() Must Reference an Exported Enum

`f.select('field', 'Label', enums.SOME_ENUM)` stores `enums.SOME_ENUM` as `field.options`. If `SOME_ENUM` is not exported, `field.options` is `undefined`. When the detail modal opens, `generateSelectHtml()` throws:
```
Uncaught TypeError: Cannot convert undefined or null to object
    at Object.entries (<anonymous>)
    at generateSelectHtml (layer8d-forms-fields.js:284)
```

This crash is **deferred** — only when a user clicks a row to open the detail view.

### Checklist When Adding f.select()
1. Identify the enum name (e.g., `enums.SEGMENT_TYPE`)
2. Open the `*-enums.js` file and verify it exists in the `.enums = { ... }` export
3. If missing: check protobuf for values, add `factory.create([...])`, add to exports, add renderer if used in columns
4. Verify on BOTH desktop and mobile

---

## Rule 3: Column Factory Method Completeness

1. Every column factory method used in `*-columns.js` MUST exist in `layer8-column-factory.js`.
2. Every `col.enum()` and `col.status()` call MUST pass a valid function as the `renderer` argument (4th parameter).

### Why Atomic Failure Occurs
```javascript
Module.columns = {
    ModelA: [
        ...col.id('id'),          // would work
        ...col.number('qty'),     // THROWS if col.number doesn't exist
    ],
    ModelB: [...],                // never reached
};
```

### Available Factory Methods
Keep synchronized with `layer8-column-factory.js`:
- `col(key, label)` — basic text column
- `basic(keys)` — multiple basic columns from array
- `number(key, label)` — numeric column
- `boolean(key, label, options)` — boolean column
- `status(key, label, enumValues, renderer)` — status badge column
- `enum(key, label, enumValues, renderer)` — enum text column
- `date(key, label)` — date column
- `money(key, label)` — money column
- `period(key, label)` — period column
- `id(key, label)` — ID column
- `custom(key, label, renderFn, options)` — custom render column
- `link(key, label, onClick, displayFn)` — clickable link column

### Common Renderer Causes of Failure
```javascript
// 1. Missing render property in enums file
Module.render = {
    statusA: createStatusRenderer(...),
    // statusB is missing!
};
...col.enum('status', 'Status', null, render.statusB)  // undefined

// 2. Wrong argument order (3 args instead of 4)
...col.enum('status', 'Status', render.myFunc)     // WRONG
...col.enum('status', 'Status', null, render.myFunc) // CORRECT

// 3. Render object not yet populated (script load order)
const render = Module.render;  // undefined if enums hasn't loaded
```

### When Adding a New Column Type
1. **Add the method to `layer8-column-factory.js` FIRST**
2. **Then** use it in `*-columns.js` files
3. **Never** use a factory method that doesn't exist yet

---

## The Shared Cascade Failure

All three rules produce the same catastrophic result:

1. TypeError in enums or columns file → `Module.render` or `Module.columns` never assigned
2. Columns file: `const render = Module.render` → `undefined`
3. `render.xxx` → TypeError → `Module.columns` never assigned
4. ALL tables fall back to DEFAULT_COLUMNS: `id`, `name`, `status`
5. ALL columns appear empty across ALL sections
6. No console error unless DevTools is open before page load

## Error Symptoms
- ALL table sections show only `id`, `name`, `status` columns
- Clicking a row crashes with `Cannot convert undefined or null to object` (missing enum)
- Status columns show raw numbers instead of labels (wrong renderer call)
- TypeError in console: `col.xxx is not a function` or `renderer is not a function`
- Looks like a data/serialization bug, but the real cause is a missing factory method, enum, or renderer

## Verification
```bash
# Check all factory method calls exist
grep -oP 'col\.(\w+)\(' *-columns.js | sort -u
grep -oP '^\s+(\w+):\s*function' layer8-column-factory.js | sort -u

# Extract all enum references from f.select() calls
grep -oP "enums\.\K[A-Z_]+" <forms-file>
# Check each one exists in the enums file
grep "<ENUM_NAME>" <enums-file>

# After modifying any *-columns.js:
# 1. Verify every col.enum()/col.status() has exactly 4 arguments
# 2. Verify the 4th argument exists in the corresponding *-enums.js render object
# 3. Check browser console for renderer validation errors
```
