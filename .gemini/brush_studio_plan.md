# Brush Studio UI — Implementation Plan (Phase 4)

## Overview
A full-screen modal dialog inspired by Procreate's Brush Studio.
Three-column layout: **Attributes sidebar** | **Settings panel** | **Drawing Pad**

## Visual Design Reference
- Dark theme: `#1a1a1c` base, `#0d0d0f` deep panels
- Accent: uses app's `colorAccent` (default indigo `#6366f1`)
- Glassmorphism borders: `#2a2a2c` with 1px border
- Premium typography: 10px letter-spaced section headers
- Smooth animations: 200ms slide, OutCubic easing
- Rounded corners: 14-18px on panels, 8-10px on controls

## Architecture: 8 Incremental Steps

### Step 1: Shell & Layout (BrushStudioDialog.qml)
Create the main dialog skeleton:
- Full-screen overlay with dark dimmer background
- Three-column RowLayout (200px | flex | 400px)
- Top bar with: Cancel | Save As Copy Brush | Apply (blue)
- Brush preview thumbnail in top-left corner
- Open/close animations (scale + opacity)
**File:** `components/BrushStudioDialog.qml`

### Step 2: Attributes Sidebar (Left Column)
The 10 category tabs with icons and labels:
1. Path (〰️) — Stroke path settings
2. Shape (✦) — Tip shape source & behavior
3. Randomize (🎲) — Scatter, count, flip
4. Texture (▦) — Grain source & behavior
5. Visibility (◇) — Rendering mode, flow, edges
6. Water Mix (💧) — Wet mix engine params
7. Stylus Sensitivity (✏️) — Pressure/tilt curves
8. Color Dynamic (🎨) — Hue/sat/light jitter
9. Customize (⚙) — Properties & limits
10. Creation (ℹ) — About, author, reset
Each tab: hover highlight, active state with accent bar, smooth transition.

### Step 3: Settings Panel — Reusable Sub-Components
Create premium slider/toggle/section components:
- `StudioSlider` — Label + slider + numeric value (tappable for direct input)
- `StudioToggle` — Label + premium toggle switch
- `StudioSection` — Collapsible section with accent bar header
- `StudioPreviewBox` — Rounded dark box for shape/grain preview
These live inside BrushStudioDialog.qml as inline `component` declarations.

### Step 4: Settings Content — Path & Shape Tabs
- **Path tab:** Spacing, StreamLine, Jitter Lateral, Jitter Linear, Fall Off
- **Shape tab:** Shape Source preview box, Invert toggle, Contrast slider,
  Blur slider, Rotation slider

### Step 5: Settings Content — Texture & Visibility Tabs
- **Texture tab:** Grain Source preview, Scale, Depth, Depth Minimum,
  Movement toggle (Moving vs Texturized), Rotation, Offset Jitter
- **Visibility tab:** Rendering Mode selector, Flow, Wet Edges,
  Burnt Edges, Blend Mode dropdown

### Step 6: Settings Content — Water Mix & Stylus Tabs
- **Water Mix tab:** Dilution, Charge, Attack, Pull, Grade, Blur,
  Wetness Jitter
- **Stylus tab:** Pressure Size/Opacity/Flow/Edge Flow sliders,
  Tilt Size/Opacity/Flow/Edge Flow sliders

### Step 7: Settings Content — Color Dynamic, Customize, Creation
- **Color Dynamic:** Stamp Color Jitter (H/S/L/D), Stroke Color Jitter
- **Customize:** Max/Min Size, Max/Min Opacity, Preview Size, Smudge
- **Creation:** Brush Title (read-only), Author, Date, Reset buttons

### Step 8: Drawing Pad (Right Column)
- Dark canvas area with "Drawing Pad" header
- Pencil icon + settings gear in top-left
- Color picker circle + eraser toggle in top-right
- Clear button (3-finger scrub hint)
- Mini FBO or Canvas element for live brush preview drawing
- Drawing Pad Settings popup: Clear, Reset, Preview Size, Color circles

## Integration Points
- Open from: BrushLibrary long-press → "Edit Brush" menu item
- Open from: existing `showBrushSettings` button in toolbar
- Reads current brush via `mainCanvas.activeBrushName`
- Writes changes via `mainCanvas.usePreset()` on Apply
- Cancel reverts to original preset values

## Files to Create/Modify
1. **CREATE** `src/ui/qml/components/BrushStudioDialog.qml` — Main dialog
2. **MODIFY** `src/ui/qml/main_pro.qml` — Add dialog instance + trigger
3. **MODIFY** `src/ui/qml/components/BrushLibrary.qml` — Add "Edit" option
