# Layer8D Desktop API Reference

Quick reference for all Layer8D desktop UI components.

## Layer8DConfig

```js
await Layer8DConfig.load()                     // Fetches login.json
Layer8DConfig.getConfig()                      // Returns full app config
Layer8DConfig.getDateFormat()                  // 'mm/dd/yyyy'
Layer8DConfig.getApiPrefix()                   // '/erp'
Layer8DConfig.resolveEndpoint('/30/Employee')  // '/erp/30/Employee'
```

## Layer8DUtils

```js
Layer8DUtils.escapeHtml(text)                  // XSS-safe escaping
Layer8DUtils.formatDate(timestamp)             // Unix seconds -> 'MM/DD/YYYY'
Layer8DUtils.formatDateTime(timestamp)         // Unix seconds -> 'MM/DD/YYYY HH:MM:SS'
Layer8DUtils.parseDateToTimestamp(dateString)   // 'MM/DD/YYYY' -> Unix seconds
Layer8DUtils.formatMoney(cents, currency?)     // 150000 -> '$1,500.00'
Layer8DUtils.formatPercentage(decimal)         // 0.75 -> '75.00%'
Layer8DUtils.formatPhone(digits)               // '5551234567' -> '(555) 123-4567'
Layer8DUtils.formatSSN(digits, masked?)        // masked: '***-**-6789'
Layer8DUtils.formatHours(minutes)              // 150 -> '2:30'
Layer8DUtils.getNestedValue(obj, 'a.b.c')     // Deep property access
Layer8DUtils.debounce(fn, ms)                  // Returns debounced function
Layer8DUtils.matchEnumValue(input, enumMap)    // Case-insensitive enum match
```

## Layer8DRenderers

```js
Layer8DRenderers.renderEnum(value, enumMap)
Layer8DRenderers.renderBoolean(value)
Layer8DRenderers.renderDate(timestamp)
Layer8DRenderers.renderDateTime(timestamp)
Layer8DRenderers.renderMoney(cents, currency?)
Layer8DRenderers.renderPercentage(decimal)
Layer8DRenderers.renderPhone(digits)
Layer8DRenderers.renderSSN(digits, masked?)
Layer8DRenderers.renderHours(minutes)
Layer8DRenderers.renderRating(value, max?)
Layer8DRenderers.createStatusRenderer(enumMap, classMap) // Returns function
```

## Layer8DPopup

```js
Layer8DPopup.show({
    title: 'Edit Employee',                // Plain text title
    titleHtml: '<b>Custom</b> Title',      // HTML title (overrides title)
    content: '<div>...</div>',             // Body HTML
    size: 'large',                         // 'small'|'medium'|'large'|'xlarge'
    showFooter: true,                      // Show cancel/save buttons
    saveButtonText: 'Save',
    cancelButtonText: 'Cancel',
    noPadding: false,                      // Remove body padding
    onSave: (formData) => {},              // Save callback
    onShow: (body) => {}                   // Called 50ms after popup appears
});

Layer8DPopup.close()                       // Close topmost
Layer8DPopup.closeAll()                    // Close all stacked
Layer8DPopup.updateContent('<html>')       // Replace body HTML
Layer8DPopup.updateTitle('New Title')
Layer8DPopup.getBody()                     // Get body element
```

Built-in tab support via event delegation:
```html
<div class="probler-popup-tabs">
    <div class="probler-popup-tab active" data-tab="overview">Overview</div>
    <div class="probler-popup-tab" data-tab="details">Details</div>
</div>
<div class="probler-popup-tab-content">
    <div class="probler-popup-tab-pane active" data-pane="overview">...</div>
    <div class="probler-popup-tab-pane" data-pane="details">...</div>
</div>
```

## Layer8DNotification

```js
Layer8DNotification.success('Record saved')
Layer8DNotification.error('Failed to save', ['Detail 1', 'Detail 2'])
Layer8DNotification.warning('Check input')
Layer8DNotification.info('Processing...')
Layer8DNotification.close()
```

Durations: error=0 (manual close), warning=5000ms, success=3000ms, info=4000ms.

## Layer8DTable

Constructor takes a single options object. **Must call `table.init()` after construction.**

