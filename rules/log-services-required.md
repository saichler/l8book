# Log Services Required for Every Project (CRITICAL)

## Rule
Every Layer 8 project MUST include both `log-vnet` and `log-agent` services as separate binaries with their own directories, Dockerfiles, and build scripts. These are NOT optional — they are required infrastructure services, same as the main `vnet`.

## Why This Matters
The Layer 8 ecosystem uses distributed log collection via `l8logfusion`. Without `log-vnet` (the log aggregation virtual network) and `log-agent` (the per-node log collector), the System section's Logs tab has no data, and operators have no centralized visibility into service logs across nodes.

## Required Services

### log-vnet
Dedicated virtual network for log traffic, separate from the main service vnet.

| Property | Value |
|----------|-------|
| Directory | `go/<project>/log-vnet/` |
| Image name | `saichler/<project>-log-vnet:latest` |
| Base image | `saichler/<project>-security:latest` |
| K8s Kind | DaemonSet (hostNetwork: true) |
| Purpose | Routes log data between log-agents and the main service |

### log-agent
Per-node log collector that watches log files and forwards them to the log-vnet.

| Property | Value |
|----------|-------|
| Directory | `go/<project>/log-agent/` |
| Image name | `saichler/<project>-log-agent:latest` |
| Base image | `saichler/<project>-security:latest` |
| K8s Kind | DaemonSet |
| Purpose | Collects log files from `/data/logs/<project>` and forwards via log-vnet |

## Files Required Per Service

```
go/<project>/log-vnet/
├── main.go
├── Dockerfile
└── build.sh

go/<project>/log-agent/
├── main.go
├── Dockerfile
└── build.sh
```

## Canonical References
- **log-vnet**: `../probler/go/prob/log-vnet/`
- **log-agent**: `../probler/go/prob/log-agent/`

Copy from probler and adapt: binary name, image name, base image (`saichler/<project>-security`), and log directory path (`/data/logs/<project>`).

## Integration Checklist
When adding log services to a new project:
- [ ] `log-vnet/` directory with main.go, Dockerfile, build.sh
- [ ] `log-agent/` directory with main.go, Dockerfile, build.sh
- [ ] Both added to `build-all-images.sh` (log-vnet first, then log-agent, before other services)
- [ ] Both added to all four K8s YAML manifests (local, baremetal, gke, kind)
- [ ] Both added to `k8s/deploy.sh` and `k8s/undeploy.sh`
- [ ] Both added to `k8s/kind-start.sh` image list AND rollout wait loop
- [ ] Dockerfiles use `saichler/<project>-security:latest`, NOT `erp-security`
- [ ] log-agent `LOGPATH` defaults to `/data/logs/<project>`
