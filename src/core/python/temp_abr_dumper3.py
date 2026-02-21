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
        
        # ABR desc blocks might have a name length prefix or something before the actual descriptor?
        # Let's write the first 32 bytes to see:
        print("Header bytes:")
        print(desc_data[:32])
        
        # Or usually there's a 4 byte version or padding or string length. Let's try Descriptor.read
        stream = io.BytesIO(desc_data)
        
        # In PSD format 'desc' block involves 4 byte version etc.
        # But maybe we can just read the descriptor using psd_tools if we skip a few bytes.
        
        # PSD descriptor usually starts with version (4 bytes), then class name (length then utf-16 string), then the actual descriptor. 
        # But `Descriptor.read` expects just the descriptor itself or perhaps it starts with a 4 byte string length? 
        # Let's inspect the stream inside psd-tools
        pass

parse_desc(r"C:/Users/bonil/Pictures/Ale/©MITSU- MAIN (used) 2021.abr")
