# PRD: Layer 8 Ecosystem Company Website

## Overview

A professional, modern company website for the Layer 8 Ecosystem — a revolutionary software development company that expedites developing enterprise-grade software from months/years to days/weeks. The website will feature parallax scrolling, custom illustration animations, and a polished corporate feel.

**Location**: `go/layer8/web/`
**Serving**: Via existing `go/layer8/main.go` which already runs an HTTPS web server on port 4443.

---

## Site Structure

### Pages

1. **Home (index.html)** — Hero section, value proposition, key stats, call-to-action
2. **Component detail pages** — One per component project, generated from README.md content

### Home Page Sections (Single-Page Vertical Scroll)

1. **Hero** — Typography-driven. Headline: "Build Production Systems in Days — Not Years." Subtext: "Layer 8 is an AI-native, intent-driven architecture that eliminates implicit complexity." CTAs: "Explore the System" / "See It Working". No images, no background visuals — let typography carry the impact.
2. **Proof** — Real systems built with Layer 8. Each shows: title, one-line description, "Built in X days." Evidence over claims.
3. **The Problem** — Short, direct statements: software systems are slow to build, architecture is implicit and fragile, complexity compounds over time. No paragraphs. Just clarity.
4. **The Shift** — Layer 8's approach: intent-driven services, runtime API discovery, deterministic execution. Optional simple diagram (no heavy visuals).
5. **How It Works** — Flow: Service → Contract → Runtime → Exposure. No predefined endpoints, APIs emerge dynamically, security built-in. Concise and structured.
6. **Architecture** — Interactive layered dependency diagram showing how components build on each other (see Architecture section below)
7. **Components** — Service cards grid for all Layer 8 component projects
8. **Founders** — Team section with links to LinkedIn profiles
9. **Call to Action** — "Explore the System" / "Run It Locally" / "Read the Architecture". No "Contact Sales" or "Book a Demo."
10. **Footer** — Links, copyright, GitHub organization link

---

## Design Specifications

**Full design guide**: `plans/look.md`

### Core Principle
> Radical Simplicity. Deterministic Power. Zero Noise.

This is a proof surface for a new architecture paradigm, not a marketing site. Every element must justify its existence.

