# 🎨 Brush Studio — Full Implementation Plan
## ArtFlow Studio — Advanced Brush Settings

> **Goal**: Build a fully functional, Procreate-level Brush Studio where every slider,
> toggle, and curve editor is connected to the C++ `BrushEngine` and produces
> real-time visual feedback in the Drawing Pad and brush shape preview.

---

## 📊 Current State Analysis

### ✅ What Already Exists
| Layer | Component | Status |
|-------|-----------|--------|
| **C++ Data Model** | `BrushPreset` struct | ✅ Has Shape, Grain, Stroke, Dynamics, WetMix, ColorDynamics, Customize |
| **C++ Engine** | `BrushEngine` + `BrushSettings` | ✅ Basic painting works (size, opacity, hardness, spacing, wetness, smudge) |
| **C++ Manager** | `BrushPresetManager` | ✅ Loads/saves JSON presets, `findByName()`, `applyToLegacy()` |
| **C++ Bridge** | `CanvasItem` Q_PROPERTYs | ✅ ~15 properties exposed (size, opacity, flow, hardness, spacing, stabilization, streamline, grain, wetness, smudge, etc.) |
| **JSON Presets** | `assets/brushes/*.json` | ✅ 6 category files with full schema |
| **QML UI** | `BrushStudioDialog.qml` | ⚠️ 10 tabs exist but most have placeholder/non-functional controls |
| **QML Drawing Pad** | Canvas element | ✅ Basic QML Canvas drawing (not using BrushEngine) |

### ❌ What's Missing
1. **~40+ new Q_PROPERTYs** in `CanvasItem` to expose all brush settings to QML
2. **Bidirectional binding**: QML sliders → C++ properties → BrushEngine → real-time preview
3. **Preset mutation**: Modify a preset in-memory, preview changes, then save/discard
4. **Curve editor widget**: Interactive Bézier curve for pressure/tilt/speed response
5. **Shape/Grain source picker**: Import images for brush tip and grain textures
6. **Real Drawing Pad**: Using actual `BrushEngine` instead of QML Canvas 2D
7. **Save As Copy / Apply / Cancel** logic with undo/reset points
8. **Dual Brush** system

---

## 🏗️ Architecture Design

### Data Flow
```
QML Slider → Q_PROPERTY setter → m_editingPreset (BrushPreset copy)
                                       ↓
                              BrushEngine.setBrush(settings)
                                       ↓
                              Drawing Pad re-renders preview
                                       ↓
                              Brush Shape thumbnail updates
```

### Key Design Decisions
1. **Editing Copy**: When Brush Studio opens, clone the active `BrushPreset` into
   `m_editingPreset`. All slider changes modify this copy. "Apply" commits it back;
   "Cancel" discards it.
2. **Proxy Properties**: Add a `Q_INVOKABLE` API like `setBrushStudioProperty(key, value)`
   rather than 40+ individual Q_PROPERTYs. This keeps the header clean.
3. **Drawing Pad**: Embed a second `CanvasItem` (mini-canvas) inside the dialog,
   OR use the existing QML Canvas but feed it computed stamp images from C++.
4. **Preset Persistence**: Modified presets save back to JSON files in `assets/brushes/`.

---

## 📋 Implementation Phases

---

### PHASE 1: Core Property Bridge (Priority: 🔴 Critical)
**Goal**: Expose all brush preset fields to QML via a generic property API.

#### Files to modify:
- `src/CanvasItem.h`
- `src/CanvasItem.cpp`
- `src/core/cpp/include/brush_preset.h`

#### Tasks:

**1.1 — Add editing preset state to CanvasItem**
```cpp
// CanvasItem.h — new private members
BrushPreset m_editingPreset;      // Working copy for Brush Studio
bool m_isEditingBrush = false;    // True when Brush Studio is open
BrushPreset m_resetPoint;         // For "Reset Brush" feature

// New Q_INVOKABLE methods
Q_INVOKABLE void beginBrushEdit(const QString &brushName);
Q_INVOKABLE void cancelBrushEdit();
Q_INVOKABLE void applyBrushEdit();
Q_INVOKABLE void saveAsCopyBrush(const QString &newName);
Q_INVOKABLE void createResetPoint();
Q_INVOKABLE void resetBrushToPoint();
```