```js
const table = new Layer8DTable({
    containerId: 'my-table-container',     // REQUIRED: DOM element ID
    endpoint: '/erp/30/Employee',          // API endpoint
    modelName: 'Employee',                 // Model name for L8Query
    columns: [...],                        // Column definitions
    pageSize: 10,                          // Rows per page (default: 10)
    serverSide: true,                      // Server-side pagination
    primaryKey: 'employeeId',              // Primary key field
    sortable: true,                        // Column sorting (default: true)
    filterable: true,                      // Column filtering (default: true)
    filterDebounceMs: 1000,                // Filter debounce (default: 1000)
    transformData: (item) => ({...}),      // Transform each row
    baseWhereClause: 'status=1',           // Base WHERE for all queries
    onDataLoaded: (data, items, total) => {},
    onRowClick: (item, id) => {},          // Row click handler
    onAdd: () => {},                       // Add button (null = hidden)
    onEdit: (id) => {},                    // Edit button (null = hidden)
    onDelete: (id) => {},                  // Delete button (null = hidden)
    addButtonText: 'Add Employee',
    showActions: true,                     // Action column (default: true)
    emptyMessage: 'No data found.',
    pageSizeOptions: [5, 10, 25, 50]
});
table.init();
```

Instance methods:
```js
table.init()                               // Initialize and render
table.setData(array)                       // Client-side: set data
table.setServerData(array, totalCount)     // Server-side: set data
table.fetchData(page, pageSize)            // Fetch from server
table.setBaseWhereClause('status=1')       // Update WHERE, re-fetch
table.render()                             // Re-render
table.sort('columnKey')                    // Sort (toggles asc/desc)
table.goToPage(2)                          // Navigate (1-indexed)
```

Static methods:
```js
Layer8DTable.tag('Active', 'status-active')
Layer8DTable.tags(['A', 'B'], 'my-class')
Layer8DTable.countBadge(5, 'item', 'items')
Layer8DTable.statusTag(true, 'Up', 'Down')
```

## Layer8DDatePicker

```js
Layer8DDatePicker.attach(inputElement, {
    minDate: 1609459200,                   // Unix seconds
    maxDate: 1735689600,
    onChange: (timestamp, formatted) => {},
    showTodayButton: true,
    firstDayOfWeek: 0                      // 0=Sunday, 1=Monday
});
Layer8DDatePicker.setDate(input, timestamp) // 0 = 'Current'/'N/A'
Layer8DDatePicker.getDate(input)            // Unix timestamp (0=Current, null=empty)
Layer8DDatePicker.detach(input)
```

## Layer8DInputFormatter

Supported types: `ssn`, `phone`, `currency`, `percentage`, `routingNumber`, `ein`, `email`, `url`, `colorCode`, `rating`, `hours`

```js
Layer8DInputFormatter.attach(input, 'currency', { min: 0, max: 1000000 })
Layer8DInputFormatter.getValue(input)       // Raw value (cents for currency)
Layer8DInputFormatter.setValue(input, 15000) // Set value (cents)
Layer8DInputFormatter.validate(input)       // { valid, errors[] }
Layer8DInputFormatter.detach(input)
Layer8DInputFormatter.attachAll(container)  // Auto-attach via data-format attr
Layer8DInputFormatter.collectValues(container) // { fieldName: rawValue }

// Display formatters
Layer8DInputFormatter.format.currency(15000)        // '$150.00'
Layer8DInputFormatter.format.ssn('123456789', true)  // '***-**-6789'
Layer8DInputFormatter.format.phone('5551234567')     // '(555) 123-4567'
```

## Layer8DReferencePicker

```js
Layer8DReferencePicker.attach(inputElement, {
    endpoint: '/erp/30/Department',        // REQUIRED
    modelName: 'Department',               // REQUIRED
    idColumn: 'departmentId',              // REQUIRED
    displayColumn: 'name',                 // REQUIRED
    displayFormat: (item) => `${item.code} - ${item.name}`,
    selectColumns: ['departmentId', 'name', 'code'],
    baseWhereClause: 'isActive=true',
    pageSize: 10,
    onChange: (id, displayValue, item) => {},
    title: 'Select Department'
});
Layer8DReferencePicker.getValue(input)      // Selected ID
Layer8DReferencePicker.getItem(input)       // Full selected item
Layer8DReferencePicker.setValue(input, id, displayValue, item)
Layer8DReferencePicker.detach(input)
```

