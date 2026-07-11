# Verify app.html Scripts Against Loading Order (CRITICAL)

## Rule
After completing ANY PRD implementation that includes a UI, you MUST verify the project's `app.html` (and `m/app.html` for mobile) script tags against the canonical loading order in `desktop-script-loading-order.md` (and `mobile-script-loading-order.md`). Every l8ui script that the project uses MUST be present, and MUST appear in the correct dependency order.

## Why This Is Critical
A missing script tag in `app.html` causes a silent cascading failure: the undefined global (`ReferenceError: X is not defined`) kills the IIFE that depends on it, which prevents module initialization (`Layer8DModuleFactory.create()` fails), which breaks ALL navigation, tables, CRUD, and forms across the entire UI. The error only appears in the browser console — the page loads but nothing works.

This bug is invisible during implementation because no build step validates JS dependency ordering — Go compiles fine, HTML is syntactically valid, and the error only surfaces at runtime when the page loads in a browser.

## The Verification Process
After UI implementation is complete:

1. **List all l8ui scripts in app.html:**
   ```bash
   grep 'src="l8ui/' go/<project>/ui/web/app.html | sed 's/.*src="//' | sed 's/".*//'
   ```

2. **Compare against the canonical loading order** in `desktop-script-loading-order.md`

3. **For each l8ui script in app.html**, verify:
   - Its dependencies (scripts it references) are listed BEFORE it
   - No script is missing from the sequence

4. **Common missing scripts** (files that are dependencies but easy to overlook):
   - `layer8-module-factory-core.js` — required before `layer8d-module-factory.js`
   - `layer8d-service-registry.js` — required before `layer8d-module-crud.js`
   - `layer8d-forms-fields.js` — required before `layer8d-forms.js`

## When This Applies
- After completing a PRD implementation with UI
- After adding new l8ui components to an existing project
- After updating the l8ui submodule to a newer version that may have added new files
- After copying `app.html` from another project and adapting it

## Error Symptoms
- Browser console: `Uncaught ReferenceError: <GlobalName> is not defined`
- Multiple modules fail to initialize (same error repeated for each init file)
- Page loads but shows no navigation, no tables, no data
- Dashboard may partially work (if it doesn't depend on the missing module system)
