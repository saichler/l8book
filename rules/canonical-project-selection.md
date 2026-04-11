# Canonical Project Selection by Objective

## Rule
Before treating any existing Layer 8 project as the canonical reference for a new project, classify the new project's objective first. The correct canonical reference depends on the objective — **l8erp is not universal**.

| New project objective | Canonical reference | Scope |
|-----------------------|---------------------|-------|
| ERP-style (business entities, CRUD, persistence) | `../l8erp` | Project structure, run-local.sh, login.json, k8s YAMLs, UI patterns, mock data |
| Observation / collecting operational data from a source | `../probler` | Project structure and the full **targets → collect → parse → cache in memory** pipeline |

For observation/collection projects specifically, the following sub-references apply within the probler family:
- **`../l8collector`** — canonical for the **collection stage** (collecting data from sources/targets)
- **`../l8parser`** — canonical for the **parsing stage** (parsing collected raw data)
- **`../probler` targets inventory** — canonical for the **targets model** and for the full end-to-end targets → collect → parse → cache pipeline

## Why This Matters
ERP projects (l8erp) model persistent business entities with CRUD lifecycles, relational data, and form-based UIs. Observation/collection projects have a fundamentally different shape: targets, collectors, parsers, and in-memory caches of live operational state. Forcing the l8erp structure onto an observation project produces the wrong architecture — wrong service boundaries, wrong data flow, wrong persistence model.

Conversely, forcing the probler structure onto an ERP project produces the wrong tradeoffs for entities that need durable storage and CRUD forms.

## Which Rules This Affects
The following rules default to `../l8erp` as the canonical reference. When the new project's objective is observation/collection, override the default and use the probler family instead:

- `prd-compliance.md` — project structure and architecture
- `run-local-script.md` — adapt from `../probler/go/run-local.sh` (or the probler family equivalent) instead
- `k8s-yaml-required-entries.md` — still applies (generic k8s requirements), reference probler k8s YAMLs
- `login-json-adaptation.md` — still applies (generic), adapt from the probler family
- `modconfig-failure-no-logout.md` — still applies (same ModConfig trap)
- `mobile-rules.md` — UI parity rules still apply; compare against probler's UI if present
- `l8ui-copy-to-new-project.md` — still applies (use setup script, not manual copy)
- `demo-directory-sync.md` — still applies (never touch the demo dir)

The l8ui component rules (tables, forms, nav, view factory, theming) apply identically to both families — they are genuinely generic.

## How to Apply
1. **Classify the project objective first.** Is it ERP-style or observation/collection? If it touches targets, collection, parsing, or in-memory caching of live state, it is observation/collection.
2. **Pick the canonical family:** l8erp for ERP-style, probler for observation/collection.
3. **For any code path that touches targets, collection, parsing, or in-memory caching**, always prefer the probler-family reference even when l8erp appears to have a similar pattern.
4. **Fall back to l8erp** for observation projects only when the pattern is genuinely generic (e.g., l8ui components, k8s YAML required entries, login.json adaptation) and has no probler-family equivalent.
5. **When both could apply** to a given component, prefer the family that matches the overall project objective.

## Path Resolution
Both canonical references live as siblings under the same parent directory:
```
<parent>/
├── l8erp/         # Canonical for ERP-style projects
├── probler/       # Canonical for observation / operational data collection
├── l8collector/   # Canonical for the collection stage
├── l8parser/      # Canonical for the parsing stage
├── l8ui/          # Shared UI component library (both families)
└── ...
```

From any project root, `../l8erp`, `../probler`, `../l8collector`, and `../l8parser` resolve to their respective projects.
