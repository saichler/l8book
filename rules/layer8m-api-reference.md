# Layer8M Mobile API Reference

Quick reference for all Layer8M mobile UI components.

## Layer8MConfig

```js
await Layer8MConfig.load()                     // Fetches /login.json
Layer8MConfig.getConfig()                      // Returns raw { login: {...}, app: {...} }
Layer8MConfig.resolveEndpoint('/30/Employee')   // '/erp/30/Employee'
Layer8MConfig.getDateFormat()                   // 'mm/dd/yyyy'
Layer8MConfig.registerModules({...})            // Register module configs
Layer8MConfig.registerReferences({...})         // Register reference picker data
Layer8MConfig.getReferenceConfig('Employee')    // Get reference config
```

**Note:** `getConfig()` returns raw login.json. Access app config via `config.app.healthPath`, NOT `config.healthPath`.

## Layer8MAuth

```js
Layer8MAuth.requireAuth()                      // Redirect if not authenticated
Layer8MAuth.getUsername()                       // Username from sessionStorage
Layer8MAuth.logout()                           // Clear session, redirect

// HTTP methods (auto-attach bearer token)
await Layer8MAuth.get(url)                     // GET, returns parsed JSON
await Layer8MAuth.post(url, data)              // POST
await Layer8MAuth.put(url, data)               // PUT
await Layer8MAuth.delete(url, data?)           // DELETE (data sent as JSON body)
```

## Layer8MUtils

```js
Layer8MUtils.escapeHtml(text)
Layer8MUtils.formatDate(timestamp)             // Unix seconds -> 'MM/DD/YYYY'
Layer8MUtils.formatDateTime(timestamp)
Layer8MUtils.parseDateToTimestamp(dateString)
Layer8MUtils.formatMoney(cents, currency?)
Layer8MUtils.formatPercentage(decimal)
Layer8MUtils.formatPhone(digits)
Layer8MUtils.formatSSN(digits, masked?)
Layer8MUtils.getNestedValue(obj, 'a.b.c')
Layer8MUtils.debounce(fn, ms)
Layer8MUtils.showSuccess(message)              // Toast
Layer8MUtils.showError(message)                // Toast
```

## Layer8MPopup

```js
Layer8MPopup.show({
    title: 'Edit Employee',
    content: '<div>...</div>',
    size: 'large',                             // 'small'|'medium'|'large'|'full'
    showFooter: true,
    saveButtonText: 'Save',
    cancelButtonText: 'Cancel',
    showCancelButton: true,
    onSave: (popup) => {},                     // popup.body for DOM access
    onShow: (popup) => {},                     // Called after render
    onTabChange: (tabId, popup) => {}          // Called when tab switches (50ms delay for layout)
});
Layer8MPopup.close()
Layer8MPopup.getBody()
```

## Layer8MConfirm

```js
const confirmed = await Layer8MConfirm.show({
    title: 'Confirm', message: 'Are you sure?',
    confirmText: 'Yes', cancelText: 'No', destructive: false
});
const confirmed = await Layer8MConfirm.confirmDelete('Employee Name');
```

## Layer8MDatePicker

```js
Layer8MDatePicker.show({
    value: 1609459200,                         // Unix timestamp
    minDate: 1577836800,
    maxDate: 1735689600,
    title: 'Select Date',
    onSelect: (timestamp, dateStr) => {}       // null for clear
});
```

## Layer8MReferencePicker

```js
Layer8MReferencePicker.show({
    endpoint: '/erp/30/Department',
    modelName: 'Department',
    idColumn: 'departmentId',
    displayColumn: 'name',
    displayFormat: (item) => `${item.code} - ${item.name}`,
    selectColumns: ['departmentId', 'name', 'code'],
    pageSize: 15,
    currentValue: 'DEPT-001',
    onChange: (id, displayValue, item) => {}
});
Layer8MReferencePicker.getValue(inputElement)
Layer8MReferencePicker.setValue(input, id, displayValue, item)
```

## Layer8MRenderers

```js
Layer8MRenderers.renderEnum(value, enumMap)
Layer8MRenderers.renderBoolean(value, { trueText, falseText })
Layer8MRenderers.renderDate(timestamp)
Layer8MRenderers.renderMoney(cents, currency?)
Layer8MRenderers.renderPercentage(decimal)
Layer8MRenderers.renderPhone(digits)
Layer8MRenderers.renderSSN(digits)
Layer8MRenderers.renderHours(hours)
Layer8MRenderers.renderPeriod({ startDate, endDate })
Layer8MRenderers.renderRating(value, max?)
Layer8MRenderers.renderProgress(value)
Layer8MRenderers.renderPriority(value, priorityMap)
Layer8MRenderers.renderEmployeeName({ firstName, lastName })
Layer8MRenderers.renderMinutes(minutes)
Layer8MRenderers.renderCount(filled, total)
Layer8MRenderers.createStatusRenderer(enumMap, classMap)
```

