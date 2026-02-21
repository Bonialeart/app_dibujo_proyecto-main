"""
ABR Diagnostic Script - Analyze the full structure of ABR files
to understand groups/folders, brush names, and sampled brush indices.
"""
import struct
import io
import sys
import json
import os

# Force UTF-8 output
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

from psd_tools.psd.descriptor import Descriptor

def safe_str(s):
    """Convert to string safely, stripping null bytes"""
    if isinstance(s, bytes):
        s = s.decode('utf-8', errors='replace')
    s = str(s)
    return s.replace('\x00', '').strip()

def analyze_brush_entry(item, depth=0):
    """Recursively analyze a brush descriptor entry"""
    result = {}
    
    if not hasattr(item, 'keys'):
        return {'value': str(item)}
    
    keys = list(item.keys())
    key_names = []
    for k in keys:
        k_str = k.decode('ascii', errors='replace') if isinstance(k, bytes) else str(k)
        key_names.append(k_str)
    
    result['keys'] = key_names
    
    # Extract name
    name = item.get(b'Nm  ', None)
    if name is not None:
        result['name'] = safe_str(name)
    
    # Check for brush group - in ABR, brushGroup identifies which folder a brush belongs to
    brush_group = item.get(b'brushGroup', None)
    if brush_group is not None:
        if hasattr(brush_group, 'keys'):
            group_name = brush_group.get(b'Nm  ', None)
            if group_name:
                result['brushGroup'] = safe_str(group_name)
        else:
            result['brushGroup'] = str(brush_group)
    
    # Check for Brsh (inner brush tip definition)
    brsh = item.get(b'Brsh', None)
    if brsh is not None and hasattr(brsh, 'keys'):
        inner_keys = [k.decode('ascii', errors='replace') if isinstance(k, bytes) else str(k) for k in brsh.keys()]
        result['inner_keys'] = inner_keys
        
        inner_name = brsh.get(b'Nm  ', None)
        if inner_name:
            result['inner_name'] = safe_str(inner_name)
        
        sampled_index = brsh.get(b'SmpI', None)
        if sampled_index is not None:
            result['SmpI'] = int(sampled_index) if not isinstance(sampled_index, int) else sampled_index
        
        diameter = brsh.get(b'Dmtr', None)
        if diameter is not None:
            try:
                result['diameter'] = float(diameter)
            except:
                result['diameter'] = str(diameter)
        
        spacing = brsh.get(b'Spcn', None)
        if spacing is not None:
            try:
                result['spacing'] = float(spacing)
            except:
                result['spacing'] = str(spacing)
        
        hardness = brsh.get(b'Hrdn', None)
        if hardness is not None:
            try:
                result['hardness'] = float(hardness)
            except:
                result['hardness'] = str(hardness)
        
        angle = brsh.get(b'Angl', None)
        if angle is not None:
            try:
                result['angle'] = float(angle)
            except:
                result['angle'] = str(angle)
        
        roundness = brsh.get(b'Rndn', None)
        if roundness is not None:
            try:
                result['roundness'] = float(roundness)
            except:
                result['roundness'] = str(roundness)
    
    return result


