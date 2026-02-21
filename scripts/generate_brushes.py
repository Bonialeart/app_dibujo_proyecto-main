
import json
import os
import uuid

# Define output directory
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "../assets/brushes"))

# Ensure output directory exists
os.makedirs(OUTPUT_DIR, exist_ok=True)
print(f"Output directory: {OUTPUT_DIR}")

# Helper function to generate UUID
def gen_uuid():
    return str(uuid.uuid4())

# Base brush template
def create_brush(name, category, icon="GN"):
    return {
        "meta": {
            "uuid": gen_uuid(),
            "name": name,
            "category": category,
            "author": "ArtFlow Studio",
            "version": 1
        },
        "rendering": {
            "blend_mode": "normal",
            "anti_aliasing": True
        },
        "shape": {
            "tip_texture": "", # Default: generated circle
            "roundness": 1.0,
            "contrast": 1.0,
             "count": 1
        },
        "stroke": {
            "spacing": 0.1,
            "streamline": 0.0
        },
        "dynamics": {
            "size": {"base_value": 1.0, "min_limit": 0.0, "pressure_curve": "linear"},
            "opacity": {"base_value": 1.0, "min_limit": 0.0, "pressure_curve": "linear"},
            "flow": {"base_value": 1.0, "min_limit": 0.0, "pressure_curve": "linear"},
            "hardness": {"base_value": 0.8, "min_limit": 0.0, "pressure_curve": "linear"}
        },
        "grain": {
            "scale": 1.0,
            "intensity": 0.5,
            "contrast": 1.0
        },
        "wet_mix": {
            "wet_mix": 0.0,
             "pigment": 1.0
        },
        "color_dynamics": {},
        "randomize": {},
        "customize": {
            "default_size": 20.0,
             "default_opacity": 1.0
        }
    }

