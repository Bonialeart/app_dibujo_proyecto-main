"""
ABR v6 samp — FINAL parser with correct structure.

Each brush in the samp block:
  [4 bytes] total_size (before UUID)
  [38 bytes] UUID string + null
  [1 byte]  misc flag
  [4 bytes] padding
  [2 bytes] version marker (0x0003)
  [4 bytes] data_size
  [16 bytes] descriptor bounds (top,left,bottom,right as int32 BE)
  [2 bytes] unknown (0x0038)
  [~230 bytes] metadata/descriptor
  [BITMAP HEADER at +263 from after_null]:
    top(4), left(4), bottom(4), right(4), depth(2), comp(1)
    if comp==1: row_sizes table (height x uint16 BE)
    pixel data (PackBits compressed or raw)
"""
import sys, struct, re, os
from PIL import Image

def u8(d,o):  return d[o]
def s16(d,o): return struct.unpack_from('>h',d,o)[0]
def u16(d,o): return struct.unpack_from('>H',d,o)[0]
def s32(d,o): return struct.unpack_from('>i',d,o)[0]
def u32(d,o): return struct.unpack_from('>I',d,o)[0]

def unpack_bits(data, expected):
    out = bytearray()
    i = 0
    while i < len(data) and len(out) < expected:
        h = struct.unpack_from('b', data, i)[0]; i += 1
        if h >= 0:
            out.extend(data[i:i+h+1]); i += h+1
        elif h != -128:
            out.extend(data[i:i+1] * (-h+1)); i += 1
    return bytes(out)

def find_bitmap_header(data, start, end):
    """Search for bitmap bounds: top(4),left(4),bottom(4),right(4),depth(2),comp(1)"""
    for off in range(start, min(end - 18, start + 600)):
        top    = s32(data, off)
        left   = s32(data, off + 4)
        bottom = s32(data, off + 8)
        right  = s32(data, off + 12)
        depth  = s16(data, off + 16)
        comp   = u8(data,  off + 18)

        height = bottom - top
        width  = right - left

        if (0 <= top <= 300 and 0 <= left <= 300 and
            1 <= height <= 16384 and 1 <= width <= 16384 and
            depth in (8, 16) and comp in (0, 1)):
            return off, top, left, bottom, right, height, width, depth, comp
    return None

def parse_abr(path, out_dir="."):
    os.makedirs(out_dir, exist_ok=True)
    data = open(path, 'rb').read()
    ver = s16(data, 0)
    sub = s16(data, 2)
    print(f"ABR v{ver} sub{sub}  size={len(data)}")

    samp_pos = data.find(b'8BIMsamp')
    if samp_pos < 0:
        print("No 8BIMsamp!"); return
    samp_size = u32(data, samp_pos + 8)
    samp_start = samp_pos + 12
    samp_end = samp_start + samp_size
    print(f"samp data: [{samp_start}..{samp_end})")

    # Find all UUIDs
    uuid_pat = re.compile(rb'\$[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\x00')
    matches = list(uuid_pat.finditer(data, samp_start, samp_end))
    print(f"Brushes found: {len(matches)}\n")

    saved = 0
    for idx, m in enumerate(matches):
        uuid_str = m.group()[1:-1].decode()
        after = m.end()  # byte after UUID null

        # Get brush block size from 4 bytes before UUID
        size_off = m.start() - 4
        if size_off >= samp_start:
            brush_total_size = u32(data, size_off)
            brush_data_end = size_off + 4 + brush_total_size
        else:
            brush_data_end = samp_end

        brush_data_end = min(brush_data_end, samp_end)

        # Search for bitmap header within the brush data
        result = find_bitmap_header(data, after, brush_data_end)
        if result is None:
            print(f"[{idx+1}] {uuid_str}: no bitmap header found, skipping")
            continue

        hdr_off, top, left, bottom, right, height, width, depth, comp = result
        hdr_rel = hdr_off - after

        print(f"[{idx+1}] {uuid_str}: {width}x{height} depth={depth} comp={comp} "
              f"hdr@+{hdr_rel}", end="")

        # Pixel data starts right after the 19-byte header (4+4+4+4+2+1)
        bpp = depth // 8
        expected_raw = width * height * bpp
        pixel_meta = hdr_off + 19

        if comp == 1:
            table_end = pixel_meta + height * 2
            if table_end > brush_data_end:
                print(" -- row table overflow, skip")
                continue
            row_sizes = [u16(data, pixel_meta + r*2) for r in range(height)]
            comp_total = sum(row_sizes)
            pixel_start = table_end
            pixel_end = min(pixel_start + comp_total, brush_data_end)
            compressed = data[pixel_start:pixel_end]
            raw = unpack_bits(compressed, expected_raw)
        else:
            pixel_start = pixel_meta
            pixel_end = min(pixel_start + expected_raw, brush_data_end)
            raw = data[pixel_start:pixel_end]

        if len(raw) < expected_raw:
            raw = raw + bytes(expected_raw - len(raw))

        # Create image
        if depth == 8:
            img = Image.frombytes('L', (width, height), raw[:expected_raw])
        else:
            px8 = bytearray(width * height)
            for i in range(width * height):
                px8[i] = raw[i*2] if i*2 < len(raw) else 0
            img = Image.frombytes('L', (width, height), bytes(px8))

        fname = os.path.join(out_dir, f"brush_{idx+1}_{width}x{height}.png")
        img.save(fname)
        print(f" -> {fname}")
        saved += 1

    print(f"\nTotal saved: {saved}/{len(matches)}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python abr_debug.py <file.abr> [output_dir]")
    else:
        out = sys.argv[2] if len(sys.argv) > 2 else "."
        parse_abr(sys.argv[1], out)
