---
name: wr-style-guide:update-guide
description: Create or update the project's docs/STYLE-GUIDE.md by examining existing CSS, components, and design patterns, then asking the user about style preferences.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Style Guide Generator

Create or update `docs/STYLE-GUIDE.md` tailored to this project's visual design and component patterns. The style-guide-lead agent reads this file to review CSS and UI component changes.

## What belongs in docs/STYLE-GUIDE.md

- **Design tokens**: Colors, spacing, typography, border radius, shadows
- **Component patterns**: How common UI elements should be built
- **Layout conventions**: Grid system, responsive breakpoints, spacing rhythm
- **CSS conventions**: Naming, architecture (BEM, utility-first, CSS modules, etc.)
- **Do/Don't examples**: Concrete examples drawn from the actual project
- **Last reviewed date**: When the guide was last reviewed or updated

## Steps

### 1. Discover project context

Examine the project to understand its current styling approach.

**Find the CSS architecture** by scanning for:
- CSS/SCSS/Sass/Less files and their structure
- Tailwind config (`tailwind.config.*`)
- CSS-in-JS patterns (styled-components, emotion, CSS modules)
- Design token files or theme configuration
- Component library usage (MUI, Chakra, Radix, shadcn, etc.)

**Discover design patterns**:
- Color palette (scan CSS custom properties, Tailwind config, or theme files)
- Typography scale (font sizes, weights, line heights in use)
- Spacing system (consistent spacing values or ad-hoc)
- Component structure (how are common patterns like cards, buttons, forms built?)
- Responsive approach (breakpoints, mobile-first vs desktop-first)

**Identify inconsistencies**:
- Are there multiple color values that should be the same token?
- Mixed approaches (some components use utility classes, others use custom CSS)?
- Inconsistent spacing or typography?

### 2. Check for existing guide

If `docs/STYLE-GUIDE.md` already exists, read it. Identify:
- Whether it still reflects the current CSS architecture
- Whether examples reference classes or patterns that no longer exist
- Whether the last reviewed date is stale (> 2 weeks)

### 3. Draft the style guide

Based on project discovery, draft sections covering:

**CSS Architecture**:
What approach this project uses and why (utility-first, BEM, CSS modules, etc.).

**Design Tokens**:
Document the token system (colors, spacing, typography, shadows, borders). Reference the actual source (CSS variables, Tailwind config, theme file).

**Component Patterns**:
How to build common UI elements. At least cover: buttons, forms, cards, navigation, layout containers.

**Layout and Responsive**:
Grid system, breakpoints, spacing rhythm, container widths.

**Do/Don't Examples**:
At least 5 concrete pairs drawn from the actual project. Show the wrong way and the right way.

**Naming Conventions**:
Class naming, file naming, component naming patterns.

### 4. Confirm with the user

You MUST use the AskUserQuestion tool to collect user confirmation.

Present:
1. The CSS architecture summary and ask if it's accurate
2. The design tokens discovered and ask if any are wrong or missing
3. The component patterns and ask if the direction is right
4. Whether any specific requirements are missing (e.g., dark mode, accessibility contrast requirements, animation preferences)

### 5. Write docs/STYLE-GUIDE.md

Write the guide including:
- A header with "Last reviewed" date (today's date)
- All sections from step 3, refined based on user feedback from step 4
- A note that the wr-style-guide:agent reads this file to review CSS and UI changes

If updating rather than creating:
- Preserve existing guidance the user hasn't asked to change
- Show the user a diff of what changed
- Update the "Last reviewed" date

$ARGUMENTS
