# Canvas Modes Implementation Plan

## Overview
Two canvas modes that can be switched from Preferences:
1. **Essential Mode** (current, polished) — Procreate-style minimalist
2. **Studio Mode** — Clip Studio-style with dockable/tabbed panels

## Phase 1: Polish Essential Mode (Simple Canvas)
### Top Bar Improvements
- [x] Better spacing and premium glassmorphism
- [x] Cleaner navigation buttons
- [ ] Add brush name display in top bar
- [ ] Better undo/redo button styling

### Slider Toolbox
- [ ] More premium styling with better glass effect  
- [ ] Better handle design
- [ ] Smoother interactions

### Side Toolbar  
- [ ] Better active state indicator (accent line instead of full bg)
- [ ] Better spacing and grouping

## Phase 2: Studio Mode (Dockable Panels)
### Architecture
- [x] Use existing StudioPanelManager.qml as foundation (Created StudioCanvasLayout.qml)
- [x] Add `canvasMode` property to mainWindow ("essential" | "studio")  
- [x] Conditional rendering based on mode

### Panel Types
- [x] **Layers Panel** — dockable version of existing layers popover
- [x] **Color Panel** — dockable ColorStudioDialog
- [x] **Brush Library Panel** — dockable BrushLibrary (Placeholder UI)
- [x] **Brush Settings Panel** — dockable brush settings
- [x] **Navigator Panel** — dockable reference/navigator 
- [ ] **Swatch Panel** — color swatches

### Docking System
- [x] Left dock area, Right dock area, Bottom dock area  
- [ ] Drag & drop panel tabs to rearrange
- [x] Tab stacking (multiple panels share same dock area as tabs)
- [ ] Floating mode (undock to float freely)
- [ ] Layout persistence via JSON

### UI for Studio Mode
- [x] All panels visible by default when mode is "studio"
- [x] Tab headers for switching between stacked panels  
- [x] Resize handles between dock areas
- Menu bar shows Window menu for toggling panels
