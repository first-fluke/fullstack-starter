---
description: when working with design tokens, colors, or theming.
---


# Design Tokens Workflow

## Source of Truth
The single source of truth for all design tokens is located in `packages/design-tokens/src/tokens.ts`.
- **Do NOT** edit `apps/web/src/app/[locale]/tokens.css` directly - it's auto-generated.
- **Do NOT** edit `apps/mobile/lib/core/theme/generated_theme.dart` directly - it's auto-generated.
- **ALWAYS** make changes in `packages/design-tokens/src/tokens.ts`.

## Color Space
- **SSOT Format**: OKLCH (Lightness, Chroma, Hue)
- **Web Output**: CSS OKLCH variables (P3 wide-gamut support)
- **Mobile Output**: Flutter `Color.from(colorSpace: ColorSpace.displayP3)` for P3 colors

## Token Structure

```typescript
// packages/design-tokens/src/tokens.ts
export interface OklchColor {
  l: number;  // Lightness: 0 (black) to 1 (white)
  c: number;  // Chroma: 0 (gray) to 0.4+ (vivid)
  h: number;  // Hue: 0-360 degrees on color wheel
  a?: number; // Alpha: 0-1, defaults to 1
}

const oklch = (l: number, c: number, h: number, a?: number): OklchColor => ({
  l, c, h, ...(a !== undefined && { a }),
});

export const tokens = {
  color: {
    light: {
      // Accent colors
      accent: oklch(0.97, 0, 0),
      accentForeground: oklch(0.205, 0, 0),

      // Background & Foreground
      background: oklch(1, 0, 0),
      foreground: oklch(0.145, 0, 0),

      // Border & Input
      border: oklch(0.922, 0, 0),
      input: oklch(0.922, 0, 0),

      // Card
      card: oklch(1, 0, 0),
      cardForeground: oklch(0.145, 0, 0),

      // Chart colors
      chart1: oklch(0.646, 0.222, 41.116),
      chart2: oklch(0.6, 0.118, 184.704),
      chart3: oklch(0.398, 0.07, 227.392),
      chart4: oklch(0.828, 0.189, 84.429),
      chart5: oklch(0.769, 0.188, 70.08),

      // Destructive (danger/error)
      destructive: oklch(0.577, 0.245, 27.325),
      destructiveForeground: oklch(1, 0, 0),

      // Muted (subtle)
      muted: oklch(0.97, 0, 0),
      mutedForeground: oklch(0.556, 0, 0),

      // Popover (dropdown/tooltip)
      popover: oklch(1, 0, 0),
      popoverForeground: oklch(0.145, 0, 0),

      // Primary (Lime Green)
      primary: oklch(0.85, 0.2, 130),
      primaryForeground: oklch(0.205, 0, 0),
      ring: oklch(0.708, 0, 0),

      // Secondary
      secondary: oklch(0.97, 0, 0),
      secondaryForeground: oklch(0.205, 0, 0),

      // Sidebar
      sidebar: oklch(0.985, 0, 0),
      sidebarAccent: oklch(0.97, 0, 0),
      sidebarAccentForeground: oklch(0.205, 0, 0),
      sidebarBorder: oklch(0.922, 0, 0),
      sidebarForeground: oklch(0.145, 0, 0),
      sidebarPrimary: oklch(0.205, 0, 0),
      sidebarPrimaryForeground: oklch(0.985, 0, 0),
      sidebarRing: oklch(0.708, 0, 0),
    },
    dark: { /* similar structure with dark mode values */ },
  },

  // Radius (pixels)
  radius: {
    base: 10,
    sm: 6,
    md: 8,
    lg: 10,
    xl: 14,
  },

  // Spacing (pixels)
  spacing: {
    xs: 4,
    sm: 8,
    md: 12,
    base: 16,
    lg: 20,
    xl: 24,
    "2xl": 32,
    "3xl": 48,
  },

  // Typography
  typography: {
    fontFamily: {
      sans: "Noto Sans KR",
      mono: "Noto Sans Mono",
    },
    fontSize: {
      xs: 12,
      sm: 14,
      base: 16,
      lg: 18,
      xl: 20,
      xl2: 24,
      xl3: 30,
      xl4: 36,
      xl5: 48,
      xl6: 60,
      xl7: 72,
      xl8: 96,
    },
    fontWeight: {
      regular: 400,
      medium: 500,
      bold: 700,
      black: 900,
    },
    lineHeight: {
      xs: 1.0,
      sm: 1.25,
      base: 1.5,
      lg: 1.75,
      xl: 1.75,
      xl2: 2.0,
      xl3: 2.25,
      xl4: 2.5,
    },
    letterSpacing: {
      tight: -0.5,
      normal: 0,
      wide: 0.8,
    },
  },

  // Style
  style: {
    borderWidth: 1,
    disabledOpacity: 0.5,
    hoverDarken: 0.05,
    hoverLighten: 0.075,
  },

  // Semantic colors (convenience layer)
  semantic: {
    info: oklch(0.6, 0.2, 260),
    success: oklch(0.65, 0.2, 145),
    warning: oklch(0.75, 0.18, 85),
  },
};
```