## Layer8DReferenceRegistry

```js
Layer8DReferenceRegistry.register({
    Employee: {
        idColumn: 'employeeId',
        displayColumn: 'lastName',
        selectColumns: ['employeeId', 'firstName', 'lastName'],
        displayLabel: 'Employee',
        displayFormat: (item) => `${item.lastName}, ${item.firstName}`
    }
});
Layer8DReferenceRegistry.get('Employee')    // Returns config object
```

## Layer8DDataSource

Shared data fetching layer used by all view types. Builds L8Query strings, handles pagination, and enforces the metadata-on-page-1-only rule.

```js
const ds = new Layer8DDataSource({
    endpoint: '/erp/30/Employee',
    modelName: 'Employee',
    columns: [...],                     // Column defs (for filter/sort keys)
    pageSize: 10,
    baseWhereClause: 'status=1',
    transformData: (item) => ({...})
});

ds.fetchData(page)                      // Fetch page (1-indexed)
ds.buildQuery(page, pageSize)           // Returns { query, invalidFilters }
ds.setBaseWhereClause('status=2')       // Update WHERE, resets to page 1
ds.setFilter('name', 'Smith')           // Set column filter
ds.clearFilters()
ds.setSort('name', 'asc')              // Set sort column/direction
ds.getTotalPages()                      // ceil(totalItems / pageSize)
```

**Pagination rule:** Metadata (totalCount, key counts) is valid ONLY on page 1. Pages 2+ preserve existing metadata.

## Layer8DForms

Unified facade for form sub-modules (`Layer8DFormsFields`, `Layer8DFormsData`, `Layer8DFormsPickers`, `Layer8DFormsModal`).

```js
// Open add form in popup
Layer8DForms.openAddForm(serviceConfig, formDef, onSuccess)

// Open edit form (fetches record first)
Layer8DForms.openEditForm(serviceConfig, formDef, recordId, onSuccess)

// Read-only details view
Layer8DForms.openViewForm(serviceConfig, formDef, data)

// Delete with confirmation
Layer8DForms.confirmDelete(serviceConfig, recordId, onSuccess)

// Low-level (from sub-modules)
Layer8DForms.generateFormHtml(formDef, data)         // Returns HTML string
Layer8DForms.collectFormData(formDef)                 // Collect form data from DOM
Layer8DForms.validateFormData(formDef, data)          // Returns errors[]
Layer8DForms.fetchRecord(endpoint, primaryKey, id, modelName) // Fetch single record
Layer8DForms.saveRecord(endpoint, data, isEdit)       // POST or PUT
Layer8DForms.deleteRecord(endpoint, id, primaryKey, modelName) // DELETE
Layer8DForms.attachDatePickers(container)             // Init date pickers
Layer8DForms.attachReferencePickers(container)        // Init reference pickers
```

Where `serviceConfig` is:
```js
{ endpoint: '/erp/30/Employee', primaryKey: 'employeeId', modelName: 'Employee' }
```

### Layer8FormFactory Presets

Extends `Layer8FormFactory` with preset field group generators for common entity patterns:

```js
const f = window.Layer8FormFactory;

f.basicEntity()                          // [code, name, description, isActive]
f.dateRange('prefix')                    // [startDate, endDate]
f.address('parentKey')                   // [line1, line2, city, stateProvince, postalCode, countryCode]
f.contact('parentKey')                   // [value, contactType]
f.audit()                                // Read-only [createdBy, createdAt, modifiedBy, modifiedAt]
f.person(includeMiddle?)                 // [firstName, (middleName), lastName]
```

### Layer8DFormsFields Extended

Extends `Layer8DFormsFields` with advanced field rendering:

- **Inline tables**: `generateInlineTableHtml(field, rows, readOnly)` -- embedded child record tables with add/edit/delete
- **Period selector**: `onPeriodTypeChange(selectEl)` -- cascading Month/Quarter/Year selects
- **Tags/multiselect**: chip-based UI for multi-value fields
- **File upload**: drag-and-drop file upload with progress indicator (uses `Layer8FileUpload`)

## Layer8DToggleTree

Generic collapsible toggle tree with dependency enforcement. Used by SYS module selection UI.

