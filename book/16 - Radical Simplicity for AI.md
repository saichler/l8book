# <div align="center">Radical Simplicity for AI</div>

We used AI extensively to harden both the architecture and the implementations of the Layer 8 ecosystem.  
In doing so, we discovered that **AI effectiveness is not limited by intelligence, but by structure**.

As part of this process, we defined a clear and explicit set of rules for AI usage—rules designed 
to prevent hallucinations, avoid duplicated code, enforce proper abstraction, and align generated 
code with architectural intent.

Rather than expecting users to repeatedly teach AI how Layer 8 works, we embedded the Layer 8 architecture 
guidelines and APIs directly into these rules—so you do not have to.

We also developed Layer 8 UI components that are already integrated with Layer 8 APIs and preloaded with 
AI guidance. These components act as guardrails, ensuring that AI-generated output remains consistent, 
serviceable, and production-ready.

Our goal is not for AI to simply write code.  
Our goal is for AI to build **quality, enterprise-grade software—correctly, the first time**.

**Radical Simplicity for AI** means delivering a working product in hours instead of months—without 
sacrificing architecture, correctness, or long-term maintainability.

---
## AI Guideline Rules

> **Download the full rule sets**  
> The complete AI rule definitions used throughout this chapter are available here:
>
> - **Generic Software Development Rules**  
    >   https://example.com/generic-software-development-rules.md
>
> - **Layer 8 Architecture and ERP Rules**  
    >   https://example.com/layer8-erp-rules.md
>
> These rule sets are designed to be injected directly into AI workflows.  
> Replace these links with their GitHub locations when publishing.

Before you start working with AI, you must give it **explicit global guidelines for software development**.

This was one of the more surprising discoveries in our work.  
Despite its apparent sophistication, AI does **not** reliably apply foundational software engineering discipline unless that discipline is stated explicitly.

To address this, we defined two distinct rule sets:

1. **Generic software development rules**  
   These are architecture-agnostic principles that apply to any serious software system.

2. **Layer 8–specific rules**  
   These encode architectural intent, serviceability constraints, and project-specific invariants that AI cannot infer on its own.

Together, these rules turn AI from a code generator into a **constrained, architecture-aware participant**.

### Examples of Generic Software Development Rules

Some of the most impactful generic rules were surprisingly basic—but critical:

- **No duplicate code**  
  AI is biased toward repetition. Any second instance of a pattern is treated as a forcing function for abstraction, not copy-paste.

- **Read before implementing**  
  When extending or integrating with existing components, AI must read *all* relevant code first. Assumptions are not allowed.

- **File size limits enforce design**  
  Files exceeding a defined size threshold are treated as architectural failures and must be refactored.

- **Configuration over behavior**  
  Module-specific files contain data only. All logic lives in shared, reusable components.

These rules dramatically reduced code sprawl, silent divergence, and long-term maintenance cost.

### Examples of Layer 8–Specific Rules

Layer 8 rules encode architectural constraints that AI cannot “guess,” even with full context:

- **Architecture is explicit, never implied**  
  Services, service areas, ownership, and boundaries must be stated and enforced.

- **Service APIs are the source of truth**  
  UI, orchestration, and automation always conform to service contracts—not the other way around.

- **Model evolution is expected**  
  Designs must assume models will change, grow, and be reused across modules without breaking behavior.

- **Serviceability over convenience**  
  Any solution that improves short-term speed but degrades observability, control, or evolution is rejected.

These rules ensure that AI-generated code aligns with Layer 8’s core principles: explicit architecture, controlled concurrency, and long-term serviceability.

### Why This Matters

Without rules, AI optimizes for *local correctness*.  
With rules, AI optimizes for *system integrity*.

The difference is not subtle.

By embedding both generic and Layer 8–specific guidelines directly into the AI workflow, we eliminated:
- Hallucinated abstractions
- Silent architectural drift
- Copy-paste module explosions
- Short-lived “working” solutions that fail at scale

AI does not replace architecture.  
**Rules are how architecture is enforced—at machine speed.**

---
# Building Your First AI System

Developing your own AI-driven system with the **Layer 8 Ecosystem** is intentionally simple.  
This guide walks you through creating your first project from scratch using Layer 8 patterns and AI-assisted development.

---

## Environment Requirements

Layer 8 assumes a development environment that is deterministic, scriptable, and aligned with production behavior.

Use one of the following:
- Linux (**Arch**, **Ubuntu**, or **Mint** recommended)
- macOS

Windows is not recommended for this workflow.  
If needed, run Linux via a virtual machine (e.g., VirtualBox).

---

## Bootstrap the Environment

Download the setup script:

https://raw.githubusercontent.com/saichler/l8book/refs/heads/main/setup/setup.sh

Make it executable:

```bash
chmod +x setup.sh
```

Run it:

```bash
./setup.sh
```

This script will:
- Install all required dependencies
- Clone the Layer 8 ecosystem projects
- Apply the Layer 8 architectural rules

At completion, your workspace will be initialized at:

```
~/proj/src/github.com/saichler/my-project
```

---

## Running Claude Code

Start Claude:

```bash
claude
```

Follow the prompts to authenticate and connect your account.

---

## Creating a PRD (Product Requirements Document)

Layer 8 starts with intent, not code.

In Claude, define your product:

```bash
Create a PRD using the Layer 8 Ecosystem Architecture for <your idea in 2–3 sentences>
```

Once the PRD is generated, validate it:

```bash
Do you have any concerns or gaps in the PRD based on the Layer 8 Ecosystem?
```

If gaps are identified:

```bash
Do any of the projects in the ../ directory address these concerns?
```

This step ensures reuse before creation — a core Layer 8 principle.

---

## Executing the PRD

Once the PRD is validated:

```bash
PRD approved. Please implement it.
```

Claude will generate a full, production-grade distributed system aligned with Layer 8 constraints.

---

## Running the System Locally

After implementation completes:

```bash
cd go
./run-local.sh
```

This launches the full distributed system locally using the deterministic Layer 8 environment.

---

## Building and Deploying

Before building images:

- Obtain the secure base images (security + PostgreSQL)
- Or if you wish to test with unsecure, just replace all:
  * Security base images with **alpine**
  * Postgres base images with **saichler/unsecure-postgres:latest**
  * Builder base images with **saichler/builder-ns:latest** 

Then build all images:

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

## Closing Note

This is not a development setup.  
This is a system production pipeline.

You are not writing code.  
You are defining intent — and the system materializes from it.