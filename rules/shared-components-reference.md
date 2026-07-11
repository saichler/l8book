# Shared Components Reference

Components shared between desktop and mobile platforms.

## Layer8EnumFactory

```js
const factory = window.Layer8EnumFactory;

// Full enum (label, value alias, CSS class)
const STATUS = factory.create([
    ['Unspecified', null, ''],
    ['Active', 'active', 'layer8d-status-active'],
    ['Inactive', 'inactive', 'layer8d-status-inactive'],
]);
// STATUS.enum = { 0: 'Unspecified', 1: 'Active', 2: 'Inactive' }
// STATUS.values = { 'active': 1, 'inactive': 2 }
// STATUS.classes = { 1: 'layer8d-status-active', 2: 'layer8d-status-inactive' }

// Simple enum (labels only, no values/classes)
const TYPE = factory.simple(['Unspecified', 'Type A', 'Type B']);

// Enum with value aliases (no classes)
const EMPLOYMENT = factory.withValues([['Full-Time', 'full-time'], ['Part-Time', 'part-time']]);
```

## Layer8RefFactory

```js
const ref = window.Layer8RefFactory;
window.MyRegistry = {
    ...ref.simple('Model', 'modelId', 'name', 'Label'),
    ...ref.person('Person', 'personId', 'lastName', 'firstName'),
    ...ref.coded('Entity', 'entityId', 'code', 'name'),
    ...ref.idOnly('LineItem', 'lineId')
};
```

## Layer8ColumnFactory

```js
const col = window.Layer8ColumnFactory;
Module.columns = {
    Model: [
        ...col.id('modelId'),
        ...col.col('field', 'Label'),
        ...col.boolean('isActive', 'Active'),
        ...col.date('createdDate', 'Created'),
        ...col.money('amount', 'Amount'),
        ...col.status('status', 'Status', enums.STATUS_VALUES, render.status),
        ...col.enum('type', 'Type', null, render.type),
        ...col.custom('key', 'Label', (item) => item.x, { sortKey: 'key' })
    ]
};
```

## Layer8FormFactory

```js
const f = window.Layer8FormFactory;
Module.forms = {
    Model: f.form('Model', [
        f.section('Info', [
            ...f.text('code', 'Code', true),
            ...f.text('name', 'Name', true),
            ...f.textarea('description', 'Description'),
            ...f.select('status', 'Status', enums.STATUS, true),
            ...f.reference('managerId', 'Manager', 'Employee'),
            ...f.date('startDate', 'Start Date'),
            ...f.money('amount', 'Amount'),
            ...f.checkbox('isActive', 'Active'),
            ...f.number('quantity', 'Quantity')
        ])
    ])
};
```

## Shared Schemas

### Column Definition (Desktop)

```js
{
    key: 'fieldName',                      // Data field (dots supported: 'user.name')
    label: 'Display Label',                // Column header
    sortKey: 'fieldName',                  // L8Query sort field
    filterKey: 'fieldName',                // L8Query filter field
    enumValues: { 'active': 1 },           // Filter validation map
    render: (item, index) => '<html>'      // Custom cell renderer
}
```

### Column Definition (Mobile)

Same as desktop plus:
```js
{
    primary: true,                         // Shown as card title
    secondary: true,                       // Shown as card subtitle
    hidden: true                           // Not rendered in card body
}
```

### Form Definition

Same schema for both desktop and mobile:

```js
{
    title: 'Employee',
    sections: [
        {
            title: 'Personal Information',
            fields: [
                { key: 'firstName', label: 'First Name', type: 'text', required: true },
                { key: 'gender', label: 'Gender', type: 'select', options: { 1: 'Male', 2: 'Female' } },
                { key: 'hireDate', label: 'Hire Date', type: 'date' },
                { key: 'salary', label: 'Salary', type: 'currency' },
                { key: 'isActive', label: 'Active', type: 'checkbox' },
                { key: 'bio', label: 'Biography', type: 'textarea' },
                { key: 'nationalId', label: 'SSN', type: 'ssn' },
                { key: 'departmentId', label: 'Dept', type: 'reference', lookupModel: 'Department' },
                { key: 'rate', label: 'Rate', type: 'percentage' },
                { key: 'phone', label: 'Phone', type: 'phone' },
                { key: 'hours', label: 'Hours', type: 'hours' }
            ]
        }
    ]
}
```