**1.2 — Generic property getter/setter for Brush Studio**
```cpp
// Single entry point for ALL brush studio properties
Q_INVOKABLE QVariant getBrushProperty(const QString &category,
                                       const QString &key);
Q_INVOKABLE void setBrushProperty(const QString &category,
                                   const QString &key,
                                   const QVariant &value);
```

Category/key map (examples):
| Category | Key | Type | Maps to |
|----------|-----|------|---------|
| `stroke` | `spacing` | float | `m_editingPreset.stroke.spacing` |
| `stroke` | `streamline` | float | `m_editingPreset.stroke.streamline` |
| `stroke` | `taper_start` | float | `m_editingPreset.stroke.taperStart` |
| `stroke` | `taper_end` | float | `m_editingPreset.stroke.taperEnd` |
| `stroke` | `fall_off` | float | NEW field |
| `stroke` | `jitter` | float | `m_editingPreset.sizeDynamics.jitter` |
| `shape` | `roundness` | float | `m_editingPreset.shape.roundness` |
| `shape` | `rotation` | float | `m_editingPreset.shape.rotation` |
| `shape` | `scatter` | float | `m_editingPreset.shape.scatter` |
| `shape` | `follow_stroke` | bool | `m_editingPreset.shape.followStroke` |
| `shape` | `flip_x` | bool | `m_editingPreset.shape.flipX` |
| `shape` | `flip_y` | bool | `m_editingPreset.shape.flipY` |
| `shape` | `contrast` | float | `m_editingPreset.shape.contrast` |
| `shape` | `blur` | float | `m_editingPreset.shape.blur` |
| `grain` | `scale` | float | `m_editingPreset.grain.scale` |
| `grain` | `intensity` | float | `m_editingPreset.grain.intensity` |
| `grain` | `rotation` | float | `m_editingPreset.grain.rotation` |
| `grain` | `brightness` | float | `m_editingPreset.grain.brightness` |
| `grain` | `contrast` | float | `m_editingPreset.grain.contrast` |
| `grain` | `rolling` | bool | `m_editingPreset.grain.rolling` |
| `wetmix` | `wet_mix` | float | `m_editingPreset.wetMix.wetMix` |
| `wetmix` | `pigment` | float | `m_editingPreset.wetMix.pigment` |
| `wetmix` | `charge` | float | `m_editingPreset.wetMix.charge` |
| `wetmix` | `pull` | float | `m_editingPreset.wetMix.pull` |
| `wetmix` | `wetness` | float | `m_editingPreset.wetMix.wetness` |
| `wetmix` | `blur` | float | `m_editingPreset.wetMix.blur` |
| `wetmix` | `dilution` | float | `m_editingPreset.wetMix.dilution` |
| `color` | `hue_jitter` | float | `m_editingPreset.colorDynamics.hueJitter` |
| `color` | `saturation_jitter` | float | `m_editingPreset.colorDynamics.saturationJitter` |
| `color` | `brightness_jitter` | float | `m_editingPreset.colorDynamics.brightnessJitter` |
| `dynamics` | `size_base` | float | `m_editingPreset.sizeDynamics.baseValue` |
| `dynamics` | `size_min` | float | `m_editingPreset.sizeDynamics.minLimit` |
| `dynamics` | `opacity_base` | float | `m_editingPreset.opacityDynamics.baseValue` |
| `dynamics` | `opacity_min` | float | `m_editingPreset.opacityDynamics.minLimit` |
| `dynamics` | `flow_base` | float | `m_editingPreset.flowDynamics.baseValue` |
| `dynamics` | `flow_min` | float | `m_editingPreset.flowDynamics.minLimit` |
| `customize` | `min_size` | float | `m_editingPreset.minSize` |
| `customize` | `max_size` | float | `m_editingPreset.maxSize` |
| `customize` | `min_opacity` | float | `m_editingPreset.minOpacity` |
| `customize` | `max_opacity` | float | `m_editingPreset.maxOpacity` |
| `customize` | `smudge` | float | `m_editingPreset.wetMix.pull` |
| `meta` | `name` | string | `m_editingPreset.name` |
| `meta` | `author` | string | `m_editingPreset.author` |
| `meta` | `category` | string | `m_editingPreset.category` |

