import sys
import struct

def dump_abr(filepath):
    print(f"Opening: {filepath}")
    with open(filepath, 'rb') as f:
        # ABR header
        version = struct.unpack('>h', f.read(2))[0]
        print(f"ABR Version: {version}")
        if version in (1, 2):
            pass # old format
        elif version in (6, 10):
            # Read blocks
            while True:
                sig = f.read(4)
                if not sig: break
                if sig != b'8BIM':
                    print(f"Unknown signature: {sig}, aborting...")
                    break
                
                block_type = f.read(4).decode('ascii', errors='replace')
                size = struct.unpack('>I', f.read(4))[0]
                print(f"Block: 8BIM {block_type} | Size: {size}")
                
                if block_type in ('samp', 'patt'):
                    f.seek(size, 1)
                elif block_type == 'desc' or block_type == 'prm ':
                    f.seek(size, 1) # We'll examine this later
                else:
                    f.seek(size, 1)

dump_abr(r"C:/Users/bonil/Pictures/Ale/©MITSU- MAIN (used) 2021.abr")
