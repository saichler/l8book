# Adding a New Module

## Desktop

Example: "Projects" module, service area 60.

### Step 1: Module Config

**File:** `l8ui/projects/projects-config.js`

```js
(function() {
    'use strict';
    const svc = Layer8ModuleConfigFactory.service;
    const mod = Layer8ModuleConfigFactory.module;

    Layer8ModuleConfigFactory.create({
        namespace: 'Projects',
        modules: {
            'planning': mod('Planning', 'icon-emoji', [
                svc('projects', 'Projects', 'icon', '/60/Project', 'Project'),
                svc('tasks', 'Tasks', 'icon', '/60/Task', 'ProjectTask')
            ])
        },
        submodules: ['ProjectPlanning']
    });
})();
```

### Step 2: Sub-Module Data Files (per sub-module)

**Enums:** `l8ui/projects/planning/planning-enums.js`
```js
(function() {
    'use strict';
    window.ProjectPlanning = window.ProjectPlanning || {};
    ProjectPlanning.enums = {
        STATUS: { 0: 'Unknown', 1: 'Draft', 2: 'Active', 3: 'Done' },
        STATUS_VALUES: { 'draft': 1, 'active': 2, 'done': 3 },
        STATUS_CLASSES: { 1: 'status-pending', 2: 'status-active', 3: 'status-completed' }
    };
    ProjectPlanning.render = {};
    ProjectPlanning.render.status = Layer8DRenderers.createStatusRenderer(
        ProjectPlanning.enums.STATUS, ProjectPlanning.enums.STATUS_CLASSES
    );
})();
```

**Columns:** `l8ui/projects/planning/planning-columns.js`
```js
(function() {
    'use strict';
    var enums = ProjectPlanning.enums;
    var render = ProjectPlanning.render;
    ProjectPlanning.columns = {
        Project: [
            { key: 'projectId', label: 'ID', sortKey: 'projectId', filterKey: 'projectId' },
            { key: 'name', label: 'Name', sortKey: 'name', filterKey: 'name' },
            { key: 'status', label: 'Status', sortKey: 'status', filterKey: 'status',
              enumValues: enums.STATUS_VALUES,
              render: (item) => render.status(item.status) }
        ]
    };
    ProjectPlanning.primaryKeys = { Project: 'projectId' };
})();
```

**Forms:** `l8ui/projects/planning/planning-forms.js`
```js
(function() {
    'use strict';
    var enums = ProjectPlanning.enums;
    ProjectPlanning.forms = {
        Project: {
            title: 'Project',
            sections: [{
                title: 'Project Information',
                fields: [
                    { key: 'name', label: 'Name', type: 'text', required: true },
                    { key: 'status', label: 'Status', type: 'select', options: enums.STATUS },
                    { key: 'startDate', label: 'Start', type: 'date', required: true }
                ]
            }]
        }
    };
})();
```

### Step 3: Module Init

**File:** `l8ui/projects/projects-init.js`
```js
(function() {
    'use strict';
    Layer8DModuleFactory.create({
        namespace: 'Projects',
        defaultModule: 'planning',
        defaultService: 'projects',
        sectionSelector: 'planning',
        initializerName: 'initializeProjects',
        requiredNamespaces: ['ProjectPlanning']
    });
})();
```

### Step 4: Section HTML

**File:** `sections/projects.html`

**IMPORTANT:** Table container IDs follow the pattern `{moduleKey}-{serviceKey}-table-container`. CSS classes use the `l8-` prefix for ALL modules (shared CSS from `layer8-section-layout.css`).

```html
<div class="section-container l8-section">
    <div class="page-header"><h1>Projects</h1></div>
    <div class="l8-module-tabs">
        <button class="l8-module-tab active" data-module="planning">
            <span class="tab-icon">icon</span>
            <span class="tab-label">Planning</span>
        </button>
    </div>
    <div class="l8-module-content active" data-module="planning">
        <div class="l8-subnav">
            <a class="l8-subnav-item active" data-service="projects">Projects</a>
            <a class="l8-subnav-item" data-service="tasks">Tasks</a>
        </div>
        <div class="l8-service-view active" data-service="projects">
            <div class="l8-table-container" id="planning-projects-table-container"></div>
        </div>
        <div class="l8-service-view" data-service="tasks">
            <div class="l8-table-container" id="planning-tasks-table-container"></div>
        </div>
    </div>
</div>
```

### Step 5: Wire into app.html

Add script tags (order: config, enums, columns, forms per sub-module, then init):
```html
<script src="l8ui/projects/projects-config.js"></script>
<script src="l8ui/projects/planning/planning-enums.js"></script>
<script src="l8ui/projects/planning/planning-columns.js"></script>
<script src="l8ui/projects/planning/planning-forms.js"></script>
<script src="l8ui/projects/projects-init.js"></script>
```

### Step 6: Wire into sections.js

```js
const sections = { ..., projects: 'sections/projects.html' };
const sectionInitializers = { ..., projects: () => { if (typeof initializeProjects === 'function') initializeProjects(); } };
```

### Step 7: Register Reference Models

```js
Layer8DReferenceRegistry.register({
    Project: { idColumn: 'projectId', displayColumn: 'name', displayLabel: 'Project' }
});
```

## Mobile

### Step 1: Module Data Files