**1.3 — Live preview signal**
```cpp
signals:
    void brushPropertyChanged(const QString &category, const QString &key);
    void editingPresetChanged(); // Emitted after any property change
```

After each `setBrushProperty()`, immediately:
1. Update `m_editingPreset`
2. Call `applyToLegacy()` → `m_brushEngine->setBrush()`
3. Emit `editingPresetChanged()`
4. Call `update()` to trigger repaint

**Estimated effort**: ~4 hours

---

### PHASE 2: QML Bindings & Tab Content (Priority: 🔴 Critical)
**Goal**: Connect every QML slider/toggle in all 10 tabs to the C++ property bridge.

#### Files to modify:
- `src/ui/qml/components/BrushStudioDialog.qml`

#### Architecture Pattern for each slider:
```qml
StudioSlider {
    label: "Spacing"
    from: 0; to: 100; value: studio.getProperty("stroke", "spacing") * 100
    onValueChanged: {
        if (targetCanvas) {
            targetCanvas.setBrushProperty("stroke", "spacing", value / 100)
        }
    }
}
```

#### Tab-by-Tab Implementation:

**Tab 0: Path (Stroke Properties)**
| Control | Type | Category.Key | Range |
|---------|------|-------------|-------|
| Spacing | Slider | `stroke.spacing` | 0% – 100% |
| StreamLine | Slider | `stroke.streamline` | 0% – 100% |
| Jitter (Lateral) | Slider | `stroke.jitter_lateral` | 0% – 100% |
| Jitter (Linear) | Slider | `stroke.jitter_linear` | 0% – 100% |
| Fall Off | Slider | `stroke.fall_off` | 0% – 100% |
| Stabilizer | Slider | `stroke.stabilization` | 0% – 100% |
| Taper Start | Slider | `stroke.taper_start` | 0% – 100% |
| Taper End | Slider | `stroke.taper_end` | 0% – 100% |
| Taper Size | Slider | `stroke.taper_size` | 0% – 100% |
| Anti-Concussion | Toggle | `stroke.anti_concussion` | on/off |

**Tab 1: Shape**
| Control | Type | Category.Key | Range |
|---------|------|-------------|-------|
| Shape Source | Image Picker | `shape.tip_texture` | file path |
| Invert | Toggle | `shape.invert` | on/off |
| Contrast | Slider | `shape.contrast` | 0% – 200% |
| Blur | Slider | `shape.blur` | 0% – 100% |
| Rotation | Slider | `shape.rotation` | -180° – 180° |
| Roundness | Slider | `shape.roundness` | 0% – 100% |
| Scatter | Slider | `shape.scatter` | 0% – 100% |
| Follow Stroke | Toggle | `shape.follow_stroke` | on/off |
| Flip X | Toggle | `shape.flip_x` | on/off |
| Flip Y | Toggle | `shape.flip_y` | on/off |
| Randomize | Toggle | `shape.randomize` | on/off |

**Tab 2: Randomize**
| Control | Type | Category.Key | Range |
|---------|------|-------------|-------|
| Position Jitter X | Slider | `random.pos_jitter_x` | 0% – 100% |
| Position Jitter Y | Slider | `random.pos_jitter_y` | 0% – 100% |
| Rotation Jitter | Slider | `random.rotation_jitter` | 0% – 100% |
| Roundness Jitter | Slider | `random.roundness_jitter` | 0% – 100% |
| Size Jitter | Slider | `random.size_jitter` | 0% – 100% |
| Opacity Jitter | Slider | `random.opacity_jitter` | 0% – 100% |

