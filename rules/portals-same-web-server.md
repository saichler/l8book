# Portals Must Be Served from the Same Web Server (CRITICAL)

## Rule
A portal is a different UI for a different audience (e.g., admin dashboard vs. member-facing app, ERP vs. Employee Self-Service). Portals MUST be subdirectories under the same web server's web root — NEVER separate binaries, Docker images, or K8s deployments.

**There is exactly ONE web server process per project.** All portals, all audiences, all entry points are served from that single process.

## Why This Is Critical
Two web servers with `hostNetwork: true` on the same node bind to the same port. The second one will always crash. Even without hostNetwork, creating a separate binary, Dockerfile, Docker image, K8s manifest, and deployment for what is just a subdirectory of static files is a massive architectural violation that wastes resources and creates unsolvable port conflicts.

## Correct Pattern (follow l8erp)
```
go/<project>/ui/web/
├── app.html              # Admin/main portal
├── login.html
├── login.json
├── js/
├── sections/
├── member/               # Member portal — subdirectory, NOT a separate service
│   ├── app.html
│   ├── js/
│   └── css/
├── ess/                  # ESS portal — subdirectory
│   ├── app.html
│   ├── js/
│   └── css/
└── l8ui/
```

All portals are served by the single `go/<project>/ui/main.go` web server. Type registrations for all portals go in that single `main.go`.

## Wrong Pattern (NEVER do this)
```
go/<project>/ui/           # Main web server
go/<project>/member-ui/    # WRONG: separate binary for a portal
go/<project>/ess-ui/       # WRONG: separate binary for a portal
```

Each with its own `main.go`, `Dockerfile`, `build.sh`, K8s manifest entry — this is WRONG.

## What a Portal Is NOT
A portal is NOT:
- A separate microservice
- A separate binary
- A separate Docker image
- A separate K8s deployment/DaemonSet/StatefulSet
- A separate entry in `build-all-images.sh`

A portal IS:
- A subdirectory under the existing web root
- Served by the existing web server process
- Sharing the same TLS certificate, port, and authentication endpoint

## Checklist Before Creating a New UI Entry Point
1. Does a web server already exist for this project? → YES, always.
2. Is this a different audience/view of the same system? → It's a portal. Add a subdirectory.
3. Does it need its own binary? → NO. Never.
4. Does it need its own Dockerfile? → NO. Never.
5. Does it need its own K8s manifest entry? → NO. Never.

## Historical Context
This rule was created after the FMC project shipped a `member-ui` as a completely separate binary, Docker image, and K8s StatefulSet. It crashed in a loop because it tried to bind to the same port as the main web server. The member-ui was a member-facing portal — a subdirectory of static files that should have been served by the existing `fmc-web` process. The mistake wasted a full Dockerfile, build.sh, K8s manifest entries across all four deployment modes, and a kind-start.sh image entry — all for something that should have been a `cp -r` into a subdirectory.
