# Security Config JSON Structure & Row-Level Data Scoping (CRITICAL)

## Rule
Every Layer 8 project's security config JSON defines users, roles, credentials, and system config. Roles contain **rules** that control both action-level authorization (can this role POST to this service?) and **row-level data scoping** (which rows does this role see on GET?). Do NOT implement custom data filtering in ServiceCallbacks — use the framework's deny rules with L8Query expressions.

## Config Structure

The security config JSON has these top-level sections:

```json
{
  "credentials": { ... },
  "key": "<AES encryption key>",
  "secret": "<shared secret>",
  "roles": { ... },
  "users": { ... },
  "sysconfig": { ... }
}
```

### Credentials
Maps external systems (databases, APIs, etc.) to their authentication details:
```json
"credentials": {
  "postgres": {
    "aside": "dbuser",
    "yside": "5432",
    "zside": "dbpassword"
  }
}
```

### Users
Pre-defined users with role assignments, password hashes, and account settings:
```json
"users": {
  "admin": {
    "userName": "admin",
    "password": "admin",
    "roles": { "admin": true }
  },
  "operator": {
    "userName": "operator",
    "password": "operator",
    "roles": { "operator": true, "viewer": true }
  }
}
```

### Roles and Rules
Each role contains a `rules` map. Rules come in two types:

#### Allow Rules (action-level authorization)
```json
"therapist-crud-appt": {
  "ruleId": "therapist-crud-appt",
  "elemType": "Appointment",
  "allowed": true,
  "actions": { "-999": true },
  "attributes": { "*": "*" }
}
```
- `allowed: true` — this is a permit rule
- `actions` — map of action codes to boolean (`-999` = all actions, `1`=POST, `2`=PUT, `3`=PATCH, `4`=DELETE, `5`=GET)
- `attributes` — `{"*": "*"}` means all attributes are accessible
- `elemType` — the protobuf type this rule applies to

#### Deny Rules with Row-Level Scoping
```json
"client-deny-appt-scope": {
  "ruleId": "client-deny-appt-scope",
  "elemType": "Appointment",
  "allowed": false,
  "actions": {},
  "attributes": {
    "Appointment": "select * from Appointment where clientId!=${userId}",
    "appointment.therapistnotes": ""
  }
}
```
- `allowed: false` — this is a deny rule
- `actions: {}` — empty actions means this is a data filter, not an action block
- `attributes` map contains two types of entries:
  - **Row-level filters**: Keys WITHOUT dots (e.g., `"Appointment"`) — value is an L8Query string with `${userId}` placeholder. Rows matching this query are DENIED (removed from results).
  - **Field-level denials**: Keys WITH dots (e.g., `"appointment.therapistnotes"`) — value is empty string. These fields are blanked on all returned rows.

### System Config
Database, logging, web endpoints, and infrastructure settings:
```json
"sysconfig": {
  "dataStoreType": 1,
  "dataStoreName": "mydb",
  "logLevel": 3,
  "webPort": 2773,
  "queueSize": 100
}
```

## Row-Level Data Scoping — How It Works

The framework's `ScopeView()` is called **after every GET request**, before results are returned to the client:

1. Looks up the authenticated user's roles
2. For each role's deny rules, checks the `attributes` map
3. **Row-level filters** (keys without dots): Substitutes `${userId}` with the authenticated user's ID, parses the L8Query, and removes matching rows from results
4. **Field-level denials** (keys with dots): Blanks the specified fields on remaining rows

### The ${userId} Placeholder
`${userId}` is substituted at runtime with the authenticated user's ID. This is the ONLY supported placeholder.

### Deny = Negative Filter
The L8Query in a deny rule specifies what to REMOVE. To scope a user to only their own data:
```
"select * from SpringListing where buyerId!=${userId}"
```
This means "deny rows where buyerId is NOT the current user" — effectively the user only sees rows where buyerId IS their ID.

## Designing Security Rules for a New Project

### Step 1: Identify roles
List all roles and what each should be able to do (CRUD per entity type).

### Step 2: Write allow rules
For each role, create allow rules granting action access to entity types.

### Step 3: Write deny/scope rules
For each role, identify data that should be restricted:
- **User-scoped data**: Use `${userId}` deny rules to restrict to own data
- **Sensitive fields**: Use dot-notation field denials to blank fields

### Step 4: Handle public vs. private data
Some entities are intentionally public (e.g., active listings in a marketplace). Only add deny rules for private data. For public data with a private subset (e.g., draft listings), scope only the private statuses:
```json
"buyer-deny-other-drafts": {
  "allowed": false,
  "attributes": {
    "SpringListing": "select * from SpringListing where buyerId!=${userId} and status=1"
  },
  "elemType": "SpringListing"
}
```
This denies access to OTHER users' draft listings while keeping active/fulfilled listings visible to all.

## What NOT to Do
- Do NOT implement row-level filtering in ServiceCallbacks — use security config deny rules
- Do NOT hardcode user ID checks in Before/After hooks
- Do NOT create custom middleware for data scoping
- Do NOT use `baseWhereClause` in the UI as a substitute for server-side scoping — UI filters are for convenience, not security

## Config File Location
The security config JSON lives in the project's security plugin directory:
```
go/secure/plugin/<projectname>/<projectname>.json
```

## Config Pipeline
```
JSON file → protojson.Unmarshal → L8SecureConfig protobuf
→ proto.Marshal → AES encrypt → secure store (.sec file)
→ At runtime: decrypt → unmarshal → SecurityProvider.init()
→ AAA builds RolePermissions index for O(1) lookups
→ ScopeView() filters GET results per-request
```

## Reference Implementation
The canonical example is `l8secure/go/secure/plugin/phy/phy.json` (l8physio project security config). It demonstrates:
- 5 roles with granular allow/deny rules
- Row-level scoping via `${userId}` deny rules
- Field-level denials (blanking sensitive fields)
- Pre-defined users with role assignments

## PRD Requirement
Every PRD that defines roles and access control MUST include a **Security Config Design** section showing:
1. Role definitions with allow rules per entity type
2. Deny rules with L8Query expressions for row-level scoping
3. Field-level denials for sensitive data
4. Which data is intentionally public vs. user-scoped

## Relationship to Other Rules
- Extends `security-provider-interface.md`: this rule documents the config format that ISecurityProvider consumes
- Extends `security-provisioning-channels.md`: this rule documents the structure of the "security config JSON" channel
- Referenced by `prd-compliance.md`: PRDs must include security config design