**Tab 3: Texture (Grain)**
| Control | Type | Category.Key | Range |
|---------|------|-------------|-------|
| Texture Source | Image Picker | `grain.texture` | file path |
| Invert | Toggle | `grain.invert` | on/off |
| Contrast | Slider | `grain.contrast` | 0% – 200% |
| Brightness | Slider | `grain.brightness` | -100% – 100% |
| Scale | Slider | `grain.scale` | 10% – 500% |
| Rotation | Slider | `grain.rotation` | -180° – 180° |
| Overlap | Slider | `grain.overlap` | 0% – 100% |
| Depth | Slider | `grain.intensity` | 0% – 100% |
| Rolling/Moving | Toggle | `grain.rolling` | on/off |
| Blur | Slider | `grain.blur` | 0% – 100% |
| Motion Blur | Slider | `grain.motion_blur` | 0% – 100% |
| Random Offset | Toggle | `grain.random_offset` | on/off |
| Blend Mode | Dropdown | `grain.blend_mode` | normal/multiply/etc |

**Tab 4: Visibility (Rendering)**
| Control | Type | Category.Key | Range |
|---------|------|-------------|-------|
| Blend Mode | Dropdown | `rendering.blend_mode` | 6 modes |
| Flow | Slider | `rendering.flow` | 0% – 100% |
| Wet Edges | Slider | `rendering.wet_edges` | 0% – 100% |
| Burnt Edges | Slider | `rendering.burnt_edges` | 0% – 100% |
| Anti-Aliasing | Toggle | `rendering.anti_aliasing` | on/off |

**Tab 5: Water Mix**
| Control | Type | Category.Key | Range |
|---------|------|-------------|-------|
| Pigment | Slider | `wetmix.pigment` | 0% – 100% |
| Charge | Slider | `wetmix.charge` | 0% – 100% |
| Pull (Mixer Pull) | Slider | `wetmix.pull` | 0% – 100% |
| Blur | Slider | `wetmix.blur` | 0% – 100% |
| Wet | Toggle | `wetmix.wet_mix` | 0% – 100% |
| Wetness | Slider | `wetmix.wetness` | 0% – 100% |
| Dilution | Slider | `wetmix.dilution` | 0% – 100% |
| Wet Edges Jitter | Slider | `wetmix.wet_jitter` | 0% – 100% |

**Tab 6: Stylus Sensitivity**
| Control | Type | Category.Key | Range |
|---------|------|-------------|-------|
| Pressure → Size | Curve | `dynamics.size_pressure_curve` | Bézier |
| Pressure → Opacity | Curve | `dynamics.opacity_pressure_curve` | Bézier |
| Pressure → Flow | Curve | `dynamics.flow_pressure_curve` | Bézier |
| Tilt → Size | Slider | `dynamics.size_tilt` | 0% – 100% |
| Tilt → Opacity | Slider | `dynamics.opacity_tilt` | 0% – 100% |
| Tilt → Flow | Slider | `dynamics.flow_tilt` | 0% – 100% |
| Tilt → Roundness | Slider | `dynamics.roundness_tilt` | 0% – 100% |
| Speed → Size | Slider | `dynamics.size_speed` | -100% – 100% |
| Speed → Opacity | Slider | `dynamics.opacity_speed` | -100% – 100% |
| Speed → Flow | Slider | `dynamics.flow_speed` | -100% – 100% |

**Tab 7: Color Dynamics**
| Control | Type | Category.Key | Range |
|---------|------|-------------|-------|
| Stroke Hue Jitter | Slider | `color.stroke_hue_jitter` | 0% – 100% |
| Stroke Saturation Jitter | Slider | `color.stroke_sat_jitter` | 0% – 100% |
| Stroke Lightness Jitter | Slider | `color.stroke_light_jitter` | 0% – 100% |
| Stroke Darkness Jitter | Slider | `color.stroke_dark_jitter` | 0% – 100% |
| Stamp Hue Jitter | Slider | `color.stamp_hue_jitter` | 0% – 100% |
| Stamp Saturation Jitter | Slider | `color.stamp_sat_jitter` | 0% – 100% |
| Stamp Lightness Jitter | Slider | `color.stamp_light_jitter` | 0% – 100% |
| Stamp Darkness Jitter | Slider | `color.stamp_dark_jitter` | 0% – 100% |
| Pressure Hue Jitter | Slider | `color.pressure_hue_jitter` | 0% – 100% |
| Pressure Saturation Jitter | Slider | `color.pressure_sat_jitter` | 0% – 100% |
| Tilt Hue Jitter | Slider | `color.tilt_hue_jitter` | 0% – 100% |
| Secondary Color | Toggle | `color.secondary_color` | on/off |

