"""
Correct samp block parsing for ABR V6/V10 files.
The samp block contains brush tip images (sampled brushes).

Structure of samp block (V6.2):
  - After "8BIMsamp" comes:
    - 4 bytes: total samp block size (big-endian)
    - Individual samples, each structured as:
      - UUID-based header (variable length) OR length-prefixed
      
Actually, from the GIMP source code and other reverse engineering:

The samp block structure (V6.2 subversions):
  For each brush sample in the block:
    - 4 bytes: sample data length
    - UUID string (Pascal-style, with length)
    - Some flags
    - Then the image data:
      - 4 bytes: always 8 (depth declaration?)
      - 16 bytes: rect (T,L,B,R as int32 BE)
      - 2 bytes: depth (bits per channel, usually 8)
      - 1 byte: compression (0=raw, 1=RLE)
      - pixel data (raw or RLE compressed)
"""
import sys, struct, os
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

def parse_samp_block_v6(data, samp_offset, samp_end):
    """
    Parse the samp block for V6/V10 ABR files.
    Returns list of (width, height, image_data_offset, compression, depth) tuples.
    """
    samples = []
    
    # The samp data area: from samp_offset to samp_end
    samp_data = data[samp_offset:samp_end]
    
    # Strategy: scan for the image header pattern
    # Every image in the samp block starts with:
    #   [some_length(4B)] [00 00 00 08] rect(16B) depth(2B) compression(1B)
    # The critical marker is [length(4)] [00 00 00 08] [rect...]
    
    # We look for the pattern of valid rect preceded by 0x00000008
    pos = 0
    while pos < len(samp_data) - 23:  # need at least 23 bytes for header
        # Look for the 0x00000008 marker
        if samp_data[pos:pos+4] == b'\x00\x00\x00\x08':
            # Check if this is followed by a valid rect
            rect_start = pos + 4
            if rect_start + 18 <= len(samp_data):
                t, l, b, r = struct.unpack('>iiii', samp_data[rect_start:rect_start+16])
                w = r - l
                h = b - t
                
                if 0 < w <= 8192 and 0 < h <= 8192:
                    depth = struct.unpack('>H', samp_data[rect_start+16:rect_start+18])[0]
                    
                    if depth in (1, 8, 16):
                        comp_offset = rect_start + 18
                        if comp_offset < len(samp_data):
                            comp = samp_data[comp_offset]
                            if comp in (0, 1):
                                pixel_data_start = comp_offset + 1
                                
                                # For the sample_len preceding this, go back 4 bytes from \x00\x00\x00\x08
                                sample_len = 0
                                if pos >= 4:
                                    sample_len = struct.unpack('>I', samp_data[pos-4:pos])[0]
                                
                                samples.append({
                                    'width': w,
                                    'height': h,
                                    'depth': depth,
                                    'compression': comp,
                                    'pixel_data_offset': samp_offset + pixel_data_start,
                                    'sample_len': sample_len,
                                    'samp_local_offset': pos,
                                })
                                
                                # Skip past the pixel data to find next sample
                                if comp == 0:
                                    # Raw: w * h * (depth/8) bytes
                                    raw_size = w * h * (depth // 8)
                                    pos = pixel_data_start + raw_size
                                    continue
                                elif comp == 1:
                                    # RLE: first 2*h bytes are row lengths, then compressed data
                                    # We can't easily skip, so just move past and keep scanning
                                    pos = pixel_data_start + 2 * h  
                                    # Actually we need to read the row lengths to know total size
                                    # For now just continue scanning
                                    continue
        pos += 1
    
    return samples


# Test on all files
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
    subver = struct.unpack('>H', data[2:4])[0]
    
    print(f'\n{"="*70}')
    print(f'{os.path.basename(filepath)} (v{version}.{subver}, {len(data)} bytes)')
    print(f'{"="*70}')
    
    # Find all 8BIM blocks
    offset = 4
    all_blocks = []
    while offset < len(data) - 8:
        if data[offset:offset+4] != b'8BIM':
            break
        key = data[offset+4:offset+8].decode('ascii', errors='replace')
        block_size = struct.unpack('>I', data[offset+8:offset+12])[0]
        data_start = offset + 12
        
        next_pos = data.find(b'8BIM', offset + 8)
        actual_size = (next_pos - data_start) if next_pos != -1 else (len(data) - data_start)
        
        all_blocks.append({'offset': offset, 'key': key, 'data_start': data_start, 'actual_size': actual_size})
        offset = next_pos if next_pos != -1 else len(data)
    
    print(f'Blocks: {[(b["key"], b["actual_size"]) for b in all_blocks]}')
    
    # Parse samp and IDNA blocks (both may contain brush tip images)
    total_samples = []
    
    for block in all_blocks:
        if block['key'] in ('samp', 'IDNA'):
            samples = parse_samp_block_v6(data, block['data_start'], block['data_start'] + block['actual_size'])
            print(f'\n{block["key"]} block: {block["actual_size"]} bytes, {len(samples)} brush samples found')
            
            for i, s in enumerate(samples[:10]):
                print(f'  [{i}] {s["width"]}x{s["height"]} depth={s["depth"]} comp={s["compression"]}')
            if len(samples) > 10:
                print(f'  ... {len(samples)-10} more')
            
            total_samples.extend(samples)
    
    print(f'\nTOTAL brush tip samples: {len(total_samples)}')
    
    # Check descriptor count
    from psd_tools.psd.descriptor import Descriptor
    import io
    
    desc_idx = data.find(b'8BIMdesc')
    if desc_idx != -1:
        size = struct.unpack('>I', data[desc_idx+8:desc_idx+12])[0]
        desc_data = data[desc_idx+12:desc_idx+12+size]
        stream = io.BytesIO(desc_data)
        stream.read(4)
        desc = Descriptor.read(stream)
        brsh_list = desc[b'Brsh']
        print(f'Descriptor brush entries: {len(brsh_list)}')
        
        # Count which ones reference sampled tips vs computed
        sampled = 0
        computed = 0
        for item in brsh_list:
            if not hasattr(item, 'keys'): continue
            brsh_inner = item.get(b'Brsh', None)
            if brsh_inner and hasattr(brsh_inner, 'keys'):
                # Check if it has computed params (Dmtr = diameter for round brushes)
                has_dmtr = b'Dmtr' in brsh_inner
                has_smpi = b'SmpI' in brsh_inner
                has_name = b'Nm  ' in brsh_inner
                inner_name = str(brsh_inner.get(b'Nm  ', '')).replace(chr(0),'').strip() if has_name else ''
                
                if has_smpi:
                    sampled += 1
                elif has_dmtr and not inner_name.startswith('Sampled'):
                    computed += 1
                else:
                    # Has a named brush tip, likely sampled even without SmpI
                    sampled += 1
            else:
                computed += 1
        
        print(f'  Sampled: ~{sampled}, Computed: ~{computed}')