```js
const tree = Layer8DToggleTree.create({
    container: document.getElementById('tree-container'),
    data: treeData,                    // Hierarchical data array
    onToggle: (path, enabled) => {},   // Called when a node is toggled
    dependencies: dependencyMap        // Optional dependency enforcement
});
tree.getDisabledPaths()                // Returns Set of disabled paths
```

## Layer8DModuleFilter

Runtime module filter that hides disabled modules/sub-modules/services based on server-stored config.

```js
await Layer8DModuleFilter.load(bearerToken)        // Load config on app startup
Layer8DModuleFilter.isEnabled('hcm')               // Check module
Layer8DModuleFilter.isEnabled('hcm.payroll')       // Check sub-module
Layer8DModuleFilter.isEnabled('hcm.core-hr.employees') // Check service
Layer8DModuleFilter.applyToSidebar()               // Hide disabled sidebar items
Layer8DModuleFilter.applyToSection('hcm')          // Hide disabled tabs/services
await Layer8DModuleFilter.save(disabledPaths, bearerToken) // Save config
```

Uses dot-notation paths. A disabled parent disables all children. Dashboard and System are never filtered.

## Layer8DViewFactory

Registry of view type constructors. Creates the appropriate view component based on service `viewType` configuration. Default is `'table'`.

```js
Layer8DViewFactory.register('chart', factoryFn)       // Register a view type
Layer8DViewFactory.create('chart', options)            // Create view instance
Layer8DViewFactory.has('kanban')                       // Check if type registered
Layer8DViewFactory.getTypes()                          // ['table','chart','kanban',...]
Layer8DViewFactory.detectTitleField(columns, pk)       // Auto-detect label field

// Create view with a type-switcher dropdown
Layer8DViewFactory.createWithSwitcher(type, options, viewTypes, serviceKey, onSwitch)
```

All view instances follow the same interface: `init()`, `refresh()`, `destroy()`.

Registered view types: `table`, `chart`, `kanban`, `timeline`, `calendar`, `gantt`, `tree`, `wizard`.

### Layer8ViewSwitcher

Small icon button with floating dropdown menu for switching between view types. Shared by desktop and mobile.

```js
// Render HTML for the switcher
const html = Layer8ViewSwitcher.render(serviceKey, viewTypes, activeType)

// Attach click handlers
Layer8ViewSwitcher.attach(container, function(newViewType) { ... })
```

View labels: `table` -> "Table View", `chart` -> "Chart View", `kanban` -> "Kanban Board", `timeline` -> "Timeline", `calendar` -> "Calendar", `tree` -> "Tree Grid", `gantt` -> "Gantt Chart", `wizard` -> "Wizard".

## Layer8DChart

SVG chart component supporting bar, line, and pie/donut renderers. Auto-detects category and value fields from column definitions. Includes an inline chart type selector (bar | line | pie).

```js
const chart = new Layer8DChart({
    containerId: 'chart-container',
    columns: [...],                     // Column defs (for auto-detection)
    dataSource: dataSourceInstance,      // Layer8DDataSource
    viewConfig: {
        chartType: 'bar',              // 'bar'|'line'|'area'|'pie'|'donut'
        categoryField: 'status',       // Group-by field (auto-detected if omitted)
        valueField: 'amount',          // Value field (auto-detected if omitted)
        aggregation: 'count',          // 'count'|'sum'|'avg'|'min'|'max'
        title: 'Chart Title',
        colors: ['#0ea5e9', ...],      // Custom palette (uses theme if omitted)
        pageSize: 100                  // Fetch all data for chart
    },
    onItemClick: (item, label) => {},
    onAdd: () => {}
});
chart.init();
chart.setData(items, total);
chart.refresh();
chart.destroy();
```

Static utilities:
```js
Layer8DChart.readThemeColor('--layer8d-primary', '#0ea5e9')
Layer8DChart.getThemePalette()          // Array of 10 theme colors
```

Sub-renderers (internal, auto-dispatched by `chartType`):
- `Layer8DChartBar.render(chart, w, h)` -- vertical/horizontal bars
- `Layer8DChartLine.render(chart, w, h)` -- line/area with data points
- `Layer8DChartPie.render(chart, w, h)` -- pie/donut with legend

**Chart type selector:** An inline button group (Bar | Line | Pie) renders above the chart. Clicking a button updates `chartType` and re-renders the SVG without refetching data.

