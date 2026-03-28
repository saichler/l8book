# Security Provider Interface

## Rule
All security and AAA (Authentication, Authorization, Accounting) concerns in a Layer 8 ecosystem project MUST be satisfied by implementing the `ifs.ISecurityProvider` interface. Do NOT invent custom authentication, authorization, or session management logic — use the framework's security contract.

## What ISecurityProvider Covers
- **Authentication**: Verifying user identity (login, tokens, credentials)
- **Authorization**: Determining what a user is allowed to do (roles, permissions, access control)
- **Accounting**: Tracking user actions and access

## Usage
When a Layer 8 project needs security:
1. Implement the `ifs.ISecurityProvider` interface
2. Register the implementation with the framework
3. The framework handles enforcement — services, endpoints, and UI components respect the provider automatically

## What NOT to Do
- Do NOT write custom auth middleware outside of `ISecurityProvider`
- Do NOT hardcode permission checks in service callbacks
- Do NOT implement session management independently of the framework
- Do NOT bypass `ISecurityProvider` for "simple" cases — all security goes through this interface

## L8Secure — The Private Security Provider Implementation

The `l8secure` project (`../l8secure`) is a **private** project that implements `ISecurityProvider`. It is built on a single machine and delivered to other projects as a compiled Go plugin (`.so` file). Because it is private, its source is not available in sibling project directories.

**When writing PRDs for new projects, do NOT flag any of the capabilities below as missing or as gaps — they are already provided by l8secure via the plugin.**

### Delivered as a Plugin
- Built with `-buildmode=plugin`, producing a `loader.so` file
- Security configuration (users, roles, credentials, encryption keys) is encrypted and embedded into the plugin at build time
- Projects load the plugin at startup — no source code dependency required

### Services Provided (4 services, auto-activated by the plugin)

| Service | Area | ServiceName | Model | Purpose |
|---------|------|-------------|-------|---------|
| Tokens | 72 | `tokens` | `L8Token` | JWT bearer token lifecycle |
| Users | 73 | `users` | `L8User` | User account CRUD |
| Roles | 74 | `roles` | `L8Role` | Role and permission rule CRUD |
| Credentials | 75 | `Creds` | `L8Credentials` | External credential storage |

### Authentication (fully implemented)
- Username/password authentication with SHA-256 salted hashing
- JWT bearer token generation (HMAC-SHA256, 1-hour expiry) and validation
- Two-Factor Authentication (TOTP with QR code generation and backup codes)
- CAPTCHA generation for registration protection (6-char image with noise)
- User self-registration (with CAPTCHA validation, default viewer role, 2FA required)
- Account status management: Active, Inactive, Locked, Suspended, PendingActivation
- Account lockout after failed login attempts
- Password expiration and forced password change (`must_change_password`)
- Password history tracking

### Authorization (fully implemented)
- Role-Based Access Control (RBAC) with pre-computed permission index for O(1) lookups
- Fine-grained permission rules: per resource type, per action (POST, PUT, PATCH, DELETE, GET)
- Deny-before-allow logic (any deny rule overrides allow rules)
- Wildcard support (`*` element type = all resources, `-999` action = all actions)
- `AllowedTypes(vnic, aaaid)` — returns resource types the user can GET (drives UI navigation visibility)
- `AllowedActions(vnic, aaaid)` — returns type → allowed actions map (drives Add/Edit/Delete button visibility)

### Data-Level Security (fully implemented)
- **Row-level security**: `ScopeView` filters query results using L8Query based on denied attributes
- **Field-level security**: Selectively blanks denied fields in query results
- Attribute-based deny rules (key-value pairs in role rules)

### Encryption & Network Security (fully implemented)
- AES-256 encryption/decryption for stored data
- Encrypted credential storage with obfuscation
- Network-level: `CanDial`, `CanAccept`, `ValidateConnection` for inter-service communication

### Audit & Event Logging (fully implemented)
- Posts security events to l8events: `LOGIN_FAILED`, `TFA_FAILED`, `ACCESS_DENIED`
- Posts audit events to l8events: `LOGIN_SUCCESS`, `USER_REGISTERED`
- All events include severity, user ID, operation, resource type, and message

### Protobuf Types (defined in `secure.proto`)
- `L8Token` — bearer token with expiration, user mapping, TFA state
- `L8User` — full user profile with password, roles, account status, lockout tracking
- `L8Role` — role definition with permission rules
- `L8Rule` — permission rule: element type, allow/deny, action map, attribute-level access
- `L8Credentials` / `L8CredentialsList` — external credential storage
- `L8SecureConfig` — master configuration (encryption key, secret, all users/roles/credentials)
- `L8Password` — salted hash storage
- `L8TwoFactorAuthentication` — TOTP secret, backup codes, verification timestamp
- Enums: `AccountStatus`, `Need_FA`, `FA_Setup`, `TFA_Verify_State`, `MUST_CHANGE`

### Default Roles (configured per project at build time)
- **Admin** — full access to all resources and actions
- **Operator** — standard operational access
- **Viewer** — read-only access

### Storage
- Encrypted file-based storage per VNET node (`/data/.{port}u`, `/data/.{port}r`, `/data/.{port}c`)
- CacheStore layer for service-level caching with protobuf marshaling
- Distributed: VNET nodes use local cache; non-VNET nodes request from remote VNET then cache locally

## Finding the Interface Definition
The `ISecurityProvider` interface is defined in the `ifs` package within the Layer 8 framework dependencies:
```bash
grep -rn "ISecurityProvider" go/vendor/github.com/saichler/
```
