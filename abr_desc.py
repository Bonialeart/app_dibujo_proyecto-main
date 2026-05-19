import sys, struct, re

def dump_desc(path):
    data = open(path, 'rb').read()
    
    desc_pos = data.find(b'8BIMdesc')
    if desc_pos < 0:
        print("No desc block found")
        return
        
    size = struct.unpack_from('>I', data, desc_pos+8)[0]
    desc_data = data[desc_pos+12 : desc_pos+12+size]
    
    print(f"desc block size: {len(desc_data)}")
    
    # Try to extract unicode strings (Photoshop descriptor text strings usually have a length followed by utf-16be)
    # The tag for unicode string is usually 'TEXT' then length(4) then utf-16be data
    offset = 0
    while offset < len(desc_data) - 4:
        if desc_data[offset:offset+4] == b'TEXT':
            str_len = struct.unpack_from('>I', desc_data, offset+4)[0]
            if str_len > 0 and str_len < 1000:
                try:
                    text_bytes = desc_data[offset+8 : offset+8 + str_len*2]
                    # decode as utf-16be
                    text = text_bytes.decode('utf-16be').strip('\x00')
                    print(f"Found TEXT at {offset}: {text}")
                    # Also look backwards 200 bytes for a UUID to map it
                    start_search = max(0, offset - 500)
                    chunk = desc_data[start_search:offset]
                    uuids = re.findall(rb'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', chunk)
                    if uuids:
                        print(f"  -> Associated UUIDs nearby: {[u.decode() for u in uuids]}")
                except Exception as e:
                    pass
        offset += 1

if __name__ == "__main__":
    dump_desc(sys.argv[1])
