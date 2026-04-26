# Never Edit Vendor Directory (CRITICAL)

## Rule
NEVER make changes to files inside the `vendor/` directory. The vendor directory contains copies of dependencies managed by `go mod vendor`. Any changes made there will be overwritten on the next vendor refresh and do not propagate to the actual dependency source.

## What To Do Instead
1. **Find the actual project** for the dependency (all Layer 8 projects are siblings under the same parent directory — see project location rules)
2. **Make changes in the actual project's source** (e.g., `../l8orm/go/orm/...`, NOT `go/vendor/github.com/saichler/l8orm/go/orm/...`)
3. **Re-vendor** after changes are committed:
   ```bash
   cd go
   rm -rf go.sum go.mod vendor
   go mod init
   GOPROXY=direct GOPRIVATE=github.com go mod tidy
   go mod vendor
   ```

## Why This Is Critical
- Changes in `vendor/` are invisible to the dependency's own repo — they exist only in the consuming project's working tree
- `go mod vendor` overwrites the entire `vendor/` directory, destroying all local edits
- Other projects that depend on the same library will never see the fix
- It creates a false sense of "done" — the code compiles locally but the fix is not actually committed anywhere

## Common Trap
When tracing a bug into a dependency, it feels faster to edit the vendored copy directly. Resist this — always navigate to the sibling project directory and make the change there.
