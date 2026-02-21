"""
ArtFlow Studio - ABR Parser (V5 - FULL METADATA)
=================================================
Extrae pinceles completos de archivos .abr de Adobe Photoshop.

Soporta:
  1. V6+/V10 Modernos: Minería de PNG + Descriptor Metadata
  2. V2 Intermedios: Deep Scan RLE/Raw (32-bit coords)
  3. V1 Ancestrales: Parseo Estructurado (16-bit coords)

Extrae por cada pincel:
  - Nombre real del pincel
  - Textura del tip (imagen PIL)
  - Tamaño (diámetro) predeterminado
  - Spacing
  - Hardness, Angle, Roundness
  - Flow, Opacity, Wetness, Scatter
  - Dynamics (presión→tamaño, presión→opacidad, etc.)
"""

import io
import struct
import re
import sys
import os
from PIL import Image


# ============================================================================
#  DESCRIPTOR PARSER - Estructura interna de Photoshop
# ============================================================================

class DescriptorParser:
    """
    Parsea los bloques de tipo Descriptor de Adobe (8BIMdesc) que contienen
    los metadatos de cada pincel: nombre, spacing, diameter, hardness, etc.
    
    Usa el enfoque de MorrowShore (marcadores de tipo) mejorado con
    delimitación por pincel basada en 'Nm  ' (nombre).
    """

    TYPE_MARKERS = {
        b'UntF': 'UntF',  # Unit Float (e.g. #Pxl, #Prc, #Ang)
        b'bool': 'bool',  # Boolean
        b'long': 'long',  # 32-bit integer
        b'doub': 'doub',  # 64-bit double
        b'enum': 'enum',  # Enumeration
        b'TEXT': 'TEXT',  # Unicode text
        b'Objc': 'Objc',  # Sub-object (curves, dynamics groups)
        b'VlLs': 'VlLs',  # Value List
    }
    
    # Mapeo de claves internas de Photoshop a nombres legibles
    KEY_MAP = {
        'Nm  ': 'name',
        'Dmtr': 'diameter',       # Diámetro del pincel (px)
        'Hrdn': 'hardness',       # Dureza (%)
        'Angl': 'angle',          # Ángulo de rotación
        'Rndn': 'roundness',      # Redondez (%)
        'Spcn': 'spacing',        # Espaciado (%)
        'FlwR': 'flow',           # Flujo
        'Opct': 'opacity',        # Opacidad
        'Wtns': 'wetness',        # Humedad
        'jitter': 'jitter',
        'szJt': 'size_jitter',    # Jitter de tamaño
        'opJt': 'opacity_jitter', # Jitter de opacidad
        'flJt': 'flow_jitter',
        'Sctr': 'scatter',        # Dispersión
        'Cnt ': 'count',          # Conteo
        'IntC': 'intensity',
        'useS': 'use_scatter',
        'useTipDynamics': 'use_tip_dynamics',
        'szVr': 'size_variance',
        'mnmS': 'minimum_size',   # Tamaño mínimo (%)
        'opVr': 'opacity_variance',
        'mnmO': 'minimum_opacity',
        'flVr': 'flow_variance',
        'Angl': 'angle',
        'Rndm': 'randomize',
        'BckC': 'back_color',
        'Sftn': 'softness',
        'Nois': 'noise',
        'WtEd': 'wet_edges',
        'useP': 'use_paint_dynamics',
        'pnTr': 'pen_tilt',
        'TxR2': 'texture_2',
        'MdID': 'md_id',   # SampledBrush index → for correlating with samp images
        'SmpI': 'sampled_index',
    }

    @staticmethod
    def parse_descriptor_block(data):
        """
        Parsea un bloque de datos binarios buscando los marcadores de tipo de Adobe.
        Retorna una lista de tuplas (key, type, value) con TODOS los parámetros encontrados.
        """
        results = []
        L = len(data)
        pos = 0

        while pos < L - 4:
            found_marker = False

            for marker_bytes, marker_name in DescriptorParser.TYPE_MARKERS.items():
                if data[pos:pos+len(marker_bytes)] != marker_bytes:
                    continue

                key = DescriptorParser._find_key_before(data, pos)

                if marker_name == 'TEXT':
                    if pos + 8 <= L:
                        length = struct.unpack('>I', data[pos+4:pos+8])[0]
                        text_start = pos + 8
                        text_end = min(text_start + length * 2, L)
                        try:
                            text = data[text_start:text_end].decode('utf-16-be').rstrip('\x00')
                        except:
                            text = data[text_start:text_end].decode('utf-8', errors='replace').rstrip('\x00')
                        results.append((key, 'TEXT', text))
                        pos = text_end
                        found_marker = True
                        break

                elif marker_name == 'UntF':
                    if pos + 16 <= L:
                        unit_code = data[pos+4:pos+8].decode('ascii', errors='ignore').strip()
                        val = struct.unpack('>d', data[pos+8:pos+16])[0]
                        results.append((key, f'UntF#{unit_code}', val))
                        pos += 16
                        found_marker = True
                        break

                elif marker_name == 'long':
                    if pos + 8 <= L:
                        val = struct.unpack('>i', data[pos+4:pos+8])[0]
                        results.append((key, 'long', val))
                        pos += 8
                        found_marker = True
                        break

                elif marker_name == 'bool':
                    if pos + 5 <= L:
                        val = bool(data[pos+4])
                        results.append((key, 'bool', val))
                        pos += 5
                        found_marker = True
                        break

                elif marker_name == 'doub':
                    if pos + 12 <= L:
                        val = struct.unpack('>d', data[pos+4:pos+12])[0]
                        results.append((key, 'doub', val))
                        pos += 12
                        found_marker = True
                        break

                elif marker_name == 'enum':
                    if pos + 12 <= L:
                        enum_type = data[pos+8:pos+12].decode('ascii', errors='ignore').rstrip('\x00')
                        if not enum_type:
                            enum_type = data[pos+4:pos+8].decode('ascii', errors='ignore').rstrip('\x00')

                        enum_pos = pos + 12
                        while enum_pos < L and data[enum_pos] in [0, 32]:
                            enum_pos += 1

                        enum_value = ""
                        while enum_pos < L and 32 <= data[enum_pos] <= 126:
                            c = chr(data[enum_pos])
                            if c.isalnum() or c in ' .-_':
                                enum_value += c
                            enum_pos += 1

                        enum_value = enum_value.strip()
                        if enum_value:
                            results.append((key, 'enum', f"{enum_type}.{enum_value}"))
                        else:
                            results.append((key, 'enum', enum_type))

                        # Avanzar al siguiente marcador conocido
                        next_pos = L
                        for next_marker in DescriptorParser.TYPE_MARKERS.keys():
                            found_next = data.find(next_marker, enum_pos)
                            if found_next != -1:
                                next_pos = min(next_pos, found_next)
                        pos = next_pos
                        found_marker = True
                        break

                elif marker_name == 'Objc':
                    # Buscar nombre de clase después de Objc
                    obj_pos = pos + 4
                    class_found = False
                    while obj_pos < min(L - 4, pos + 100):
                        if 97 <= data[obj_pos] <= 122:  # lowercase letter
                            class_name = ""
                            temp_pos = obj_pos
                            while temp_pos < L and (
                                (97 <= data[temp_pos] <= 122) or   # lowercase
                                (65 <= data[temp_pos] <= 90) or    # uppercase
                                (48 <= data[temp_pos] <= 57) or    # numbers
                                data[temp_pos] in [95]             # underscore
                            ):
                                class_name += chr(data[temp_pos])
                                temp_pos += 1

                            if len(class_name) > 2:
                                results.append((key, 'Objc', class_name))
                                pos = temp_pos
                                class_found = True
                                break
                        obj_pos += 1

                    if not class_found:
                        results.append((key, 'Objc', 'unknown'))
                        pos += 4
                    found_marker = True
                    break

                elif marker_name == 'VlLs':
                    # Saltar listas de valores (difíciles de parsear sin contexto)
                    next_pos = L
                    for next_marker in DescriptorParser.TYPE_MARKERS.keys():
                        found_next = data.find(next_marker, pos + 4)
                        if found_next != -1:
                            next_pos = min(next_pos, found_next)
                    results.append((key, 'VlLs', 'list'))
                    pos = next_pos
                    found_marker = True
                    break

            if not found_marker:
                pos += 1

        return results

    @staticmethod
    def _find_key_before(data, pos, max_lookback=50):
        """Busca la clave ASCII imprimible que precede al marcador."""
        start = max(0, pos - max_lookback)
        segment = data[start:pos]

        key = ""
        for i in range(len(segment) - 1, -1, -1):
            if 32 <= segment[i] <= 126:
                key = chr(segment[i]) + key
            else:
                break

        return key.strip()

    @staticmethod
    def split_into_brushes(flat_params):
        """
        Toma la lista plana de (key, type, value) y la divide en brushes individuales.
        Cada brush comienza con un key 'Nm  ' de tipo TEXT (el nombre del pincel).
        """
        brushes = []
        current = None

        for key, ptype, value in flat_params:
            # Las claves internas tienen 4 chars (ej: "Nm  ", "Dmtr", "Hrdn")
            # Buscamos patrones de nombre de pincel
            if key.endswith('Nm  ') and ptype == 'TEXT':
                if current is not None:
                    brushes.append(current)
                current = {'name': value, '_raw_params': []}
            
            if current is not None:
                current['_raw_params'].append((key, ptype, value))
                mapped_key = DescriptorParser.KEY_MAP.get(key[-4:].strip() if len(key) >= 4 else key, None)
                
                if mapped_key and mapped_key != 'name':
                    # Extraer valor numérico
                    if ptype.startswith('UntF'):
                        current[mapped_key] = value
                    elif ptype in ('long', 'doub', 'bool'):
                        current[mapped_key] = value
                    elif ptype == 'enum':
                        current[mapped_key] = value
                    elif ptype == 'TEXT':
                        current[mapped_key] = value

        if current is not None:
            brushes.append(current)

        return brushes


