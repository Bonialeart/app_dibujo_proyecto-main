use rayon::prelude::*;
use std::slice;

// ─── Modos de Pincel de Licuado ──────────────────────────────────
#[repr(i32)]
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum LiquifyMode {
    Push = 0,
    TwirlCW,
    TwirlCCW,
    Pinch,
    Expand,
    Crystalize,
    Edge,
    Reconstruct,
    Smooth,
}

impl From<i32> for LiquifyMode {
    fn from(val: i32) -> Self {
        match val {
            0 => LiquifyMode::Push,
            1 => LiquifyMode::TwirlCW,
            2 => LiquifyMode::TwirlCCW,
            3 => LiquifyMode::Pinch,
            4 => LiquifyMode::Expand,
            5 => LiquifyMode::Crystalize,
            6 => LiquifyMode::Edge,
            7 => LiquifyMode::Reconstruct,
            8 => LiquifyMode::Smooth,
            _ => LiquifyMode::Push,
        }
    }
}

// ─── Estructura del Motor de Licuado en Rust ──────────────────────
pub struct LiquifyEngineRust {
    active: bool,
    mode: LiquifyMode,
    radius: f32,
    strength: f32,
    morpher: f32,
    width: i32,
    height: i32,
    original: Vec<u8>,
    dx: Vec<f32>,
    dy: Vec<f32>,
    rng_state: u32,
}

impl LiquifyEngineRust {
    pub fn new() -> Self {
        LiquifyEngineRust {
            active: false,
            mode: LiquifyMode::Push,
            radius: 80.0,
            strength: 0.6,
            morpher: 0.0,
            width: 0,
            height: 0,
            original: Vec::new(),
            dx: Vec::new(),
            dy: Vec::new(),
            rng_state: 12345,
        }
    }

    pub fn begin(&mut self, source_pixels: &[u8], width: i32, height: i32) {
        self.width = width;
        self.height = height;
        self.original = source_pixels.to_vec();
        
        let len = (width * height) as usize;
        self.dx = vec![0.0f32; len];
        self.dy = vec![0.0f32; len];
        self.active = true;
    }

    pub fn end(&mut self) {
        self.active = false;
    }

    fn falloff(&self, dist: f32) -> f32 {
        if dist >= self.radius {
            return 0.0;
        }
        let t = dist / self.radius;
        let sharp = 1.0 - t * t;
        let smooth = 0.5 * (1.0 + (t * std::f32::consts::PI).cos());
        sharp * (1.0 - self.morpher) + smooth * self.morpher
    }

    fn rand_float(&mut self) -> f32 {
        self.rng_state ^= self.rng_state << 13;
        self.rng_state ^= self.rng_state >> 17;
        self.rng_state ^= self.rng_state << 5;
        (self.rng_state & 0xFFFF) as f32 / 65536.0
    }

    #[inline]
    fn idx(&self, x: i32, y: i32) -> Option<usize> {
        if x < 0 || x >= self.width || y < 0 || y >= self.height {
            None
        } else {
            Some((y * self.width + x) as usize)
        }
    }

