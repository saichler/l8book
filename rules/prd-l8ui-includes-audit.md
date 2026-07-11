# PRD Must Include Complete L8UI Includes Audit (CRITICAL)

## Rule
Every PRD that includes UI work MUST contain a section titled **"L8UI Includes Audit"** that lists every CSS and JS file from `desktop-script-loading-order.md` and `mobile-script-loading-order.md`. Each file must be marked as either **included** or **not applicable (with reason)**. A PRD without this section MUST NOT be written to `./plans/`.

## Why This Is Critical
This rule was created after the l8stocks project shipped with 34 missing l8ui JS files and 14 missing CSS files. The existing verification rule (`verify-app-html-scripts-against-loading-order.md`) requires a post-implementation check, but it was never followed. By moving the audit to the planning phase, missing includes are caught before any code is written — the project's `app.html` starts complete on day one.

## The Audit Section Format

```markdown
## L8UI Includes Audit

### Desktop app.html — CSS
- [x] layer8d-theme-tokens.css
- [x] layer8d-theme.css
- [x] layer8d-animations.css
- [x] layer8d-scrollbar.css
- [x] layer8-print.css
- [x] layer8-section-layout.css
- [x] layer8-section-responsive.css
- [x] layer8d-table.css
- [x] layer8d-chart.css
- [x] layer8d-kanban.css
- [x] layer8d-timeline.css
- [x] layer8d-calendar.css
- [x] layer8d-tree-grid.css
- [x] layer8d-gantt.css
- [x] layer8d-wizard.css
- [x] layer8d-widget.css
- [x] layer8-view-switcher.css
- [x] layer8-markdown.css
- [x] l8agent-chat.css
- [x] l8agent-bubble.css
- [x] l8sys.css
- [x] l8health.css
- [x] l8sys-modules.css
- [x] l8logs.css
- [x] l8dataimport.css
- [x] layer8d-toggle-tree.css
- [x] layer8d-popup.css
- [x] layer8d-popup-forms.css
- [x] layer8d-form-fields.css
- [x] layer8-file-upload.css
- [x] layer8d-popup-inline-table.css
- [x] layer8d-popup-content.css
- [x] layer8d-datepicker.css
- [x] layer8d-reference-picker.css
- [x] layer8d-input-formatter.css
- [x] layer8d-notification.css

### Desktop app.html — JS
- [x] layer8d-theme-switcher.js
- [x] layer8d-config.js
- [x] layer8d-websocket.js
- [x] layer8d-utils.js
- [x] layer8d-renderers.js
- [x] layer8d-reference-registry.js
- [x] layer8d-portal-switcher.js
- [x] layer8-enum-factory.js
- [x] layer8-ref-factory.js
- [x] layer8-column-factory.js
- [x] layer8-form-factory.js
- [x] layer8-form-factory-presets.js
- [x] layer8-svg-factory.js
- [x] layer8d-module-config-factory.js
- [x] layer8-section-generator.js
- [x] layer8d-notification.js
- [x] layer8d-input-formatter-utils.js
- [x] layer8d-input-formatter-masks.js
- [x] layer8d-input-formatter-types-validators.js
- [x] layer8d-input-formatter-types.js
- [x] layer8d-input-formatter-core.js
- [x] layer8d-input-formatter.js
- [x] layer8-format-display.js
- [x] layer8d-forms-fields.js
- [x] layer8d-forms-fields-ext.js
- [x] layer8d-forms-data.js
- [x] layer8d-forms-pickers.js
- [x] layer8d-forms-modal.js
- [x] layer8d-forms.js
- [x] layer8d-popup.js
- [x] layer8d-datepicker-utils.js
- [x] layer8d-datepicker-calendar.js
- [x] layer8d-datepicker-core.js
- [x] layer8d-datepicker.js
- [x] layer8d-reference-picker-utils.js
- [x] layer8d-reference-picker-data.js
- [x] layer8d-reference-picker-render.js
- [x] layer8d-reference-picker-events.js
- [x] layer8d-reference-picker-core.js
- [x] layer8d-reference-picker.js
- [x] layer8d-table-core.js
- [x] layer8d-table-data.js
- [x] layer8d-table-render.js
- [x] layer8d-table-events.js
- [x] layer8d-table-filter.js
- [x] layer8d-table.js
- [x] layer8-csv-export.js
- [x] layer8-excel-export.js
- [x] layer8-pdf-export.js
- [x] layer8-export-helper.js
- [x] layer8-file-upload.js
- [x] layer8d-data-source.js
- [x] layer8d-view-factory.js
- [x] layer8-view-switcher.js
- [x] layer8d-chart-core.js
- [x] layer8d-chart-bar.js
- [x] layer8d-chart-line.js
- [x] layer8d-chart-pie.js
- [x] layer8d-kanban-core.js
- [x] layer8d-kanban-render.js
- [x] layer8d-kanban-events.js
- [x] layer8d-timeline.js
- [x] layer8d-calendar-core.js
- [x] layer8d-calendar-render.js
- [x] layer8d-calendar-events.js
- [x] layer8d-tree-grid-core.js
- [x] layer8d-tree-grid-render.js
- [x] layer8d-tree-grid-events.js
- [x] layer8d-gantt-core.js
- [x] layer8d-gantt-render.js
- [x] layer8d-gantt-events.js
- [x] layer8d-wizard-core.js
- [x] layer8d-wizard-render.js
- [x] layer8d-widget.js
- [x] layer8d-service-registry.js
- [x] layer8d-module-crud.js
- [x] layer8d-module-navigation.js
- [x] layer8d-toggle-tree.js
- [x] layer8d-module-filter.js
- [x] layer8d-permission-filter.js
- [x] layer8-module-factory-core.js
- [x] layer8d-module-factory.js
- [x] layer8-markdown.js
- [x] l8agent-enums.js
- [x] l8agent-columns.js
- [x] l8agent-forms.js
- [x] l8agent-chat.js
- [x] l8agent-bubble.js
- [x] l8sys-config.js
- [x] l8health.js
- [x] l8security-enums.js
- [x] l8security-columns.js
- [x] l8security-forms.js
- [x] l8security.js
- [x] l8security-users-crud.js
- [x] l8security-roles-crud.js
- [x] l8security-credentials-crud.js
- [x] l8security-events-enums.js
- [x] l8security-events-columns.js
- [x] l8sys-dependency-graph.js
- [x] l8sys-modules-map.js
- [x] l8sys-modules.js
- [x] l8logs.js
- [x] l8dataimport.js
- [x] l8dataimport-templates.js
- [x] l8dataimport-transfer.js
- [x] l8dataimport-execute.js
- [x] l8sys-init.js

### Mobile m/app.html — CSS
(Same audit for all mobile CSS from mobile-script-loading-order.md)

### Mobile m/app.html — JS
(Same audit for all mobile JS from mobile-script-loading-order.md)
```

## Process
1. Before writing a UI PRD to `./plans/`, read `desktop-script-loading-order.md` and `mobile-script-loading-order.md`
2. Copy the checklist above into the PRD
3. Mark every file as included or not applicable
4. If any file is marked not applicable, provide a reason
5. The first implementation phase of the PRD must create `app.html` and `m/app.html` with ALL checked files included

## What This Prevents
- Missing l8ui CSS/JS files that cause silent feature breakage
- Custom reimplementation of utilities that already exist in l8ui
- Post-implementation discovery of gaps that should have been caught at planning

## Relationship to Other Rules
- Extends `prd-compliance.md`: adds l8ui includes audit as a mandatory PRD section
- Enforces `desktop-script-loading-order.md` and `mobile-script-loading-order.md` at planning time
- Supersedes the post-implementation check in `verify-app-html-scripts-against-loading-order.md` — that rule remains as a safety net but should never be the first line of defense
