import struct

def test_heuristic(filepath):
    with open(filepath, 'rb') as f:
        data = f.read()
    
    idx = data.find(b'8BIMdesc')
    if idx == -1: return
    
    size = struct.unpack('>I', data[idx+8:idx+12])[0]
    desc_data = data[idx+12:idx+12+size]
    
    offset = 0
    brushes = []
    current_brush = {}
    
    # We will just search for b'TEXT' which often follows names
    # Wait, 'Nm  ' is usually followed by 'TEXT'
    
    pos = 0
    while pos < len(desc_data):
        if desc_data[pos:pos+4] == b'Nm  ':
            pos += 4
            if desc_data[pos:pos+4] == b'TEXT':
                pos += 4
                length = struct.unpack('>I', desc_data[pos:pos+4])[0]
                pos += 4
                name = desc_data[pos:pos+length*2].decode('utf-16-be', errors='ignore')
                name = name.rstrip('\x00')
                current_brush = {'name': name}
                brushes.append(current_brush)
                pos += length*2
                continue
        pos += 1

    # Now let's test if we found exactly 31 brushes?
    print(f"Found {len(brushes)} names using TEXT heuristic.")
    for b in brushes:
        print(b['name'])

test_heuristic(r"C:/Users/bonil/Pictures/Ale/©MITSU- MAIN (used) 2021.abr")
