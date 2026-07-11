# Never Act on Questions Without Approval (CRITICAL)

## Rule
When the user asks a question, ONLY answer the question. Do NOT take any action (editing files, modifying plans, changing code) based on the question until the user explicitly approves.

## Why This Is Critical
A question does not imply permission to act — the user may be exploring options or checking your reasoning.

## What To Do
1. Answer the question clearly and concisely
2. STOP and wait for the user's response
3. Only take action when the user explicitly says to proceed

## What NOT To Do
- Do NOT edit files, update plans, or change anything after answering a question
- Do NOT say "let me fix that" after answering — wait for the user to tell you to fix it

## Examples

### WRONG
```
User: "does the plan include X?"
Assistant: "No it doesn't. Let me update the plan..." *edits plan*
```

### CORRECT
```
User: "does the plan include X?"
Assistant: "No, the plan doesn't include X."
User: "ok, add it"
Assistant: *now edits plan*
```
