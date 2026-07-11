# Vendor and Git Rules (CRITICAL)

## Rule 1: NEVER Edit Vendor

NEVER edit, write, modify, or overwrite any file inside any `vendor/` directory. No exceptions. No workarounds. No "restoring to original content." No replace directives in go.mod. NOTHING.

The vendor directory contains copies of dependencies managed by `go mod vendor`. Any changes made there will be overwritten on the next vendor refresh and do not propagate to the actual dependency source.

### Why This Is Critical
- Changes in `vendor/` are invisible to every other consumer of the dependency — they exist only in this project's working tree, creating a false sense of "done"
- `go mod vendor` overwrites the entire `vendor/` directory, destroying all local edits
- Other projects that depend on the same library will never see the fix

### What To Do Instead
1. **Find the actual project** for the dependency (all Layer 8 projects are siblings under the same parent directory — see project location rules)
2. **Make changes in the actual project's source** (e.g., `../l8orm/go/orm/...`, NOT `go/vendor/github.com/saichler/l8orm/go/orm/...`)
3. Then STOP and tell the user what was changed. The user handles pushing, re-vendoring, and rebuilding.

### Common Trap
When tracing a bug into a dependency, it feels faster to edit the vendored copy directly. Resist this — always navigate to the sibling project directory and make the change there.

## Rule 2: NEVER Run Vendor/Module Commands

NEVER run any of these commands:
- `go mod tidy`
- `go mod vendor`
- `go mod init`
- `rm -rf vendor`
- `rm -rf go.mod`
- `rm -rf go.sum`
- Any command that modifies `go.mod`, `go.sum`, or the `vendor/` directory

The user manages the entire Go dependency and vendoring workflow.

## Rule 3: NEVER Run Git Commands Unless Instructed

NEVER run any `git` command (`git checkout`, `git add`, `git commit`, `git push`, `git reset`, `git status`, `git diff`, etc.) unless the user explicitly instructs you to.

## Why These Rules Are Critical

These rules exist because repeated violations in a single session broke the build, corrupted go.mod, and wasted significant time. The cost of violating these rules is high — broken builds, lost work, and user frustration.

## Where to Find Dependencies

All third-party dependencies are vendored. The `vendor/` directory under the **Go module root** (`go/vendor/`) is the location for all external code. When searching for code across the project's dependencies, look in `go/vendor/`, not in `$GOPATH`, module cache, or sibling project directories.

### Vendor Location
The Go module root is `go/` (where `go.mod` lives), so the vendor directory is at:
```
<project-root>/go/vendor/github.com/saichler/<dependency>/...
```

For example, to find the `l8utils` cache package in the `l8orm` project:
```
go/vendor/github.com/saichler/l8utils/go/utils/cache/
```

**Do NOT search sibling directories** like `/home/saichler/proj/src/github.com/saichler/<dep>/` — those are separate checkouts that may be at different versions than what the project depends on. Always use the vendored copy.