    pub fn apply_brush(&mut self, cx: f32, cy: f32, prev_cx: f32, prev_cy: f32) {
        if !self.active {
            return;
        }

        let x0 = (cx - self.radius).max(0.0) as i32;
        let y0 = (cy - self.radius).max(0.0) as i32;
        let x1 = (cx + self.radius).min((self.width - 1) as f32) as i32;
        let y1 = (cy + self.radius).min((self.height - 1) as f32) as i32;

        let mut dir_x = cx - prev_cx;
        let mut dir_y = cy - prev_cy;
        let dir_len = (dir_x * dir_x + dir_y * dir_y).sqrt();
        if dir_len > 0.001 {
            dir_x /= dir_len;
            dir_y /= dir_len;
        }

        let radius_sq = self.radius * self.radius;

        for py in y0..=y1 {
            for px in x0..=x1 {
                let dx = px as f32 - cx;
                let dy = py as f32 - cy;
                let dist_sq = dx * dx + dy * dy;

                if dist_sq >= radius_sq {
                    continue;
                }

                let dist = dist_sq.sqrt();
                let f = self.falloff(dist) * self.strength;

                if f < 0.0001 {
                    continue;
                }

                match self.mode {
                    LiquifyMode::Push => {
                        if let Some(i) = self.idx(px, py) {
                            let push_scale = self.radius * 0.15;
                            self.dx[i] -= dir_x * f * push_scale;
                            self.dy[i] -= dir_y * f * push_scale;
                        }
                    }
                    LiquifyMode::TwirlCW | LiquifyMode::TwirlCCW => {
                        if let Some(i) = self.idx(px, py) {
                            let clockwise = self.mode == LiquifyMode::TwirlCW;
                            let angle = f * 0.08 * (if clockwise { 1.0 } else { -1.0 });
                            let cos_a = angle.cos();
                            let sin_a = angle.sin();

                            let new_dx = dx * cos_a - dy * sin_a;
                            let new_dy = dx * sin_a + dy * cos_a;

                            self.dx[i] += new_dx - dx;
                            self.dy[i] += new_dy - dy;
                        }
                    }
                    LiquifyMode::Pinch => {
                        if let Some(i) = self.idx(px, py) {
                            let pull_dx = cx - px as f32;
                            let pull_dy = cy - py as f32;
                            let scale = f * 0.06;
                            self.dx[i] += pull_dx * scale;
                            self.dy[i] += pull_dy * scale;
                        }
                    }
                    LiquifyMode::Expand => {
                        if let Some(i) = self.idx(px, py) {
                            let scale = f * 0.06;
                            self.dx[i] += dx * scale;
                            self.dy[i] += dy * scale;
                        }
                    }
                    LiquifyMode::Crystalize => {
                        if let Some(i) = self.idx(px, py) {
                            let rand_dx = (self.rand_float() - 0.5) * 2.0 * self.radius * 0.3;
                            let rand_dy = (self.rand_float() - 0.5) * 2.0 * self.radius * 0.3;
                            self.dx[i] += rand_dx * f * 0.4;
                            self.dy[i] += rand_dy * f * 0.4;
                        }
                    }
                    LiquifyMode::Reconstruct => {
                        if let Some(i) = self.idx(px, py) {
                            let blend = f * 0.3;
                            self.dx[i] *= 1.0 - blend;
                            self.dy[i] *= 1.0 - blend;
                        }
                    }
                    LiquifyMode::Smooth => {
                        let mut sum_dx = 0.0;
                        let mut sum_dy = 0.0;
                        let mut count = 0;

                        for ky in -1..=1 {
                            for kx in -1..=1 {
                                if let Some(ni) = self.idx(px + kx, py + ky) {
                                    sum_dx += self.dx[ni];
                                    sum_dy += self.dy[ni];
                                    count += 1;
                                }
                            }
                        }

                        if count > 0 {
                            if let Some(i) = self.idx(px, py) {
                                let avg_dx = sum_dx / count as f32;
                                let avg_dy = sum_dy / count as f32;
                                let blend = f * 0.5;
                                self.dx[i] = self.dx[i] * (1.0 - blend) + avg_dx * blend;
                                self.dy[i] = self.dy[i] * (1.0 - blend) + avg_dy * blend;
                            }
                        }
                    }
                    LiquifyMode::Edge => {
                        if let Some(i) = self.idx(px, py) {
                            let mut edge_dx = cx - px as f32;
                            let mut edge_dy = cy - py as f32;

                            let stroke_x = cx - prev_cx;
                            let stroke_y = cy - prev_cy;
                            let stroke_len_sq = stroke_x * stroke_x + stroke_y * stroke_y;

                            if stroke_len_sq > 0.001 {
                                let mut t = ((px as f32 - prev_cx) * stroke_x + (py as f32 - prev_cy) * stroke_y) / stroke_len_sq;
                                t = t.clamp(0.0, 1.0);

                                let proj_x = prev_cx + t * stroke_x;
                                let proj_y = prev_cy + t * stroke_y;

                                edge_dx = proj_x - px as f32;
                                edge_dy = proj_y - py as f32;
                            }

                            let scale = f * 0.06;
                            self.dx[i] += edge_dx * scale;
                            self.dy[i] += edge_dy * scale;
                        }
                    }
                }
            }
        }
    }

    fn sample_original(&self, sx: f32, sy: f32, out_pixel: &mut [u8; 4]) {
        let sx = sx.clamp(0.0, (self.width - 1) as f32);
        let sy = sy.clamp(0.0, (self.height - 1) as f32);

        let x0 = sx.floor() as i32;
        let y0 = sy.floor() as i32;
        let x1 = (x0 + 1).min(self.width - 1);
        let y1 = (y0 + 1).min(self.height - 1);

        let fx = sx - x0 as f32;
        let fy = sy - y0 as f32;

        let pixel = |x: i32, y: i32| -> &[u8] {
            let idx = ((y * self.width + x) * 4) as usize;
            &self.original[idx..idx + 4]
        };

        let p00 = pixel(x0, y0);
        let p10 = pixel(x1, y0);
        let p01 = pixel(x0, y1);
        let p11 = pixel(x1, y1);

        for ch in 0..4 {
            let v = p00[ch] as f32 * (1.0 - fx) * (1.0 - fy)
                + p10[ch] as f32 * fx * (1.0 - fy)
                + p01[ch] as f32 * (1.0 - fx) * fy
                + p11[ch] as f32 * fx * fy;
            out_pixel[ch] = v.clamp(0.0, 255.0) as u8;
        }
    }

