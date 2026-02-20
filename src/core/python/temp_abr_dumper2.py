import sys
from psd_tools.psd.descriptor import Descriptor
import struct
import json

def find_descriptors(filepath):
    with open(filepath, 'rb') as f:
        data = f.read()

    print(f"File length: {len(data)}")
    idx = 0
    while True:
        idx = data.find(b'8BIM', idx)
        if idx == -1:
            break
        
        sig = data[idx:idx+4]
        btype = data[idx+4:idx+8]
        size = struct.unpack('>I', data[idx+8:idx+12])[0]
        
        print(f"Found {btype} at {idx}, size {size}")
        if btype == b'samp':
            pass
        elif btype == b'prm ':  # Sometimes 'prm ' (parameters?)
            try:
                 print("Attempting to parse prm...")
            except Exception as e:
                 print("Parse error on prm", e)
        idx += 12 + size + (1 if size % 2 != 0 else 0)

find_descriptors(r"C:/Users/bonil/Pictures/Ale/©MITSU- MAIN (used) 2021.abr")
