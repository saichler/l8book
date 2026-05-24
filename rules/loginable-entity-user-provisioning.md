# Loginable Entity Must Provision a User with Portal (CRITICAL)

## Rule
When a project creates an entity that represents a person who needs to log in (member, client, patient, employee, partner, etc.), a corresponding user MUST be provisioned via the Security API with a `Portal` field. Without the Portal field, the user cannot be redirected to the correct portal after login.

**User provisioning MUST happen in the UI layer (JavaScript), NOT in the Go ServiceCallback.** The ServiceCallback must NEVER import `l8secure` or any security types — see `never-import-l8secure.md`.

## Why This Is Critical
If a loginable entity is created without a corresponding user+portal:
1. The person has no credentials — they cannot log in at all
2. Even if a user is created later without the Portal field, the `/auth` endpoint returns an empty portal, and the login page doesn't know where to redirect
3. The person sees the default admin portal instead of their intended portal, or gets stuck on the login page

## The Pattern: UI-Based User Provisioning

User provisioning is done from the UI layer via JavaScript, following the l8physio pattern:

### Step 1: Create a user provisioning JS file

```javascript
// <project>/<project>-user-provisioning.js
(function() {
    'use strict';
    var USERS_ENDPOINT = '/73/users';
    var DEFAULT_PASSWORD = '12345678';

    function getHeaders() {
        return Object.assign({ 'Content-Type': 'application/json' },
            typeof getAuthHeaders === 'function' ? getAuthHeaders() : {});
    }

    async function postUser(user) {
        try {
            var resp = await fetch(Layer8DConfig.resolveEndpoint(USERS_ENDPOINT), {
                method: 'POST', headers: getHeaders(), body: JSON.stringify(user)
            });
            if (!resp.ok) {
                console.warn('[UserProvisioning] user creation returned', resp.status);
                return false;
            }
            return true;
        } catch (e) {
            console.warn('[UserProvisioning] user creation failed', e);
            return false;
        }
    }

    async function createEntityUser(entity) {
        var email = entity.email;
        if (!email) return;
        var roles = {}; roles['<role-name>'] = true;
        var ok = await postUser({
            userId: entity.<entityId>,
            fullName: (entity.firstName + ' ' + entity.lastName).trim(),
            email: email,
            accountStatus: 'ACCOUNT_STATUS_ACTIVE',
            portal: '<portal-subdirectory>/app.html',
            password: { hash: DEFAULT_PASSWORD },
            roles: roles
        });
        if (ok) Layer8DNotification.success('User account "' + email + '" created');
        else    Layer8DNotification.warning('Entity saved but user account creation failed');
    }

    window.<Project>UserProvisioning = { createEntityUser: createEntityUser };
})();
```

### Step 2: Wire into the module init file

Override `_openAddModal` for the loginable entity's model so that after a successful save, the user provisioning function is called:

```javascript
var origOpenAdd = window.<Module> && window.<Module>._openAddModal;
if (typeof origOpenAdd === 'function') {
    window.<Module>._openAddModal = function(service) {
        if (service.model === '<EntityModel>' && window.<Project>UserProvisioning) {
            // Override save to call createEntityUser after successful POST
            // (see l8physio physio-init.js lines 73-119 for full pattern)
        } else {
            origOpenAdd.call(this, service);
        }
    };
}
```

### Step 3: Add script tag to app.html

Include the provisioning JS before the init JS in `app.html`.

## What NOT to Do

```go
// WRONG — importing l8secure in a ServiceCallback
import "github.com/saichler/l8secure/go/types/secure"

user := &secure.L8User{ ... }
l8c.PostEntity("users", 73, user, vnic)
```

Projects must NEVER import `l8secure`. User provisioning belongs in the UI layer, not the Go backend.

## Identifying a Loginable Entity
An entity represents a loginable person if ANY of the following are true:
- It has an `email` field AND is intended for an external user (member, client, patient)
- The PRD describes a portal or separate UI for this entity's audience
- The entity has fields like `userId`, `password`, or `accountStatus`
- The PRD mentions "self-registration" or "login" for this entity type

## Required User Fields
When provisioning a user for a loginable entity, ALL of the following fields are required:

| Field | Value | Why |
|-------|-------|-----|
| `userId` | Entity's primary key ID | Links user to entity |
| `email` | Entity's email | For login and communication |
| `fullName` | Entity's name fields combined | Display in UI header |
| `accountStatus` | `ACCOUNT_STATUS_ACTIVE` | Allows immediate login |
| `portal` | `"<subdirectory>/app.html"` | Redirects to correct portal after login |
| `password` | `{ hash: "<default>" }` | Initial credentials |
| `roles` | Role map (e.g., `{"member": true}`) | Authorization scope |

## The Portal Field Is Mandatory
The `Portal` field on the user is what the `/auth` endpoint returns after successful authentication. The login page's `getRedirectUrl(result.portal)` uses this value to redirect the user to their portal. Without it, the redirect fails silently.

## Mock Data
Mock data generators don't go through the UI, so they must create users explicitly in their phase files using `map[string]interface{}` posted to `/project/73/users` via the HTTP client. See `security-provisioning-channels.md`.

## Canonical Reference
- **l8physio**: `physio-user-provisioning.js` in `../l8physio/go/physio/ui/web/physio/` — UI-based user provisioning for clients and therapists
- **l8physio**: `physio-init.js` lines 73-119 — wiring provisioning into the CRUD add flow

## PRD Requirement
Every PRD that introduces a new entity type representing a loginable person MUST include:
1. Which portal subdirectory the entity's audience uses
2. Which role(s) the entity's user gets
3. A UI-based user provisioning JS file (following the l8physio pattern)
4. The init file wiring to call provisioning on entity add
5. The security config JSON must define the role with appropriate allow/deny rules

## Historical Context
This rule was created after the FMC project's `FmcMember` entity was implemented without user provisioning. The first fix incorrectly placed provisioning in the Go ServiceCallback using `l8secure` types. The correct pattern (from l8physio) is UI-based provisioning via JavaScript — no Go backend involvement, no `l8secure` import.

## Relationship to Other Rules
- Extends `security-provisioning-channels.md`: users must be created via Security API — this rule adds WHEN and WHERE (UI layer)
- Extends `portals-same-web-server.md`: portals are subdirectories — this rule ensures users are linked to the correct portal
- Extends `never-import-l8secure.md`: projects must never import l8secure — user provisioning uses plain JS objects, not Go types
- Referenced by `prd-compliance.md`: PRDs with loginable entities must plan user provisioning
