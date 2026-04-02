# Layer 8: Radical Simplicity for Humans

**The book, rules, and bootstrap tools for the Layer 8 Ecosystem.**

Layer 8 is a working architectural model built to test a hypothesis: if architecture is designed correctly, company success and work-life balance stop being in conflict. This repository contains the full text of the Layer 8 book, the AI guideline rules that power AI-assisted development, and the setup tooling to bootstrap new projects.

---

## What Is Layer 8?

Layer 8 is not a framework, a platform, or a product. It is a set of architectural constraints that force alignment between company goals, system behavior, and human effort.

**Radical Simplicity** is not aesthetic — it is architectural. It means reducing the number of things that can go wrong *by construction*:

- Make intent explicit
- Encode guarantees structurally
- Centralize complexity instead of distributing it
- Remove entire classes of failure rather than detecting them later

---

## The Book

The `book/` directory contains the full text, organized as an architectural argument:

| Chapter | Topic |
|---------|-------|
| 00 | Introduction — Why This Book Exists |
| 01 | Thoughts |
| 02 | Ground Rules |
| 03 | Architecture Is the Alignment Mechanism |
| 04 | Failure Modes of Implicit Architecture |
| 05 | The Economics of Implicit Architecture |
| 06 | Security & AAA |
| 07 | Networking |
| 08 | Serialization |
| 09 | Model-Agnostic Runtime — Data Without Schemas |
| 10 | Service as a Contract — Enforced by Concurrency |
| 11 | API & Query Language |
| 12 | Object Relation Mapping |
| 13 | Web Server |
| 14 | Quality |
| 15 | Practice: Making Architecture Explicit |
| 16 | Radical Simplicity for AI |
| 17 | Migration |

### Recommended Reading Paths

- **Technical leaders / executives**: Introduction, Failure Modes, Economics, Architecture as Alignment, Migration
- **Architects**: Ground Rules, Failure Modes, Security through Quality, Architecture as Alignment
- **Senior engineers**: Failure Modes, Ground Rules, Service as a Contract, Runtime/Serialization/ORM/API, Quality
- **Skeptics**: Introduction (Proof Not Theory), Failure Modes, Ground Rules, Economics

---

## AI Rules

The `rules/` directory contains the explicit architectural guidelines injected into AI workflows. These rules prevent hallucinations, enforce proper abstraction, and align AI-generated code with Layer 8 architectural intent.

Rather than expecting users to repeatedly teach AI how Layer 8 works, the architecture and APIs are embedded directly into these rules — so you don't have to.

---

## Building Your First AI-Driven System

Developing your own AI-driven system with the Layer 8 Ecosystem is intentionally simple. This section walks you through creating your first project from scratch using Layer 8 patterns and AI-assisted development.

### Environment Requirements

Use one of the following:
- **Linux** (Arch, Ubuntu, or Mint recommended)
- **macOS**

Windows is not recommended. If needed, run Linux via a virtual machine (e.g., VirtualBox).

### 1. Bootstrap the Environment

Download and run the setup script:

```bash
curl -O https://raw.githubusercontent.com/saichler/l8book/refs/heads/main/setup/setup.sh
chmod +x setup.sh
./setup.sh
```

This will:
- Install all required dependencies
- Clone the Layer 8 ecosystem projects
- Apply the Layer 8 architectural rules

Your workspace will be initialized at:
```
~/proj/src/github.com/saichler/my-project
```

### 2. Start Claude Code

```bash
claude
```

Follow the prompts to authenticate and connect your account.

### 3. Create a PRD (Product Requirements Document)

Layer 8 starts with intent, not code. In Claude, define your product:

```
Create a PRD using the Layer 8 Ecosystem Architecture for <your idea in 2-3 sentences>
```

Validate the PRD:

```
Do you have any concerns or gaps in the PRD based on the Layer 8 Ecosystem?
```

If gaps are identified:

```
Do any of the projects in the ../ directory address these concerns?
```

This ensures reuse before creation — a core Layer 8 principle.

### 4. Execute the PRD

Once validated:

```
PRD approved. Please implement it.
```

Claude will generate a full, production-grade distributed system aligned with Layer 8 constraints.

### 5. Run Locally

```bash
cd go
./run-local.sh
```

This launches the full distributed system locally.

### 6. Build and Deploy

Before building images, either:
- Obtain the secure base images (security + PostgreSQL), or
- For testing with unsecure images, replace:
  - Security base images with **alpine**
  - Postgres base images with **saichler/unsecure-postgres:latest**
  - Builder base images with **saichler/builder-ns:latest**

Build all images:

```bash
go/build-all-images.sh
```

Deploy to Kubernetes:

```bash
cd k8s
./deploy.sh
```

Your system is now running on your cluster.

---

## The Layer 8 Ecosystem

This repository is part of a family of sibling projects:

| Project | Purpose |
|---------|---------|
| [l8book](https://github.com/saichler/l8book) | Book, rules, and bootstrap tooling (this repo) |
| [l8erp](https://github.com/saichler/l8erp) | Reference ERP implementation (canonical example) |
| [l8ui](https://github.com/saichler/l8ui) | Shared UI component library |
| [l8bugs](https://github.com/saichler/l8bugs) | Bug tracking system |
| [l8id](https://github.com/saichler/l8id) | Identity and access management |
| [l8agent](https://github.com/saichler/l8agent) | AI agent |
| [l8notify](https://github.com/saichler/l8notify) | Notifications |
| [l8events](https://github.com/saichler/l8events) | Event processing |
| [l8alarms](https://github.com/saichler/l8alarms) | Alarm management |
| [l8logfusion](https://github.com/saichler/l8logfusion) | Distributed log collection |
| [l8topology](https://github.com/saichler/l8topology) | Topology visualization |
| [probler](https://github.com/saichler/probler) | Data collection, parsing, and modeling |

---

## License

This work is released under [CC0 1.0 Universal](LICENSE) — public domain.