# Categories and their brushes
categories = {
    "Sketching": {
        "icon": "SK",
        "brushes": [
            ("HB Pencil", {'spacing': 0.15, 'shape': {'tip_texture': 'tip_sketching_hb_pencil.png', 'roundness': 0.8}, 'grain': {'intensity': 0.7, 'scale': 0.5, 'texture': 'paper_grain.png'}, 'dynamics': {'size': {'pressure_curve': 'ease_in'}, 'opacity': {'pressure_curve': 'linear', 'min_limit': 0.2}}, 'customize': {'default_size': 15.0}}),
            ("6B Real Pencil", {'spacing': 0.12, 'shape': {'tip_texture': 'tip_sketching_6b_real_pencil.png', 'roundness': 0.6, 'scatter': 0.1}, 'grain': {'intensity': 0.9, 'texture': 'graphite.png'}, 'dynamics': {'size': {'pressure_curve': 'soft'}, 'opacity': {'pressure_curve': 'soft'}}, 'customize': {'default_size': 25.0}}),
            ("Peppermint Graphite", {'spacing': 0.1, 'shape': {'tip_texture': 'tip_sketching_peppermint_graphite.png'}, 'grain': {'intensity': 0.8, 'scale': 0.4}, 'rendering': {'blend_mode': 'multiply'}, 'customize': {'default_size': 18.0}}),
            ("Derwent Pencil", {'spacing': 0.2, 'shape': {'tip_texture': 'tip_sketching_derwent_pencil.png'}, 'grain': {'texture': 'rough_paper.png'}, 'customize': {'default_size': 30.0}}),
            ("Mechanical 0.5", {'spacing': 0.05, 'shape': {'tip_texture': 'tip_sketching_mechanical_0_5.png', 'roundness': 1.0}, 'dynamics': {'size': {'base_value': 1.0, 'min_limit': 0.9}}, 'customize': {'default_size': 5.0}}),
            ("Carpenter Pencil", {'shape': {'tip_texture': 'tip_sketching_carpenter_pencil.png', 'roundness': 0.2, 'rotation': 45.0}, 'customize': {'default_size': 40.0}}),
            ("Pro Sketch", {'stroke': {'streamline': 0.2}, 'shape': {'tip_texture': 'tip_sketching_pro_sketch.png'}, 'customize': {'default_size': 20.0}}),
            ("Artistic Graphite", {'stroke': {'taper_start': 20.0}, 'shape': {'tip_texture': 'tip_sketching_artistic_graphite.png'}, 'grain': {'intensity': 0.6}, 'customize': {'default_size': 35.0}}),
            ("Wax Color Pencil", {'rendering': {'blend_mode': 'multiply'}, 'shape': {'tip_texture': 'tip_sketching_wax_color_pencil.png'}, 'grain': {'intensity': 0.9, 'contrast': 1.2}, 'customize': {'default_size': 22.0}}),
            ("Graphite Smudge", {'wet_mix': {'wet_mix': 0.8, 'smudge': 0.7}, 'shape': {'tip_texture': 'tip_sketching_graphite_smudge.png'}, 'customize': {'default_size': 45.0}}),
            ("Evolution", {'stroke': {'streamline': 0.4}, 'shape': {'tip_texture': 'tip_sketching_evolution.png', 'roundness': 0.9}, 'customize': {'default_size': 12.0}}),
        ]
    },
    "Inking": {
        "icon": "IN",
        "brushes": [
            ("G-Pen", {'stroke': {'streamline': 0.6, 'taper_end': 30.0}, 'shape': {'tip_texture': 'tip_inking_g_pen.png', 'roundness': 1.0}, 'dynamics': {'size': {'pressure_curve': 'hard'}}, 'customize': {'default_size': 12.0}}),
            ("Studio Pen", {'stroke': {'streamline': 0.4}, 'shape': {'tip_texture': 'tip_inking_studio_pen.png'}, 'customize': {'default_size': 15.0}}),
            ("Monoline", {'dynamics': {'size': {'min_limit': 1.0}}, 'shape': {'tip_texture': 'tip_inking_monoline.png'}, 'customize': {'default_size': 20.0}}),
            ("Dry Ink", {'shape': {'tip_texture': 'tip_inking_dry_ink.png', 'scatter': 0.05}, 'customize': {'default_size': 18.0}}),
            ("Bleed Ink", {'shape': {'blur': 2.0, 'tip_texture': 'tip_inking_bleed_ink.png'}, 'grain': {'texture': 'paper_bleed.png'}, 'customize': {'default_size': 25.0}}),
            ("Gel Pen", {'rendering': {'blend_mode': 'normal'}, 'shape': {'tip_texture': 'tip_inking_gel_pen.png'}, 'customize': {'default_size': 8.0, 'default_opacity': 0.95}}),
            ("Sumi-e Ink", {'wet_mix': {'wet_mix': 0.6, 'pigment': 0.8}, 'shape': {'tip_texture': 'tip_inking_sumi_e_ink.png'}, 'stroke': {'taper_start': 40.0}, 'customize': {'default_size': 50.0}}),
            ("Fountain Pen", {'shape': {'rotation': 45.0, 'roundness': 0.3, 'tip_texture': 'tip_inking_fountain_pen.png'}, 'customize': {'default_size': 14.0}}),
            ("Mercury Ink", {'stroke': {'streamline': 0.5}, 'shape': {'tip_texture': 'tip_inking_mercury_ink.png'}, 'customize': {'default_size': 16.0}}),
            ("Thylacine", {'shape': {'tip_texture': 'tip_inking_thylacine.png'}, 'customize': {'default_size': 22.0}}),
            ("Rough Inker", {'shape': {'scatter': 0.08, 'tip_texture': 'tip_inking_rough_inker.png'}, 'customize': {'default_size': 18.0}}),
            ("Bic Pen", {'stroke': {'spacing': 0.08}, 'shape': {'tip_texture': 'tip_inking_bic_pen.png'}, 'customize': {'default_size': 6.0}}),
        ]
    },
    "Drawing": {
        "icon": "DR",
        "brushes": [
            ("Conte Crayon", {'shape': {'roundness': 0.6, 'tip_texture': 'tip_drawing_conte_crayon.png'}, 'grain': {'texture': 'rough_paper.png'}, 'customize': {'default_size': 40.0}}),
            ("Soft Pastel", {'grain': {'intensity': 0.9, 'scale': 1.2}, 'shape': {'tip_texture': 'tip_drawing_soft_pastel.png'}, 'customize': {'default_size': 50.0}}),
            ("Oil Pastel", {'wet_mix': {'wet_mix': 0.4}, 'shape': {'tip_texture': 'tip_drawing_oil_pastel.png'}, 'customize': {'default_size': 45.0}}),
            ("Wax Stick", {'shape': {'roundness': 0.8, 'tip_texture': 'tip_drawing_wax_stick.png'}, 'customize': {'default_size': 35.0}}),
            ("Gloaming", {'rendering': {'blend_mode': 'multiply'}, 'shape': {'tip_texture': 'tip_drawing_gloaming.png'}, 'customize': {'default_size': 60.0}}),
            ("Blackburn", {'shape': {'roundness': 0.1, 'tip_texture': 'tip_drawing_blackburn.png'}, 'customize': {'default_size': 70.0}}),
            ("Oberon", {'shape': {'scatter': 0.2, 'tip_texture': 'tip_drawing_oberon.png'}, 'customize': {'default_size': 55.0}}),
            ("Blackboard Chalk", {'grain': {'texture': 'chalk_grain.png'}, 'shape': {'tip_texture': 'tip_drawing_blackboard_chalk.png'}, 'customize': {'default_size': 28.0}}),
            ("Artistic Crayon", {'dynamics': {'opacity': {'pressure_curve': 'ease_in'}}, 'shape': {'tip_texture': 'tip_drawing_artistic_crayon.png'}, 'customize': {'default_size': 32.0}}),
            ("Eagle Sketch", {'shape': {'tip_texture': 'tip_drawing_eagle_sketch.png'}, 'customize': {'default_size': 25.0}}),
        ]
    },
    "Painting": {
        "icon": "PT",
        "brushes": [
            ("Round Brush", {'wet_mix': {'wet_mix': 0.5}, 'shape': {'tip_texture': 'tip_painting_round_brush.png'}, 'customize': {'default_size': 40.0}}),
            ("Flat Brush", {'shape': {'roundness': 0.2, 'tip_texture': 'tip_painting_flat_brush.png'}, 'wet_mix': {'wet_mix': 0.6}, 'customize': {'default_size': 50.0}}),
            ("Nikko Rull", {'shape': {'tip_texture': 'tip_painting_nikko_rull.png'}, 'grain': {'texture': 'grain_concrete.png', 'movement': 'rolling'}, 'wet_mix': {'wet_mix': 0.5}, 'customize': {'default_size': 60.0}}),
            ("Salamanca", {'shape': {'tip_texture': 'tip_painting_salamanca.png'}, 'wet_mix': {'wet_mix': 0.7}, 'customize': {'default_size': 55.0}}),
            ("Wet Acrylic", {'wet_mix': {'wet_mix': 0.8, 'pull': 0.6}, 'shape': {'tip_texture': 'tip_painting_wet_acrylic.png'}, 'customize': {'default_size': 45.0}}),
            ("Old Oil", {'shape': {'tip_texture': 'tip_painting_old_oil.png'}, 'customize': {'default_size': 50.0}}),
            ("Tamar", {'shape': {'tip_texture': 'tip_painting_tamar.png'}, 'customize': {'default_size': 48.0}}),
            ("Spectra", {'color_dynamics': {'hue_jitter': 0.1}, 'shape': {'tip_texture': 'tip_painting_spectra.png'}, 'customize': {'default_size': 42.0}}),
            ("Jagged Brush", {'shape': {'tip_texture': 'tip_painting_jagged_brush.png'}, 'customize': {'default_size': 38.0}}),
            ("Fan Brush", {'shape': {'tip_texture': 'tip_painting_fan_brush.png'}, 'customize': {'default_size': 65.0}}),
            ("Opaque Gouache", {'wet_mix': {'wet_mix': 0.3}, 'shape': {'tip_texture': 'tip_painting_opaque_gouache.png'}, 'customize': {'default_size': 40.0}}),
            ("Basic Watercolor", {'rendering': {'blend_mode': 'multiply'}, 'shape': {'tip_texture': 'tip_painting_basic_watercolor.png'}, 'wet_mix': {'wet_mix': 0.9, 'dilution': 0.5}, 'customize': {'default_size': 60.0}}),
        ]
    },
    "Artistic": {
        "icon": "AR",
        "brushes": [
            ("Leatherwood", {'grain': {'texture': 'leather_grain.png'}, 'shape': {'tip_texture': 'tip_artistic_leatherwood.png'}, 'customize': {'default_size': 50.0}}),
            ("Plimsoll", {'shape': {'tip_texture': 'tip_artistic_plimsoll.png'}, 'customize': {'default_size': 45.0}}),
            ("Wild Light", {'rendering': {'blend_mode': 'screen'}, 'shape': {'tip_texture': 'tip_artistic_wild_light.png'}, 'customize': {'default_size': 60.0}}),
            ("Saguaro", {'shape': {'tip_texture': 'tip_artistic_saguaro.png'}, 'customize': {'default_size': 55.0}}),
            ("Hartz", {'grain': {'texture': 'crosshatch.png'}, 'shape': {'tip_texture': 'tip_artistic_hartz.png'}, 'customize': {'default_size': 40.0}}),
            ("Tarraleah", {'wet_mix': {'wet_mix': 0.6}, 'shape': {'tip_texture': 'tip_artistic_tarraleah.png'}, 'customize': {'default_size': 52.0}}),
            ("Old Brush", {'shape': {'scatter': 0.3, 'tip_texture': 'tip_artistic_old_brush.png'}, 'customize': {'default_size': 48.0}}),
            ("Palette Knife", {'shape': {'roundness': 0.1, 'rotation': 90.0, 'tip_texture': 'tip_artistic_palette_knife.png'}, 'wet_mix': {'wet_mix': 0.8}, 'customize': {'default_size': 80.0}}),
            ("Ink Roller", {'shape': {'roundness': 0.3, 'tip_texture': 'tip_artistic_ink_roller.png'}, 'customize': {'default_size': 70.0}}),
            ("Impressionist", {'shape': {'scatter': 0.5, 'count': 3, 'tip_texture': 'tip_artistic_impressionist.png'}, 'color_dynamics': {'hue_jitter': 0.05}, 'customize': {'default_size': 45.0}}),
        ]
    },
    "Calligraphy": {
        "icon": "CA",
        "brushes": [
            ("Monoline Calligraphy", {'stroke': {'streamline': 0.8}, 'shape': {'tip_texture': 'tip_calligraphy_monoline_calligraphy.png'}, 'dynamics': {'size': {'min_limit': 1.0}}, 'customize': {'default_size': 25.0}}),
            ("Script", {'stroke': {'streamline': 0.7}, 'shape': {'roundness': 0.6, 'tip_texture': 'tip_calligraphy_script.png'}, 'customize': {'default_size': 30.0}}),
            ("Brush Pen", {'stroke': {'taper_start': 30.0, 'taper_end': 30.0}, 'shape': {'tip_texture': 'tip_calligraphy_brush_pen.png'}, 'dynamics': {'size': {'pressure_curve': 'soft'}}, 'customize': {'default_size': 35.0}}),
            ("Chalk Lettering", {'grain': {'texture': 'chalk.png'}, 'shape': {'tip_texture': 'tip_calligraphy_chalk_lettering.png'}, 'customize': {'default_size': 40.0}}),
            ("Streaker", {'shape': {'tip_texture': 'tip_calligraphy_streaker.png'}, 'customize': {'default_size': 45.0}}),
            ("Shale", {'shape': {'rotation': 30.0, 'tip_texture': 'tip_calligraphy_shale.png'}, 'customize': {'default_size': 38.0}}),
            ("Water Pen", {'wet_mix': {'wet_mix': 0.7, 'dilution': 0.4}, 'shape': {'tip_texture': 'tip_calligraphy_water_pen.png'}, 'customize': {'default_size': 40.0}}),
            ("Gothic Pen", {'shape': {'roundness': 0.2, 'rotation': 45.0, 'tip_texture': 'tip_calligraphy_gothic_pen.png'}, 'customize': {'default_size': 30.0}}),
            ("Neon Line", {'rendering': {'blend_mode': 'add'}, 'shape': {'blur': 5.0, 'tip_texture': 'tip_calligraphy_neon_line.png'}, 'customize': {'default_size': 20.0}}),
        ]
    },
    "Airbrushing": {
        "icon": "AB",
        "brushes": [
            ("Soft Airbrush", {'shape': {'hardness': 0.0, 'tip_texture': 'tip_airbrushing_soft_airbrush.png'}, 'customize': {'default_size': 80.0}}),
            ("Medium Airbrush", {'shape': {'hardness': 0.5, 'tip_texture': 'tip_airbrushing_medium_airbrush.png'}, 'customize': {'default_size': 60.0}}),
            ("Hard Airbrush", {'shape': {'hardness': 1.0, 'tip_texture': 'tip_airbrushing_hard_airbrush.png'}, 'customize': {'default_size': 40.0}}),
            ("Noise Airbrush", {'grain': {'texture': 'noise.png'}, 'shape': {'tip_texture': 'tip_airbrushing_noise_airbrush.png'}, 'customize': {'default_size': 70.0}}),
            ("Soft Blend", {'wet_mix': {'wet_mix': 0.0, 'smudge': 1.0}, 'shape': {'tip_texture': 'tip_airbrushing_soft_blend.png'}, 'customize': {'default_size': 90.0}}),
            ("Digital Shader", {'dynamics': {'opacity': {'pressure_curve': 'linear'}}, 'shape': {'tip_texture': 'tip_airbrushing_digital_shader.png'}, 'customize': {'default_size': 55.0}}),
        ]
    },
    "Textures": {
        "icon": "TX",
        "brushes": [
            ("Halftone", {'grain': {'texture': 'halftone.png', 'scale': 0.5}, 'shape': {'tip_texture': 'tip_textures_halftone.png'}, 'customize': {'default_size': 100.0}}),
            ("Grid", {'grain': {'texture': 'grid.png'}, 'shape': {'tip_texture': 'tip_textures_grid.png'}, 'customize': {'default_size': 120.0}}),
            ("Perlin Noise", {'grain': {'texture': 'perlin.png'}, 'shape': {'tip_texture': 'tip_textures_perlin_noise.png'}, 'customize': {'default_size': 150.0}}),
            ("Watercolor Paper", {'grain': {'texture': 'watercolor_paper.png'}, 'shape': {'tip_texture': 'tip_textures_watercolor_paper.png'}, 'customize': {'default_size': 200.0}}),
            ("Concrete", {'grain': {'texture': 'concrete.png'}, 'shape': {'tip_texture': 'tip_textures_concrete.png'}, 'customize': {'default_size': 130.0}}),
            ("Wood", {'grain': {'texture': 'wood_grain.png'}, 'shape': {'tip_texture': 'tip_textures_wood.png'}, 'customize': {'default_size': 140.0}}),
            ("Canvas", {'grain': {'texture': 'canvas.png'}, 'shape': {'tip_texture': 'tip_textures_canvas.png'}, 'customize': {'default_size': 180.0}}),
            ("Rust", {'grain': {'texture': 'rust.png'}, 'shape': {'tip_texture': 'tip_textures_rust.png'}, 'customize': {'default_size': 110.0}}),
            ("Victorian", {'grain': {'texture': 'victorian.png'}, 'shape': {'tip_texture': 'tip_textures_victorian.png'}, 'customize': {'default_size': 160.0}}),
            ("Cubes", {'grain': {'texture': 'cubes.png'}, 'shape': {'tip_texture': 'tip_textures_cubes.png'}, 'customize': {'default_size': 125.0}}),
            ("Diagonal Rain", {'grain': {'texture': 'rain_lines.png'}, 'shape': {'tip_texture': 'tip_textures_diagonal_rain.png'}, 'customize': {'default_size': 145.0}}),
        ]
    },
    "Abstract": {
        "icon": "ABS",
        "brushes": [
            ("Polygons", {'shape': {'tip_texture': 'tip_abstract_polygons.png', 'scatter': 0.5}, 'customize': {'default_size': 80.0}}),
            ("Daisy", {'shape': {'tip_texture': 'tip_abstract_daisy.png', 'rotation_mode': 'follow_stroke'}, 'customize': {'default_size': 70.0}}),
            ("Glitch", {'grain': {'texture': 'glitch.png'}, 'shape': {'tip_texture': 'tip_abstract_glitch.png'}, 'customize': {'default_size': 60.0}}),
            ("Kaleidoscope", {'shape': {'count': 6, 'rotation': 60.0, 'tip_texture': 'tip_abstract_kaleidoscope.png'}, 'customize': {'default_size': 90.0}}),
            ("Fractal", {'grain': {'texture': 'fractal.png'}, 'shape': {'tip_texture': 'tip_abstract_fractal.png'}, 'customize': {'default_size': 100.0}}),
            ("3D Mesh", {'shape': {'tip_texture': 'tip_abstract_3d_mesh.png'}, 'customize': {'default_size': 85.0}}),
            ("Pointillism", {'shape': {'scatter': 0.8, 'count': 10, 'tip_texture': 'tip_abstract_pointillism.png'}, 'customize': {'default_size': 40.0}}),
            ("Loop", {'shape': {'tip_texture': 'tip_abstract_loop.png', 'follow_stroke': True}, 'customize': {'default_size': 55.0}}),
        ]
    },
    "Charcoal": {
        "icon": "CH",
        "brushes": [
            ("6B Charcoal", {'grain': {'texture': 'charcoal_grain.png'}, 'shape': {'tip_texture': 'tip_charcoal_6b_charcoal.png'}, 'customize': {'default_size': 35.0}}),
            ("Willow Stick", {'shape': {'roundness': 0.7, 'tip_texture': 'tip_charcoal_willow_stick.png'}, 'grain': {'intensity': 0.6}, 'customize': {'default_size': 40.0}}),
            ("Compressed Stick", {'shape': {'roundness': 0.4, 'tip_texture': 'tip_charcoal_compressed_stick.png'}, 'customize': {'default_size': 45.0}}),
            ("Burnt Charcoal", {'grain': {'texture': 'burnt.png'}, 'shape': {'tip_texture': 'tip_charcoal_burnt_charcoal.png'}, 'customize': {'default_size': 38.0}}),
            ("Charcoal Shader", {'shape': {'rotation': 90.0, 'roundness': 0.2, 'tip_texture': 'tip_charcoal_charcoal_shader.png'}, 'customize': {'default_size': 60.0}}),
            ("Charcoal Pencil", {'customize': {'default_size': 15.0}, 'shape': {'tip_texture': 'tip_charcoal_charcoal_pencil.png'}}),
            ("Charcoal Dust", {'shape': {'scatter': 0.4, 'blur': 10.0, 'tip_texture': 'tip_charcoal_charcoal_dust.png'}, 'customize': {'default_size': 55.0}}),
        ]
    },
    "Elements": {
        "icon": "EL",
        "brushes": [
            ("Clouds", {'shape': {'tip_texture': 'tip_elements_clouds.png', 'scatter': 0.2}, 'rendering': {'blend_mode': 'screen'}, 'customize': {'default_size': 150.0}}),
            ("Smoke", {'shape': {'tip_texture': 'tip_elements_smoke.png', 'scatter': 0.1}, 'customize': {'default_size': 120.0}}),
            ("Fire", {'shape': {'tip_texture': 'tip_elements_fire.png'}, 'rendering': {'blend_mode': 'add'}, 'color_dynamics': {'hue_jitter': 0.05, 'brightness_jitter': 0.2}, 'customize': {'default_size': 100.0}}),
            ("Water Ocean", {'grain': {'texture': 'ocean_waves.png'}, 'shape': {'tip_texture': 'tip_elements_water_ocean.png'}, 'wet_mix': {'wet_mix': 0.6}, 'customize': {'default_size': 110.0}}),
            ("Rain", {'shape': {'tip_texture': 'tip_elements_rain.png', 'scatter': 0.3}, 'customize': {'default_size': 80.0}}),
            ("Snow", {'shape': {'tip_texture': 'tip_elements_snow.png', 'scatter': 0.6, 'count': 2}, 'customize': {'default_size': 60.0}}),
            ("Grass", {'shape': {'tip_texture': 'tip_elements_grass.png', 'scatter': 0.4, 'follow_stroke': True}, 'color_dynamics': {'hue_jitter': 0.08}, 'customize': {'default_size': 50.0}}),
            ("Leaves", {'shape': {'tip_texture': 'tip_elements_leaves.png', 'scatter': 0.5, 'rotation_jitter': 0.5}, 'customize': {'default_size': 55.0}}),
            ("Fur", {'shape': {'tip_texture': 'tip_elements_fur.png', 'count': 5, 'spacing': 0.05}, 'customize': {'default_size': 45.0}}),
        ]
    },
    "Sprays": {
        "icon": "SP",
        "brushes": [
            ("Fat Cap", {'shape': {'hardness': 0.2, 'scatter': 0.05, 'tip_texture': 'tip_sprays_fat_cap.png'}, 'customize': {'default_size': 80.0}}),
            ("Skinny Cap", {'shape': {'hardness': 0.5, 'scatter': 0.02, 'tip_texture': 'tip_sprays_skinny_cap.png'}, 'customize': {'default_size': 30.0}}),
            ("Splatter", {'shape': {'tip_texture': 'tip_sprays_splatter.png', 'scatter': 0.8, 'count': 3}, 'customize': {'default_size': 90.0}}),
            ("Flicks", {'shape': {'tip_texture': 'tip_sprays_flicks.png', 'scatter': 0.6}, 'customize': {'default_size': 60.0}}),
            ("Drips", {'shape': {'tip_texture': 'tip_sprays_drips.png', 'follow_stroke': True}, 'customize': {'default_size': 50.0}}),
            ("Stencil Spray", {'grain': {'texture': 'stencil_mesh.png'}, 'shape': {'tip_texture': 'tip_sprays_stencil_spray.png'}, 'customize': {'default_size': 75.0}}),
        ]
    },
    "Industrial": {
        "icon": "IND",
        "brushes": [
            ("Polished Metal", {'grain': {'texture': 'brushed_metal.png'}, 'shape': {'tip_texture': 'tip_industrial_polished_metal.png'}, 'customize': {'default_size': 80.0}}),
            ("Corrosion", {'grain': {'texture': 'rust_spot.png'}, 'shape': {'tip_texture': 'tip_industrial_corrosion.png'}, 'customize': {'default_size': 70.0}}),
            ("Wasteland", {'shape': {'tip_texture': 'tip_industrial_wasteland.png'}, 'customize': {'default_size': 90.0}}),
            ("Metal Mesh", {'grain': {'texture': 'hex_mesh.png'}, 'shape': {'tip_texture': 'tip_industrial_metal_mesh.png'}, 'customize': {'default_size': 100.0}}),
            ("Wires", {'shape': {'tip_texture': 'tip_industrial_wires.png', 'follow_stroke': True}, 'customize': {'default_size': 40.0}}),
            ("Urban Floor", {'grain': {'texture': 'asphalt.png'}, 'shape': {'tip_texture': 'tip_industrial_urban_floor.png'}, 'customize': {'default_size': 120.0}}),
        ]
    },
    "Luminance": {
        "icon": "LU",
        "brushes": [
            ("Light Pen", {'rendering': {'blend_mode': 'add'}, 'shape': {'roundness': 1.0, 'hardness': 0.9, 'tip_texture': 'tip_luminance_light_pen.png'}, 'customize': {'default_size': 20.0}}),
            ("Neon Tube", {'rendering': {'blend_mode': 'add'}, 'shape': {'blur': 10.0, 'tip_texture': 'tip_luminance_neon_tube.png'}, 'customize': {'default_size': 35.0}}),
            ("Bokeh", {'rendering': {'blend_mode': 'screen'}, 'shape': {'tip_texture': 'tip_luminance_bokeh.png', 'scatter': 0.4}, 'customize': {'default_size': 80.0}}),
            ("Flares", {'rendering': {'blend_mode': 'add'}, 'shape': {'tip_texture': 'tip_luminance_flares.png', 'scatter': 0.2}, 'customize': {'default_size': 90.0}}),
            ("Glimmer", {'rendering': {'blend_mode': 'add'}, 'shape': {'tip_texture': 'tip_luminance_glimmer.png', 'scatter': 0.7, 'count': 5}, 'customize': {'default_size': 50.0}}),
            ("Nebula", {'rendering': {'blend_mode': 'screen'}, 'shape': {'tip_texture': 'tip_luminance_nebula.png'}, 'color_dynamics': {'hue_jitter': 0.2}, 'customize': {'default_size': 150.0}}),
            ("Laser", {'rendering': {'blend_mode': 'add'}, 'stroke': {'streamline': 1.0}, 'shape': {'tip_texture': 'tip_luminance_laser.png'}, 'customize': {'default_size': 10.0}}),
        ]
    },
    "Vintage": {
        "icon": "VI",
        "brushes": [
            ("Newsprint", {'grain': {'texture': 'newsprint.png'}, 'rendering': {'blend_mode': 'multiply'}, 'shape': {'tip_texture': 'tip_vintage_newsprint.png'}, 'customize': {'default_size': 70.0}}),
            ("Comic 60s", {'grain': {'texture': 'halftone_big.png'}, 'shape': {'tip_texture': 'tip_vintage_comic_60s.png'}, 'customize': {'default_size': 65.0}}),
            ("Worn Ink", {'shape': {'tip_texture': 'tip_vintage_worn_ink.png'}, 'customize': {'default_size': 35.0}}),
            ("VHS Noise", {'grain': {'texture': 'vhs_lines.png'}, 'shape': {'tip_texture': 'tip_vintage_vhs_noise.png'}, 'customize': {'default_size': 100.0}}),
            ("Old Map", {'grain': {'texture': 'parchment.png'}, 'color': {'r': 139, 'g': 69, 'b': 19}, 'shape': {'tip_texture': 'tip_vintage_old_map.png'}, 'customize': {'default_size': 40.0}}),
            ("Lithograph", {'grain': {'texture': 'stone_grain.png'}, 'shape': {'tip_texture': 'tip_vintage_lithograph.png'}, 'customize': {'default_size': 55.0}}),
        ]
    },
}

def generate_brushes():
    print(f"Generating {len(categories)} brush categories...")

    for cat_name, info in categories.items():
        icon = info["icon"]
        brushes_data = info["brushes"]

        brush_list = []
        for b_name, b_settings in brushes_data:
            # Create base
            brush = create_brush(b_name, cat_name, icon)
            
            # recursive update function
            def update(d, u):
                for k, v in u.items():
                    if isinstance(v, dict):
                        d[k] = update(d.get(k, {}), v)
                    else:
                        d[k] = v
                return d

            # Merge specific settings
            update(brush, b_settings)
            
            brush_list.append(brush)

        # Create Group JSON
        group_data = {
            "name": cat_name,
            "icon": icon,
            "brushes": brush_list
        }

        # Save to file
        filename = f"{cat_name.lower()}.json"
        filepath = os.path.join(OUTPUT_DIR, filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(group_data, f, indent=2)
            
        print(f"  - Created {filename} with {len(brush_list)} brushes")

if __name__ == "__main__":
    generate_brushes()
