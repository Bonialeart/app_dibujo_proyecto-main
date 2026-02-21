"""
Deep analysis of samp block structure to understand how to find all brush tip images
"""
import sys, struct, io, os
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
    subver = struct.unpack('>H', data[2:4])[0]
    
    print(f'\n{"="*70}')
    print(f'{os.path.basename(filepath)} - Version {version}.{subver}')
    print(f'File size: {len(data)} bytes')
    print(f'{"="*70}')
    
    # Find samp block
    samp_idx = data.find(b'8BIMsamp')
    if samp_idx == -1:
        print("No samp block!")
        continue
    
    print(f'8BIMsamp at offset {samp_idx}')
    
    # After '8BIM' + 'samp' (8 bytes), the block structure is:
    # - Pascal string (1 byte length + chars + padding to even)
    # - 4-byte block data length
    pos = samp_idx + 8
    name_len = data[pos]
    pos += 1 + name_len
    if (name_len + 1) % 2 != 0:
        pos += 1
    
    # The block size field - for V6 this might be a 4-byte size
    block_size_raw = struct.unpack('>I', data[pos:pos+4])[0]
    pos += 4
    
    print(f'Block size field: {block_size_raw} (0x{block_size_raw:08x})')
    
    # Find next 8BIM block to determine ACTUAL size
    next_8bim = data.find(b'8BIM', samp_idx + 8)
    if next_8bim != -1:
        actual_samp_size = next_8bim - pos
        print(f'Next 8BIM at offset {next_8bim}')
        print(f'ACTUAL samp data size (by next block): {actual_samp_size} bytes')
    else:
        actual_samp_size = len(data) - pos
        print(f'No next 8BIM, actual size: {actual_samp_size}')
    
    samp_data = data[pos:pos+actual_samp_size]
    
    # Now let's try to parse individual samples within this block
    # The ABR V6 samp block structure contains individual brush tips
    # Each one starts with a 4-byte sample length
    print(f'\nParsing individual samples in samp block...')
    
    samp_pos = 0
    samples = []
    while samp_pos < len(samp_data) - 4:
        # Read sample length
        sample_len = struct.unpack('>I', samp_data[samp_pos:samp_pos+4])[0]
        
        if sample_len == 0 or sample_len > actual_samp_size:
            # Bad length - stop
            print(f'  Bad length {sample_len} at samp offset {samp_pos}, stopping')
            break
        
        sample_start = samp_pos + 4
        sample_end = sample_start + sample_len
        
        if sample_end > len(samp_data):
            print(f'  Sample at offset {samp_pos} claims length {sample_len} but only {len(samp_data) - sample_start} bytes remaining')
            break
        
        sample_data = samp_data[sample_start:sample_end]
        
        # Parse sample header
        # The V6.2 sample format is:
        # skip 4 bytes (misc info)
        # top(4) left(4) bottom(4) right(4) = rect
        # depth(2) = bits per channel (usually 8)
        # compression(1) = 0=raw, 1=RLE
        
        if len(sample_data) >= 21:
            misc = struct.unpack('>I', sample_data[0:4])[0]
            t, l, b, r = struct.unpack('>iiii', sample_data[4:20])
            depth = struct.unpack('>H', sample_data[20:22])[0] if len(sample_data) >= 22 else 0
            comp = sample_data[22] if len(sample_data) >= 23 else -1
            
            w = r - l
            h = b - t
            
            info = {
                'offset': samp_pos,
                'length': sample_len,
                'width': w,
                'height': h,
                'depth': depth,
                'compression': comp,
            }
            samples.append(info)
            
            if len(samples) <= 20:
                print(f'  Sample [{len(samples)-1}]: offset={samp_pos}, len={sample_len}, {w}x{h}, depth={depth}, comp={comp}')
        
        # Advance - align to even boundary
        actual_len = sample_len
        if actual_len % 2 != 0:
            actual_len += 1
        samp_pos += 4 + actual_len
    
    print(f'\nTotal samples parsed: {len(samples)}')
    
    if len(samples) > 20:
        print(f'(Only first 20 printed)')
        # Print last few
        for s in samples[-5:]:
            print(f'  Sample [{samples.index(s)}]: offset={s["offset"]}, len={s["length"]}, {s["width"]}x{s["height"]}, depth={s["depth"]}, comp={s["compression"]}')
    
    # Now check descriptor to see how many brushes reference sampled tips
    desc_idx = data.find(b'8BIMdesc')
    if desc_idx != -1:
        size = struct.unpack('>I', data[desc_idx+8:desc_idx+12])[0]
        desc_data = data[desc_idx+12:desc_idx+12+size]
        stream = io.BytesIO(desc_data)
        stream.read(4)
        desc = Descriptor.read(stream)
        brsh_list = desc[b'Brsh']
        
        # Count sampled vs computed brushes and get their inner info
        sampled_refs = []
        computed = []
        for i, item in enumerate(brsh_list):
            if not hasattr(item, 'keys'): continue
            name = safe_str(item.get(b'Nm  ', ''))
            brsh_inner = item.get(b'Brsh', None)
            
            if brsh_inner and hasattr(brsh_inner, 'keys'):
                smp_i = brsh_inner.get(b'SmpI', None)
                inner_name = safe_str(brsh_inner.get(b'Nm  ', ''))
                
                # Check the tip type - computed vs sampled
                inner_keys = [k.decode('ascii', errors='replace') if isinstance(k, bytes) else str(k) for k in brsh_inner.keys()]
                
                if smp_i is not None:
                    sampled_refs.append((i, name, smp_i))
                elif 'Dmtr' in inner_keys or 'Hrdn' in inner_keys:
                    # Has diameter/hardness = likely computed (round) brush
                    computed.append((i, name, 'computed (has Dmtr/Hrdn)'))
                elif inner_name.startswith('Sampled') or (b'type' in brsh_inner):
                    sampled_refs.append((i, name, 'implicit sampled'))
                else:
                    computed.append((i, name, f'keys: {inner_keys[:5]}'))
            else:
                computed.append((i, name, 'no Brsh inner'))
        
        print(f'\nDescriptor brush analysis:')
        print(f'  Total: {len(brsh_list)}')
        print(f'  Sampled (with SmpI): {len(sampled_refs)}')
        print(f'  Computed/other: {len(computed)}')
        
        if sampled_refs:
            print(f'  First 10 sampled:')
            for idx, name, smp in sampled_refs[:10]:
                print(f'    [{idx}] {name} SmpI={smp}')
