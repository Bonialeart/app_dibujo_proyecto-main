import sys
import psd_tools
from psd_tools.psd.descriptor import Descriptor, DescriptorBlock
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
        
        # In PSD format 'desc' block usually has a little extra header
        stream = io.BytesIO(desc_data)
        try:
             # Try to skip the version or unknown bytes if needed.
             # The first 4 bytes might be the string length of the name or version (16 is Common).
             # Let's see if DescriptorBlock parses it.
             # Actually, DescriptorBlock doesn't take version but just reads from classname.
             # Let's see what Descriptor.read does: reads classname then Descriptor.
             stream.seek(0)
             stream.read(4) # skip version/padding or length?
             res = Descriptor.read(stream)
             print("Parsed successfully via skipping 4!")
             print(list(res.keys()))
        except Exception as e:
             print("Failed 4:", e)
             try:
                 stream.seek(0)
                 res = Descriptor.read(stream)
                 print("Parsed without skip!")
                 print(list(res.keys()))
             except Exception as e:
                 print("Failed 0:", e)

parse_desc(r"C:/Users/bonil/Pictures/Ale/©MITSU- MAIN (used) 2021.abr")
