# Never Import l8secure in Any Project (CRITICAL)

## Rule
No Layer 8 project may import ANY package from `l8secure`. This applies to ALL import paths under `github.com/saichler/l8secure/` — types, interfaces, utilities, everything. No exceptions.

## What This Means
- Do NOT import `github.com/saichler/l8secure/go/types/secure` for `L8User`, `L8Password`, `AccountStatus`, or any other type
- Do NOT import any other package under `github.com/saichler/l8secure/`
- Do NOT add `l8secure` as a dependency via `go mod tidy` or any other mechanism

## How to Provision Users Without l8secure
When a ServiceCallback needs to create a user (e.g., for loginable entities), construct the user data as a `map[string]interface{}` and POST it to the Security API endpoint (service area 73). Do NOT reference `l8secure` types.

```go
// CORRECT — use map, no l8secure import
userData := map[string]interface{}{
    "userId":        entity.EntityId,
    "fullName":      strings.TrimSpace(entity.FirstName + " " + entity.LastName),
    "email":         entity.Email,
    "accountStatus": "ACCOUNT_STATUS_ACTIVE",
    "portal":        "member/app.html",
    "password":      map[string]interface{}{"hash": "defaultpassword"},
    "roles":         map[string]bool{"member": true},
}
_, err := l8c.PostEntity("users", 73, userData, vnic)
```

```go
// WRONG — imports l8secure types
import "github.com/saichler/l8secure/go/types/secure"

user := &secure.L8User{
    UserId:        entity.EntityId,
    AccountStatus: secure.AccountStatus_ACCOUNT_STATUS_ACTIVE,
    // ...
}
```

## Verification
After any change that touches user provisioning or security-related code:
```bash
grep -rn "l8secure" go/ --include="*.go" | grep -v vendor/
# Must return ZERO results
```

## Applies To
- All service callbacks (`*ServiceCallback.go`)
- All main entry points (`main.go`)
- All test and mock files (`go/tests/`)
- Every `.go` file in the project outside of `vendor/`
