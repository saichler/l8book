# Kubernetes Deployment Rules (CRITICAL)

## K8s Directory Must Be at Project Root

### Rule
The `k8s/` directory MUST be placed at the project root, NOT under the `go/` directory. Kubernetes manifests, deploy/undeploy scripts, and KIND cluster scripts are project-level deployment artifacts — they are not part of the Go module.

### Correct
```
<project-root>/
├── go/
├── proto/
├── k8s/              <- HERE, at project root
│   ├── <project>-local.yaml
│   ├── <project>-baremetal.yaml
│   ├── <project>-gke.yaml
│   ├── <project>-kind.yaml
│   ├── deploy.sh
│   ├── un-deploy.sh
│   ├── kind-start.sh
│   └── kind-stop.sh
└── ...
```

### Wrong
```
<project-root>/
├── go/
│   ├── k8s/          <- WRONG, not inside go/
│   └── ...
└── ...
```

### Why This Matters
The `go/` directory is the Go module root (where `go.mod` lives). K8s manifests have nothing to do with Go — they are infrastructure/deployment artifacts. Placing them inside `go/` conflates the Go module boundary with the deployment boundary and breaks the convention established across all Layer 8 projects.

## K8s YAML Required Entries

### Rule
When creating Kubernetes YAML manifests for any new project, ALL of the following entries MUST be included. These requirements apply to ALL four deployment mode YAMLs (`-local.yaml`, `-baremetal.yaml`, `-gke.yaml`, `-kind.yaml`). Never omit structural entries.

### Required Entries Checklist

#### Namespace metadata
```yaml
metadata:
  name: <namespace>
  labels:
    name: <namespace>    # REQUIRED — do not omit labels
```

#### StatefulSet/DaemonSet metadata
```yaml
metadata:
  namespace: <namespace>
  name: <name>
  labels:
    app: <name>          # REQUIRED — do not omit labels
```

#### Container env section (ALL containers)
```yaml
containers:
  - name: <name>
    image: <image>
    imagePullPolicy: Always
    env:                           # REQUIRED — do not omit
      - name: NODE_IP
        valueFrom:
          fieldRef:
            fieldPath: status.hostIP
```

#### Volume naming convention
```yaml
volumeMounts:
  - name: hdata              # Use "hdata", not "data"
    mountPath: /data
volumes:
  - name: hdata              # Must match volumeMounts name
    hostPath:
      path: /data
      type: DirectoryOrCreate
```

### Why This Matters
- **Namespace labels**: Required for label-based selectors and network policies
- **Resource labels**: Required for `kubectl` filtering and service discovery
- **NODE_IP env var**: Used by the application to know which node it's running on — without it, inter-service communication and vnet discovery fail
- **Volume name `hdata`**: Convention consistency across all projects

### Verification
After creating any k8s YAML, verify ALL four deployment mode files:
```bash
# Check all four modes
for f in k8s/<project>-local.yaml k8s/<project>-baremetal.yaml k8s/<project>-gke.yaml k8s/<project>-kind.yaml; do
  echo "=== $f ==="
  # Check namespace has labels
  grep -A2 "kind: Namespace" "$f" | grep "labels:"

  # Check resource has labels
  grep -A4 "kind: StatefulSet\|kind: DaemonSet\|kind: Deployment" "$f" | grep "labels:"

  # Check NODE_IP env is present
  grep -c "NODE_IP" "$f"

  # Check volume name convention
  grep "name: hdata" "$f"
done
```

### Reference
The canonical k8s YAMLs for l8pollaris-pattern projects are in `probler/k8s/` (four files: `-local`, `-baremetal`, `-gke`, `-kind`). For ERP-pattern projects, see `l8erp/k8s/`. Always diff new project YAMLs against the appropriate reference before finalizing.

## Four K8s Deployment Modes Required

### Rule
Every Layer 8 project PRD that includes Kubernetes deployment MUST produce four separate YAML manifests covering four deployment modes, plus KIND cluster scripts. Do NOT create a single YAML — all four are required deliverables, same as the Go source code.