**Tab 8: Customize (Properties)**
| Control | Type | Category.Key | Range |
|---------|------|-------------|-------|
| Min Size | Slider | `customize.min_size` | 1 – max_size |
| Max Size | Slider | `customize.max_size` | min_size – 1000 |
| Min Opacity | Slider | `customize.min_opacity` | 0% – max_opacity |
| Max Opacity | Slider | `customize.max_opacity` | min_opacity – 100% |
| Smudge | Slider | `customize.smudge` | 0% – 100% |
| Preview Size | Slider | `customize.preview_size` | 10% – 200% |
| Stamp Preview | Toggle | `customize.stamp_preview` | on/off |

**Tab 9: Creation (About)**
| Control | Type | Category.Key | Range |
|---------|------|-------------|-------|
| Brush Name | TextInput | `meta.name` | text |
| Author | TextInput | `meta.author` | text |
| Date Created | Label | `meta.date` | read-only |
| Category | Label | `meta.category` | read-only |
| Notes | TextArea | `meta.notes` | text |
| Copy Settings | Button | action | — |
| Paste Settings | Button | action | — |
| Export Brush | Button | action | — |
| Reset to Default | Button | action | — |

**Estimated effort**: ~6 hours

---

### PHASE 3: Extend BrushPreset Data Model (Priority: 🟡 High)
**Goal**: Add all missing fields to `BrushPreset` that the UI needs.

#### File: `src/core/cpp/include/brush_preset.h`

**3.1 — New fields in StrokeSettings:**
```cpp
struct StrokeSettings {
    // ... existing ...
    float jitterLateral = 0.0f;    // NEW
    float jitterLinear = 0.0f;     // NEW
    float fallOff = 0.0f;          // NEW
    float stabilization = 0.0f;    // NEW (separate from streamline)
    float taperSize = 0.0f;        // NEW
    float distance = 1.0f;         // NEW
};
```

**3.2 — New fields in ShapeSettings:**
```cpp
struct ShapeSettings {
    // ... existing ...
    bool invert = false;           // NEW
    bool randomize = false;        // NEW
    int count = 1;                 // NEW (stamp count)
    float countJitter = 0.0f;      // NEW
};
```

**3.3 — New struct: RandomizeSettings**
```cpp
struct RandomizeSettings {
    float posJitterX = 0.0f;
    float posJitterY = 0.0f;
    float rotationJitter = 0.0f;
    float roundnessJitter = 0.0f;
    float sizeJitter = 0.0f;
    float opacityJitter = 0.0f;
    QJsonObject toJson() const;
    static RandomizeSettings fromJson(const QJsonObject &obj);
} randomize;
```

**3.4 — Expand GrainSettings:**
```cpp
struct GrainSettings {
    // ... existing ...
    bool invert = false;           // NEW
    float overlap = 0.0f;          // NEW
    float blur = 0.0f;             // NEW
    float motionBlur = 0.0f;       // NEW
    float motionBlurAngle = 0.0f;  // NEW
    bool randomOffset = false;     // NEW
    QString blendMode = "normal";  // NEW
};
```

**3.5 — Expand WetMixSettings:**
```cpp
struct WetMixSettings {
    // ... existing ...
    float pressurePigment = 0.0f;  // NEW
    float pullPressure = 0.0f;     // NEW
    float wetJitter = 0.0f;        // NEW
};
```