## Workflow

### 1. Modify Tokens
Edit `packages/design-tokens/src/tokens.ts`:
- Add/update colors in `tokens.color.light` and `tokens.color.dark`
- Modify radius, spacing, typography, or style values

### 2. Build & Distribute
Run the build command to generate platform-specific outputs:

```bash
mise //packages/design-tokens:build
```

This generates:
- **Web**: `apps/web/src/app/[locale]/tokens.css` (OKLCH CSS variables)
- **Mobile**: `apps/mobile/lib/core/theme/generated_theme.dart` (ForUI FThemeData)

### 3. Watch Mode (Development)
For automatic rebuilds during development:

```bash
mise //packages/design-tokens:dev
```

## Adding New Colors

### Available Color Categories

The token system provides these color categories:

- **Base Colors**: `primary`, `secondary`, `accent`, `foreground`, `background`
- **Component Colors**: `card`, `popover`, `sidebar`, `input`, `border`
- **Feedback Colors**: `destructive`, `muted`, `ring`
- **Chart Colors**: `chart1` through `chart5` (for data visualization)
- **Semantic Colors**: `info`, `success`, `warning` (convenience layer)

### Step 1: Add to tokens.ts

```typescript
color: {
  light: {
    // Use oklch() helper for new colors
    newColor: oklch(0.65, 0.2, 145),
    newColorForeground: oklch(0.205, 0, 0),
  },
  dark: {
    // Add same colors with dark mode values
    newColor: oklch(0.65, 0.2, 145),
    newColorForeground: oklch(0.985, 0, 0),
  },
}
```

### Step 2: Build
```bash
mise //packages/design-tokens:build
```

### Step 3: Use in Code

**Web (CSS variable):**
```css
background-color: oklch(var(--color-newColor) / var(--alpha));
```

**Mobile (Flutter theme):**
```dart
Color.from(
  colorSpace: ColorSpace.displayP3,
  l: tokens.newColor.l,
  c: tokens.newColor.c,
  h: tokens.newColor.h,
)
```

## OKLCH Color Guide

| Component | Range | Description |
|-----------|-------|-------------|
| L (Lightness) | 0-1 | 0 = black, 1 = white |
| C (Chroma) | 0-0.4+ | 0 = gray, higher = more vivid |
| H (Hue) | 0-360 | Color wheel angle |
| A (Alpha) | 0-1 | Optional, defaults to 1 |

### Common Hue Values
- 0: Red
- 30: Orange
- 60: Yellow
- 130: Lime Green (primary)
- 180: Cyan
- 240: Blue
- 300: Magenta

## Testing
Run tests to verify color conversion accuracy:

```bash
mise //packages/design-tokens:test
```

Tests cover:
- OKLCH to P3 conversion accuracy
- CSS generation correctness
- Flutter theme generation
- Edge cases and boundary conditions