### Supported Field Types

`text`, `email`, `tel`, `number`, `textarea`, `date`, `datetime`, `select`, `checkbox`, `currency`, `percentage`, `phone`, `ssn`, `reference`, `url`, `rating`, `hours`, `ein`, `routingNumber`, `colorCode`, `period`, `file`

### Field-Level Read-Only

Any field can be marked `readOnly: true` to render as a display-only span instead of an editable input. Read-only fields are skipped during form data collection (never sent to the server on POST/PUT).

```js
{ key: 'nodeId', label: 'Node ID', type: 'text', readOnly: true }
{ key: 'severity', label: 'Severity', type: 'select', options: SEVERITY_ENUM, readOnly: true }
```

Use this for system-managed fields that the user can see but not modify (e.g., alarm identity fields, computed values). The `datetime` type is inherently display-only and does not need `readOnly`.

### Data Collection Behaviors

| Type | Input Format | Stored Value |
|------|-------------|-------------|
| currency | Dollar amount | Cents (integer) |
| percentage | Percent value | Decimal (0.75) |
| hours | HH:MM | Total minutes |
| date | Calendar picker | Unix timestamp (0 = Current/N/A) |
| reference | Picker | ID value |
| checkbox | Toggle | 1 or 0 |
| number | Number | parseFloat |
| period | 3 cascading selects (type/year/value) | `{periodType, periodYear, periodValue}` (L8Period) |

## Layer8Markdown

Converts markdown text to sanitized HTML. Supports bold, italic, inline code, code blocks (with optional language), headers (h1-h6), unordered/ordered lists, horizontal rules, and links.

```js
Layer8Markdown.render(text)              // Returns HTML string
Layer8Markdown.renderInto(element, text) // Renders directly into DOM element
```

## Layer8FileUpload

**Global object:** `window.Layer8FileUpload` (shared between desktop and mobile)

Uploads and downloads files via the backend `FileStore` protobuf service. Files are sent as base64-encoded bytes within standard JSON requests. Maximum file size: 5MB.

```js
// Upload a file
const result = await Layer8FileUpload.upload(file, documentId, version)
// Returns: { storagePath, fileName, fileSize, mimeType, checksum }

// Download a file
await Layer8FileUpload.download(storagePath, fileName)

// Format bytes to human-readable
Layer8FileUpload.formatSize(bytes)    // e.g., "1.5 MB"
```

**Form field type:** `f.file(key, label, required)` creates a file upload field.
- Desktop: drag-and-drop area with "Drop file here or click to browse (max 5MB)"
- Mobile: native `<input type="file">` (triggers camera/gallery picker)
- Data collection spreads `storagePath`, `fileName`, `fileSize`, `mimeType`, and `checksum` onto the form data object.

## Layer8CsvExport

**Global object:** `window.Layer8CsvExport` (shared between desktop and mobile)

Posts to the backend `CsvExport` service which pages through all data server-side, builds a CSV with attribute-based column headers, and returns the complete CSV string. The client triggers a browser file download.

Backend endpoint: `POST /erp/0/CsvExport` with JSON body:
```json
{ "modelType": "Employee", "serviceName": "Employee", "serviceArea": 30 }
```

```js
Layer8CsvExport.export({
    modelName: 'Employee',
    serviceName: 'Employee',
    serviceArea: 30,
    filename: 'Employee'
});

Layer8CsvExport.parseEndpoint(endpoint)    // '/erp/30/Employee' -> { serviceName, serviceArea }
```

The Export button appears automatically in both desktop and mobile pagination bars when `endpoint` and `modelName` are set.