    pub fn render_preview(&self, out_pixels: &mut [u8]) {
        if self.width <= 0 || self.height <= 0 || self.original.is_empty() {
            return;
        }

        let row_size = (self.width * 4) as usize;
        
        // Procesamos las filas en paralelo utilizando Rayon
        out_pixels.par_chunks_mut(row_size).enumerate().for_each(|(y, row)| {
            for x in 0..self.width {
                let i = (y as i32 * self.width + x as i32) as usize;
                let sx = x as f32 + self.dx[i];
                let sy = y as f32 + self.dy[i];

                let mut pixel = [0u8; 4];
                self.sample_original(sx, sy, &mut pixel);

                let off = x as usize * 4;
                row[off + 0] = pixel[0];
                row[off + 1] = pixel[1];
                row[off + 2] = pixel[2];
                row[off + 3] = pixel[3];
            }
        });
    }
}

// ══════════════════════════════════════════════════════════════════
//  FFI Boundary Functions (C Linkage)
// ══════════════════════════════════════════════════════════════════

#[no_mangle]
pub extern "C" fn liquify_create() -> *mut LiquifyEngineRust {
    Box::into_raw(Box::new(LiquifyEngineRust::new()))
}

#[no_mangle]
pub unsafe extern "C" fn liquify_destroy(engine: *mut LiquifyEngineRust) {
    if !engine.is_null() {
        drop(Box::from_raw(engine));
    }
}

#[no_mangle]
pub unsafe extern "C" fn liquify_begin(
    engine: *mut LiquifyEngineRust,
    source_pixels: *const u8,
    width: i32,
    height: i32,
) {
    if let Some(engine) = engine.as_mut() {
        let size = (width * height * 4) as usize;
        let pixels = slice::from_raw_parts(source_pixels, size);
        engine.begin(pixels, width, height);
    }
}

#[no_mangle]
pub unsafe extern "C" fn liquify_end(engine: *mut LiquifyEngineRust) {
    if let Some(engine) = engine.as_mut() {
        engine.end();
    }
}

#[no_mangle]
pub unsafe extern "C" fn liquify_set_parameters(
    engine: *mut LiquifyEngineRust,
    mode: i32,
    radius: f32,
    strength: f32,
    morpher: f32,
) {
    if let Some(engine) = engine.as_mut() {
        engine.mode = LiquifyMode::from(mode);
        engine.radius = radius;
        engine.strength = strength;
        engine.morpher = morpher;
    }
}

#[no_mangle]
pub unsafe extern "C" fn liquify_apply_brush(
    engine: *mut LiquifyEngineRust,
    cx: f32,
    cy: f32,
    prev_cx: f32,
    prev_cy: f32,
) {
    if let Some(engine) = engine.as_mut() {
        engine.apply_brush(cx, cy, prev_cx, prev_cy);
    }
}

#[no_mangle]
pub unsafe extern "C" fn liquify_render_preview(
    engine: *mut LiquifyEngineRust,
    out_pixels: *mut u8,
) {
    if let Some(engine) = engine.as_mut() {
        let size = (engine.width * engine.height * 4) as usize;
        let pixels = slice::from_raw_parts_mut(out_pixels, size);
        engine.render_preview(pixels);
    }
}

#[no_mangle]
pub unsafe extern "C" fn liquify_is_active(engine: *mut LiquifyEngineRust) -> bool {
    if let Some(engine) = engine.as_mut() {
        engine.active
    } else {
        false
    }
}

#[no_mangle]
pub unsafe extern "C" fn liquify_get_displacement(
    engine: *mut LiquifyEngineRust,
    out_dx: *mut f32,
    out_dy: *mut f32,
    max_len: i32,
) {
    if let Some(engine) = engine.as_mut() {
        let len = (engine.width * engine.height) as usize;
        if len <= max_len as usize {
            let dx_slice = slice::from_raw_parts_mut(out_dx, len);
            let dy_slice = slice::from_raw_parts_mut(out_dy, len);
            dx_slice.copy_from_slice(&engine.dx);
            dy_slice.copy_from_slice(&engine.dy);
        }
    }
}

// Conservamos la función de prueba para evitar romper cambios anteriores
#[no_mangle]
pub extern "C" fn test_rust_integration(a: i32, b: i32) -> i32 {
    a + b
}
