# PRD Compliance (CRITICAL)

All PRDs must:
- Comply with all the rules at `../l8book/rules`
- Comply with the Layer 8 Ecosystem architecture, with example at the `../l8erp` project
- Include a detailed compliance checklist covering protobuf design, service design, UI design, mock data, deployment, and configuration

---

## Rule 1: PRD Must Be Compliant with Rules

Every PRD MUST be reviewed against ALL rules at `../l8book/rules` before it is considered complete. If a PRD contradicts or omits requirements from a rule, it must be corrected before approval.

### Compliance Checklist

#### Project Structure & Architecture
- Project structure follows l8erp layout (see Rule 2 below)
- Directory names, file naming conventions, and organization match l8erp patterns

#### Protobuf Design
- Enum zero values are UNSPECIFIED (proto-enum-zero-value)
- List types use `repeated X list = 1` convention (proto-list-convention)
- No direct struct references between Prime Objects — use ID fields only (prime-object-references)
- Child entities are embedded `repeated` fields, not separate services (prime-object-references)

#### Service Design
- ServiceName is 10 characters or less (maintainability)
- ServiceArea is consistent within a module (maintainability)
- ServiceCallback auto-generates primary key on POST (maintainability)
- Types are registered in UI main.go (maintainability)

#### UI Design
- All UI module integration steps are planned (ui-module-integration)
- Desktop and mobile parity is addressed (mobile-rules)
- Immutable entities/fields have read-only UI (immutability-ui-alignment)
- Child types use inline tables, not standalone UI (prime-object-references)
- UI components and patterns follow the l8ui guide (see Rule 3 below)

#### Mock Data
- All services have mock data generators planned (data-completeness-pipeline)
- Phase ordering accounts for cross-module dependencies (mock-phase-ordering)

#### Deployment
- New deployable services include build.sh, Dockerfile, K8s YAML (deployment-artifacts)
- All four K8s deployment modes are produced: local, baremetal, GKE, KIND (k8s-three-deployment-modes)
- KIND cluster scripts (kind-start.sh, kind-stop.sh) are included
- run-local.sh section is included (run-local-script)
- K8s YAMLs include all required entries in all four modes (k8s-yaml-required-entries)

#### Configuration
- login.json adaptation is planned if copied from another project (login-json-adaptation)
- ModConfig handling is addressed (modconfig-failure-no-logout)

### Process
1. After drafting a PRD, review it against all rules at `../l8book/rules`
2. Flag any conflicts or omissions
3. Update the PRD to comply before writing it to `./plans/`
4. If a rule does not apply to the project, note the exemption explicitly in the PRD

---

## Rule 2: PRD Must Follow the Layer 8 Ecosystem Architecture

Every PRD MUST follow the project structure and architecture established in the Layer 8 Ecosystem, with `../l8erp` as the canonical example. Do NOT invent new directory structures, naming conventions, or architectural patterns.

### Project Structure to Follow