# ============================================================================
#  BRUSH TIP - Resultado individual
# ============================================================================

class BrushTip:
    """Representa un pincel individual extraído de un archivo ABR."""
    
    def __init__(self, name, pil_image, params=None):
        self.name = name
        self.pil_image = pil_image
        self.params = params or {}
        
        # Imagen
        self.width = pil_image.width
        self.height = pil_image.height
        self.size = max(self.width, self.height)
        
        # Parámetros extraídos (con defaults seguros)
        self.diameter = self.params.get('diameter', float(self.size))
        self.spacing = self.params.get('spacing', 25.0)  # % del diámetro
        self.hardness = self.params.get('hardness', 100.0)  # %
        self.angle = self.params.get('angle', 0.0)  # degrees
        self.roundness = self.params.get('roundness', 100.0)  # %
        self.flow = self.params.get('flow', 100.0)  # %
        self.opacity = self.params.get('opacity', 100.0)  # %
        self.scatter = self.params.get('scatter', 0.0)
        self.wetness = self.params.get('wetness', 0.0)
        
        # Dynamics
        self.size_jitter = self.params.get('size_jitter', 0.0)
        self.opacity_jitter = self.params.get('opacity_jitter', 0.0)
        self.minimum_size = self.params.get('minimum_size', 0.0)
        self.minimum_opacity = self.params.get('minimum_opacity', 0.0)
        
    def get_image(self):
        return self.pil_image
    
    def summary(self):
        """Resumen textual del pincel."""
        lines = [f"  Name: {self.name}"]
        lines.append(f"  Size: {self.width}x{self.height} px, Diameter: {self.diameter:.0f}")
        lines.append(f"  Spacing: {self.spacing:.1f}%, Hardness: {self.hardness:.1f}%")
        lines.append(f"  Angle: {self.angle:.1f}°, Roundness: {self.roundness:.1f}%")
        if self.flow != 100.0:
            lines.append(f"  Flow: {self.flow:.1f}%")
        if self.scatter > 0:
            lines.append(f"  Scatter: {self.scatter:.1f}")
        if self.size_jitter > 0:
            lines.append(f"  Size Jitter: {self.size_jitter:.1f}%")
        return "\n".join(lines)


