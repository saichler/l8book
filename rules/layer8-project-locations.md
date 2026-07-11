# Layer 8 Project Locations

## Rule
All Layer 8 projects are checked out as siblings under the same parent directory. From any project root, `../projectname` resolves to that project.

## Path Resolution

```
<parent>/
├── l8ui/          # Shared UI component library
├── l8erp/         # Reference ERP project (canonical example)
├── l8bugs/        # Bugs project
├── l8book/        # Book project
├── l8id/          # Identity project
├── l8topology/    # Topology visualization
├── l8opensim/     # API simulator
├── l8agent/       # AI agent
├── l8logfusion/   # Logging and distributed log collection
├── l8myfamily/    # Android app using Layer 8 services
├── l8notify/      # Notification handling and delivery
├── l8events/      # Event processing and management
├── l8alarms/      # Alarm detection, raising, and resolution
├── l8collector/   # Collection stage (canonical)
├── l8parser/      # Parsing stage (canonical)
├── l8physio/      # Physiotherapy project
├── probler/       # Data collection, parsing, and modeling
└── ...
```

## Project Purpose Table

| Project | Purpose |
|---------|---------|
| `l8ui` | Shared UI component library (tables, forms, popups, navigation, charts). Contains `setup-l8ui-submodule.sh` and `rules/` for component usage. |
| `l8erp` | Reference ERP project. Canonical for project structure, run-local.sh, login.json, K8s YAMLs, UI patterns, mock data. |
| `l8topology` | Topology visualization patterns: rendering/interacting with network/system topology graphs, node/edge modeling, graph layout and interaction. |
| `probler` | Data collection, parsing, and modeling. Canonical for the full targets -> collect -> parse -> cache pipeline. |
| `l8opensim` | API simulation patterns: defining/serving simulated API responses, decoupling development from real external services. |
| `l8agent` | AI agent patterns: building an AI agent within the Layer 8 framework, agent integration and lifecycle. |
| `l8logfusion` | Logging patterns: structured logging instrumentation, distributed log collection, log transport and storage. |
| `l8myfamily` | Android app patterns: building an Android application that consumes Layer 8 services, client-server integration. |
| `l8notify` | Notification handling: sending, routing, and managing user-facing notifications (email, in-app, push). |
| `l8events` | Event processing: defining, emitting, and processing system events across services. |
| `l8alarms` | Alarm lifecycle: detecting alarm conditions, raising alarms, tracking severity, acknowledge/clear/resolve. |
| `l8collector` | Canonical for the collection stage (collecting data from sources/targets). |
| `l8parser` | Canonical for the parsing stage (parsing collected raw data). |

## Usage
- When referencing l8ui source, scripts, or rules: use `../l8ui/`
- When adding l8ui to a new project: copy `../l8ui/setup-l8ui-submodule.sh` into the project's `web/` directory and run it
- When implementing a pattern for a new project, reference the appropriate canonical project before designing your own
- See `canonical-project-selection.md` for choosing between l8erp (ERP-style) and probler (observation/collection) as the canonical reference
