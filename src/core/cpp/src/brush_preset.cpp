#include "../include/brush_preset.h"
#include "../include/brush_engine.h"
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUuid>

namespace artflow {

// ============================================================
// ShapeSettings
// ============================================================
QJsonObject BrushPreset::ShapeSettings::toJson() const {
  QJsonObject obj;
  if (!tipTexture.isEmpty())
    obj["tip_texture"] = tipTexture;
  obj["rotation"] = rotation;
  obj["follow_stroke"] = followStroke;
  obj["scatter"] = scatter;
  obj["roundness"] = roundness;
  obj["flip_x"] = flipX;
  obj["flip_y"] = flipY;
  obj["contrast"] = contrast;
  obj["blur"] = blur;
  obj["invert"] = invert;
  obj["randomize"] = randomize;
  obj["count"] = count;
  obj["count_jitter"] = countJitter;
  obj["calligraphic"] = calligraphic;
  return obj;
}

BrushPreset::ShapeSettings
BrushPreset::ShapeSettings::fromJson(const QJsonObject &obj) {
  ShapeSettings s;
  s.tipTexture = obj.value("tip_texture").toString();
  s.rotation = obj.value("rotation").toDouble(0.0);
  s.followStroke = obj.value("follow_stroke").toBool(false);
  s.scatter = obj.value("scatter").toDouble(0.0);
  s.roundness = obj.value("roundness").toDouble(1.0);
  s.flipX = obj.value("flip_x").toBool(false);
  s.flipY = obj.value("flip_y").toBool(false);
  s.contrast = obj.value("contrast").toDouble(1.0);
  s.blur = obj.value("blur").toDouble(0.0);
  s.invert = obj.value("invert").toBool(false);
  s.randomize = obj.value("randomize").toBool(false);
  s.count = obj.value("count").toInt(1);
  s.countJitter = obj.value("count_jitter").toDouble(0.0);
  s.calligraphic = obj.value("calligraphic").toDouble(0.0);
  return s;
}

// ============================================================
// RandomizeSettings
// ============================================================
QJsonObject BrushPreset::RandomizeSettings::toJson() const {
  QJsonObject obj;
  obj["pos_jitter_x"] = posJitterX;
  obj["pos_jitter_y"] = posJitterY;
  obj["rotation_jitter"] = rotationJitter;
  obj["roundness_jitter"] = roundnessJitter;
  obj["size_jitter"] = sizeJitter;
  obj["opacity_jitter"] = opacityJitter;
  return obj;
}

BrushPreset::RandomizeSettings
BrushPreset::RandomizeSettings::fromJson(const QJsonObject &obj) {
  RandomizeSettings r;
  r.posJitterX = obj.value("pos_jitter_x").toDouble(0.0);
  r.posJitterY = obj.value("pos_jitter_y").toDouble(0.0);
  r.rotationJitter = obj.value("rotation_jitter").toDouble(0.0);
  r.roundnessJitter = obj.value("roundness_jitter").toDouble(0.0);
  r.sizeJitter = obj.value("size_jitter").toDouble(0.0);
  r.opacityJitter = obj.value("opacity_jitter").toDouble(0.0);
  return r;
}

// ============================================================
// GrainSettings
// ============================================================
QJsonObject BrushPreset::GrainSettings::toJson() const {
  QJsonObject obj;
  if (!texture.isEmpty())
    obj["texture"] = texture;
  obj["scale"] = scale;
  obj["intensity"] = intensity;
  obj["rotation"] = rotation;
  obj["brightness"] = brightness;
  obj["contrast"] = contrast;
  obj["rolling"] = rolling;
  obj["invert"] = invert;
  obj["overlap"] = overlap;
  obj["blur"] = blur;
  obj["motion_blur"] = motionBlur;
  obj["motion_blur_angle"] = motionBlurAngle;
  obj["random_offset"] = randomOffset;
  obj["blend_mode"] = blendMode;
  return obj;
}

BrushPreset::GrainSettings
BrushPreset::GrainSettings::fromJson(const QJsonObject &obj) {
  GrainSettings g;
  g.texture = obj.value("texture").toString();
  g.scale = obj.value("scale").toDouble(1.0);
  g.intensity = obj.value("intensity").toDouble(0.5);
  g.rotation = obj.value("rotation").toDouble(0.0);
  g.brightness = obj.value("brightness").toDouble(0.0);
  g.contrast = obj.value("contrast").toDouble(1.0);
  g.rolling = obj.value("rolling").toBool(true);
  g.invert = obj.value("invert").toBool(false);
  g.overlap = obj.value("overlap").toDouble(0.0);
  g.blur = obj.value("blur").toDouble(0.0);
  g.motionBlur = obj.value("motion_blur").toDouble(0.0);
  g.motionBlurAngle = obj.value("motion_blur_angle").toDouble(0.0);
  g.randomOffset = obj.value("random_offset").toBool(false);
  g.blendMode = obj.value("blend_mode").toString("normal");
  return g;
}

// ============================================================
// StrokeSettings
// ============================================================
QJsonObject BrushPreset::StrokeSettings::toJson() const {
  QJsonObject obj;
  obj["spacing"] = spacing;
  obj["streamline"] = streamline;
  obj["taper_start"] = taperStart;
  obj["taper_end"] = taperEnd;
  obj["anti_concussion"] = antiConcussion;
  obj["jitter_lateral"] = jitterLateral;
  obj["jitter_linear"] = jitterLinear;
  obj["fall_off"] = fallOff;
  obj["stabilization"] = stabilization;
  obj["taper_size"] = taperSize;
  obj["distance"] = distance;
  return obj;
}

BrushPreset::StrokeSettings
BrushPreset::StrokeSettings::fromJson(const QJsonObject &obj) {
  StrokeSettings s;
  s.spacing = obj.value("spacing").toDouble(0.1);
  s.streamline = obj.value("streamline").toDouble(0.0);
  s.taperStart = obj.value("taper_start").toDouble(0.0);
  s.taperEnd = obj.value("taper_end").toDouble(0.0);
  s.antiConcussion = obj.value("anti_concussion").toBool(false);
  s.jitterLateral = obj.value("jitter_lateral").toDouble(0.0);
  s.jitterLinear = obj.value("jitter_linear").toDouble(0.0);
  s.fallOff = obj.value("fall_off").toDouble(0.0);
  s.stabilization = obj.value("stabilization").toDouble(0.0);
  s.taperSize = obj.value("taper_size").toDouble(0.0);
  s.distance = obj.value("distance").toDouble(1.0);
  return s;
}

// ============================================================
// WetMixSettings
// ============================================================
QJsonObject BrushPreset::WetMixSettings::toJson() const {
  QJsonObject obj;
  obj["wet_mix"] = wetMix;
  obj["pigment"] = pigment;
  obj["charge"] = charge;
  obj["pull"] = pull;
  obj["wetness"] = wetness;
  obj["blur"] = blur;
  obj["dilution"] = dilution;
  obj["pressure_pigment"] = pressurePigment;
  obj["pull_pressure"] = pullPressure;
  obj["wet_jitter"] = wetJitter;

  // New fields
  obj["bleed"] = bleed;
  obj["absorption_rate"] = absorptionRate;
  obj["drying_time"] = dryingTime;
  obj["wet_on_wet_multiplier"] = wetOnWetMultiplier;

  // Oil Paint
  obj["mixing"] = mixing;
  obj["loading"] = loading;
  obj["depletion_rate"] = depletionRate;
  obj["dirty_mixing"] = dirtyMixing;
  obj["color_pickup"] = colorPickup;
  obj["blend_only"] = blendOnly;
  obj["scrape_through"] = scrapeThrough;

  return obj;
}

BrushPreset::WetMixSettings
BrushPreset::WetMixSettings::fromJson(const QJsonObject &obj) {
  WetMixSettings w;
  w.wetMix = obj.value("wet_mix").toDouble(0.0);
  w.pigment = obj.value("pigment").toDouble(1.0);
  w.charge = obj.value("charge").toDouble(1.0);
  w.pull = obj.value("pull").toDouble(0.0);
  w.wetness = obj.value("wetness").toDouble(0.0);
  w.blur = obj.value("blur").toDouble(0.0);
  w.dilution = obj.value("dilution").toDouble(0.0);
  w.pressurePigment = obj.value("pressure_pigment").toDouble(0.0);
  w.pullPressure = obj.value("pull_pressure").toDouble(0.0);
  w.wetJitter = obj.value("wet_jitter").toDouble(0.0);

  // New fields
  w.bleed = obj.value("bleed").toDouble(0.0);
  w.absorptionRate = obj.value("absorption_rate").toDouble(0.0);
  w.dryingTime = obj.value("drying_time").toDouble(0.0);
  w.wetOnWetMultiplier = obj.value("wet_on_wet_multiplier").toDouble(1.0);

  // Oil Paint
  w.mixing = obj.value("mixing").toDouble(0.5);
  w.loading = obj.value("loading").toDouble(1.0);
  w.depletionRate = obj.value("depletion_rate").toDouble(0.0);
  w.dirtyMixing = obj.value("dirty_mixing").toBool(false);
  w.colorPickup = obj.value("color_pickup").toDouble(0.0);
  w.blendOnly = obj.value("blend_only").toBool(false);
  w.scrapeThrough = obj.value("scrape_through").toBool(false);

  return w;
}

// ============================================================
// ImpastoSettings
// ============================================================
QJsonObject BrushPreset::ImpastoSettings::toJson() const {
  QJsonObject obj;
  obj["enabled"] = enabled;
  obj["depth"] = depth;
  obj["shine"] = shine;
  obj["texture_strength"] = textureStrength;
  obj["edge_buildup"] = edgeBuildup;
  obj["directional_ridges"] = directionalRidges;
  obj["smoothing"] = smoothing;
  obj["preserve_existing"] = preserveExisting;
  return obj;
}

BrushPreset::ImpastoSettings
BrushPreset::ImpastoSettings::fromJson(const QJsonObject &obj) {
  ImpastoSettings i;
  i.enabled = obj.value("enabled").toBool(false);
  i.depth = obj.value("depth").toDouble(0.0);
  i.shine = obj.value("shine").toDouble(0.0);
  i.textureStrength = obj.value("texture_strength").toDouble(0.0);
  i.edgeBuildup = obj.value("edge_buildup").toDouble(0.0);
  i.directionalRidges = obj.value("directional_ridges").toBool(false);
  i.smoothing = obj.value("smoothing").toDouble(0.0);
  i.preserveExisting = obj.value("preserve_existing").toBool(false);
  return i;
}

// ============================================================
// BristleSettings
// ============================================================
QJsonObject BrushPreset::BristleSettings::toJson() const {
  QJsonObject obj;
  obj["enabled"] = enabled;
  obj["count"] = count;
  obj["stiffness"] = stiffness;
  obj["clumping"] = clumping;
  obj["fan_spread"] = fanSpread;
  obj["individual_variation"] = individualVariation;
  obj["dry_brush_effect"] = dryBrushEffect;
  obj["softness"] = softness;
  obj["point_taper"] = pointTaper;
  return obj;
}

BrushPreset::BristleSettings
BrushPreset::BristleSettings::fromJson(const QJsonObject &obj) {
  BristleSettings b;
  b.enabled = obj.value("enabled").toBool(false);
  b.count = obj.value("count").toInt(1);
  b.stiffness = obj.value("stiffness").toDouble(0.5);
  b.clumping = obj.value("clumping").toDouble(0.0);
  b.fanSpread = obj.value("fan_spread").toDouble(0.0);
  b.individualVariation = obj.value("individual_variation").toDouble(0.0);
  b.dryBrushEffect = obj.value("dry_brush_effect").toBool(false);
  b.softness = obj.value("softness").toDouble(0.0);
  b.pointTaper = obj.value("point_taper").toDouble(0.0);
  return b;
}

// ============================================================
// SmudgeSettings
// ============================================================
QJsonObject BrushPreset::SmudgeSettings::toJson() const {
  QJsonObject obj;
  obj["strength"] = strength;
  obj["blend_mode"] = blendMode;
  obj["pressure_influence"] = pressureInfluence;
  obj["length"] = length;
  obj["gaussian_blur"] = gaussianBlur;
  obj["smear"] = smear;
  return obj;
}

BrushPreset::SmudgeSettings
BrushPreset::SmudgeSettings::fromJson(const QJsonObject &obj) {
  SmudgeSettings s;
  s.strength = obj.value("strength").toDouble(0.0);
  s.blendMode = obj.value("blend_mode").toString("normal");
  s.pressureInfluence = obj.value("pressure_influence").toDouble(0.0);
  s.length = obj.value("length").toDouble(0.0);
  s.gaussianBlur = obj.value("gaussian_blur").toDouble(0.0);
  s.smear = obj.value("smear").toBool(false);
  return s;
}

// ============================================================
// CanvasInteractionSettings
// ============================================================
QJsonObject BrushPreset::CanvasInteractionSettings::toJson() const {
  QJsonObject obj;
  obj["texture_reveal"] = textureReveal;
  obj["absorption"] = absorption;
  obj["skip_valleys"] = skipValleys;
  obj["catch_peaks"] = catchPeaks;
  return obj;
}

BrushPreset::CanvasInteractionSettings
BrushPreset::CanvasInteractionSettings::fromJson(const QJsonObject &obj) {
  CanvasInteractionSettings c;
  c.textureReveal = obj.value("texture_reveal").toDouble(0.0);
  c.absorption = obj.value("absorption").toDouble(0.0);
  c.skipValleys = obj.value("skip_valleys").toBool(false);
  c.catchPeaks = obj.value("catch_peaks").toDouble(0.0);
  return c;
}

// ============================================================
// PigmentSettings
// ============================================================
QJsonObject BrushPreset::PigmentSettings::toJson() const {
  QJsonObject obj;
  obj["granulation"] = granulation;
  obj["flow"] = flow;
  obj["staining"] = staining;
  obj["separation"] = separation;
  return obj;
}

BrushPreset::PigmentSettings
BrushPreset::PigmentSettings::fromJson(const QJsonObject &obj) {
  PigmentSettings p;
  p.granulation = obj.value("granulation").toDouble(0.0);
  p.flow = obj.value("flow").toDouble(1.0);
  p.staining = obj.value("staining").toDouble(0.0);
  p.separation = obj.value("separation").toDouble(0.0);
  return p;
}

// ============================================================
// BloomSettings
// ============================================================
QJsonObject BrushPreset::BloomSettings::toJson() const {
  QJsonObject obj;
  obj["enabled"] = enabled;
  obj["intensity"] = intensity;
  obj["radius"] = radius;
  obj["threshold"] = threshold;
  obj["random_variation"] = randomVariation;
  return obj;
}

BrushPreset::BloomSettings
BrushPreset::BloomSettings::fromJson(const QJsonObject &obj) {
  BloomSettings b;
  b.enabled = obj.value("enabled").toBool(false);
  b.intensity = obj.value("intensity").toDouble(0.0);
  b.radius = obj.value("radius").toDouble(0.0);
  b.threshold = obj.value("threshold").toDouble(0.0);
  b.randomVariation = obj.value("random_variation").toDouble(0.0);
  return b;
}

// ============================================================
// EdgeDarkeningSettings
// ============================================================
QJsonObject BrushPreset::EdgeDarkeningSettings::toJson() const {
  QJsonObject obj;
  obj["enabled"] = enabled;
  obj["intensity"] = intensity;
  obj["width"] = width;
  return obj;
}

BrushPreset::EdgeDarkeningSettings
BrushPreset::EdgeDarkeningSettings::fromJson(const QJsonObject &obj) {
  EdgeDarkeningSettings e;
  e.enabled = obj.value("enabled").toBool(false);
  e.intensity = obj.value("intensity").toDouble(0.0);
  e.width = obj.value("width").toDouble(0.0);
  return e;
}

// ============================================================
// BackrunSettings
// ============================================================
QJsonObject BrushPreset::BackrunSettings::toJson() const {
  QJsonObject obj;
  obj["enabled"] = enabled;
  obj["probability"] = probability;
  obj["intensity"] = intensity;
  return obj;
}

BrushPreset::BackrunSettings
BrushPreset::BackrunSettings::fromJson(const QJsonObject &obj) {
  BackrunSettings b;
  b.enabled = obj.value("enabled").toBool(false);
  b.probability = obj.value("probability").toDouble(0.0);
  b.intensity = obj.value("intensity").toDouble(0.0);
  return b;
}

// ============================================================
// TextureRevealSettings
// ============================================================
QJsonObject BrushPreset::TextureRevealSettings::toJson() const {
  QJsonObject obj;
  obj["enabled"] = enabled;
  obj["intensity"] = intensity;
  obj["pressure_influence"] = pressureInfluence;
  return obj;
}

BrushPreset::TextureRevealSettings
BrushPreset::TextureRevealSettings::fromJson(const QJsonObject &obj) {
  TextureRevealSettings t;
  t.enabled = obj.value("enabled").toBool(false);
  t.intensity = obj.value("intensity").toDouble(0.0);
  t.pressureInfluence = obj.value("pressure_influence").toDouble(0.0);
  return t;
}

// ============================================================
// ColorDynamics
// ============================================================
QJsonObject BrushPreset::ColorDynamics::toJson() const {
  QJsonObject obj;
  obj["hue_jitter"] = hueJitter;
  obj["saturation_jitter"] = saturationJitter;
  obj["brightness_jitter"] = brightnessJitter;
  obj["stroke_hue_jitter"] = strokeHueJitter;
  obj["stroke_sat_jitter"] = strokeSatJitter;
  obj["stroke_light_jitter"] = strokeLightJitter;
  obj["stroke_dark_jitter"] = strokeDarkJitter;
  obj["stamp_hue_jitter"] = stampHueJitter;
  obj["stamp_sat_jitter"] = stampSatJitter;
  obj["stamp_light_jitter"] = stampLightJitter;
  obj["stamp_dark_jitter"] = stampDarkJitter;
  obj["pressure_hue_jitter"] = pressureHueJitter;
  obj["pressure_sat_jitter"] = pressureSatJitter;
  obj["pressure_light_jitter"] = pressureLightJitter;
  obj["pressure_dark_jitter"] = pressureDarkJitter;
  obj["tilt_hue_jitter"] = tiltHueJitter;
  obj["tilt_sat_jitter"] = tiltSatJitter;
  obj["tilt_light_jitter"] = tiltLightJitter;
  obj["tilt_dark_jitter"] = tiltDarkJitter;
  obj["use_secondary_color"] = useSecondaryColor;

  // Oil
  obj["temperature_shift"] = temperatureShift;
  obj["broken_color"] = brokenColor;

  return obj;
}

BrushPreset::ColorDynamics
BrushPreset::ColorDynamics::fromJson(const QJsonObject &obj) {
  ColorDynamics cd;
  cd.hueJitter = obj.value("hue_jitter").toDouble(0.0);
  cd.saturationJitter = obj.value("saturation_jitter").toDouble(0.0);
  cd.brightnessJitter = obj.value("brightness_jitter").toDouble(0.0);
  cd.strokeHueJitter = obj.value("stroke_hue_jitter").toDouble(0.0);
  cd.strokeSatJitter = obj.value("stroke_sat_jitter").toDouble(0.0);
  cd.strokeLightJitter = obj.value("stroke_light_jitter").toDouble(0.0);
  cd.strokeDarkJitter = obj.value("stroke_dark_jitter").toDouble(0.0);
  cd.stampHueJitter = obj.value("stamp_hue_jitter").toDouble(0.0);
  cd.stampSatJitter = obj.value("stamp_sat_jitter").toDouble(0.0);
  cd.stampLightJitter = obj.value("stamp_light_jitter").toDouble(0.0);
  cd.stampDarkJitter = obj.value("stamp_dark_jitter").toDouble(0.0);
  cd.pressureHueJitter = obj.value("pressure_hue_jitter").toDouble(0.0);
  cd.pressureSatJitter = obj.value("pressure_sat_jitter").toDouble(0.0);
  cd.pressureLightJitter = obj.value("pressure_light_jitter").toDouble(0.0);
  cd.pressureDarkJitter = obj.value("pressure_dark_jitter").toDouble(0.0);
  cd.tiltHueJitter = obj.value("tilt_hue_jitter").toDouble(0.0);
  cd.tiltSatJitter = obj.value("tilt_sat_jitter").toDouble(0.0);
  cd.tiltLightJitter = obj.value("tilt_light_jitter").toDouble(0.0);
  cd.tiltDarkJitter = obj.value("tilt_dark_jitter").toDouble(0.0);
  cd.useSecondaryColor = obj.value("use_secondary_color").toBool(false);

  // Oil
  cd.temperatureShift = obj.value("temperature_shift").toDouble(0.0);
  cd.brokenColor = obj.value("broken_color").toDouble(0.0);

  return cd;
}

// ============================================================
// MetaSettings
// ============================================================
QJsonObject BrushPreset::MetaSettings::toJson() const {
  QJsonObject obj;
  obj["notes"] = notes;
  obj["date_created"] = dateCreated;
  if (!signatureImage.isEmpty())
    obj["signature_image"] = signatureImage;
  if (!authorPicture.isEmpty())
    obj["author_picture"] = authorPicture;
  return obj;
}

BrushPreset::MetaSettings
BrushPreset::MetaSettings::fromJson(const QJsonObject &obj) {
  MetaSettings m;
  m.notes = obj.value("notes").toString();
  m.dateCreated = obj.value("date_created").toString();
  m.signatureImage = obj.value("signature_image").toString();
  m.authorPicture = obj.value("author_picture").toString();
  return m;
}

// ============================================================
// BrushPreset — main serialization
// ============================================================

static QString blendModeToString(BrushPreset::BlendMode m) {
  switch (m) {
  case BrushPreset::BlendMode::Normal:
    return "normal";
  case BrushPreset::BlendMode::Multiply:
    return "multiply";
  case BrushPreset::BlendMode::Screen:
    return "screen";
  case BrushPreset::BlendMode::Overlay:
    return "overlay";
  case BrushPreset::BlendMode::Darken:
    return "darken";
  case BrushPreset::BlendMode::Lighten:
    return "lighten";
  }
  return "normal";
}

static BrushPreset::BlendMode blendModeFromString(const QString &s) {
  if (s == "multiply")
    return BrushPreset::BlendMode::Multiply;
  if (s == "screen")
    return BrushPreset::BlendMode::Screen;
  if (s == "overlay")
    return BrushPreset::BlendMode::Overlay;
  if (s == "darken")
    return BrushPreset::BlendMode::Darken;
  if (s == "lighten")
    return BrushPreset::BlendMode::Lighten;
  return BrushPreset::BlendMode::Normal;
}

QJsonObject BrushPreset::toJson() const {
  QJsonObject root;

  // Meta (merged with MetaSettings)
  QJsonObject meta = metaData.toJson();
  meta["uuid"] = uuid;
  meta["name"] = name;
  meta["category"] = category;
  meta["author"] = author;
  meta["version"] = version;
  root["meta"] = meta;

  // Rendering
  QJsonObject rendering;
  rendering["blend_mode"] = blendModeToString(blendMode);
  rendering["anti_aliasing"] = antiAliasing;
  root["rendering"] = rendering;

  // Shape
  root["shape"] = shape.toJson();

  // Randomize
  root["randomize"] = randomize.toJson();

  // Grain
  root["grain"] = grain.toJson();

  // Stroke
  root["stroke"] = stroke.toJson();

  // Dynamics
  QJsonObject dynamics;
  dynamics["size"] = sizeDynamics.toJson();
  dynamics["opacity"] = opacityDynamics.toJson();
  dynamics["flow"] = flowDynamics.toJson();
  dynamics["hardness"] = hardnessDynamics.toJson();
  root["dynamics"] = dynamics;

  // Wet Mix
  root["wet_mix"] = wetMix.toJson();

  // Watercolor specific
  root["pigment"] = pigment.toJson();
  root["bloom"] = bloom.toJson();
  root["edge_darkening"] = edgeDarkening.toJson();
  root["backrun"] = backrun.toJson();
  root["texture_reveal"] = textureReveal.toJson();

  // Oil Specific
  root["impasto"] = impasto.toJson();
  root["bristles"] = bristles.toJson();
  root["smudge"] = smudge.toJson();
  root["canvas_interaction"] = canvasInteraction.toJson();

  // Color Dynamics
  root["color_dynamics"] = colorDynamics.toJson();

  // Customize
  QJsonObject customize;
  customize["min_size"] = minSize;
  customize["max_size"] = maxSize;
  customize["default_size"] = defaultSize;
  customize["min_opacity"] = minOpacity;
  customize["max_opacity"] = maxOpacity;
  customize["default_opacity"] = defaultOpacity;
  customize["default_hardness"] = defaultHardness;
  customize["default_flow"] = defaultFlow;
  root["customize"] = customize;

  return root;
}

BrushPreset BrushPreset::fromJson(const QJsonObject &root) {
  BrushPreset preset;

  // Meta
  QJsonObject meta = root["meta"].toObject();
  preset.metaData = MetaSettings::fromJson(meta);
  preset.uuid = meta.value("uuid").toString();
  preset.name = meta.value("name").toString("Unnamed Brush");
  preset.category = meta.value("category").toString("General");
  preset.author = meta.value("author").toString("ArtFlow Studio");
  preset.version = meta.value("version").toInt(1);

  if (preset.uuid.isEmpty()) {
    preset.uuid = generateUUID();
  }

  // Rendering
  QJsonObject rendering = root["rendering"].toObject();
  preset.blendMode =
      blendModeFromString(rendering.value("blend_mode").toString("normal"));
  preset.antiAliasing = rendering.value("anti_aliasing").toBool(true);

  // Shape
  if (root.contains("shape"))
    preset.shape = ShapeSettings::fromJson(root["shape"].toObject());

  // Randomize
  if (root.contains("randomize"))
    preset.randomize =
        RandomizeSettings::fromJson(root["randomize"].toObject());

  // Grain
  if (root.contains("grain"))
    preset.grain = GrainSettings::fromJson(root["grain"].toObject());

  // Stroke
  if (root.contains("stroke"))
    preset.stroke = StrokeSettings::fromJson(root["stroke"].toObject());

  // Dynamics
  QJsonObject dynamics = root["dynamics"].toObject();
  if (dynamics.contains("size"))
    preset.sizeDynamics =
        DynamicsProperty::fromJson(dynamics["size"].toObject());
  if (dynamics.contains("opacity"))
    preset.opacityDynamics =
        DynamicsProperty::fromJson(dynamics["opacity"].toObject());
  if (dynamics.contains("flow"))
    preset.flowDynamics =
        DynamicsProperty::fromJson(dynamics["flow"].toObject());
  if (dynamics.contains("hardness"))
    preset.hardnessDynamics =
        DynamicsProperty::fromJson(dynamics["hardness"].toObject());

  // Wet Mix
  if (root.contains("wet_mix"))
    preset.wetMix = WetMixSettings::fromJson(root["wet_mix"].toObject());

  // Watercolor specific
  if (root.contains("pigment"))
    preset.pigment = PigmentSettings::fromJson(root["pigment"].toObject());
  if (root.contains("bloom"))
    preset.bloom = BloomSettings::fromJson(root["bloom"].toObject());
  if (root.contains("edge_darkening"))
    preset.edgeDarkening =
        EdgeDarkeningSettings::fromJson(root["edge_darkening"].toObject());
  if (root.contains("backrun"))
    preset.backrun = BackrunSettings::fromJson(root["backrun"].toObject());
  preset.textureReveal =
      TextureRevealSettings::fromJson(root["texture_reveal"].toObject());

  // Oil specific
  if (root.contains("impasto"))
    preset.impasto = ImpastoSettings::fromJson(root["impasto"].toObject());
  if (root.contains("bristles"))
    preset.bristles = BristleSettings::fromJson(root["bristles"].toObject());
  if (root.contains("smudge"))
    preset.smudge = SmudgeSettings::fromJson(root["smudge"].toObject());
  if (root.contains("canvas_interaction"))
    preset.canvasInteraction = CanvasInteractionSettings::fromJson(
        root["canvas_interaction"].toObject());

  // Color Dynamics
  if (root.contains("color_dynamics"))
    preset.colorDynamics =
        ColorDynamics::fromJson(root["color_dynamics"].toObject());

  // Customize
  QJsonObject customize = root["customize"].toObject();
  preset.minSize = customize.value("min_size").toDouble(1.0);
  preset.maxSize = customize.value("max_size").toDouble(500.0);
  preset.defaultSize = customize.value("default_size").toDouble(20.0);
  preset.minOpacity = customize.value("min_opacity").toDouble(0.0);
  preset.maxOpacity = customize.value("max_opacity").toDouble(1.0);
  preset.defaultOpacity = customize.value("default_opacity").toDouble(1.0);
  preset.defaultHardness = customize.value("default_hardness").toDouble(0.8);
  preset.defaultFlow = customize.value("default_flow").toDouble(1.0);

  return preset;
}

// ============================================================
// Bridge: BrushPreset -> legacy BrushSettings
// ============================================================
void BrushPreset::applyToLegacy(BrushSettings &s) const {
  s.size = defaultSize;
  s.opacity = defaultOpacity;
  s.hardness = defaultHardness;
  s.spacing = stroke.spacing;
  s.flow = defaultFlow;
  s.stabilization = stroke.streamline;

  // === DUAL TEXTURE SYSTEM ===

  // Tip texture (brush shape) — separate slot
  if (!shape.tipTexture.isEmpty()) {
    s.tipTextureName = shape.tipTexture;
    s.tipTextureID = 0; // Will be loaded lazily by BrushEngine
    s.tipRotation = shape.rotation * 3.14159265f / 180.0f; // deg to rad
    qDebug() << "BrushPreset::applyToLegacy: Setting tipTextureName to"
             << s.tipTextureName;
  }

  s.calligraphicInfluence = shape.calligraphic;

  // Grain texture (paper grain) — separate slot
  if (!grain.texture.isEmpty()) {
    s.useTexture = true;
    s.textureName = grain.texture;
    s.textureScale = grain.scale;
    s.textureIntensity = grain.intensity;
  }

  // If only tip texture is set (no grain), still mark texture as used for
  // the shader pipeline to activate
  if (!shape.tipTexture.isEmpty() && grain.texture.isEmpty()) {
    s.useTexture = false; // No grain, but tip is on its own channel
  }

  // Apply tip rotation
  s.tipRotation = shape.rotation * 3.14159265f / 180.0f;
  s.rotateWithStroke = shape.followStroke;

  // Dynamics
  s.sizeByPressure =
      (sizeDynamics.baseValue > 0.01f || sizeDynamics.minLimit < 0.99f);
  s.opacityByPressure = (opacityDynamics.minLimit < 0.99f);
  s.jitter = sizeDynamics.jitter; // Legacy
  s.velocityDynamics = sizeDynamics.velocityInfluence;

  // New Jitter Settings
  s.jitterLateral = stroke.jitterLateral;
  s.jitterLinear = stroke.jitterLinear;
  s.posJitterX = randomize.posJitterX;
  s.posJitterY = randomize.posJitterY;
  s.rotationJitter = randomize.rotationJitter;
  s.roundnessJitter = randomize.roundnessJitter;
  s.sizeJitter = randomize.sizeJitter;
  s.opacityJitter = randomize.opacityJitter;

  // Taper
  s.taperStart = stroke.taperStart;
  s.taperEnd = stroke.taperEnd;
  s.taperSize = stroke.taperSize;
  s.fallOff = stroke.fallOff;
  s.distance = stroke.distance;

  // Shape
  s.roundness = shape.roundness;
  s.flipX = shape.flipX;
  s.flipY = shape.flipY;
  s.invertShape = shape.invert;
  s.randomizeShape = shape.randomize;
  s.count = shape.count;
  s.countJitter = shape.countJitter;
  s.shapeContrast = shape.contrast;
  s.shapeBlur = shape.blur;

  // Grain
  s.invertGrain = grain.invert;
  s.grainOverlap = grain.overlap;
  s.grainBlur = grain.blur;
  s.grainMotionBlur = grain.motionBlur;
  s.grainMotionBlurAngle = grain.motionBlurAngle;
  s.grainRandomOffset = grain.randomOffset;
  s.grainBlendMode = grain.blendMode;
  s.grainBright = grain.brightness;
  s.grainCon = grain.contrast;

  // Wet Mix
  s.wetness = wetMix.wetness;
  s.smudge = wetMix.pull;
  s.dilution = wetMix.dilution;
  s.pressurePigment = wetMix.pressurePigment;
  s.pullPressure = wetMix.pullPressure;
  s.wetJitter = wetMix.wetJitter;
  s.bleed = wetMix.bleed;
  s.absorptionRate = wetMix.absorptionRate;
  s.dryingTime = wetMix.dryingTime;
  s.wetOnWetMultiplier = wetMix.wetOnWetMultiplier;

  // Oil Wet Mix
  s.mixing = wetMix.mixing;
  s.loading = wetMix.loading;
  s.depletionRate = wetMix.depletionRate;
  s.dirtyMixing = wetMix.dirtyMixing;
  s.colorPickup = wetMix.colorPickup;
  s.blendOnly = wetMix.blendOnly;
  s.scrapeThrough = wetMix.scrapeThrough;

  // Watercolor Pigment
  s.granulation = pigment.granulation;
  s.pigmentFlow = pigment.flow;
  s.staining = pigment.staining;
  s.separation = pigment.separation;

  // Bloom
  s.bloomEnabled = bloom.enabled;
  s.bloomIntensity = bloom.intensity;
  s.bloomRadius = bloom.radius;
  s.bloomThreshold = bloom.threshold;

  // Edge Darkening
  s.edgeDarkeningEnabled = edgeDarkening.enabled;
  s.edgeDarkeningIntensity = edgeDarkening.intensity;
  s.edgeDarkeningWidth = edgeDarkening.width;

  // Texture Reveal
  s.textureRevealEnabled = textureReveal.enabled;
  s.textureRevealIntensity = textureReveal.intensity;
  s.textureRevealPressureInfluence = textureReveal.pressureInfluence;

  // === OIL PAINT ===
  // Impasto
  s.impastoEnabled = impasto.enabled;
  s.impastoDepth = impasto.depth;
  s.impastoShine = impasto.shine;
  s.impastoTextureStrength = impasto.textureStrength;
  s.impastoEdgeBuildup = impasto.edgeBuildup;
  s.impastoDirectionalRidges = impasto.directionalRidges;
  s.impastoSmoothing = impasto.smoothing;
  s.impastoPreserveExisting = impasto.preserveExisting;

  // Bristles
  s.bristlesEnabled = bristles.enabled;
  s.bristleCount = bristles.count;
  s.bristleStiffness = bristles.stiffness;
  s.bristleClumping = bristles.clumping;
  s.bristleFanSpread = bristles.fanSpread;
  s.bristleIndividualVariation = bristles.individualVariation;
  s.bristleDryBrushEffect = bristles.dryBrushEffect;
  s.bristleSoftness = bristles.softness;
  s.bristlePointTaper = bristles.pointTaper;

  // Smudge
  s.smudgeStrength = smudge.strength;
  s.smudgePressureInfluence = smudge.pressureInfluence;
  s.smudgeLength = smudge.length;
  s.smudgeGaussianBlur = smudge.gaussianBlur;
  s.smudgeSmear = smudge.smear;

  // Canvas Interaction
  s.canvasAbsorption = canvasInteraction.absorption;
  s.canvasSkipValleys = canvasInteraction.skipValleys;
  s.canvasCatchPeaks = canvasInteraction.catchPeaks;

  // Color Dynamics
  s.hueJitter = colorDynamics.hueJitter;
  s.satJitter = colorDynamics.saturationJitter;
  s.lightJitter = colorDynamics.brightnessJitter;
  s.darkJitter = 0.0f; // Not in legacy base
  s.strokeHueJitter = colorDynamics.strokeHueJitter;
  s.strokeSatJitter = colorDynamics.strokeSatJitter;
  s.strokeLightJitter = colorDynamics.strokeLightJitter;
  s.strokeDarkJitter = colorDynamics.strokeDarkJitter;
  s.tiltDarkJitter = colorDynamics.tiltDarkJitter;
  s.useSecondaryColor = colorDynamics.useSecondaryColor;

  // Oil Color Dynamics
  s.temperatureShift = colorDynamics.temperatureShift;
  s.brokenColor = colorDynamics.brokenColor;

  // Determine brush type from category/name heuristics
  if (category == "Eraser" || name.contains("Eraser", Qt::CaseInsensitive)) {
    s.type = BrushSettings::Type::Eraser;
  } else if (category == "Inking" ||
             name.contains("Ink", Qt::CaseInsensitive) ||
             name.contains("Pen", Qt::CaseInsensitive)) {
    s.type = BrushSettings::Type::Ink;
  } else if (category == "Sketching" ||
             name.contains("Pencil", Qt::CaseInsensitive) ||
             name.contains("Mechanical", Qt::CaseInsensitive)) {
    s.type = BrushSettings::Type::Pencil;
  } else if (name.contains("Water", Qt::CaseInsensitive)) {
    s.type = BrushSettings::Type::Watercolor;
  } else if (name.contains("Oil", Qt::CaseInsensitive) ||
             name.contains("Óleo", Qt::CaseInsensitive) ||
             name.contains("Acrylic", Qt::CaseInsensitive) ||
             name.contains("Blender", Qt::CaseInsensitive) ||
             name.contains("Smudge", Qt::CaseInsensitive)) {
    s.type = BrushSettings::Type::Oil;
  } else if (name.contains("Soft", Qt::CaseInsensitive) ||
             name.contains("Hard", Qt::CaseInsensitive) ||
             name.contains("Airbrush", Qt::CaseInsensitive)) {
    s.type = BrushSettings::Type::Airbrush;
  } else if (name.contains("Marker", Qt::CaseInsensitive)) {
    s.type = BrushSettings::Type::Round;
  } else {
    s.type = BrushSettings::Type::Round;
  }
}

QString BrushPreset::generateUUID() {
  return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

// ============================================================
// BrushGroup
// ============================================================
QJsonObject BrushGroup::toJson() const {
  QJsonObject obj;
  obj["name"] = name;
  obj["icon"] = icon;
  QJsonArray arr;
  for (const auto &b : brushes) {
    arr.append(b.toJson());
  }
  obj["brushes"] = arr;
  return obj;
}

BrushGroup BrushGroup::fromJson(const QJsonObject &obj) {
  BrushGroup g;
  g.name = obj.value("name").toString("General");
  g.icon = obj.value("icon").toString("GN");
  QJsonArray arr = obj["brushes"].toArray();
  for (const auto &v : arr) {
    g.brushes.push_back(BrushPreset::fromJson(v.toObject()));
  }
  return g;
}

} // namespace artflow
