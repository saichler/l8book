# L8UI: Generic Library Only (CRITICAL)

## Rule
The `l8ui/` directory contains generic UI components and utilities that are used by multiple Layer 8 projects. This library MUST NOT contain any explicit project-specific changes. All code in l8ui must be project-agnostic and reusable across any Layer 8 project.

## What Belongs in l8ui
- Generic UI components (tables, forms, popups, pickers, charts, etc.)
- Shared utilities (renderers, formatters, config loaders)
- Factory components (enum, column, form, reference factories)
- Shared CSS themes and layout styles
- The SYS module (system-level features used by all projects)

## What Does NOT Belong in l8ui
- References to specific project names, endpoints, or service areas
- Project-specific nav configs, reference registries, or module data
- Hardcoded project prefixes (e.g., `/erp/`, `/physio/`, `/bugs/`)
- Conditional logic that checks which project is running
- Any code that would only be useful to a single project

## Where Project-Specific Code Goes
Project-specific UI code lives in the project's own directories (e.g., `erp-ui/`, project-level `js/`, `sections/`, nav configs, reference registries). These files register with l8ui's generic extension points (e.g., `Layer8MReferenceRegistry.register()`, `Layer8SvgFactory.registerTemplate()`, nav config objects).