**Auto-detection priority:** When `categoryField` and `valueField` are not specified in `viewConfig`, the chart auto-detects them from columns in this order:
1. **Period columns** (`type: 'period'`) -- L8Period objects, grouped by period label
2. **Date columns** (`type: 'date'`) when money columns (`type: 'money'`) also exist -- timestamps normalized to year/quarter
3. **Status/type/category/health** patterns -- grouped by enum value
4. **Fallback** -- title field via `Layer8DViewFactory.detectTitleField()`

**Auto-enabled chart view:** The service registry automatically adds `'chart'` to a service's `supportedViews` when its columns include both a `type: 'date'` and a `type: 'money'` column. No manual `supportedViews` config is needed for date+money models.

**L8Period support:** When the `categoryField` contains L8Period objects (objects with `periodType`, `periodYear`, `periodValue` properties), the chart auto-detects them and converts each period to a human-readable label: `"2025"` (yearly), `"2025 / Q1"` (quarterly), or `"2025 / January"` (monthly). Records with the same period are grouped and aggregated. Groups are sorted chronologically.

**Date normalization:** When the `categoryField` contains Unix timestamps (from date columns), the chart normalizes them to year/quarter buckets. Labels use the format `"2025 / Q1"`. Records within the same quarter are grouped and their money values aggregated (default: sum). Groups are sorted chronologically. Timestamps may arrive as numeric strings (e.g., `"1770840462"`) -- both number and string formats are handled automatically.

## Layer8DKanban

Kanban board with configurable lanes. Cards display title, subtitle, and custom fields.

```js
// Registered as 'kanban' view type
// viewConfig options:
{
    laneField: 'status',               // Field that determines the lane
    lanes: {                            // Lane definitions (keyed by field value)
        1: { label: 'To Do', color: '#0ea5e9' },
        2: { label: 'In Progress', color: '#f59e0b' },
        3: { label: 'Done', color: '#22c55e' }
    },
    cardTitle: 'name',                 // Field for card title
    cardSubtitle: 'assignee',          // Field for card subtitle
    cardFields: ['priority', 'dueDate'] // Additional fields on cards
}
```

## Layer8DCalendar

Month/week calendar view for date-based data.

```js
// Registered as 'calendar' view type
// viewConfig options:
{
    dateField: 'startDate',            // Date field for event placement
    titleField: 'name',               // Event display title
    viewMode: 'month'                  // 'month' | 'week'
}
```

Supports navigation (prev/next month/week) and renders events as colored dots on calendar cells.

## Layer8DTimeline

Vertical timeline displaying events in chronological order with alternating left/right layout.

```js
const timeline = new Layer8DTimeline({
    containerId: 'timeline-container',
    columns: [...],
    dataSource: dataSourceInstance,
    viewConfig: {
        dateField: 'auditInfo.createdDate',    // Timestamp field
        actorField: 'auditInfo.createdBy',     // Who performed the action
        titleField: 'name',                    // Auto-detected if omitted
        descriptionField: 'description',
        colorField: 'status',                  // Optional color grouping
        pageSize: 20
    },
    onItemClick: (item, id) => {},
    onAdd: () => {}
});
timeline.init();
timeline.setData(items, total);
timeline.refresh();
timeline.destroy();
```

## Layer8DGantt

SVG-based Gantt chart for project scheduling with task bars, progress indicators, and dependency arrows.

```js
// Registered as 'gantt' view type
// viewConfig options:
{
    startDateField: 'startDate',       // Task start timestamp (auto-detected if omitted)
    endDateField: 'endDate',           // Task end timestamp (auto-detected if omitted)
    progressField: 'percentComplete',  // 0-100 completion percentage
    titleField: 'name',               // Task label (auto-detected via detectTitleField)
    dependencyField: 'dependencies',   // Array of dependent task IDs
    defaultZoom: 'week'                // 'day' | 'week' | 'month' | 'quarter' | 'year'
}
```

**Date field auto-detection:** When `startDateField` is not explicitly configured, the Gantt scans columns for date fields (`type: 'date'` or keys ending in `Date`, `Start`, `End`) and matches them to start/end roles using key patterns:
- **Start**: keys containing `start`, `begin`, or `from`
- **End**: keys containing `end`, `due`, `until`, `required`, or `expir`
- If only one pattern matches and there are 2+ date columns, the other date column is assigned to the missing role
- If a start column is found but no end column, the end field is inferred by replacing `Start` with `End` in the key (e.g., `plannedStartDate` -> `plannedEndDate`)