The four YAML files live in `k8s/` and follow the naming convention `<project>-local.yaml`, `<project>-baremetal.yaml`, `<project>-gke.yaml`, `<project>-kind.yaml`.

The two KIND scripts also live in `k8s/`: `kind-start.sh` and `kind-stop.sh`.

### The Four Modes

#### 1. Local (`<project>-local.yaml`)
For single-node development and testing (minikube, Docker Desktop K8s).

| Aspect | Pattern |
|--------|---------|
| **Storage** | No StorageClass, no PVC. All volumes use `hostPath` with `type: DirectoryOrCreate` |
| **Per-node services** | `DaemonSet` (vnet, logs, webui, inventory agents, log-agent) |
| **Scalable services** | `Deployment` with `nodeSelector` for size labels (collector, parser — small/medium/large replicas) |
| **Stateful services** | `StatefulSet` with `replicas: 1` (orm, alarms) |
| **Volume name** | `hdata` everywhere |
| **Volume mount** | `/data` |

```yaml
# Local volume pattern — every service uses this
volumes:
  - name: hdata
    hostPath:
      path: /data
      type: DirectoryOrCreate
```

#### 2. Bare-metal (`<project>-baremetal.yaml`)
For multi-node bare-metal clusters (requires `local-path-provisioner`).

| Aspect | Pattern |
|--------|---------|
| **Storage** | `StorageClass` with `rancher.io/local-path` provisioner, `reclaimPolicy: Delete`, `volumeBindingMode: WaitForFirstConsumer` |
| **Per-node services** | Converted from DaemonSet to `StatefulSet` with `podAntiAffinity` (`requiredDuringSchedulingIgnoredDuringExecution` on `kubernetes.io/hostname`) and explicit `replicas` matching cluster node count |
| **Scalable services** | Converted from Deployment to `StatefulSet` with `volumeClaimTemplates` and `nodeSelector` |
| **Stateful services** | `StatefulSet` with `volumeClaimTemplates` |
| **Volume** | `volumeClaimTemplates` on every StatefulSet — no `hostPath` |

```yaml
# Bare-metal StorageClass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: <project>-local-storage
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer

# Bare-metal volume pattern — volumeClaimTemplates on every StatefulSet
volumeClaimTemplates:
  - metadata:
      name: hdata
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: <project>-local-storage
      resources:
        requests:
          storage: 5Gi    # Adjust per service (orm/alarms: 10Gi, others: 2-5Gi)

# Bare-metal anti-affinity pattern — replaces DaemonSet one-per-node scheduling
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app: <service-name>
        topologyKey: kubernetes.io/hostname
```

The bare-metal comment at the top of the file MUST include the prerequisite:
```yaml
# Bare-metal PVC version — requires local-path-provisioner:
#   kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

#### 3. GKE (`<project>-gke.yaml`)
For Google Kubernetes Engine (managed cloud).

| Aspect | Pattern |
|--------|---------|
| **Storage** | `StorageClass` with `kubernetes.io/gce-pd` provisioner (`pd-standard`), `reclaimPolicy: Retain`, `volumeBindingMode: WaitForFirstConsumer` |
| **Shared PVC** | Single `PersistentVolumeClaim` (`<project>-data`, 50Gi) shared by all services |
| **Per-node services** | `DaemonSet` (GKE handles scheduling natively) |
| **Scalable services** | `Deployment` with `nodeSelector` |
| **Stateful services** | `StatefulSet` |
| **Volume** | All services reference the shared PVC via `persistentVolumeClaim: claimName: <project>-data` |

```yaml
# GKE StorageClass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: <project>-storage
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer

# GKE shared PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  namespace: <project>
  name: <project>-data
  labels:
    app: <project>
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: <project>-storage
  resources:
    requests:
      storage: 50Gi

# GKE volume pattern — every service references the shared PVC
volumes:
  - name: hdata
    persistentVolumeClaim:
      claimName: <project>-data
