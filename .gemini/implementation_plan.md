# ArtFlow Studio — Premium Brush Engine Overhaul

## Phase 1: Data-Driven Brush Architecture (Foundation)  ✅ COMPLETE
- [x] Create `BrushPreset` struct with full JSON schema support
- [x] Create `BrushPresetManager` singleton for loading/saving/managing presets  
- [x] Create default_brushes/ folder with JSON presets for all 22 current brushes
- [x] Migrate `usePreset()` from 340-line hardcoded if/else to JSON lookup
- [x] Support `BrushGroup` for organising presets (Sketching, Inking, etc.)
- [x] `ResponseCurve` with cubic Bezier evaluator + 256-entry LUT
- [x] `DynamicsProperty` with base value, min limit, and per-curve evaluation

## Phase 2: Enhanced GPU Rendering Pipeline  ✅ COMPLETE
- [x] Dual Texture Sampling shader (Shape Tip + Paper Grain)
  - `tipTexture` on GL_TEXTURE0 — local UV mapping (brush shape)
  - `grainTexture` on GL_TEXTURE1 — global canvas mapping (paper grain)
  - `canvasTexture` on GL_TEXTURE2 — ping-pong buffer (wet mix read-back)
- [x] Brush tip rotation support (`tipRotation` uniform)
- [x] Flow dynamics in shader (`flow * pressure` combination)
- [x] Wet Mix Engine in fragment shader:
  - Smudge: pulls canvas color into brush stroke
  - Wetness: blends brush + canvas colors with subtractive mixing
  - Dilution: thins opacity for watercolor transparency
  - Pigment pooling: darkens edges when wet
- [x] Anti-aliased `discard` for transparent fragments (perf optimization)
- [x] Updated `StrokeRenderer` with explicit grain/tip/wetmix parameter slots
- [x] Updated `BrushEngine` to load both textures independently + pass to shader
- [x] `BrushSettings` now supports `tipTextureName`, `tipTextureID`, `tipRotation`
- [x] `applyToLegacy()` properly routes tip → tipTextureName, grain → textureName

## Phase 3: Per-Preset Pressure Curve System  ✅ COMPLETE
- [x] `DynamicsProperty::evaluate()` method for quick pressure lookup
- [x] Per-preset pressure curves in `handleDraw()`:
  - SIZE dynamics through preset's ResponseCurve LUT
  - OPACITY dynamics with min limit gating
  - FLOW dynamics with min limit gating
  - VELOCITY dynamics with distance-based normalization
  - JITTER passthrough
- [x] Disables engine-level dynamics after applying preset-level dynamics
- [x] Falls back to global pressure curve for erasers

## Phase 4: Brush Settings UI (QML Modal)
- [ ] Create BrushStudioDialog.qml (full settings editor)
- [ ] 10 category sidebar (Path, Shape, Randomize, Texture, etc.)
- [ ] Real-time Testing Pad with dedicated mini-FBO
- [ ] Curve widget for pressure/tilt/speed
- [ ] Save/Apply/Cancel/SaveAsCopy flow
- [ ] Dual Brush support

## Phase 5: Scale to 150 Brushes
- [ ] Create JSON presets for all brush categories
- [ ] Texture Atlas system for brush tips
- [ ] Lazy loading + thumbnail caching for BrushLibrary.qml
- [ ] Import/Export .artbrush format (zip of JSON + textures)