## Layer8MForms

```js
const html = Layer8MForms.renderForm(formDef, data, readonly)
const data = Layer8MForms.getFormData(container)
const errors = Layer8MForms.validateForm(container)
Layer8MForms.showErrors(container, errors)
Layer8MForms.initFormFields(container)         // Init reference pickers
```

### Layer8MFormFields Extended

Extends `Layer8MFormFields` with mobile-optimized rendering for 15+ field types:

- `renderCurrencyField`, `renderPercentageField`, `renderPhoneField`, `renderSSNField`
- `renderUrlField`, `renderRatingField`, `renderHoursField`, `renderEinField`, `renderRoutingNumberField`
- `renderColorCodeField`, `renderInlineTableField`, `renderTimeField`
- `renderTagsField`, `renderMultiselectField`, `renderRichtextField`
- Tag/multiselect interaction handlers: `onTagKeydown`, `removeTag`, `toggleMultiselectDropdown`, `onMultiselectChange`

### Inline Table Handlers

Extends `Layer8MForms` with inline table management for nested child records:

```js
Layer8MForms.initInlineTableHandlers(container, formDef)
// Sets up add/edit/delete event listeners for inline table rows

// Internal methods:
// _openMobileRowEditor(fieldDef, rowIndex, rowData, onSave) -- popup row editor
// _showMobileChildDetail(fieldDef, rowData) -- read-only row detail popup
// _rerenderMobileTable(tableEl, fieldDef, rows, isReadOnly) -- re-render after changes
```

## Layer8MTable

Card-based mobile table. Constructor takes `(containerId, config)`.

```js
const table = new Layer8MTable('container-id', {
    endpoint: '/erp/30/Employee',
    modelName: 'Employee',
    columns: [...],
    rowsPerPage: 15,
    transformData: (item) => ({...}),
    statusField: 'status',
    onCardClick: (item) => {},
    getItemId: (item) => item.employeeId
});
```

### Layer8MEditTable (extends Layer8MTable)

Adds Add/Edit/Delete buttons. If callbacks are null, buttons are hidden (read-only mode).

```js
const table = new Layer8MEditTable('container-id', {
    // All Layer8MTable options plus:
    onAdd: () => {},                           // null = no add button
    addButtonText: 'Add Employee',
    onEdit: (id, item) => {},                  // null = no edit button
    onDelete: (id, item) => {},                // null = no delete button
    onRowClick: (item, id) => {},
    getItemId: (item) => item.employeeId
});
```

## Layer8MNav

```js
Layer8MNav.showHome()                          // Module cards grid
Layer8MNav.navigateToModule('hcm')             // Sub-module cards
Layer8MNav.navigateToSubModule('hcm', 'core-hr')
Layer8MNav.navigateToService('hcm', 'core-hr', 'employees')
Layer8MNav.navigateBack()
Layer8MNav.getCurrentState()                   // { level, module, subModule, service }
```

Layer8MNav looks up columns/forms/transforms from registered module objects (checked in order):
```js
[window.MobileHCM, window.MobileFIN, window.MobileSCM, window.MobileSYS, ...]
```

Each must provide:
```js
window.MobileXXX = {
    getColumns(modelName),      // Column array or null
    getFormDef(modelName),      // Form definition or null
    getTransformData(modelName) // Transform function or null (optional)
}
```

### LAYER8M_NAV_CONFIG

Navigation hierarchy:

```js
window.LAYER8M_NAV_CONFIG = {
    modules: [
        { key: 'hcm', label: 'Human Capital', icon: 'hcm', hasSubModules: true }
    ],
    hcm: {
        subModules: [
            { key: 'core-hr', label: 'Core HR', icon: 'employees' }
        ],
        services: {
            'core-hr': [
                { key: 'employees', label: 'Employees', icon: 'employees',
                  endpoint: '/30/Employee', model: 'Employee', idField: 'employeeId' },
                { key: 'leave-requests', label: 'Leave Requests', icon: 'time',
                  endpoint: '/30/LeaveReq', model: 'LeaveRequest', idField: 'requestId',
                  supportedViews: ['table', 'kanban', 'calendar'] },
                { key: 'health', label: 'Health', icon: 'health',
                  endpoint: '/0/Health', model: 'L8Health', idField: 'service',
                  readOnly: true }
            ]
        }
    },
    icons: { 'hcm': '<svg>...</svg>' },
    getIcon(key) { ... }
};
```

