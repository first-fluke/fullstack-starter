# DESIGN.md Specification

## Purpose

DESIGN.md is the single source of truth for a project's visual language.
It is both human-readable AND machine-readable. It is portable across tools,
teams, and AI agents. When a coding agent reads DESIGN.md, it should be able
to generate code that matches the design system without additional guidance.

## 6-Section Structure

### 1. Visual Theme & Atmosphere

Evocative description of mood, density, and aesthetic philosophy.
This section is about intent and feeling — NOT technical specs.

Example:
> A sophisticated dark interface with gallery-like spaciousness.
> Clean geometric forms float on deep backgrounds with subtle glass effects.
> The atmosphere is confident and minimal — every element earns its place.

### 2. Color Palette & Roles

Each color entry must include:
- Descriptive Name + Hex Code + Functional Role

Format: `Descriptive Name (#hexcode) — functional role`

Example:
```
- Deep Space Black (#0a0a0a) — primary background, page canvas
- Warm Ivory (#f5f0eb) — primary text on dark surfaces
- Signal Green (#22c55e) — CTAs, success states, active indicators
- Soft Mist (rgba(255,255,255,0.1)) — borders, dividers, glass surfaces
- Ember Red (#ef4444) — error states, destructive actions
- Steel Gray (#6b7280) — secondary text, placeholders, disabled states
```

Include shade scales (100-900) for primary and neutral colors if needed.

### 3. Typography Rules

Specify:
- Font families (with fallback stacks)
- Weight hierarchy (which weights for which purpose)
- Size scale (preferably using clamp() for fluid sizing)
- Line-height rules (different for headings vs body vs CJK)
- Letter-spacing rules (tighten headings, normal body)

### 4. Component Stylings

Concrete specifications for core components:
- **Buttons**: sizes, variants (primary/secondary/ghost), border-radius, padding, hover/active states
- **Cards/Containers**: background, border, shadow, padding, border-radius
- **Navigation**: height, layout, mobile behavior, glass effects
- **Inputs/Forms**: height, border, focus states, error states, placeholder styling

Include exact measurements, transition durations, and accessibility notes.

### 5. Layout Principles

- Grid structure (12-column, responsive gutters)
- Breakpoints (sm/md/lg/xl/2xl with pixel values)
- Max content widths
- Whitespace strategy (base unit, spacing scale)
- Responsive behavior rules (what stacks, what hides, what resizes)

### 6. Design System Notes for Code Generation

Map semantic descriptions to technical values so AI agents generate consistent code:
```
- "Pill-shaped" → rounded-full
- "Subtly rounded" → rounded-lg
- "Glass surface" → liquid-glass utility class
- "Whisper shadow" → shadow-sm with low opacity
- "Section badge" → liquid-glass rounded-full px-3.5 py-1 text-xs
- "Display heading" → font-heading italic tracking-tight leading-[0.9]
```

## Writing Guidelines

- **Be Descriptive**: "Ocean-deep Cerulean (#0077B6)" not "blue"
- **Be Functional**: always explain what each element is *used for*
- **Be Precise**: include hex codes and pixel values in parentheses after descriptions
- **Be Consistent**: same terminology throughout the document
- **Be Portable**: no framework-specific syntax in descriptions (Tailwind classes go in Section 6 only)

## Extraction Pipeline (from existing designs)

When extracting DESIGN.md from an existing site or Stitch project:

1. **Retrieval** — fetch HTML/CSS source or Stitch screen data
2. **Extraction** — identify fonts, colors, spacing, component patterns
3. **Translation** — convert raw CSS values to semantic descriptions
4. **Synthesis** — organize into 6 sections
5. **Alignment** — verify consistency, resolve conflicts, fill gaps
