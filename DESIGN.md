---
name: Crisis Response System
colors:
  surface: '#f9f9fb'
  surface-dim: '#d9dadc'
  surface-bright: '#f9f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f5'
  surface-container: '#eeeef0'
  surface-container-high: '#e8e8ea'
  surface-container-highest: '#e2e2e4'
  on-surface: '#1a1c1d'
  on-surface-variant: '#5c3f3e'
  inverse-surface: '#2f3132'
  inverse-on-surface: '#f0f0f2'
  outline: '#916f6d'
  outline-variant: '#e6bdba'
  surface-tint: '#bf0023'
  primary: '#bd0022'
  on-primary: '#ffffff'
  primary-container: '#e32636'
  on-primary-container: '#fffeff'
  inverse-primary: '#ffb3af'
  secondary: '#4c56af'
  on-secondary: '#ffffff'
  secondary-container: '#959efd'
  on-secondary-container: '#27308a'
  tertiary: '#895000'
  on-tertiary: '#ffffff'
  tertiary-container: '#ac6500'
  on-tertiary-container: '#ffffff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad7'
  primary-fixed-dim: '#ffb3af'
  on-primary-fixed: '#410005'
  on-primary-fixed-variant: '#930018'
  secondary-fixed: '#e0e0ff'
  secondary-fixed-dim: '#bdc2ff'
  on-secondary-fixed: '#000767'
  on-secondary-fixed-variant: '#343d96'
  tertiary-fixed: '#ffdcbe'
  tertiary-fixed-dim: '#ffb870'
  on-tertiary-fixed: '#2c1600'
  on-tertiary-fixed-variant: '#693c00'
  background: '#f9f9fb'
  on-background: '#1a1c1d'
  surface-variant: '#e2e2e4'
typography:
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-bold:
    fontFamily: Work Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Work Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-padding: 20px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 40px
---

## Brand & Style
The design system is centered on the concepts of **Urgency, Reliability, and Accessibility**. Designed for emergency response in Nepal, the visual language must communicate immediate action while providing a sense of calm through structured clarity. 

The style is **Modern / Functional**, prioritizing high-contrast elements and large touch targets to ensure usability during high-stress situations. It balances a utilitarian "government-service" aesthetic with modern mobile patterns, ensuring that the critical "SOS" functionality remains the singular focus of the user experience.

## Colors
This design system employs a high-visibility palette optimized for critical information hierarchy. 

*   **Primary (#E32636):** Used exclusively for SOS actions, emergency alerts, and critical errors. This "Signal Red" ensures immediate recognition.
*   **Secondary (#1A237E):** A deep Navy used for branding, navigation headers, and primary buttons that are not emergency-related. It provides a grounded, authoritative contrast to the red.
*   **Tertiary/Accents:** Warm oranges and ambers are used for cautionary alerts or non-critical weather updates.
*   **Neutrals:** The background uses a soft off-white to reduce glare, while surface containers use pure white to pop against the background.

## Typography
We use **Plus Jakarta Sans** for its approachable yet professional geometric terminals, making it highly legible at various sizes. For technical metadata and small labels, **Work Sans** provides a more neutral, stable secondary typeface.

Headlines should be bold and direct. In emergency context screens, minimize the amount of text to allow the iconography and primary actions to lead the user.

## Layout & Spacing
The layout follows a **Fluid Grid** model with a heavy emphasis on vertical stacking for mobile-first accessibility. 

*   **Rhythm:** An 8px base grid governs all spacing.
*   **Margins:** 20px internal padding for main cards to ensure content doesn't feel cramped.
*   **Safe Areas:** Large bottom-safe areas for persistent navigation.
*   **Grid:** 2-column grids for service categories (Ambulance, Fire) on mobile to maximize touch target size, expanding to 4 or 6 columns on tablets/desktop.

## Elevation & Depth
Hierarchy is established using **Tonal Layers** supplemented by subtle **Ambient Shadows**.

*   **Level 0 (Background):** Neutral light grey (#F5F5F7).
*   **Level 1 (Cards/Surfaces):** White (#FFFFFF) with a soft, diffused shadow (0px 4px 20px rgba(0,0,0,0.05)) to create separation without visual noise.
*   **Level 2 (Active States/SOS):** High-contrast primary colors with a more pronounced shadow to indicate "pressable" depth.
*   **Glassmorphism:** Reserved only for floating location chips or weather overlays to maintain focus on the map or background imagery beneath.

## Shapes
The design system uses a **Rounded** corner strategy to appear modern and reassuring.

*   **Standard Cards:** 1rem (16px) corner radius.
*   **SOS Button:** Perfectly circular (Pill-shaped) to distinguish it as the most important action.
*   **Input Fields:** 0.5rem (8px) for a more structured, functional look.

## Components
Consistent implementation of components is vital for speed of use.

*   **SOS Button:** A large, central circular button with a white border. It includes a pulsate animation when active. 
*   **Service Cards:** White background, centered icon (within a colored circular badge), bold title, and 2-line description. High touch-target area (minimum 100px height).
*   **Iconography:** Glyph-style icons within soft-colored circles. Use medical reds for Ambulance, orange for Fire, and blue for Police.
*   **Navigation:** A clean bottom tab bar with labels. The "AI Assistant" or "SOS" center icon should be elevated or styled uniquely to indicate priority.
*   **Alert Banners:** Top-aligned, high-contrast bars for immediate disaster notifications.