**3.6 — Expand ColorDynamics:**
```cpp
struct ColorDynamics {
    // ... existing (hueJitter, saturationJitter, brightnessJitter) ...
    // Stroke-level
    float strokeHueJitter = 0.0f;
    float strokeSatJitter = 0.0f;
    float strokeLightJitter = 0.0f;
    float strokeDarkJitter = 0.0f;
    // Stamp-level
    float stampHueJitter = 0.0f;
    float stampSatJitter = 0.0f;
    float stampLightJitter = 0.0f;
    float stampDarkJitter = 0.0f;
    // Pressure-driven
    float pressureHueJitter = 0.0f;
    float pressureSatJitter = 0.0f;
    float pressureLightJitter = 0.0f;
    float pressureDarkJitter = 0.0f;
    // Tilt-driven
    float tiltHueJitter = 0.0f;
    float tiltSatJitter = 0.0f;
    float tiltLightJitter = 0.0f;
    float tiltDarkJitter = 0.0f;
    // Secondary color
    bool useSecondaryColor = false;
};
```

**3.7 — New MetaSettings:**
```cpp
struct MetaSettings {
    QString notes;
    QString dateCreated;
    QByteArray signatureImage;     // PNG data for author signature
    QByteArray authorPicture;      // PNG data
} meta;
```

**3.8 — Update `fromJson()` / `toJson()` for all new fields**

**3.9 — Update `applyToLegacy()` to map new fields to `BrushSettings`**

**Estimated effort**: ~3 hours

---

### PHASE 4: BrushEngine Enhancements (Priority: 🟡 High)
**Goal**: Make the engine actually use the new settings during rendering.

#### Files:
- `src/core/cpp/include/brush_engine.h`
- `src/core/cpp/src/brush_engine.cpp`
- `src/core/cpp/src/stroke_renderer.cpp`

#### Tasks:

**4.1 — Add new fields to BrushSettings:**
```cpp
struct BrushSettings {
    // ... existing ...
    // Randomize
    float posJitterX = 0.0f;
    float posJitterY = 0.0f;
    float rotationJitter = 0.0f;
    float roundnessJitter = 0.0f;
    float sizeJitter = 0.0f;
    float opacityJitter = 0.0f;
    // Taper
    float taperStart = 0.0f;
    float taperEnd = 0.0f;
    float fallOff = 0.0f;
    // Color Dynamics
    float hueJitter = 0.0f;
    float satJitter = 0.0f;
    float lightJitter = 0.0f;
    float darkJitter = 0.0f;
    // Shape
    float roundness = 1.0f;
    bool flipX = false;
    bool flipY = false;
};
```

**4.2 — Implement jitter in `paintStroke()`:**
- Position jitter: offset stamp position by random × jitterX/Y
- Size jitter: multiply stamp size by (1 + random × sizeJitter)
- Opacity jitter: multiply opacity by (1 - random × opacityJitter)
- Rotation jitter: add random × rotationJitter to stamp rotation
- Roundness jitter: scale Y axis of stamp

**4.3 — Implement taper:**
- Track stroke progress (distance from start / total distance)
- At start: scale size by lerp(taperStart, 1.0, progress)
- At end: scale size by lerp(1.0, taperEnd, progress)

**4.4 — Implement fall-off:**
- Track accumulated distance
- Reduce opacity by fallOff rate over distance

**4.5 — Implement color dynamics in stamp rendering:**
- Per-stamp: jitter H/S/L of brush color
- Per-stroke: apply stroke-level jitter once at beginStroke()

**4.6 — Implement roundness in stamp shape:**
- Scale the stamp elliptically based on roundness value

**Estimated effort**: ~6 hours

---

### PHASE 5: Real-Time Drawing Pad (Priority: 🟡 High)
**Goal**: Replace QML Canvas with actual BrushEngine rendering.

#### Option A: Offscreen QImage approach (Recommended)
1. Add `Q_INVOKABLE QVariant renderPreviewStroke(QVariantList points)` to CanvasItem
2. This renders a stroke on a small QImage using the current editing preset
3. Returns a `data:image/png;base64,...` URL
4. QML Image element displays it
5. On each mouse move in Drawing Pad, accumulate points and call this method

#### Option B: Embedded mini-CanvasItem
1. Create a `PreviewCanvasItem` subclass that shares the engine but paints to its own FBO
2. Embed in the dialog via QML

