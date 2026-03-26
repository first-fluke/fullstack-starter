# Motion Design Reference

## Animation Libraries & When to Use

| Library         | Import                      | Best For                              |
|-----------------|-----------------------------|---------------------------------------|
| motion          | `from "motion/react"`       | Declarative, springs, layout, gestures|
| GSAP            | `from "gsap"`               | Timelines, ScrollTrigger, SplitText   |
| Three.js / R3F  | `from "@react-three/fiber"` | 3D scenes, physics (Rapier)           |
| ogl             | `from "ogl"`                | Lightweight WebGL shaders             |
| Lenis           | `from "lenis/react"`        | Smooth scroll                         |

### Decision Guide
- Simple entrance/exit → **motion**
- Scroll-linked transforms → **motion** (`useScroll` + `useTransform`)
- Complex timelines with sequencing → **GSAP** (TimelineMax, ScrollTrigger)
- Character/word splitting → **GSAP** (SplitText plugin)
- 3D objects or physics → **Three.js + R3F**
- GPU shader effects (backgrounds) → **ogl** (lighter than Three.js)
- Smooth page scrolling → **Lenis**

## Motion Principles

1. **Purposeful**: Every animation must convey state change or guide attention
2. **Fast**: 200-500ms for transitions, 150ms for micro-interactions
3. **Natural**: Use spring physics or ease-out — never linear for UI elements
4. **Restrained**: Maximum 2-3 animated elements visible simultaneously

## Common Patterns

### Entrance Animation (motion/react)
```tsx
<motion.div
  initial={{ opacity: 0, y: 20, filter: "blur(10px)" }}
  animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
  transition={{ duration: 0.35, delay: index * 0.1 }}
/>
```

### Scroll-Driven Transform (motion/react)
```tsx
const { scrollYProgress } = useScroll()
const opacity = useTransform(scrollYProgress, [0, 0.5], [0, 1])
const y = useTransform(scrollYProgress, [0, 1], [100, 0])
```

### Staggered Children (motion/react)
```tsx
<motion.div
  variants={{
    show: { transition: { staggerChildren: 0.1 } }
  }}
  initial="hidden"
  animate="show"
>
  {items.map(item => (
    <motion.div
      key={item.id}
      variants={{
        hidden: { opacity: 0, y: 20 },
        show: { opacity: 1, y: 0 }
      }}
    />
  ))}
</motion.div>
```

### GSAP ScrollTrigger
```tsx
useGSAP(() => {
  gsap.from(el.current, {
    scrollTrigger: { trigger: el.current, start: "top 80%" },
    y: 50,
    opacity: 0,
    duration: 0.8,
    ease: "power2.out"
  })
})
```

### GSAP SplitText
```tsx
const split = new SplitText(el.current, { type: "chars,words" })
gsap.from(split.chars, {
  opacity: 0,
  y: 20,
  stagger: 0.03,
  duration: 0.5
})
```

### Reduced Motion
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

```tsx
// motion/react
const prefersReducedMotion = useReducedMotion()
<motion.div
  animate={prefersReducedMotion ? {} : { y: [0, -10, 0] }}
/>
```

## Anti-Patterns
- DON'T: Bounce easing on everything (strongest motion AI slop signal)
- DON'T: Animation duration > 800ms for UI transitions
- DON'T: Animate layout-triggering properties (width, height, top, left)
- DON'T: Auto-play animations that can't be paused (a11y violation)
- DON'T: More than 2-3 animated elements visible simultaneously
- DON'T: Use `will-change` on everything — it consumes GPU memory
- DON'T: Use `linear` easing for UI elements — looks robotic
- DO: Animate only `transform` and `opacity` for 60fps
- DO: Always honor `prefers-reduced-motion` media query
- DO: Use `Intersection Observer` to trigger animations only when visible
- DO: Pause off-screen Canvas/WebGL with Intersection Observer
- DO: Remove `will-change` after animation completes
