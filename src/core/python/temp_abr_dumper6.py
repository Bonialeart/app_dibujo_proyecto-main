import sys
import psd_tools
from psd_tools.psd.descriptor import Descriptor
import struct
import io
import json

def parse_desc(filepath):
    with open(filepath, 'rb') as f:
        data = f.read()

    idx = data.find(b'8BIMdesc')
    if idx != -1:
        size = struct.unpack('>I', data[idx+8:idx+12])[0]
        desc_data = data[idx+12 : idx+12+size]
        
        stream = io.BytesIO(desc_data)
        stream.read(4)
        res = Descriptor.read(stream)
        
        brsh_list = res[b'Brsh']
        print(f"Total brushes: {len(brsh_list)}")
        
        if len(brsh_list) > 0:
            b = brsh_list[1] # A typical brush
            print("--- Brush 1 ---")
            for k, v in b.items():
                print(f"{k}: {type(v)} = {v}")
                if hasattr(v, 'items'):
                    print("  INNER:")
                    for k2, v2 in v.items():
                        print(f"    {k2}: {type(v2)} = {v2}")

parse_desc(r"C:/Users/bonil/Pictures/Ale/©MITSU- MAIN (used) 2021.abr")