#### Recommended: Option A (simpler, no GL context issues)

**5.1 — Add preview rendering to CanvasItem:**
```cpp
Q_INVOKABLE void clearPreviewPad();
Q_INVOKABLE void previewPadStroke(float x, float y, float pressure);
Q_INVOKABLE void previewPadEndStroke();
Q_INVOKABLE QString getPreviewPadImage();  // Returns base64 PNG
```

**5.2 — Maintain an offscreen QImage for the preview pad**
```cpp
private:
    QImage m_previewPadImage;
    QPainter *m_previewPadPainter = nullptr;
```

**5.3 — QML integration:**
```qml
Image {
    id: padImage
    source: targetCanvas ? targetCanvas.getPreviewPadImage() : ""
    // Update on timer or after each stroke segment
}

MouseArea {
    onPressed: targetCanvas.previewPadStroke(mouse.x, mouse.y, 0.5)
    onPositionChanged: targetCanvas.previewPadStroke(mouse.x, mouse.y, 0.5)
    onReleased: { targetCanvas.previewPadEndStroke(); padImage.source = targetCanvas.getPreviewPadImage() }
}
```

**Estimated effort**: ~4 hours

---

### PHASE 6: Brush Shape Preview (Priority: 🟡 High)
**Goal**: Show the brush shape/stamp visually in the sidebar thumbnail.

**6.1 — Enhance `get_brush_preview()`**
- Currently generates a stroke preview image
- Add `Q_INVOKABLE QString getStampPreview()` that renders a single stamp
  of the current editing preset at preview size

**6.2 — Auto-update on property change**
```qml
Image {
    source: targetCanvas.getStampPreview()
    // Refresh when editing preset changes
    Connections {
        target: targetCanvas
        function onEditingPresetChanged() {
            brushShapeImg.source = ""  // force reload
            brushShapeImg.source = targetCanvas.getStampPreview()
        }
    }
}
```

**Estimated effort**: ~2 hours

---

### PHASE 7: Pressure Curve Editor Widget (Priority: 🟢 Medium)
**Goal**: Interactive Bézier curve for pressure/tilt/speed response.

**7.1 — Create `CurveEditor.qml` component**
```qml
// Interactive canvas with:
// - Grid background
// - Bezier curve drawn from P0(0,0) to P3(1,1)
// - Two draggable control point handles (P1, P2)
// - Real-time curve preview
// - Preset buttons: Linear, Ease In, Ease Out, Soft, Hard
```

**7.2 — Properties:**
```qml
property real cx1: 0.25
property real cy1: 0.1
property real cx2: 0.25
property real cy2: 1.0
signal curveChanged(real cx1, real cy1, real cx2, real cy2)
```

**7.3 — Integration with Stylus Sensitivity tab:**
- Each curve (Size, Opacity, Flow) gets its own CurveEditor
- Changes propagate to `setBrushProperty("dynamics", "size_curve", [cx1,cy1,cx2,cy2])`

**Estimated effort**: ~4 hours

---

### PHASE 8: Shape/Grain Source Picker (Priority: 🟢 Medium)
**Goal**: Let users import images for brush tip shape and grain texture.

**8.1 — Source Library component:**
- Grid of built-in shape/grain thumbnails from `assets/textures/` and `assets/brushes/`
- FileDialog for importing custom images

**8.2 — Image processing pipeline:**
```cpp
Q_INVOKABLE void importShapeSource(const QString &imagePath);
Q_INVOKABLE void importGrainSource(const QString &imagePath);
Q_INVOKABLE QStringList getAvailableShapes();
Q_INVOKABLE QStringList getAvailableGrains();
```

**8.3 — Convert imported images to grayscale brush tips**

**Estimated effort**: ~4 hours

---

### PHASE 9: Dual Brush System (Priority: 🔵 Low)
**Goal**: Support a secondary brush that blends with the primary.

**9.1 — Uncomment and implement DualBrush in BrushPreset:**
```cpp
struct DualBrushSettings {
    bool enabled = false;
    BrushPreset secondary;
    BlendMode blendMode = BlendMode::Normal;
};
```

