# Never Act on Questions Without Approval (CRITICAL)

## Rule
When the user asks a question, ONLY answer the question. Do NOT take any action (editing files, modifying plans, changing code) based on the question until the user explicitly approves.

## Why This Is Critical
A question is a question — not an instruction. The user may be exploring options, verifying understanding, or checking your reasoning. Jumping to action on a question assumes intent the user never expressed and can introduce unwanted changes.

## What To Do
1. Answer the question clearly and concisely
2. STOP and wait for the user's response
3. Only take action when the user explicitly says to proceed

## What NOT To Do
- Do NOT edit files after answering a question
- Do NOT update plans after answering a question
- Do NOT assume the question implies a request to change anything
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
