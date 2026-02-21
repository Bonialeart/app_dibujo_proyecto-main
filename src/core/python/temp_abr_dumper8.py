import psd_tools
from psd_tools.psd.descriptor import Descriptor
import struct, io, json

def parse_desc(filepath):
    with open(filepath, 'rb') as f: data = f.read()
    idx = data.find(b'8BIMdesc')
    size = struct.unpack('>I', data[idx+8:idx+12])[0]
    stream = io.BytesIO(data[idx+12:idx+12+size])
    stream.read(4)
    res = Descriptor.read(stream)
    
    brsh_list = res[b'Brsh']
    print(f"Total brushes: {len(brsh_list)}")
    
    # search for sampled ones
    sampled = 0
    for i, b in enumerate(brsh_list):
        name = b.get(b'Nm  ')
        if b'Brsh' in b:
            # what keys are inside Brsh?
            keys = list(b[b'Brsh'].keys())
            if b'Nm  ' in b[b'Brsh']: # sometimes the tip name is inside Brsh
                pass
            if b'SmpI' in b[b'Brsh']: 
                print(f"{name} is Sampled! SmpI = {b[b'Brsh'][b'SmpI']}")
            print(f"Brush {i} ({name}) tip keys: {keys}")

parse_desc(r"C:/Users/bonil/Pictures/Ale/©MITSU- MAIN (used) 2021.abr")
