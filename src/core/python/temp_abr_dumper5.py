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
            first_brush = brsh_list[0]
            print(f"First brush keys: {list(first_brush.keys())}")
            print(f"First brush name: {first_brush.get(b'Nm  ')}") # Often 'Nm  ' is name
            if b'Tgl ' in first_brush: print(first_brush[b'Tgl ']) # Toggle folder?
            
            # Let's print out the first few brushes to see if they define folders
            for i, b in enumerate(brsh_list[:5]):
                name = b.get(b'Nm  ', b'Unknown')
                if isinstance(name, bytes): name = name.decode('utf-8', errors='ignore')
                print(f"{i}: {name}")
                if b'Tgl ' in b: print(f"  Folder? Tgl = {b[b'Tgl ']}")
                print(f"  Keys: {list(b.keys())}")

parse_desc(r"C:/Users/bonil/Pictures/Ale/©MITSU- MAIN (used) 2021.abr")
