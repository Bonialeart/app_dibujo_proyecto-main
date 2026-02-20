import sys, struct, io, json, os
sys.stdout.reconfigure(encoding='utf-8', errors='replace')
from psd_tools.psd.descriptor import Descriptor

def safe_str(s):
    return str(s).replace(chr(0), '').strip()

files = [
    r'C:\Users\bonil\Downloads\20230322 brushes.abr',
    r'C:\Users\bonil\Downloads\suke2023.abr',
    r'C:\Users\bonil\Downloads\wlop_brush.abr',
]

for filepath in files:
    if not os.path.exists(filepath):
        continue
    with open(filepath, 'rb') as f:
        data = f.read()
    
    version = struct.unpack('>H', data[0:2])[0]
    png_count = data.count(b'\x89PNG')
    
    desc_idx = data.find(b'8BIMdesc')
    if desc_idx == -1:
        continue
    
    size = struct.unpack('>I', data[desc_idx+8:desc_idx+12])[0]
    desc_data = data[desc_idx+12:desc_idx+12+size]
    stream = io.BytesIO(desc_data)
    stream.read(4)
    desc = Descriptor.read(stream)
    brsh_list = desc[b'Brsh']
    
    print(f'\n=== {os.path.basename(filepath)} ===')
    print(f'Version: {version}, Total descriptor entries: {len(brsh_list)}')
    
    # Count sampled brushes in samp block
    samp_idx = data.find(b'8BIMsamp')
    if samp_idx != -1:
        pos = samp_idx + 8
        name_len = data[pos]
        pos += 1 + name_len
        if (name_len + 1) % 2 != 0:
            pos += 1
        samp_size = struct.unpack('>I', data[pos:pos+4])[0]
        pos += 4
        
        samp_data = data[pos:pos+samp_size]
        raw_markers = samp_data.count(b'\x00\x08\x00')
        rle_markers = samp_data.count(b'\x00\x08\x01')
        print(f'Samp block: {samp_size} bytes, RAW markers: {raw_markers}, RLE markers: {rle_markers}')
        
        # Try to count samples by length-prefix parsing
        sample_count = 0
        samp_pos = 0
        while samp_pos < len(samp_data) - 4:
            sample_len = struct.unpack('>I', samp_data[samp_pos:samp_pos+4])[0]
            if sample_len == 0 or sample_len > len(samp_data):
                break
            sample_count += 1
            actual_len = sample_len
            if actual_len % 2 != 0:
                actual_len += 1
            samp_pos += 4 + actual_len
        print(f'Samp entries by length-prefix: {sample_count}')
    
    # Simulation of C++ readAbrV6 rect heuristic
    rect_count = 0
    for pattern in [b'\x00\x08\x00', b'\x00\x08\x01']:
        offset = 0
        while True:
            loc = data.find(pattern, offset)
            if loc == -1:
                break
            header_start = loc - 16
            if header_start >= 0:
                t, l, b, r = struct.unpack('>iiii', data[header_start:header_start+16])
                w = r - l
                h = b - t
                if 0 < w <= 8192 and 0 < h <= 8192:
                    rect_count += 1
            offset = loc + 3
    print(f'Brush tip images found by rect heuristic (C++ V6 method): {rect_count}')
    print(f'PNG images: {png_count}')
    print()
    
    # Check brushGroup for grouping info
    groups = {}
    no_group = 0
    for i, item in enumerate(brsh_list):
        if not hasattr(item, 'keys'):
            continue
        name = safe_str(item.get(b'Nm  ', ''))
        bg = item.get(b'brushGroup', None)
        if bg is not None and hasattr(bg, 'keys'):
            gname = safe_str(bg.get(b'Nm  ', '<unnamed group>'))
            if gname not in groups:
                groups[gname] = []
            groups[gname].append(name)
        else:
            no_group += 1
    
    print(f'Brushes with group: {sum(len(v) for v in groups.values())}')
    print(f'Brushes without group: {no_group}')
    for gname, members in groups.items():
        print(f'  Group "{gname}": {len(members)} brushes')
        for m in members[:3]:
            print(f'    - {m}')
        if len(members) > 3:
            print(f'    ... and {len(members)-3} more')
    
    # Count how many have SmpI (sampled image index) vs computed brushes
    sampled_count = 0
    computed_count = 0
    for item in brsh_list:
        if not hasattr(item, 'keys'):
            continue
        brsh_inner = item.get(b'Brsh', None)
        if brsh_inner and hasattr(brsh_inner, 'keys'):
            smp_i = brsh_inner.get(b'SmpI', None)
            if smp_i is not None:
                sampled_count += 1
            else:
                computed_count += 1
        else:
            computed_count += 1
    
    print(f'\nBrush types:')
    print(f'  Sampled (have SmpI - reference samp block): {sampled_count}')
    print(f'  Computed (generated from parameters, no texture): {computed_count}')
