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
# Building Your First AI Project

Developing your own AI-driven system with the **Layer 8 Ecosystem** is intentionally simple.  
This guide walks you through creating your first project from scratch using Layer 8 patterns and AI-assisted development.

---

## Setting Up the Development Environment
You will need a linux Arch, Ubuntu or Mint machine or a Mac machine. 
**Sorry, Windows is just not build for development**. 
You can install Virtualbox and one of the distribution above.

On your linux machine, download the following script:

### 1. Install Go, wget & Docker/Docker desktop

Download and install Go for your platform:  
https://go.dev/dl/

Download and install Docker on linux for your distribution or Docker desktop from https://docs.docker.com/get-started/ if you are on windows/mac.

If your system does not contain **wget** (cli tool), please install it.

### 2. Open a terminal and move to your home directory
```bash
cd ~
```

### 3. Extract the Go archive
```bash
tar -zxvf ~/Downloads/<golang file name>
```

### 4. Configure environment variables

Add the following to your shell configuration file (for example ~/.bashrc):

```bash
export GOROOT=~/go
export GOPATH=~/proj
export GOBIN=~/proj/bin
export PATH=~/.local/bin:~/go/bin:$GOBIN:$PATH

alias ll="ls -lt"

git config --global user.email "<your email address>"
git config --global user.name "<your name>"

export DOCKER_BUILDKIT=1
```

Reload your shell:
```bash
source ~/.bashrc
```

### 5. Create your development workspace
```bash
mkdir -p ~/proj/src/github.com/<your github username>
```

This directory will contain all your Layer 8 projects.

---

## Creating and Cloning Your Project

### 1. Create a new repository on GitHub
Create a repository at:
```
github.com/<your github username>/<your project name>
```

### 2. Clone your project locally
```bash
cd ~/proj/src/github.com/<your github username>
git clone https://github.com/<your github username>/<your project name>
```

### 3. Clone the Layer 8 ERP reference implementation
```bash
git clone https://github.com/saichler/l8erp
```

The `l8erp` project serves as a complete working example of a Layer 8 system.

---

## Install Your AI Coding Assistant

Install one of the supported AI coding tools:

Claude Code:  
https://code.claude.com/docs/en/setup

or ChatGPT Codex (or equivalent coding agent).

These tools generate architecture, code, and documentation while following Layer 8 rules.

---

## Create Your Product Requirements Document (PRD)

### 1. Navigate to your project
```bash
cd ~/proj/src/github.com/<your github username>/<your project name>
```

### 2. Start your AI coding session
```bash
claude
```
or
```bash
codex
```

### 3. Use the following prompts
Please copy & past the following prompts to setup the Layer 8 ecosystem rules and guides for the AI:

---
>\> Please install to your memory the following Layer 8 global rules so it will 
> be available in every session: ./l8erp/plans/global-rules-all.md and make sure any
> PRD is in compliance to those rules.
---

---
>\> The following ../l8erp/go/erp/ui/web/l8ui/GUIDE.md is a guide for the Layer 8 UI/UX 
> generic components, please add it to your memory and use it whenever 
> panning or implementing PRD with UI section.
---

---
>\> An example project built using the Layer 8 ecosystem is in ../l8erp. Please following this project 
> structure and architecture whenever you create a PRD for a new project.
---

---
>\> Create a PRD in the directory plans that comply with the global rules 
> and follows the Layer 8 architecture for \<your project/system idea\>
---

The AI will generate a complete PRD aligned with Layer 8 architecture and constraints.

---

## Start Implementation

Once the PRD is created:

1. Follow the implementation phases defined in the PRD.
2. Let the AI assistant generate code and structure for each phase.
3. Ensure all generated components comply with Layer 8 global rules.
4. Continue iterating until the PRD is fully implemented.

From this point forward, development becomes a guided execution of the PRD — with Layer 8 enforcing architectural consistency and AI accelerating delivery.