#### Go Module Root (`go/`)
```
go/
├── go.mod
├── go.sum
├── vendor/                          # Vendored dependencies
├── build-all-images.sh              # Builds all Docker images
├── run-local.sh                     # Local development startup
├── <module>/                        # Module directory (e.g., erp/, bugs/)
│   ├── common/                      # Shared constants (PREFIX, defaults)
│   ├── <submodule>/                 # One directory per service group
│   │   ├── <entity>Service.go       # Service definition (ServiceName, ServiceArea)
│   │   └── <entity>ServiceCallback.go  # Validation, auto-ID, business logic
│   ├── ui/
│   │   ├── main.go                  # UI server + type registration
│   │   ├── web/                     # Web assets (desktop)
│   │   │   ├── app.html             # Desktop app shell
│   │   │   ├── login.html           # Login page
│   │   │   ├── login.json           # App config (apiPrefix, title)
│   │   │   ├── l8ui/                # Shared UI library (copied from l8erp)
│   │   │   ├── js/                  # Shared JS (sections.js, reference registries)
│   │   │   ├── sections/            # Section HTML files per module
│   │   │   ├── <submodule>/         # Per-submodule JS (config, enums, columns, forms, init)
│   │   │   └── m/                   # Mobile web assets
│   │   │       ├── app.html         # Mobile app shell
│   │   │       └── js/              # Mobile JS files
│   │   ├── build.sh                 # Docker build for UI image
│   │   └── Dockerfile
│   ├── main/                        # Backend server entry point
│   │   ├── main.go
│   │   ├── build.sh
│   │   └── Dockerfile
│   └── vnet/                        # Virtual network entry point
│       ├── main.go
│       ├── build.sh
│       └── Dockerfile
├── types/                           # Generated protobuf types
│   └── <module>/                    # Per-module .pb.go files
├── tests/
│   └── mocks/                       # Mock data generators
│       ├── cmd/                     # Mock data CLI entry point
│       ├── data.go                  # Curated name arrays
│       ├── store.go                 # ID slices for cross-references
│       ├── main_phases.go           # Phase orchestration
│       └── gen_<module>_*.go        # Generator files per module area
└── k8s/                             # Kubernetes manifests
    ├── deploy.sh
    ├── undeploy.sh
    └── *.yaml                       # Per-service manifests
```

#### Proto Directory (`proto/`)
```
proto/
├── make-bindings.sh                 # Generates all .pb.go files
├── <module>.proto                   # One proto file per module
└── api.proto                        # Shared API types (auto-downloaded)
```

### Architecture Patterns to Follow

#### Service Pattern
- One service per Prime Object (entity with independent lifecycle)
- ServiceName constant (max 10 chars) + ServiceArea constant (same across module)
- ServiceCallback with Before/After hooks for validation and auto-ID generation
- Child entities embedded as `repeated` fields in parent, not separate services

#### UI Pattern
- Module config + enums + columns + forms + init files per submodule
- Section HTML with header, tabs, service navigation
- Init file calls `Layer8DModuleFactory.create()` with config
- Desktop and mobile parity

#### Main Entry Points
- Backend main registers services on a vnic and starts listening
- UI main registers types for introspection, serves web assets, proxies API calls
- Vnet main starts the virtual network layer

### Process
1. Before writing a PRD, read the l8erp directory structure: `ls -R ../l8erp/go/` and `ls -R ../l8erp/proto/`
2. Map your new project's components to the l8erp equivalents
3. Use the same directory names, file naming conventions, and organizational patterns
4. If a structural deviation is genuinely needed, document the reason explicitly in the PRD

---

## Rule 3: PRD UI Sections Must Follow the L8UI Rules

Any PRD that includes UI work MUST be designed in compliance with the l8ui rules. Before writing UI-related sections of a PRD, the l8ui rules MUST be read.

### What to Check
When a PRD describes UI behavior, verify each element against the l8ui rules:

1. **Tables and data views** — use Layer8DTable / Layer8MTable, not custom table HTML
2. **Forms and detail popups** — use the form framework (f.form, f.section, field factories), not custom form HTML
3. **Navigation** — use Layer8DModuleFactory.create() and nav configs, not hardcoded sidebar links
4. **View types** (kanban, chart, timeline, calendar, tree grid, gantt) — use registered view types via Layer8DViewFactory, not custom implementations
5. **Dashboards** — use Layer8DDashboard with widget configs, not custom dashboard layouts
6. **Wizards** — use Layer8DWizard, not custom multi-step forms
7. **Reference pickers** — use the reference picker system, not custom search dropdowns
8. **Theming** — use `--layer8d-*` CSS custom properties, not hardcoded colors or custom variables
9. **Mobile** — use Layer8M* equivalents, not custom mobile layouts

### Location of the L8UI Rules
The l8ui rules are in the `l8ui` project's rules directory: `../l8ui/rules/`

When working on a specific project, the l8ui submodule under the project's web directory will also contain the rules (e.g., `go/<project>/ui/web/l8ui/rules/`).