**Enums:** `m/js/projects/planning-enums.js`
```js
(function() {
    'use strict';
    window.MobileProjectPlanning = window.MobileProjectPlanning || {};
    MobileProjectPlanning.enums = {
        STATUS: { 0: 'Unknown', 1: 'Draft', 2: 'Active', 3: 'Done' },
        STATUS_VALUES: { 'draft': 1, 'active': 2, 'done': 3 },
        STATUS_CLASSES: { 1: 'pending', 2: 'active', 3: 'completed' }
    };
    MobileProjectPlanning.render = {};
    MobileProjectPlanning.render.status = Layer8MRenderers.createStatusRenderer(
        MobileProjectPlanning.enums.STATUS, MobileProjectPlanning.enums.STATUS_CLASSES
    );
})();
```

**Columns:** `m/js/projects/planning-columns.js` (add `primary: true` and `secondary: true` for card display)
```js
(function() {
    'use strict';
    var enums = MobileProjectPlanning.enums;
    var render = MobileProjectPlanning.render;
    MobileProjectPlanning.columns = {
        Project: [
            { key: 'projectId', label: 'ID', sortKey: 'projectId', filterKey: 'projectId' },
            { key: 'name', label: 'Name', primary: true, sortKey: 'name', filterKey: 'name' },
            { key: 'status', label: 'Status', secondary: true, sortKey: 'status',
              enumValues: enums.STATUS_VALUES,
              render: (item) => render.status(item.status) }
        ]
    };
    MobileProjectPlanning.primaryKeys = { Project: 'projectId' };
})();
```

**Forms:** `m/js/projects/planning-forms.js` (same structure as desktop, mobile namespace)

**Registry:** `m/js/projects/projects-index.js`
```js
// m/js/projects/projects-index.js
(function() {
    'use strict';
    Layer8MModuleRegistry.create('MobileProjects', {
        'Planning': MobileProjectPlanning
    });
})();
```

### Step 2: Update Nav Config

Navigation configs are project-specific and live in `erp-ui/m/nav-configs/`. Add your module to the appropriate config file:

1. Add to modules array in `layer8m-nav-config-base.js`:
   `{ key: 'projects', label: 'Projects', icon: 'projects', hasSubModules: true }`
2. Add config block to the appropriate category file (e.g., `layer8m-nav-config-prj-other.js`):
```js
LAYER8M_NAV_CONFIG.projects = {
    subModules: [
        { key: 'planning', label: 'Planning', icon: 'projects' }
    ],
    services: {
        'planning': [
            { key: 'projects', label: 'Projects', icon: 'projects',
              endpoint: '/60/Project', model: 'Project', idField: 'projectId',
              supportedViews: ['table', 'kanban', 'gantt', 'timeline'] },
            { key: 'tasks', label: 'Tasks', icon: 'projects',
              endpoint: '/60/Task', model: 'ProjectTask', idField: 'taskId' }
        ]
    }
};
```

### Step 3: Register Module with Nav.js

In `l8ui/m/js/layer8m-nav-data.js`, add `window.MobileProjects` to the registry arrays in `_getServiceColumns`, `_getServiceFormDef`, and `_getServiceTransformData`. **Note:** This requires modifying a library file; future versions may support dynamic registration.

### Step 4: Update m/app.html

Add scripts before nav config:
```html
<script src="js/projects/planning-enums.js"></script>
<script src="js/projects/planning-columns.js"></script>
<script src="js/projects/planning-forms.js"></script>
<script src="js/projects/projects-index.js"></script>
```

Add sidebar link (routes through card nav):
```html
<a href="#dashboard" class="sidebar-item" data-section="dashboard" data-module="projects">Projects</a>
```

### Step 5: Register Reference Models

Create a project-specific reference registry file in `erp-ui/m/reference-registries/`:

```js
// erp-ui/m/reference-registries/layer8m-reference-registry-projects.js
const ref = window.Layer8RefFactory;

window.Layer8MReferenceRegistryProjects = {
    ...ref.simple('Project', 'projectId', 'name', 'Project'),
    ...ref.simple('ProjectTask', 'taskId', 'name', 'Task')
};

// Register with the central registry
Layer8MReferenceRegistry.register(window.Layer8MReferenceRegistryProjects);
```

Then include it in `m/app.html` after the main reference registry loads.

## Checklist

### Desktop
- [ ] Config file (`modules`, `submodules`)
- [ ] Per sub-module: enums, columns, forms, entry point
- [ ] Init file (single `Layer8DModuleFactory.create()` call)
- [ ] Section HTML with correct container IDs (`{moduleKey}-{serviceKey}-table-container`)
- [ ] app.html: script tags in correct order
- [ ] sections.js: section mapping + initializer
- [ ] Reference registry entries

### Mobile
- [ ] Per sub-module: enums, columns (with `primary`/`secondary`), forms
- [ ] Registry index file (`getColumns`, `getFormDef`, `getTransformData`, `hasModel`)
- [ ] Nav config: `hasSubModules: true` + config block with `subModules` and `services`
- [ ] Nav.js: registry added to all lookup arrays
- [ ] m/app.html: script tags + sidebar link (`data-section="dashboard" data-module="xxx"`)
- [ ] Reference registry entries

### Critical Rules
- Field names MUST match actual API/protobuf field names (verify against `.pb.go` files)
- Endpoint names max 10 characters
- CSS classes use `l8-` prefix for ALL desktop modules (shared CSS from `layer8-section-layout.css`)
- Desktop: `new Layer8DTable(options)` then `table.init()` -- single options object
- Mobile: `new Layer8MEditTable(containerId, config)` -- two arguments, no init() call needed
