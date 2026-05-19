import sys, struct

def analyze_blocks(path):
    data = open(path, 'rb').read()
    if len(data) < 4: return
    ver = struct.unpack_from('>h', data, 0)[0]
    sub = struct.unpack_from('>h', data, 2)[0]
    print(f"ABR v{ver} sub{sub} size={len(data)}")

    offset = 4
    while offset + 12 <= len(data):
        sig = data[offset:offset+4]
        if sig != b'8BIM':
            # sometimes v6 brushes have a different structure?
            print(f"Unexpected sig at {offset}: {sig.hex()}")
            # let's just search for '8BIM'
            next_8bim = data.find(b'8BIM', offset)
            if next_8bim < 0: break
            offset = next_8bim
            continue
            
        key = data[offset+4:offset+8]
        size = struct.unpack_from('>I', data, offset+8)[0]
        
        print(f"Found 8BIM block: {key.decode('ascii', 'replace')} at {offset}, size: {size}")
        
        if key == b'pnam':
            # Print content of pnam if it's text
            content = data[offset+12:offset+12+size]
            print(f"  Content: {content[:100]}")
        
        offset += 12 + size
        # align to 2 or 4 bytes? 
        if offset % 2 != 0: offset += 1

if __name__ == "__main__":
    analyze_blocks(sys.argv[1])
