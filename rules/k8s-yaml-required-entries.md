# K8s YAML Required Entries (CRITICAL)

## Rule
When creating Kubernetes YAML manifests for any new project, ALL of the following entries MUST be included. These requirements apply to ALL four deployment mode YAMLs (`-local.yaml`, `-baremetal.yaml`, `-gke.yaml`, `-kind.yaml` — see `k8s-three-deployment-modes.md`). Never omit structural entries.

## Required Entries Checklist

### Namespace metadata
```yaml
metadata:
  name: <namespace>
  labels:
    name: <namespace>    # REQUIRED — do not omit labels
```

### StatefulSet/DaemonSet metadata
```yaml
metadata:
  namespace: <namespace>
  name: <name>
  labels:
    app: <name>          # REQUIRED — do not omit labels
```

### Container env section (ALL containers)
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

### Volume naming convention
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

## Why This Matters
- **Namespace labels**: Required for label-based selectors and network policies
- **Resource labels**: Required for `kubectl` filtering and service discovery
- **NODE_IP env var**: Used by the application to know which node it's running on — without it, inter-service communication and vnet discovery fail
- **Volume name `hdata`**: Convention consistency across all projects

## Verification
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

## Reference
The canonical k8s YAMLs for l8pollaris-pattern projects are in `probler/k8s/` (four files: `-local`, `-baremetal`, `-gke`, `-kind`). For ERP-pattern projects, see `l8erp/k8s/`. Always diff new project YAMLs against the appropriate reference before finalizing.