```

#### 4. KIND (`<project>-kind.yaml`)
For local multi-node testing using KIND (Kubernetes IN Docker).

| Aspect | Pattern |
|--------|---------|
| **Storage** | KIND's built-in `standard` StorageClass (ships with `rancher/local-path-provisioner` pre-installed). No custom StorageClass definition needed. |
| **Per-node services** | Same as bare-metal: `StatefulSet` with `podAntiAffinity` |
| **Scalable services** | Same as bare-metal: `StatefulSet` with `volumeClaimTemplates` and `nodeSelector` |
| **Stateful services** | Same as bare-metal: `StatefulSet` with `volumeClaimTemplates` |
| **Volume** | `volumeClaimTemplates` with `storageClassName: standard` — no custom StorageClass, no `hostPath` |

```yaml
# KIND volume pattern — same as bare-metal but uses built-in "standard" StorageClass
# No StorageClass definition needed — KIND ships with it
volumeClaimTemplates:
  - metadata:
      name: hdata
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: standard
      resources:
        requests:
          storage: 5Gi
```

The KIND YAML comment at the top MUST include:
```yaml
# KIND cluster version — uses KIND's built-in standard StorageClass
# KIND ships with rancher/local-path-provisioner pre-installed as StorageClass "standard"
# No custom StorageClass definition needed.
```

#### KIND vs Bare-metal: The Only Difference
The KIND YAML is identical to the bare-metal YAML with two changes:
1. **Remove** the custom `StorageClass` definition block (bare-metal defines `<project>-local-storage`)
2. **Replace** all `storageClassName: <project>-local-storage` with `storageClassName: standard`

Everything else — workload kinds, anti-affinity, replicas, RBAC, Services, ConfigMaps — is identical.

### KIND Cluster Scripts

Every project MUST include two scripts in `k8s/`:

#### `kind-start.sh`
1. Checks if `kind` CLI is installed; installs it if missing
2. Creates a KIND cluster with 1 control-plane + 1 worker node
3. Loads local Docker images into the KIND cluster
4. Deploys `<project>-kind.yaml` in phased order:
   - **Phase 1**: Namespace + vnet + logs-vnet (wait for rollout before proceeding)
   - **Phase 2**: Core services — parsers, collectors, inventory, orm, alarms, webui, log-agent, topo (wait for all rollouts)
   - **Phase 3**: Admission controller (RBAC, bootstrap job, webhook — must be last because it depends on core services being ready)

#### `kind-stop.sh`
1. Deletes the KIND cluster
2. Cleans up generated config files

Copy these from `probler/k8s/` and adapt the cluster name and image list.

### What Is Identical Across All Four Modes

The following elements MUST be identical in all four YAMLs:
- **Namespace** definition (name + labels)
- **Container images** (same `image:` tags)
- **Container env vars** (NODE_IP, service-specific vars)
- **Container ports** (same containerPort values)
- **Service definitions** (ClusterIP services, Ingress, etc.)
- **RBAC resources** (ServiceAccount, Role, ClusterRole, RoleBinding, ClusterRoleBinding)
- **ConfigMaps** and **Jobs** (admission bootstrap, etc.)
- **ValidatingWebhookConfiguration** (if applicable)

The ONLY differences between modes are:
1. **Storage provisioning** (hostPath vs local-path PVC vs gce-pd PVC vs KIND built-in standard)
2. **Workload kind** (DaemonSet vs StatefulSet-with-anti-affinity for per-node services in bare-metal/KIND)
3. **Volume source** (hostPath vs volumeClaimTemplates vs shared PVC)

### Conversion Rules: Local to Bare-metal / KIND

When converting from local to bare-metal (KIND is identical except for StorageClass name):

| Local Kind | Bare-metal/KIND Kind | Key Changes |
|------------|----------------------|-------------|
| DaemonSet (no hostNetwork) | StatefulSet + anti-affinity | Add `serviceName`, `replicas`, `affinity.podAntiAffinity`, `volumeClaimTemplates`; remove `volumes` + `hostPath` |
| DaemonSet (hostNetwork: true) | StatefulSet + anti-affinity + hostNetwork | Same as above, keep `hostNetwork: true` |
| Deployment (nodeSelector) | StatefulSet + nodeSelector | Add `serviceName`, `volumeClaimTemplates`; remove `volumes` + `hostPath` |
| StatefulSet | StatefulSet | Add `volumeClaimTemplates` if using hostPath; adjust storage size |

### Conversion Rules: Local to GKE

When converting from local to GKE:

| Local Kind | GKE Kind | Key Changes |
|------------|----------|-------------|
| DaemonSet | DaemonSet (unchanged) | Replace `hostPath` volume with `persistentVolumeClaim: claimName: <project>-data` |
| Deployment | Deployment (unchanged) | Same volume replacement |
| StatefulSet | StatefulSet (unchanged) | Same volume replacement |

### Conversion Rules: Bare-metal to KIND

| Change | What to Do |
|--------|-----------|
| StorageClass definition | **Remove** the entire `StorageClass` resource (bare-metal defines a custom one; KIND has it built-in) |
| `storageClassName` references | **Replace** `<project>-local-storage` with `standard` in all `volumeClaimTemplates` |
| Everything else | **Identical** — no other changes needed |

### Canonical Reference
The probler project (`../probler/k8s/`) contains the canonical examples of all four modes plus the KIND scripts. When creating deployment YAMLs for a new project, **copy from probler and adapt** — do NOT write from scratch.

### PRD Requirement
Every PRD deployment section MUST list all four YAML files and KIND scripts as deliverables:
```markdown
### Kubernetes Manifests
- `k8s/<project>-local.yaml` — hostPath volumes, for single-node dev/test
- `k8s/<project>-baremetal.yaml` — local-path PVCs, for multi-node bare-metal
- `k8s/<project>-gke.yaml` — GCE PD storage, for Google Kubernetes Engine
- `k8s/<project>-kind.yaml` — KIND built-in standard StorageClass, for local multi-node testing
- `k8s/kind-start.sh` — creates KIND cluster and deploys the project
- `k8s/kind-stop.sh` — tears down KIND cluster
```

### Verification
After creating the four YAMLs and KIND scripts:
```bash
# All four files exist
ls k8s/<project>-local.yaml k8s/<project>-baremetal.yaml k8s/<project>-gke.yaml k8s/<project>-kind.yaml

