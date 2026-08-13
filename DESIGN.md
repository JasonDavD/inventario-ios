---
name: Precision Minimalist
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#45474a'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#76777b'
  outline-variant: '#c6c6ca'
  surface-tint: '#5d5e62'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1a1c1f'
  on-primary-container: '#838487'
  inverse-primary: '#c6c6ca'
  secondary: '#a33e00'
  on-secondary: '#ffffff'
  secondary-container: '#fd6c1a'
  on-secondary-container: '#581e00'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#201b15'
  on-tertiary-container: '#8b827b'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e2e2e6'
  primary-fixed-dim: '#c6c6ca'
  on-primary-fixed: '#1a1c1f'
  on-primary-fixed-variant: '#45474a'
  secondary-fixed: '#ffdbcd'
  secondary-fixed-dim: '#ffb596'
  on-secondary-fixed: '#360f00'
  on-secondary-fixed-variant: '#7c2e00'
  tertiary-fixed: '#ece0d8'
  tertiary-fixed-dim: '#cfc5bc'
  on-tertiary-fixed: '#201b15'
  on-tertiary-fixed-variant: '#4d453f'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
  charcoal-deep: '#121417'
  charcoal-muted: '#343A40'
  industrial-orange: '#E85D04'
  border-subtle: '#E9ECEF'
  surface-tonal: '#F1F3F5'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '600'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.01em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.05em
  label-md:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.08em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  space-xs: 8px
  space-sm: 16px
  space-md: 24px
  space-lg: 40px
  space-xl: 64px
  gutter: 20px
  margin-mobile: 20px
  margin-desktop: 48px
---

## Brand & Style
This design system shifts the "Industrial Precision" aesthetic toward a high-end, technical minimalism. It is designed for professional users who value efficiency, clarity, and a premium digital experience. The brand personality is disciplined, sophisticated, and focused, moving away from "heavy-duty" clunkiness toward "precision instrument" refinement.

The visual style is **Minimalism** with an **Industrial Modernist** core. It leverages expansive whitespace and a monochromatic charcoal-heavy palette to create a sense of focus. The "high-end tool" feel is achieved through impeccable alignment, generous breathing room, and the elimination of decorative elements like heavy borders or aggressive shadows. The emotional response is one of professional mastery and calm control.

## Colors
The palette is dominated by deep charcoals and clean whites to establish a premium, technical environment. 

- **Primary (Deep Charcoal):** Used for typography, primary icons, and structural elements. It provides a grounded, authoritative presence.
- **Secondary (Industrial Orange):** Retained from the original identity but used strictly as a high-intent accent for critical CTAs, status indicators, or "active" highlights.
- **Neutral:** A range of crisp, cool grays. Whitespace is used as a functional element to separate data-dense regions.
- **Tonal Accents:** Deep charcoals are used for containers in "Dark Mode" sections or high-contrast headers, ensuring a sophisticated industrial feel.

## Typography
The system uses **Inter** exclusively to maintain a clean, systematic appearance. Hierarchy is established through stark weight contrasts and generous letter spacing in smaller roles.

- **Headlines:** Use a Semi-Bold weight (`600`) instead of Bold to feel more modern and less "loud." Larger sizes feature tighter tracking for a locked-in, professional look.
- **Body:** Standard weight with increased tracking (`0.01em`) to improve legibility in technical specifications.
- **Labels:** Small labels use a semi-bold weight and significant tracking (`0.05em` to `0.08em`) to mimic the precision engraving found on high-end industrial tools. These should often be presented in sentence case or all-caps for technical metadata.

## Layout & Spacing
The layout follows a **Fluid Grid** system with a strict 4px/8px baseline rhythm. This ensures that even dense technical data feels organized and intentional.

- **Grid Model:** 12-column grid for desktop, 4-column for mobile.
- **Spacing Rhythm:** Use `space-md` (24px) as the default container padding to increase the sense of luxury and "high-end" minimalism.
- **Reflow:** On mobile, margins increase to 20px to prevent content from feeling cramped against the screen edges.
- **Vertical Rhythm:** Use `space-lg` (40px) between major sections to emphasize the minimalist aesthetic and allow the eye to rest.

## Elevation & Depth
Depth is communicated through **Tonal Layers** rather than shadows. This maintains the clean, flat aesthetic required for a minimalist industrial look.

- **Surface Tiers:** The base background is white (`#FFFFFF`). Secondary containers use a subtle tonal shift (`#F1F3F5`) to create separation.
- **Low-Contrast Outlines:** Instead of shadows, use 1px subtle borders (`#E9ECEF`) to define card boundaries and input fields.
- **Ghost Elevation:** For interactive elements, use a very soft, barely-perceptible ambient shadow (Blur 12px, Opacity 0.03) only when an element is "active" or "hovered."
- **Overlays:** Modals use a clean background blur (Backdrop Filter: 8px) with a semi-transparent charcoal overlay to maintain focus without adding visual clutter.

## Shapes
The shape language is **Rounded (0.5rem / 8px)**. This represents a "slight increase" from traditional industrial systems to provide a friendlier, modern software feel.

- **Standard Elements:** Buttons, inputs, and small cards use the base 8px radius.
- **Large Elements:** Large containers and promotional cards use `rounded-lg` (16px) to soften the layout.
- **Technical Elements:** Progress bars and tags may use the "Pill" (999px) shape to provide variety against the rectangular grid.

## Components
- **Buttons:**
    - **Primary:** Deep Charcoal background with white text. No shadow.
    - **Accent:** Industrial Orange, used only for the single most important action on a screen.
    - **Secondary:** Tonal Gray background with charcoal text; no border.
- **Input Fields:** Use a 1px `border-subtle` and a white background. On focus, the border transitions to `charcoal-deep` with no glow. Labels are always `label-lg` in `charcoal-muted`.
- **Cards:** Defined by tonal differences (`surface-tonal`) or 1px subtle outlines. Avoid drop shadows. Ensure internal padding is at least `space-md` (24px).
- **Chips:** Small, `rounded-lg` tags with a `surface-tonal` background and `label-md` typography. Used for status or technical categories.
- **Lists:** High-density lists use subtle 1px horizontal dividers. Eliminate vertical dividers to keep the layout open.
- **Data Tables:** Modern industrial spec tables should use `body-md` with `charcoal-muted` text for headers and `charcoal-deep` for values, ensuring maximum data legibility.