def analyze_abr(filepath):
    print(f"\n{'='*80}")
    print(f"ANALYZING: {filepath}")
    print(f"{'='*80}")
    
    with open(filepath, 'rb') as f:
        data = f.read()
    
    print(f"File size: {len(data)} bytes")
    
    # Read version
    version = struct.unpack('>H', data[0:2])[0]
    subversion = struct.unpack('>H', data[2:4])[0]
    print(f"Version: {version}.{subversion}")
    
    # Count PNG signatures
    png_count = data.count(b'\x89PNG')
    print(f"PNG signatures found: {png_count}")
    
    # Find 8BIM blocks
    offset = 0
    blocks_found = []
    while True:
        idx = data.find(b'8BIM', offset)
        if idx == -1:
            break
        block_type = data[idx+4:idx+8].decode('ascii', errors='replace')
        blocks_found.append((idx, block_type))
        offset = idx + 1
    
    print(f"\n8BIM blocks found:")
    for pos, btype in blocks_found:
        print(f"  Offset {pos}: 8BIM{btype}")
    
    # Parse descriptor with psd-tools
    desc_idx = data.find(b'8BIMdesc')
    if desc_idx == -1:
        print("\nNo 8BIMdesc block found!")
        return
    
    print(f"\n{'='*60}")
    print(f"DESCRIPTOR ANALYSIS (offset {desc_idx})")
    print(f"{'='*60}")
    
    size = struct.unpack('>I', data[desc_idx+8:desc_idx+12])[0]
    desc_data = data[desc_idx+12:desc_idx+12+size]
    print(f"Descriptor block size: {size} bytes")
    
    stream = io.BytesIO(desc_data)
    stream.read(4)  # skip version/padding
    
    try:
        desc = Descriptor.read(stream)
    except Exception as e:
        print(f"Failed to parse descriptor: {e}")
        return
    
    print(f"\nTop-level keys: {[safe_str(k) for k in desc.keys()]}")
    
    # Analyze the Brsh list
    brsh_key = b'Brsh'
    if brsh_key not in desc:
        print("No 'Brsh' key found in descriptor!")
        return
    
    brsh_list = desc[brsh_key]
    print(f"\nTotal items in Brsh list: {len(brsh_list)}")
    
    # Analyze each brush entry
    groups_seen = set()
    entries_with_sampled = 0
    entries_without_sampled = 0
    entries_computed = 0
    
    all_entries = []
    
    for i, item in enumerate(brsh_list):
        entry = analyze_brush_entry(item)
        entry['index'] = i
        all_entries.append(entry)
        
        name = entry.get('name', '<no name>')
        inner_name = entry.get('inner_name', '')
        smp_i = entry.get('SmpI', None)
        group = entry.get('brushGroup', '')
        
        if group:
            groups_seen.add(group)
        
        if smp_i is not None:
            entries_with_sampled += 1
        elif 'inner_keys' in entry:
            entries_computed += 1
        else:
            entries_without_sampled += 1
        
        # Print each brush
        smp_str = f" SmpI={smp_i}" if smp_i is not None else ""
        inner_str = f" tip='{inner_name}'" if inner_name else ""
        group_str = f" GROUP='{group}'" if group else ""
        diam_str = f" D={entry.get('diameter', '?')}" if 'diameter' in entry else ""
        
        print(f"  [{i:3d}] '{name}'{smp_str}{inner_str}{group_str}{diam_str}")
    
    # Count samples in samp block
    samp_idx = data.find(b'8BIMsamp')
    samp_count = 0
    if samp_idx != -1:
        print(f"\n{'='*60}")
        print(f"SAMP BLOCK ANALYSIS (offset {samp_idx})")
        print(f"{'='*60}")
        
        pos = samp_idx + 8
        name_len = data[pos]
        pos += 1 + name_len
        if (name_len + 1) % 2 != 0:
            pos += 1
        
        samp_size = struct.unpack('>I', data[pos:pos+4])[0]
        pos += 4
        print(f"Samp block data start: {pos}, size: {samp_size} bytes")
        
        # Try to parse individual samples in samp block
        # Each sample in V6.2 has: 4-byte length, then the sample data
        samp_end = pos + samp_size
        samp_pos = pos
        while samp_pos < samp_end - 4:
            sample_len = struct.unpack('>I', data[samp_pos:samp_pos+4])[0]
            if sample_len == 0 or sample_len > samp_size:
                # Try more heuristic approach: look for image dimension patterns
                break
            samp_count += 1
            actual_len = sample_len
            # Align to even
            if actual_len % 2 != 0:
                actual_len += 1
            samp_pos += 4 + actual_len
        
        print(f"Individual samp entries (by length field): {samp_count}")
        
        # Also try heuristic: count image headers in samp
        # \x00\x08\x01 and \x00\x08\x00 are compression markers
        comp_raw = data[pos:samp_end].count(b'\x00\x08\x00')
        comp_rle = data[pos:samp_end].count(b'\x00\x08\x01')
        print(f"Compression markers in samp: RAW={comp_raw}, RLE={comp_rle}, Total={comp_raw+comp_rle}")
    
    # Summary
    print(f"\n{'='*60}")
    print(f"SUMMARY for {os.path.basename(filepath)}")
    print(f"{'='*60}")
    print(f"Total descriptor brush entries: {len(brsh_list)}")
    print(f"  Sampled (with SmpI): {entries_with_sampled}")
    print(f"  Computed (no SmpI but have Brsh keys): {entries_computed}")
    print(f"  No inner brush data: {entries_without_sampled}")
    print(f"PNG images: {png_count}")
    print(f"Samp entries: {samp_count}")
    print(f"Unique groups seen: {groups_seen}")
    
    # Output JSON for further analysis
    json_path = filepath + '.analysis.json'
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(all_entries, f, indent=2, ensure_ascii=False, default=str)
    print(f"\nFull analysis saved to: {json_path}")


if __name__ == '__main__':
    files = [
        r"C:\Users\bonil\Downloads\20230322 brushes.abr",
        r"C:\Users\bonil\Downloads\suke2023.abr", 
        r"C:\Users\bonil\Downloads\wlop_brush.abr",
    ]
    
    for f in files:
        if os.path.exists(f):
            try:
                analyze_abr(f)
            except Exception as e:
                print(f"ERROR analyzing {f}: {e}")
                import traceback
                traceback.print_exc()
        else:
            print(f"File not found: {f}")