### Extensibility Patterns

The l8ui library is designed for extensibility. Project-specific code lives in a separate directory (e.g., `erp-ui/`) and registers with the library components.

#### Layer8MReferenceRegistry.register()

Register project-specific model reference configurations:

```js
// In erp-ui/m/reference-registries/layer8m-reference-registry-mymodule.js
const ref = window.Layer8RefFactory;

window.Layer8MReferenceRegistryMyModule = {
    ...ref.simple('Model', 'modelId', 'name', 'Label'),
    ...ref.person('Person', 'personId', 'lastName', 'firstName'),
    ...ref.coded('Entity', 'entityId', 'code', 'name'),
    ...ref.idOnly('LineItem', 'lineId')
};

// Register with the central registry
Layer8MReferenceRegistry.register(window.Layer8MReferenceRegistryMyModule);
```

#### Layer8SvgFactory.registerTemplate()

Register project-specific SVG illustration templates:

```js
// In erp-ui/erp-svg-templates.js
Layer8SvgFactory.registerTemplate('myModule', function(color) {
    return `<svg viewBox="0 0 400 300">
        <circle cx="200" cy="150" r="50" fill="${color}" opacity="0.2"/>
        <!-- more SVG content -->
    </svg>`;
});
```

Use in section generator:
```js
Layer8SectionConfigs.register('mymodule', {
    svgContent: Layer8SvgFactory.get('myModule', '#4CAF50'),
    // ...
});
```

## Layer8MModuleRegistry

Factory that creates mobile module registries, replacing manual `findModule()` boilerplate.

```js
// Creates window.MobileHCM with getColumns, getFormDef, etc.
window.MobileHCM = Layer8MModuleRegistry.create('MobileHCM', {
    'Core HR': MobileCoreHR,
    'Payroll': MobilePayroll,
    'Benefits': MobileBenefits
});
```

The created registry provides:
```js
registry.getColumns(modelName)      // Column array or null
registry.getFormDef(modelName)      // Form definition or null
registry.getEnums(modelName)        // Enums object or null
registry.getPrimaryKey(modelName)   // Primary key field name or null
registry.getRender(modelName)       // Render object or null
registry.hasModel(modelName)        // Boolean
registry.getAllModels()             // Array of all model names
registry.getModuleName(modelName)   // Sub-module name or null
```

## Layer8MViewFactory

Mobile view factory -- mirrors `Layer8DViewFactory` for mobile. Creates view instances by type. All mobile view wrappers auto-register on load.

```js
Layer8MViewFactory.register('chart', factoryFn)       // Register a view type
Layer8MViewFactory.create('chart', options)            // Create view instance
Layer8MViewFactory.has('kanban')                       // Check if type registered
```

Registered view types: `table`, `chart`, `kanban`, `calendar`, `timeline`, `gantt`, `tree`, `wizard`.

All view instances follow the same interface: `init()`, `refresh()`, `destroy()`.

**Mobile view switching:** `Layer8MNavData.loadServiceData()` reads `supportedViews` from the service config. When multiple views are available, it renders a `Layer8ViewSwitcher` dropdown above the data container. Switching views destroys the current view and creates a new one via `Layer8MViewFactory.create()`.

**Auto-detect chart:** If a service's columns include both `type: 'date'` and `type: 'money'`, `'chart'` is automatically added to the available views (same logic as desktop `layer8d-service-registry.js`).

**Service config `supportedViews`:**
```js
{ key: 'work-orders', label: 'Work Orders', endpoint: '/70/MfgWorkOrd',
  model: 'MfgWorkOrder', idField: 'workOrderId',
  supportedViews: ['table', 'kanban', 'gantt'] }
```

## Layer8MDataSource

Mobile data fetching layer -- mirrors `Layer8DDataSource` for mobile. Builds L8Query strings, handles pagination, and enforces the metadata-on-page-1-only rule.

```js
const ds = new Layer8MDataSource({
    endpoint: '/erp/30/Employee',
    modelName: 'Employee',
    columns: [...],
    pageSize: 15,
    baseWhereClause: 'status=1',
    transformData: (item) => ({...}),
    onDataLoaded: (items, total) => {},
    onError: (err) => {},
    onMetadata: (metadata) => {}
});

ds.fetchData(page)                      // Fetch page (1-indexed)
ds.buildQuery(page, pageSize)           // Returns { query, isInvalid }
ds.setBaseWhereClause('status=2')       // Update WHERE, resets to page 1
ds.setFilter('name', 'Smith')           // Set column filter
ds.clearFilters()
ds.setSort('name', 'asc')
ds.getTotalPages()
```