# KIND scripts exist and are executable
ls -la k8s/kind-start.sh k8s/kind-stop.sh

# Local uses hostPath only (no StorageClass, no PVC)
grep -c "StorageClass\|PersistentVolumeClaim\|volumeClaimTemplates" k8s/<project>-local.yaml
# Expected: 0

# Bare-metal uses local-path provisioner
grep "rancher.io/local-path" k8s/<project>-baremetal.yaml

# GKE uses gce-pd provisioner
grep "kubernetes.io/gce-pd" k8s/<project>-gke.yaml

# KIND uses built-in standard StorageClass (no custom StorageClass definition)
grep -c "kind: StorageClass" k8s/<project>-kind.yaml
# Expected: 0
grep "storageClassName: standard" k8s/<project>-kind.yaml

# Same images across all four
diff <(grep "image:" k8s/<project>-local.yaml | sort) <(grep "image:" k8s/<project>-baremetal.yaml | sort)
diff <(grep "image:" k8s/<project>-local.yaml | sort) <(grep "image:" k8s/<project>-gke.yaml | sort)
diff <(grep "image:" k8s/<project>-local.yaml | sort) <(grep "image:" k8s/<project>-kind.yaml | sort)

# NODE_IP env var present in all services that need it (all four files)
for f in k8s/<project>-{local,baremetal,gke,kind}.yaml; do echo "$f:"; grep -c "NODE_IP" "$f"; done
```

### Relationship to Other Rules
- Extends `deployment-artifacts.md`: that rule requires K8s YAMLs exist; this rule specifies all four modes are required
- Extends `l8pollaris-binary-deployment.md`: l8pollaris projects that follow the probler pattern must produce all four modes
