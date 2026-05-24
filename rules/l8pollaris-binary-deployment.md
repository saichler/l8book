# L8Pollaris Pattern: Binary & Deployment Must Match Probler

## Rule
Whenever a project uses **l8pollaris** for the **collection → parsing → inventory/orm** pattern (consuming `l8collector` and `l8parser`), its binary layout and deployment artifacts MUST mirror the probler project exactly. Do NOT invent a different process topology, Dockerfile pattern, or K8s manifest structure for these services.

Probler is the canonical reference: `../probler` (see `probler-project-location.md`).

## What "Same as Probler" Means

### Per-service directory layout
Every service in the collection → parsing → inventory/orm chain gets its own directory under `go/prob/<service>/` (adjust module name per project), containing:

```
go/<module>/<service>/
├── main.go         # Process entrypoint — creates vnic, registers the service, starts listening
├── build.sh        # docker build --no-cache --platform=linux/amd64 + docker push
└── Dockerfile      # Multi-stage: saichler/builder -> saichler/<base> final
```

### Service set that MUST exist
At minimum, the pattern requires the following separate binaries (each its own directory, image, and K8s manifest):

| Service | Purpose | Probler reference |
|---------|---------|-------------------|
| `collector` | Runs `l8collector`, collects raw data from targets | `go/prob/collector/` |
| `parser` | Runs `l8parser`, parses collected data into typed models | `go/prob/parser/` |
| `orm` | Persists parsed data via the ORM layer | `go/prob/orm/` |
| `inv_*` | One per inventory domain (e.g. `inv_box`, `inv_k8s`, `inv_gpu`) | `go/prob/inv_box/`, etc. |
| `vnet` | Virtual network backbone | `go/prob/vnet/` |
| `log-vnet`, `log-agent` | Distributed logging (if used) | `go/prob/log-vnet/`, `go/prob/log-agent/` |

Each service is a **separate process, separate image, separate K8s resource** — never collapsed into a single binary.

### Deployment artifacts
For every service above, produce:

1. **build.sh** at `go/<module>/<service>/build.sh` — follows probler's pattern:
   ```bash
   #!/usr/bin/env bash
   set -e
   docker build --no-cache --platform=linux/amd64 -t saichler/<image>:latest .
   docker push saichler/<image>:latest
   ```
2. **Dockerfile** at `go/<module>/<service>/Dockerfile` — multi-stage: `saichler/builder:latest` for the build stage, `saichler/<project>-security:latest` (or `<project>-postgres` if needs DB) for the runtime stage. **CRITICAL: each project MUST use its own base images** — never use another project's (e.g., `erp-security`). The base images contain a compiled `loader.so` security plugin whose dependency tree must match the project's own dependencies; mismatched base images cause protobuf namespace conflict panics at runtime.
3. **K8s manifests** — four YAML files covering all deployment modes (see `k8s-three-deployment-modes.md`): `k8s/<project>-local.yaml` (hostPath), `k8s/<project>-baremetal.yaml` (local-path PVCs), `k8s/<project>-gke.yaml` (GCE PD), `k8s/<project>-kind.yaml` (KIND built-in standard StorageClass). Each service must appear in all four files with the correct kind, namespace, hostNetwork choice, volume pattern, and NODE_IP env var matching probler's equivalent for that mode.
3a. **KIND scripts** — `k8s/kind-start.sh` and `k8s/kind-stop.sh` for creating/destroying a KIND cluster. Copy from probler and adapt the cluster name and image list.
4. **k8s/deploy.sh** and **k8s/undeploy.sh** — include every new manifest in the correct dependency order (vnet first, then log services, then collector → parser → orm → inventory services, then UI).
5. **build-all-images.sh** — call each service's `build.sh` in order.

## Why This Matters
- The collection → parsing → inventory/orm pipeline has known inter-service timing, dependency, and network assumptions baked into the probler split.
- Collapsing services into one binary, or splitting them differently, breaks l8pollaris's expectations about which node owns which service area.
- Diverging K8s manifests (different volume names, missing NODE_IP, wrong namespaces) causes silent cross-service discovery failures.
- Probler is the tested reference — every deviation is a potential runtime bug.

## Process When Building a New Project With This Pattern
1. Read `../probler/go/prob/` directory listing and `../probler/k8s/` before writing any deployment code.
2. For each service in the pattern, **copy the probler equivalent's `build.sh`, `Dockerfile`, and all four K8s YAMLs** (`-local.yaml`, `-baremetal.yaml`, `-gke.yaml`, `-kind.yaml`) plus the KIND scripts (`kind-start.sh`, `kind-stop.sh`), then adapt only: image name, binary name, namespace, and project-specific paths.
3. Do NOT hand-write these files from scratch.
4. Cross-reference with `deployment-artifacts.md`, `k8s-yaml-required-entries.md`, `k8s-three-deployment-modes.md`, and `run-local-script.md` — all of which already require copying from canonical references.

## Verification
Before approving a PRD or finishing a deployment change in a project that uses l8pollaris + l8collector + l8parser:

```bash
# Every collection→parsing→inventory/orm service must have build.sh, Dockerfile
for svc in collector parser orm inv_box; do
  test -f go/<module>/$svc/build.sh   || echo "MISSING: $svc/build.sh"
  test -f go/<module>/$svc/Dockerfile || echo "MISSING: $svc/Dockerfile"
done

# All four K8s deployment mode YAMLs must exist
for mode in local baremetal gke kind; do
  test -f k8s/<project>-${mode}.yaml || echo "MISSING: k8s/<project>-${mode}.yaml"
done

# KIND scripts must exist
test -f k8s/kind-start.sh || echo "MISSING: k8s/kind-start.sh"
test -f k8s/kind-stop.sh  || echo "MISSING: k8s/kind-stop.sh"
```

Any `MISSING` line is a rule violation — fix it before proceeding.

## When This Rule Does NOT Apply
- Projects that do NOT use l8pollaris for collection/parsing (e.g., pure ERP projects like l8erp follow the l8erp deployment template instead).
- Services outside the collection → parsing → inventory/orm chain (e.g., a project-specific UI or analytics service) — those follow `deployment-artifacts.md` generically, not the probler-specific split.