**Zoom levels:** Day, Week, Month, Quarter, and Year. Quarter groups cells by ~91 days; Year groups by ~365 days.

**Timestamp handling:** Timestamps from the server may arrive as numeric strings (e.g., `"1770840462"` instead of `1770840462`). The Gantt automatically coerces numeric strings to numbers for correct date parsing.

## Layer8DTreeGrid

Hierarchical tree table that builds parent-child relationships from a flat list using a `parentIdField`.

```js
const tree = new Layer8DTreeGrid({
    containerId: 'tree-container',
    columns: [...],
    dataSource: dataSourceInstance,
    viewConfig: {
        parentIdField: 'parentId',     // Field linking to parent's ID
        idField: 'categoryId',         // Primary key (default: primaryKey)
        labelField: 'name',            // Auto-detected if omitted
        expandedByDefault: true,       // Start expanded (default: true)
        pageSize: 500                  // Fetch all for tree building
    },
    primaryKey: 'categoryId',
    onItemClick: (item, id) => {},
    onAdd: () => {},
    onEdit: (id) => {},
    onDelete: (id) => {}
});
tree.init();
tree.setData(items);
tree.toggleNode(nodeId);
tree.expandAll();
tree.collapseAll();
tree.refresh();
tree.destroy();
```

## Layer8DWizard

Multi-step wizard view with step navigation, progress indicator, and per-step content rendering.

```js
// Registered as 'wizard' view type
// viewConfig options:
{
    steps: [
        { key: 'info', label: 'Basic Info', fields: ['name', 'code'] },
        { key: 'config', label: 'Configuration', fields: ['type', 'status'] },
        { key: 'review', label: 'Review' }
    ]
}
```

## Layer8DWidget

Dashboard KPI card component for rendering stats with trends, sparklines, and mini charts.

```js
// Render a single KPI card
Layer8DWidget.render(
    { label: 'Total Revenue', icon: '$', onClick: () => {} },
    1500000,                           // Value (auto-formats to 1.5M)
    {
        trend: 'up',                   // 'up' | 'down'
        trendValue: 12.5,             // Percentage change
        sparklineData: [10, 20, 15, 30, 25],  // SVG sparkline
        sparklineColor: '#22c55e'
    }
)

// Render a grid of KPI widgets
Layer8DWidget.renderEnhancedStatsGrid(kpis, iconMap)   // Returns HTML string
```

## Layer8DModuleFactory

Single call bootstraps an entire module with navigation, CRUD, and service registry:

```js
Layer8DModuleFactory.create({
    namespace: 'HCM',                      // window.HCM
    defaultModule: 'core-hr',              // Default sub-module tab
    defaultService: 'employees',           // Default service
    sectionSelector: 'core-hr',            // data-module attribute
    initializerName: 'initializeHCM',      // Global init function name
    requiredNamespaces: ['CoreHR', 'Payroll']
});
```

This call: registers sub-modules, creates forms facade, attaches tab/subnav navigation, attaches CRUD operations, and exposes the global initializer function.

### Layer8ModuleConfigFactory

Factory for creating module configurations with minimal boilerplate. Use instead of manually setting `modules`, `submodules`, and `renderStatus` on namespace objects.

```js
// Helper: create a service entry
const svc = Layer8ModuleConfigFactory.service;

// Helper: create a module entry
const mod = Layer8ModuleConfigFactory.module;

// Create a full module config
Layer8ModuleConfigFactory.create({
    namespace: 'Bi',
    modules: {
        'reporting': mod('Reporting', 'icon', [
            svc('reports', 'Reports', 'icon', '/35/BiReport', 'BiReport'),
            svc('schedules', 'Schedules', 'icon', '/35/BiSchedule', 'BiReportSchedule')
        ]),
        'dashboards': mod('Dashboards', 'icon', [
            svc('dashboards', 'Dashboards', 'icon', '/35/BiDashbrd', 'BiDashboard')
        ])
    },
    submodules: ['BiReporting', 'BiDashboards']
});
```

This creates `window.Bi` with `.modules`, `.submodules`, and `.renderStatus` properties.
