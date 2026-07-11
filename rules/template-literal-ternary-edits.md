# Template Literal Ternary Edit Safety

## Rule
When wrapping existing content inside a JavaScript template literal with a conditional expression (`${condition ? \`...\` : ''}`), the Edit tool's `old_string` MUST include enough context to cover BOTH the opening AND closing of the new nesting level. Never add an opening `${condition ? \`` without also editing the corresponding closing to add `` \` : ''}`.

## Why This Is Critical
Template literals can nest (backticks inside `${}`), but every opening backtick needs a matching close. A partial edit that introduces a new nesting level without closing it creates a **syntax error that silently kills the entire JS file** — no console error, no runtime exception, just undefined functions.

## The Dangerous Pattern

### WRONG: Partial edit that only covers the opening
```javascript
// old_string covers lines 5-10
        <div class="section">
            <table>
                <tbody>${items.map(i => `...`).join('')}</tbody>

// new_string wraps in ternary but doesn't close it
        ${items.length > 0 ? `
        <div class="section">
            <table>
                <tbody>${items.map(i => `...`).join('')}</tbody>
```
The existing `</table></div>` and outer closing backtick remain unchanged, so the ternary is never closed with `` ` : ''}`.

### CORRECT: Edit includes enough context to close the ternary
```javascript
// old_string covers lines 5-12 (includes the closing tags)
        <div class="section">
            <table>
                <tbody>${items.map(i => `...`).join('')}</tbody>
            </table>
        </div>

// new_string properly opens AND closes the ternary
        ${items.length > 0 ? `
        <div class="section">
            <table>
                <tbody>${items.map(i => `...`).join('')}</tbody>
            </table>
        </div>
        ` : ''}
```

## Verification
After ANY edit that adds ternary expressions or conditional wrappers inside template literals:
1. **Run `node -c <file>` immediately** to check for syntax errors
2. Count opening `${` and closing `}` — they must match
3. Count backticks — every `` ` `` inside a `${}` expression needs a matching close
4. Verify every ternary `? \`` has a corresponding `` \` : ...}`

## Error Symptoms
- Handler function undefined or "X is not a function" in console (the file failed to load)
- No visible error at all (the most common case — the file silently fails to parse)

## When This Applies
Any edit that introduces new `${}` ternary nesting inside an existing template literal.