### Visual System
- **Background**: Pure white / near-white (#FFFFFF / #FAFAFA)
- **Primary color**: Black (#000000)
- **Secondary**: Neutral gray (#666666 / #999999)
- **Accent** (very limited): Blue (#0070F3) or subtle green (#00A86B)
- **Rules**: No gradients. No shadows unless extremely subtle. No more than 2-3 colors total.

### Typography
- **Primary font**: Inter
- **Code snippets**: JetBrains Mono
- **Hero headlines**: 48-72px, bold, tight line-height
- **Section titles**: 28-36px, bold
- **Body**: 16-18px, high readability, generous spacing
- **Content style**: Short sentences. No paragraphs longer than 3 lines. Aggressive whitespace.

### Layout
- Strict vertical flow, centered content, max-width ~1100px
- Large vertical spacing between sections (80-140px)
- Left-aligned text, consistent margins, no justified text

### Interaction
- **Hover**: Subtle color change only
- **Scroll**: Simple reveal (fade/slide) — no complex animations
- **Behavior**: Fast, predictable, no surprises

### What NOT to Include
- Stock photos, decorative graphics, overly complex diagrams
- Marketing banners, testimonials, buzzwords
- No flashy animations, no randomness

---

## Components Section

Each Layer 8 component project gets a service card. Cards are organized by category.

### Categories and Components

#### Foundational Infrastructure
| Project | Display Name | One-liner |
|---------|-------------|-----------|
| l8types | Type System | Service interfaces and core type definitions |
| l8utils | Utilities | Shared utilities — logging, caching, configuration |
| l8reflect | Introspection | Model-agnostic runtime reflection and change tracking |
| l8srlz | Serialization | High-performance cross-platform object serialization |
| l8ql | Query Language | SQL-like query language for Go data structures |
| l8bus | Virtual Network | Overlay networking with routing, health, and leader election |

#### Services & Persistence
| Project | Display Name | One-liner |
|---------|-------------|-----------|
| l8services | Service Framework | Distributed services with SLA, transactions, and replication |
| l8orm | ORM | Object-relational mapping as a service |
| l8web | Web Server | REST web server framework for Layer 8 services |
| l8test | Testing | Integration testing with full distributed topology |

#### Feature Libraries
| Project | Display Name | One-liner |
|---------|-------------|-----------|
| l8notify | Notifications | Multi-channel notification dispatch with throttling and escalation |
| l8agent | AI Agent | AI-powered chat orchestration with data masking |
| l8ui | UI Library | Shared desktop and mobile UI component library |
| l8events | Events | Event processing and distribution |
| l8topology | Topology | Network topology modeling and visualization |
| l8traffic | Traffic | Traffic engineering and SR policy management |

#### Data Pipeline
| Project | Display Name | One-liner |
|---------|-------------|-----------|
| l8collector | Collector | Multi-protocol network data collection (SNMP, SSH, K8s, REST) |
| l8parser | Parser | Model-agnostic data parsing with vendor configs |
| l8inventory | Inventory | Distributed cache for parsed infrastructure data |
| l8pollaris | Polling Config | Advanced polling configuration and target management |
| l8logfusion | Log Fusion | Distributed log aggregation and centralized storage |

#### Simulation
| Project | Display Name | One-liner |
|---------|-------------|-----------|
| l8opensim | Network Simulator | Scalable simulator for 25,000+ devices across 28 types |

### Service Card Design
Minimal, content-first cards:
- **Project name** (bold) and display name
- **One-line description** (body text)
- **GitHub link**: `https://github.com/saichler/{project}`
- **"Learn More" link**: Opens a detail page (`/components/{project}.html`)
- **Hover**: Subtle color change only — no shadows, no glow, no lift

### Component Detail Pages
Each component gets a dedicated page at `components/{project}.html` containing:
- Navigation back to home
- Project name and description
- Detailed content derived from the project's README.md
- GitHub repository link
- Architecture diagram (if applicable)
- Related components

---

## Proof Section (Products)

Real systems built with Layer 8. Replace claims with evidence. Format: title, one-line description, build timeline.

### l8erp — Enterprise Resource Planning
- **Description**: Complete ERP system — 12 modules, 243 services, 654 entity types
- **Evidence**: Built in weeks, not years
- **Link**: GitHub repository

### probler — Network Automation & Monitoring
- **Description**: Full-stack network intelligence — poll, parse, model, cache, persist
- **Evidence**: 8 microservices, end-to-end data pipeline
- **Link**: GitHub repository

### Presentation
- Clean, minimal cards — title, one-line description, evidence line
- No dashboard mockups, no decorative illustrations
- Each links to its GitHub repository

---

## Founders Section

### Sharon Aicler
- **Role**: Co-Founder
- **LinkedIn**: https://www.linkedin.com/in/sharon-aicler/

### Harold Lowenthal
- **Role**: Co-Founder
- **LinkedIn**: https://www.linkedin.com/in/harold-lowenthal-80010213/

Display as professional cards with placeholder avatar illustrations and LinkedIn link buttons.

---

## Architecture

The website is a section within the Layer 8 Ecosystem home page. The Layer 8 book describes a layered architecture where each component builds on the ones below it. The website should visually communicate this architecture — showing how foundational components (types, utils, reflection, serialization) support higher-level components (services, ORM, web server), which in turn enable feature libraries (notifications, AI agent, UI) and data pipeline services (collector, parser, inventory), ultimately powering end-user products (l8erp, probler).

### Component Dependency Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      PRODUCTS                           │
│              l8erp    probler    l8bugs                  │
├─────────────────────────────────────────────────────────┤
│                  FEATURE LIBRARIES                      │
│   l8notify  l8agent  l8ui  l8events  l8topology         │
│   l8traffic  l8alarms                                   │
├─────────────────────────────────────────────────────────┤
│                   DATA PIPELINE                         │
│   l8collector  l8parser  l8inventory  l8pollaris        │
│   l8logfusion                                           │
├─────────────────────────────────────────────────────────┤
│               SERVICES & PERSISTENCE                    │
│         l8services    l8orm    l8web    l8test           │
├─────────────────────────────────────────────────────────┤
│              FOUNDATIONAL INFRASTRUCTURE                │
│    l8types   l8utils   l8reflect   l8srlz   l8ql       │
│                        l8bus                             │
├─────────────────────────────────────────────────────────┤
│                   SIMULATION                            │
│                     l8opensim                            │
└─────────────────────────────────────────────────────────┘
```

This layered diagram should be represented as an animated SVG in the Architecture section of the website, with layers building up from bottom to top on scroll. Each layer lights up as the user scrolls to it, and clicking a component navigates to its detail page.

### Website Architecture Section (New Page Section)

The home page should include an **Architecture** section (between "The Solution" and "Components") that:
1. Shows the layered dependency diagram above as an interactive animated SVG
2. Each component is a clickable box linking to its detail page
3. Animated data flow lines show how data moves up through the layers
4. Brief caption explaining: "Every layer builds on the one below it. No circular dependencies. Each component has a single responsibility."

---

## File Size Constraints

All source files (HTML, CSS, JS) MUST stay under 500 lines per the maintainability rules. Given the scope of the website:

- **index.html**: Will be large with all sections. If it approaches 500 lines, split into partial HTML files loaded via JS, or split sections into separate HTML files with shared navigation.
- **CSS files**: Already split by concern (style.css, components.css, animations.css). If any exceeds 450 lines, split further (e.g., `hero.css`, `sections.css`).
- **JS files**: Already split by concern. Keep each under 500 lines.
- **Component detail pages**: Each is a single component — should stay well under 500 lines individually.
- **SVG illustrations**: Complex inline SVGs should be in separate `.svg` files under `images/svg/`, not inlined into HTML, to keep HTML files small.

---

## Technical Implementation

### File Structure
```
go/layer8/web/
├── index.html              # Main single-page site
├── css/
│   ├── style.css           # Main stylesheet (layout, typography, color variables)
│   └── components.css      # Component cards and grid styling
├── js/
│   ├── reveal.js           # IntersectionObserver scroll-triggered fade/slide reveals
│   └── nav.js              # Navigation and smooth scroll
└── components/             # Per-component detail pages
    ├── l8types.html
    ├── l8utils.html
    ├── l8reflect.html
    ├── ... (one per component)
    └── template.html       # Base template for detail pages
```

### Technology
- **Pure HTML/CSS/JS** — No build tools, no npm, no frameworks
- **CSS Custom Properties** for color/spacing tokens
- **IntersectionObserver API** for scroll-triggered reveals
- **Inter + JetBrains Mono** via CDN (Google Fonts)
- **Responsive**: Mobile-first with breakpoints at 768px and 1100px

### Performance
- No external JS dependencies (fonts only external resource)
- Minimal JS — just scroll reveals and navigation
- No complex animations, no heavy assets

---

## Implementation Phases

### Phase 1: Core Structure and Hero
1. Create `go/layer8/web/` directory structure
2. Build `index.html` with semantic HTML structure for all sections
3. Implement base CSS (reset, Inter + JetBrains Mono typography, layout grid, color variables)
4. Build hero section — typography-driven, no images
5. Implement simple scroll reveal system (fade/slide via IntersectionObserver)
6. Build navigation with smooth scroll to sections

### Phase 2: Content Sections
1. Build "Proof" section — product evidence cards (l8erp, probler)
2. Build "The Problem" section — short direct statements, no paragraphs
3. Build "The Shift" section — Layer 8 approach, optional simple diagram
4. Build "How It Works" section — Service → Contract → Runtime → Exposure flow
5. Build "Architecture" section — layered dependency diagram with clickable components

### Phase 3: Components Section
1. Build service card component (HTML/CSS) — minimal, content-first
2. Build responsive card grid layout
3. Populate all component cards with data

### Phase 4: Component Detail Pages
1. Create detail page HTML template
2. Build detail pages for each component from README.md content
3. Add navigation between detail pages and home

### Phase 5: Founders, CTA, and Footer
1. Build founders section with LinkedIn-linked cards
2. Build call-to-action section ("Explore the System" / "Run It Locally" / "Read the Architecture")
3. Build footer

### Phase 6: Polish and Responsive
1. Responsive design testing and fixes
2. Cross-browser testing
3. Final polish — spacing, typography, consistency
4. Verify all files under 500 lines

---

## Traceability Matrix

| # | Item | Phase |
|---|------|-------|
| 1 | Directory structure creation | Phase 1 |
| 2 | index.html skeleton with all sections | Phase 1 |
| 3 | CSS foundation (Inter/JetBrains Mono, colors, grid, max-width 1100px) | Phase 1 |
| 4 | Hero section — typography-driven, no images | Phase 1 |
| 5 | Scroll reveal system (fade/slide via IntersectionObserver) | Phase 1 |
| 6 | Navigation with smooth scroll | Phase 1 |
| 7 | Proof section — product evidence cards | Phase 2 |
| 8 | Problem section — short direct statements | Phase 2 |
| 9 | The Shift section — Layer 8 approach | Phase 2 |
| 10 | How It Works section — service flow | Phase 2 |
| 11 | Architecture section — layered dependency diagram | Phase 2 |
| 12 | Service card component (minimal, content-first) | Phase 3 |
| 13 | Responsive card grid | Phase 3 |
| 14 | All 22 component cards populated | Phase 3 |
| 15 | GitHub links on all component cards | Phase 3 |
| 16 | "Learn More" links to detail pages | Phase 3 |
| 17 | Detail page template | Phase 4 |
| 18 | 22 component detail pages from README.md content | Phase 4 |
| 19 | Detail page navigation | Phase 4 |
| 20 | Founders section with LinkedIn links | Phase 5 |
| 21 | Call-to-action section | Phase 5 |
| 22 | Footer | Phase 5 |
| 23 | Responsive design testing and fixes | Phase 6 |
| 24 | Cross-browser testing | Phase 6 |
| 25 | File size compliance (all files under 500 lines) | Phase 6 |

---

## Verification Phase

After all phases are complete:
1. Open the website at `https://<host>:4443/layer8/`
2. Verify hero animation plays smoothly
3. Scroll through all sections — verify parallax effect works
4. Verify all 22 component cards render with correct data
5. Click each GitHub link — verify it opens the correct repository
6. Click each "Learn More" link — verify detail page loads with content
7. Verify products section shows l8erp and probler
8. Verify founders section shows both founders with LinkedIn links
9. Test on mobile viewport (375px width) — verify responsive layout
10. Test on tablet viewport (768px width)
11. Verify all scroll-triggered animations fire correctly
12. Verify no console errors
