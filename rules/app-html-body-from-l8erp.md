# app.html Body Must Be Copied from l8erp (CRITICAL)

## Rule
The `<body>` section of every Layer 8 project's `app.html` (and `m/app.html` for mobile) MUST be copied from l8erp's app.html and adapted — NEVER written from scratch. The l8ui CSS (theme, section layout, scrollbar, animations) depends on a specific DOM structure with specific CSS class names. Writing custom HTML that looks visually similar but uses different class names or DOM hierarchy will produce a completely broken layout.

## Why This Is Critical
The l8ui CSS files (`layer8d-theme.css`, `layer8-section-layout.css`, `layer8d-scrollbar.css`) target specific selectors:
- `header.app-header` — the header bar with logo, title, theme switcher, user menu
- `nav.sidebar > ul.nav-menu > li > a.nav-link[data-section]` — sidebar navigation
- `main.main-content > #content-area` — the main content area where sections load
- `.app-container` — the flex container that positions header, sidebar, and content
- `#layer8d-popup-root` — the popup rendering container

If ANY of these elements are missing, renamed, or restructured, the entire layout breaks: header doesn't render, sidebar has no styling, content area doesn't fill the viewport, popups don't appear.

## Required Body Structure (Copy and Adapt)
```html
<body>
    <div class="app-container">
        <!-- Header — change title, subtitle, logo only -->
        <header class="app-header">
            <svg class="header-illustration" viewBox="0 0 1920 60" xmlns="http://www.w3.org/2000/svg">
                <!-- Copy SVG content from l8erp exactly -->
            </svg>
            <div class="header-left">
                <img src="l8ui/images/logo.gif" alt="PROJECT_TITLE Logo" class="header-logo">
                <div class="header-title">
                    <h1>PROJECT_TITLE</h1>
                    <p class="header-subtitle">PROJECT_SUBTITLE</p>
                </div>
            </div>
            <div class="header-right">
                <div class="powered-by-header">
                    <span>Powered by</span>
                    <img src="l8ui/images/Layer8Logo.gif" alt="Layer 8 Ecosystem" class="layer8-header-logo">
                    <span class="layer8-header-text">Layer 8 Ecosystem</span>
                </div>
                <div class="layer8d-theme-picker">
                    <!-- Copy theme picker from l8erp exactly -->
                </div>
                <div class="user-menu">
                    <span class="username">Admin</span>
                    <button class="logout-btn" onclick="logout()">Logout</button>
                </div>
            </div>
        </header>

        <!-- Sidebar — change nav items only -->
        <nav class="sidebar">
            <ul class="nav-menu">
                <li><a href="#" data-section="SECTION_KEY" class="nav-link active">
                    <span class="nav-icon">EMOJI</span>
                    <span>LABEL</span>
                </a></li>
                <!-- Add one <li> per section -->
            </ul>
        </nav>

        <!-- Main Content — DO NOT CHANGE -->
        <main class="main-content">
            <div id="content-area"></div>
        </main>
    </div>

    <!-- Popup Root — DO NOT OMIT -->
    <div id="layer8d-popup-root"></div>
```

## What to Adapt
- `<title>` tag in `<head>`
- `<h1>` and `<p class="header-subtitle">` text in the header
- Sidebar `<li>` items — one per project section, with correct `data-section` values
- `alt` attributes on images

## What NOT to Change
- The `class="app-container"` wrapper
- The `<header class="app-header">` structure and class names
- The `<nav class="sidebar">` with `<ul class="nav-menu">` and `<a class="nav-link">`
- The `<main class="main-content"><div id="content-area"></div></main>` structure
- The `<div id="layer8d-popup-root"></div>` element
- The `<div class="user-menu">` with `<span class="username">` and `<button class="logout-btn">`

## app.js Must Also Follow l8erp Pattern
The app.js that drives section loading and navigation MUST follow the l8erp pattern:
- Use `DOMContentLoaded` event handler
- Reference `document.querySelectorAll('.nav-link')` for sidebar navigation
- Reference `document.querySelector('.username')` for username display
- Load sections into `document.getElementById('content-area')` (NOT `#main-content`)
- Call `loadSection('dashboard')` for the default view
- Skip l8erp-specific features that don't apply (currency cache, exchange rates, ModuleFilter)
- Per `modconfig-failure-no-logout.md`: remove or guard `Layer8DModuleFilter.load()` if the project doesn't have a ModConfig service

## css/base-core.css Is Required (CRITICAL)
The l8erp project has a `css/base-core.css` file that defines the **entire grid layout** for the app shell: `.app-container` (CSS grid), `.app-header`, `.sidebar`, `.nav-menu`, `.nav-link`, `.main-content`, `#content-area`, `.header-left`, `.header-right`, `.user-menu`, `.username`, `.logout-btn`. Without this file, the body HTML has correct class names but **no layout CSS** — everything stacks vertically with no styling.

Every new project MUST copy `css/base-core.css` and `css/responsive.css` from l8erp and include them in app.html after `layer8-section-responsive.css`:
```html
<link rel="stylesheet" href="css/base-core.css">
<link rel="stylesheet" href="css/responsive.css">
```

## Historical Context
This rule was created after l8spring's UI was completely broken because: (1) app.html body was written from scratch with wrong DOM structure, and (2) `css/base-core.css` was never created — the file that defines the entire grid layout for header, sidebar, and content area. The l8ui shared CSS does NOT include app shell layout; that lives in the project's own `css/base-core.css`.