**9.2 — UI: "+" button adds secondary brush preview below primary**

**9.3 — Engine: Render secondary brush to temp buffer, composite with primary**

**Estimated effort**: ~8 hours

---

### PHASE 10: Save/Export/Import System (Priority: 🟢 Medium)
**Goal**: Full brush persistence workflow.

**10.1 — Apply button:**
```cpp
void CanvasItem::applyBrushEdit() {
    auto *bpm = BrushPresetManager::instance();
    bpm->updatePreset(m_editingPreset);  // Save back to JSON
    usePreset(m_editingPreset.name);     // Apply to engine
    m_isEditingBrush = false;
}
```

**10.2 — Save As Copy:**
```cpp
void CanvasItem::saveAsCopyBrush(const QString &newName) {
    BrushPreset copy = m_editingPreset;
    copy.name = newName;
    copy.uuid = BrushPreset::generateUUID();
    auto *bpm = BrushPresetManager::instance();
    bpm->addPreset(copy);
}
```

**10.3 — Export as .brush file** (JSON + embedded textures in zip)

**10.4 — Import .brush file**

**10.5 — Reset to default:**
```cpp
void CanvasItem::resetBrushToPoint() {
    m_editingPreset = m_resetPoint;
    // re-apply and re-emit all signals
}
```

**Estimated effort**: ~3 hours

---

## 📅 Implementation Schedule

| Phase | Name | Priority | Effort | Dependencies |
|-------|------|----------|--------|-------------|
| **1** | Core Property Bridge | 🔴 Critical | 4h | None |
| **2** | QML Tab Bindings | 🔴 Critical | 6h | Phase 1 |
| **3** | Extend Data Model | 🟡 High | 3h | None (parallel with 1) |
| **4** | Engine Enhancements | 🟡 High | 6h | Phase 3 |
| **5** | Real Drawing Pad | 🟡 High | 4h | Phase 1, 4 |
| **6** | Shape Preview | 🟡 High | 2h | Phase 1 |
| **7** | Curve Editor | 🟢 Medium | 4h | Phase 2 |
| **8** | Source Picker | 🟢 Medium | 4h | Phase 3 |
| **9** | Dual Brush | 🔵 Low | 8h | Phase 4 |
| **10** | Save/Export | 🟢 Medium | 3h | Phase 1, 3 |

### Recommended Order:
```
Phase 1 + 3 (parallel) → Phase 2 → Phase 4 → Phase 5 + 6 (parallel)
→ Phase 7 → Phase 10 → Phase 8 → Phase 9
```

**Total estimated effort: ~44 hours**

---

## 🧪 Testing Strategy

1. **Unit tests for BrushPreset**: Serialize → Deserialize roundtrip
2. **Visual regression**: Screenshot comparison of brush strokes before/after
3. **Manual QA checklist per tab**: Each slider produces visible change in:
   - Drawing Pad preview
   - Brush shape thumbnail
   - Actual canvas painting
4. **Edge cases**: Min/max values, rapid slider changes, Cancel discards changes

---

## 📁 Files to Create/Modify Summary

### New Files:
- `src/ui/qml/components/CurveEditor.qml` — Pressure curve widget
- `src/ui/qml/components/SourceLibrary.qml` — Shape/Grain picker
- (Optional) `src/core/cpp/include/preview_renderer.h` — Offscreen preview

### Modified Files:
- `src/core/cpp/include/brush_preset.h` — Expand data model
- `src/core/cpp/include/brush_engine.h` — New BrushSettings fields
- `src/core/cpp/src/brush_engine.cpp` — Implement jitter, taper, color dynamics
- `src/core/cpp/src/brush_preset.cpp` — Serialize new fields
- `src/CanvasItem.h` — New Q_INVOKABLEs and preview pad state
- `src/CanvasItem.cpp` — Implement property bridge and preview
- `src/ui/qml/components/BrushStudioDialog.qml` — Connect all UI controls
- `src/ui/resources.qrc` — Register new QML files
