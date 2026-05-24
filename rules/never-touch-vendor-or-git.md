# NEVER Touch Vendor or Run Git Commands (CRITICAL)

## Rule 1: NEVER Edit Vendor
NEVER edit, write, modify, or overwrite any file inside any `vendor/` directory. No exceptions. No workarounds. No "restoring to original content." No replace directives in go.mod. NOTHING.

If a dependency needs changes, edit the actual source in the sibling project directory (e.g., `../l8utils/`). Then STOP and tell the user what was changed. The user handles pushing, re-vendoring, and rebuilding.

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

## Why This Is Critical
These rules exist because repeated violations in a single session broke the build, corrupted go.mod, and wasted significant time. The cost of violating these rules is high — broken builds, lost work, and user frustration.
