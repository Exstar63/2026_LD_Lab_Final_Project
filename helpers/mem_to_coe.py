#!/usr/bin/env python3
"""Convert .mem file to .coe format for Vivado Block Memory Generator"""

import os

def mem_to_coe(mem_file, coe_file):
    """Convert hex memory file to COE format"""
    with open(mem_file, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]
    
    # Write COE header and data
    with open(coe_file, 'w') as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        
        for i, line in enumerate(lines):
            if i < len(lines) - 1:
                f.write(f"{line},\n")
            else:
                f.write(f"{line};\n")  # Last entry ends with semicolon
    
    print(f"Converted {len(lines)} entries: {mem_file} -> {coe_file}")

if __name__ == "__main__":
    # Convert csc_lut.mem to csc_lut.coe
    mem_path = os.path.join(os.path.dirname(__file__), "..", "final_proj", "csc_lut.mem")
    coe_path = os.path.join(os.path.dirname(__file__), "..", "final_proj", "csc_lut.coe")
    
    if os.path.exists(mem_path):
        mem_to_coe(mem_path, coe_path)
        print(f"✓ File created: {coe_path}")
    else:
        print(f"✗ File not found: {mem_path}")