# ============================================================================
#  PARSER RESULT
# ============================================================================

class ParserResult:
    def __init__(self):
        self.brushes = []         # List[BrushTip]
        self.metadata = []        # Lista de dicts con metadatos del descriptor
        self.version = 0
        self.total_in_file = 0    # Cuántos pinceles dice tener el archivo


# ============================================================================
#  ABR PARSER - Motor Principal
# ============================================================================

class ABRParser:
    """
    UNIVERSAL ABR PARSER (V5 - FULL METADATA)
    ==========================================
    Extrae pinceles completos: imagen + nombre + todos los parámetros.
    
    Pipeline:
      1. Parsear 8BIMdesc → extraer metadatos de cada pincel
      2. Extraer texturas (PNG mining o samp RAW/RLE)
      3. Correlacionar: emparejar cada textura con su metadata
      4. Crear BrushTips completos
    """

    # Alias for external access
    BrushTip = BrushTip

    @staticmethod
    def parse(filepath):
        """
        Punto de entrada principal. Parsea un archivo .abr completo.
        Retorna un ParserResult con todos los pinceles encontrados.
        """
        print(f"\n{'='*60}")
        print(f"[ABR PARSER] Analizando: {filepath}")
        print(f"{'='*60}")
        
        result = ParserResult()

        with open(filepath, 'rb') as f:
            data = f.read()

        if len(data) < 4:
            print("[ABR] ERROR: Archivo demasiado pequeño.")
            return result

        # --- FASE 1: Leer versión del archivo ---
        version = struct.unpack('>h', data[:2])[0]
        result.version = version
        print(f"[ABR] Versión ABR: {version}")

        # --- FASE 2: Extraer METADATOS del bloque descriptor ---
        brush_metadata = ABRParser._extract_metadata(data)
        result.metadata = brush_metadata
        result.total_in_file = len(brush_metadata)
        
        if brush_metadata:
            print(f"[ABR] Metadatos extraídos: {len(brush_metadata)} pinceles")
            for i, md in enumerate(brush_metadata):
                print(f"  [{i}] {md.get('name', '???')} | "
                      f"Ø{md.get('diameter', '?')} | "
                      f"Spc:{md.get('spacing', '?')}% | "
                      f"Hrd:{md.get('hardness', '?')}%")
        else:
            print("[ABR] No se encontraron metadatos de descriptor.")

        # --- FASE 3: Extraer TEXTURAS ---
        textures = []

        # Estrategia A: PNG Mining (para pinceles HD modernos)
        if b'\x89PNG' in data:
            print("[ABR] Detectada firma PNG. Ejecutando minería de PNG...")
            textures = ABRParser._extract_png_textures(data)
            print(f"[ABR] PNGs extraídos: {len(textures)}")

        # Estrategia B: Lectura estructural de samp block
        if not textures:
            print("[ABR] Intentando lectura estructural V1/V2/V6...")
            if version == 1:
                textures = ABRParser._extract_v1_textures(data)
            elif version in (2, 6, 10):
                textures = ABRParser._extract_samp_textures(data)

        # Estrategia C: Deep Scan (fuerza bruta)
        if not textures:
            print("[ABR] Intentando deep scan de fuerza bruta...")
            textures = ABRParser._deep_scan_textures(data)

        print(f"[ABR] Total texturas extraídas: {len(textures)}")

        # --- FASE 4: CORRELACIÓN - Emparejar metadatos con texturas ---
        result.brushes = ABRParser._correlate(brush_metadata, textures, filepath)

        print(f"\n[ABR] === RESULTADO FINAL ===")
        print(f"[ABR] Total pinceles completos: {len(result.brushes)}")
        for b in result.brushes:
            print(b.summary())

        return result

    # ========================================================================
    #  FASE 2: Extraer Metadatos del Descriptor
    # ========================================================================

    @staticmethod
    def _extract_metadata(data):
        """Busca el bloque 8BIMdesc y parsea los metadatos de cada pincel."""
        desc_idx = data.find(b'8BIMdesc')
        if desc_idx == -1:
            # Intentar con 'desc' solo (algunos ABR lo usan sin 8BIM)
            desc_idx = data.find(b'desc')
            if desc_idx == -1:
                return []
            desc_data_start = desc_idx + 4
        else:
            desc_data_start = desc_idx + 8

        # Leer tamaño del bloque
        if desc_data_start + 4 > len(data):
            return []
        
        desc_size = struct.unpack('>I', data[desc_data_start:desc_data_start+4])[0]
        desc_data = data[desc_data_start + 4: desc_data_start + 4 + desc_size]

        if len(desc_data) < 10:
            return []

        print(f"[ABR] Bloque descriptor encontrado en offset {desc_idx}, tamaño: {desc_size}")

        # Parsear los parámetros planos
        flat_params = DescriptorParser.parse_descriptor_block(desc_data)
        
        # Dividir en pinceles individuales
        brush_dicts = DescriptorParser.split_into_brushes(flat_params)

        return brush_dicts

    # ========================================================================
    #  FASE 3A: Extraer texturas PNG (Modernos)
    # ========================================================================

    @staticmethod
    def _extract_png_textures(data):
        """Extrae todas las imágenes PNG embebidas en el archivo."""
        textures = []
        png_sig = b'\x89PNG\r\n\x1a\n'
        iend_sig = b'IEND'
        offset = 0
        
        while True:
            start = data.find(png_sig, offset)
            if start == -1:
                break
            
            iend = data.find(iend_sig, start)
            if iend == -1:
                break
            
            end = iend + 8  # IEND chunk size (4+4+CRC)
            
            try:
                pil_img = Image.open(io.BytesIO(data[start:end]))
                pil_img.load()
                
                # Extraer nombre cercano (heurístico)
                name = ABRParser._extract_name_near(data, start)

                textures.append({
                    'image': pil_img,
                    'name': name,
                    'offset': start,
                })
            except Exception as e:
                pass
            
            offset = end
        
        return textures

    @staticmethod
    def _extract_name_near(data, png_start):
        """Intenta extraer un nombre de pincel cerca de la posición PNG."""
        try:
            chunk = data[max(0, png_start-500):png_start]
            # Buscar secuencia TEXT + length + UTF-16BE
            text_marker = b'TEXT'
            idx = chunk.rfind(text_marker)
            if idx != -1 and idx + 8 < len(chunk):
                length = struct.unpack('>I', chunk[idx+4:idx+8])[0]
                if 0 < length < 200:
                    text_data = chunk[idx+8:idx+8+length*2]
                    name = text_data.decode('utf-16-be', errors='ignore').rstrip('\x00').strip()
                    if len(name) > 1:
                        return name
            
            # Fallback: buscar cadenas UTF-16 legibles
            text = chunk.decode('utf-16-be', errors='ignore')
            clean = "".join([c for c in text if c.isprintable() and (c.isalnum() or c in ' -_()')])
            matches = re.findall(r'[a-zA-Z0-9\s\-\_\(\)]{3,}', clean)
            if matches:
                return matches[-1].strip()
        except:
            pass
        return None

    # ========================================================================
    #  FASE 3B: Extraer texturas V1 (Ancestrales)
    # ========================================================================

    @staticmethod
    def _extract_v1_textures(data):
        """Parseo estructurado para ABR versión 1."""
        textures = []
        stream = io.BytesIO(data)
        
        version = struct.unpack('>h', stream.read(2))[0]
        if version != 1:
            return textures
        
        count = struct.unpack('>h', stream.read(2))[0]
        print(f"[ABR V1] Pinceles declarados: {count}")

        for i in range(count):
            try:
                brush_type = struct.unpack('>h', stream.read(2))[0]
                block_size = struct.unpack('>I', stream.read(4))[0]
                start_pos = stream.tell()

                if brush_type == 1:  # Computed brush
                    stream.seek(block_size, 1)
                    continue
                elif brush_type == 2:  # Sampled brush
                    misc_size = struct.unpack('>I', stream.read(4))[0]
                    stream.seek(misc_size, 1)
                    
                    spacing = struct.unpack('>h', stream.read(2))[0]
                    
                    # Pascal string (nombre)
                    name_len = ord(stream.read(1))
                    name = stream.read(name_len).decode('latin-1', errors='ignore')
                    if (name_len + 1) % 2 != 0:
                        stream.read(1)  # padding
                    
                    stream.read(2)  # Antialias + misc

                    # V1 coords son shorts de 16-bit
                    top, left, bottom, right = (
                        struct.unpack('>h', stream.read(2))[0],
                        struct.unpack('>h', stream.read(2))[0],
                        struct.unpack('>h', stream.read(2))[0],
                        struct.unpack('>h', stream.read(2))[0],
                    )
                    width = right - left
                    height = bottom - top

                    depth = struct.unpack('>h', stream.read(2))[0]
                    compression = ord(stream.read(1))

                    if 0 < width < 4096 and 0 < height < 4096:
                        img_data = ABRParser._read_bitmap(stream, width, height, compression)
                        if img_data and len(img_data) >= width * height:
                            img = Image.frombytes('L', (width, height), bytes(img_data[:width*height]))
                            bg = Image.new("RGB", (width, height), (255, 255, 255))
                            final = Image.merge("RGBA", (*bg.split(), img))
                            textures.append({
                                'image': final,
                                'name': name if name else None,
                                'spacing': spacing,
                                'offset': start_pos, 
                            })

                # Asegurar avance correcto
                expected_end = start_pos + block_size
                if stream.tell() < expected_end:
                    stream.seek(expected_end)
                    
            except Exception as e:
                print(f"[ABR V1] Error en bloque {i}: {e}")
                break

        return textures

    # ========================================================================
    #  FASE 3C: Extraer texturas del bloque samp (V6/V10)
    # ========================================================================

    @staticmethod
    def _extract_samp_textures(data):
        """Extrae las imágenes del bloque 8BIMsamp."""
        textures = []
        
        samp_idx = data.find(b'8BIMsamp')
        if samp_idx == -1:
            print("[ABR] No se encontró bloque 'samp'.")
            return ABRParser._deep_scan_textures(data)

        stream_start = samp_idx + 8  # Después de "8BIMsamp"
        
        # Saltar Pascal String del nombre del bloque
        if stream_start >= len(data):
            return textures
        name_len = data[stream_start]
        stream_start += 1 + name_len
        if (name_len + 1) % 2 != 0:
            stream_start += 1

        # Tamaño del bloque samp
        if stream_start + 4 > len(data):
            return textures
        section_size = struct.unpack('>I', data[stream_start:stream_start+4])[0]
        stream_start += 4

        section_data = data[stream_start:stream_start + section_size]
        print(f"[ABR] Bloque 'samp' encontrado, tamaño: {section_size} bytes")

        # Buscar cabeceras de imagen dentro del bloque samp
        # Cada imagen tiene: Top(4), Left(4), Bottom(4), Right(4), Depth(2), Compression(1)
        stream = io.BytesIO(section_data)
        
        patterns = [b'\x00\x08\x01', b'\x00\x08\x00']  # depth=8 + RLE/RAW
        
        for pattern in patterns:
            offset = 0
            while True:
                loc = section_data.find(pattern, offset)
                if loc == -1:
                    break

                try:
                    header_start = loc - 16
                    if header_start >= 0:
                        stream.seek(header_start)
                        t, l, b, r = struct.unpack('>llll', stream.read(16))
                        w, h = r - l, b - t

                        if 0 < w < 8192 and 0 < h < 8192:
                            stream.seek(loc + 3)
                            compression = pattern[2]
                            img_data = ABRParser._read_bitmap(stream, w, h, compression)

                            if img_data and len(img_data) >= w * h:
                                img = Image.frombytes('L', (w, h), bytes(img_data[:w*h]))
                                img = img.point(lambda x: 255 - x)  # Invertir
                                bg = Image.new("RGB", (w, h), (255, 255, 255))
                                final = Image.merge("RGBA", (*bg.split(), img))
                                textures.append({
                                    'image': final,
                                    'name': None,
                                    'offset': samp_idx + header_start,
                                })
                                offset = stream.tell()
                                continue
                except:
                    pass

                offset = loc + 3

        return textures

    # ========================================================================
    #  FASE 3D: Deep Scan (Fuerza Bruta)
    # ========================================================================

    @staticmethod
    def _deep_scan_textures(data):
        """Escaneo de fuerza bruta buscando patrones RAW/RLE en todo el archivo."""
        textures = []
        stream = io.BytesIO(data)
        
        patterns = [b'\x00\x08\x01', b'\x00\x08\x00']

        for pattern in patterns:
            offset = 0
            while True:
                loc = data.find(pattern, offset)
                if loc == -1:
                    break

                try:
                    header_start = loc - 16
                    if header_start >= 0:
                        stream.seek(header_start)
                        t, l, b, r = struct.unpack('>llll', stream.read(16))
                        w, h = r - l, b - t

                        if 0 < w < 4096 and 0 < h < 4096:
                            stream.seek(loc + 3)
                            compression = pattern[2]
                            img_data = ABRParser._read_bitmap(stream, w, h, compression)

                            if img_data and len(img_data) >= w * h:
                                img = Image.frombytes('L', (w, h), bytes(img_data[:w*h]))
                                bg = Image.new("RGB", (w, h), (255, 255, 255))
                                final = Image.merge("RGBA", (*bg.split(), img))
                                textures.append({
                                    'image': final,
                                    'name': f"Scanned Brush {len(textures)+1}",
                                    'offset': loc,
                                })
                                offset = stream.tell()
                                continue
                except:
                    pass

                offset = loc + 3

        return textures

    # ========================================================================
    #  FASE 4: Correlación Metadatos ↔ Texturas
    # ========================================================================

    @staticmethod
    def _correlate(metadata_list, texture_list, filepath):
        """
        Empareja metadatos (del descriptor) con texturas (de samp/PNG).
        
        Reglas:
          - Si ambas listas tienen el mismo tamaño → emparejar 1:1
          - Si hay más texturas que metadatos → crear tips genéricos para las extras
          - Si hay más metadatos que texturas → metadatos sin imagen se ignoran
        """
        brushes = []
        filename = os.path.splitext(os.path.basename(filepath))[0]

        n_meta = len(metadata_list)
        n_tex = len(texture_list)

        if n_meta > 0 and n_tex > 0:
            # Emparejar por índice
            max_idx = max(n_meta, n_tex)
            for i in range(max_idx):
                if i < n_tex:
                    tex = texture_list[i]
                    img = tex['image']
                    
                    params = {}
                    name_from_tex = tex.get('name')

                    if i < n_meta:
                        md = metadata_list[i]
                        params = {k: v for k, v in md.items() if k != '_raw_params' and k != 'name'}
                        name = md.get('name', name_from_tex or f"{filename} {i+1}")
                    else:
                        name = name_from_tex or f"{filename} {i+1}"
                    
                    # Si V1, incorporar spacing del bloque binario
                    if 'spacing' in tex and 'spacing' not in params:
                        params['spacing'] = tex['spacing']

                    brushes.append(BrushTip(name, img, params))

        elif n_tex > 0:
            # Solo texturas (sin metadatos del descriptor)
            for i, tex in enumerate(texture_list):
                name = tex.get('name') or f"{filename} {i+1}"
                params = {}
                if 'spacing' in tex:
                    params['spacing'] = tex['spacing']
                brushes.append(BrushTip(name, tex['image'], params))

        elif n_meta > 0:
            # Solo metadatos (sin texturas) - crear placeholder
            print(f"[ABR] ADVERTENCIA: {n_meta} metadatos sin texturas correspondientes.")
            for md in metadata_list:
                img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
                from PIL import ImageDraw
                draw = ImageDraw.Draw(img)
                draw.ellipse([8, 8, 56, 56], fill=(128, 128, 128, 200))
                params = {k: v for k, v in md.items() if k != '_raw_params' and k != 'name'}
                brushes.append(BrushTip(md.get('name', '?'), img, params))

        if not brushes:
            print("[ABR] (!) Archivo completamente ilegible. Creando fallback.")
            img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
            from PIL import ImageDraw
            draw = ImageDraw.Draw(img)
            draw.text((10, 25), "?", fill=(255, 0, 0, 255))
            brushes.append(BrushTip("Error", img))

        return brushes

    # ========================================================================
    #  UTILIDADES: Lectura de bitmaps RAW/RLE
    # ========================================================================

    @staticmethod
    def _read_bitmap(stream, width, height, compression):
        """Lee un bitmap RAW o RLE (PackBits) del stream."""
        if compression == 0:  # RAW
            return stream.read(width * height)
        elif compression == 1:  # RLE (PackBits)
            rle_data = bytearray()
            for row in range(height):
                row_data = bytearray()
                while len(row_data) < width:
                    try:
                        header_raw = stream.read(1)
                        if not header_raw:
                            break
                        header = header_raw[0]
                        if header > 127:
                            header -= 256

                        if 0 <= header <= 127:
                            cnt = header + 1
                            chunk = stream.read(cnt)
                            if not chunk:
                                break
                            row_data.extend(chunk)
                        elif -127 <= header <= -1:
                            cnt = -header + 1
                            val = stream.read(1)
                            if not val:
                                break
                            row_data.extend(val * cnt)
                        # -128 es noop
                    except:
                        break
                rle_data.extend(row_data[:width])
            return rle_data
        return None


# ============================================================================
#  CLI - Uso desde línea de comandos
# ============================================================================

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python abr_parser.py <archivo.abr> [--save-tips <directorio>]")
        sys.exit(1)

    filepath = sys.argv[1]
    save_dir = None
    
    if '--save-tips' in sys.argv:
        idx = sys.argv.index('--save-tips')
        if idx + 1 < len(sys.argv):
            save_dir = sys.argv[idx + 1]

    result = ABRParser.parse(filepath)

    print(f"\n{'='*60}")
    print(f"RESUMEN: {len(result.brushes)} pinceles en archivo v{result.version}")
    print(f"{'='*60}")
    
    for i, brush in enumerate(result.brushes):
        print(f"\n--- Pincel {i+1} ---")
        print(brush.summary())
        
        if save_dir:
            os.makedirs(save_dir, exist_ok=True)
            safe_name = re.sub(r'[^\w\-]', '_', brush.name)
            out_path = os.path.join(save_dir, f"{safe_name}.png")
            brush.pil_image.save(out_path)
            print(f"  → Guardado en: {out_path}")
