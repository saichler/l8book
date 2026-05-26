# Associate IDs for Cross-Entity ScopeView Filtering

## What It Is
`L8User` has a `repeated string associate_ids` field (field 19). ScopeView supports a `${associateIds}` placeholder in deny rules that expands to `[id1,id2,id3]` bracket notation — compatible with L8Query's existing `not in` comparator.

## When to Use
When a user needs to see data belonging to a list of associated entities (not just their own data). Examples: a parent seeing only their children's records, a manager seeing only their departments' data, a sales rep seeing only their assigned territories.

## How to Populate associate_ids
Set `associate_ids` on the user via the Security API (PUT to `/73/users`) or in the security config JSON:

```json
"users": {
  "guardian1": {
    "userName": "guardian1",
    "password": "password",
    "roles": { "guardian": true },
    "associateIds": ["STU-001", "STU-002"]
  }
}
```

UI-based provisioning (JavaScript) can also set `associateIds` as an array of strings on the user object when POSTing/PUTing to the Security API.

## How to Write Deny Rules

Use `${associateIds}` with `not in` syntax in deny rule attributes:

```json
"guardian-deny-student-scope": {
  "ruleId": "guardian-deny-student-scope",
  "elemType": "Student",
  "allowed": false,
  "actions": {},
  "attributes": {
    "Student": "select * from Student where studentId not in ${associateIds}"
  }
}
```

### How It Works
Given a user with `associate_ids: ["STU-001", "STU-002"]`:

**Rule template:** `select * from Student where studentId not in ${associateIds}`
**After resolution:** `select * from Student where studentId not in [STU-001,STU-002]`
**Effect:** Rows where `studentId` is NOT in the list are denied (removed). Only records matching STU-001 and STU-002 are returned.

## Empty associate_ids Behavior
If a user has no `associate_ids`, the placeholder resolves to `[]` (empty list). `not in []` denies all rows — the user sees nothing. This is the secure default.

## Combining with ${userId}
Both placeholders can be used in the same deny rule or across different rules for the same role:

```json
"attributes": {
  "Appointment": "select * from Appointment where clientId not in ${associateIds}",
  "appointment.therapistnotes": ""
}
```

## ID Value Constraint
Values in `associate_ids` must NOT contain `,`, `[`, or `]` characters. The bracket notation parser (`getInStringList`) splits on these delimiters. Layer 8 IDs are typically clean alphanumeric strings (e.g., `STU-001`), so this is unlikely to be an issue.

## Common Deny Rule Patterns

| Project | User Role | associate_ids Contains | Deny Rule |
|---------|-----------|----------------------|-----------|
| l8learn | Guardian | Children's student IDs | `studentId not in ${associateIds}` |
| l8erp | Sales Rep | Assigned territory IDs | `territoryId not in ${associateIds}` |
| l8erp | Manager | Department IDs | `departmentId not in ${associateIds}` |
| probler | GPU Operator | Owned device IDs | `deviceId not in ${associateIds}` |

## Consuming Projects Are Responsible For
1. Populating `associate_ids` on their users (via Security API or security config JSON)
2. Writing deny rules that reference `${associateIds}` in their security plugin config
3. Re-vendoring l8secure after the change is available
