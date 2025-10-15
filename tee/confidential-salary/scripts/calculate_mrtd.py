#!/usr/bin/env python3
"""
Calculate MRTD (Measurement of Trust Domain) for TDX
This simulates how Intel TDX calculates the MRTD from TD memory pages
"""

import hashlib
import struct
import json
import sys
import os
from typing import List, Tuple

class MRTDCalculator:
    """
    Simulates MRTD calculation process used by Intel TDX.
    MRTD is a SHA-384 hash of:
    1. TD attributes and configuration
    2. Initial memory pages loaded into the TD
    3. Page permissions and types
    """
    
    # TDX page types
    PAGE_TYPE_NORMAL = 0
    PAGE_TYPE_SEPT = 1
    PAGE_TYPE_TD_VMCS = 2
    PAGE_TYPE_RESERVED = 3
    
    def __init__(self):
        self.hasher = hashlib.sha384()
        self.pages_measured = 0
        
    def extend_measurement(self, data: bytes):
        """Extend the current measurement with new data"""
        self.hasher.update(data)
        
    def measure_td_config(self, attributes: int, xfam: int, max_vcpus: int):
        """Measure TD configuration"""
        # TD attributes (8 bytes)
        self.extend_measurement(struct.pack('<Q', attributes))
        
        # XFAM (Extended Features) (8 bytes)
        self.extend_measurement(struct.pack('<Q', xfam))
        
        # Max VCPUs (4 bytes)
        self.extend_measurement(struct.pack('<I', max_vcpus))
        
        # Reserved (4 bytes)
        self.extend_measurement(struct.pack('<I', 0))
        
        print(f"Measured TD config: attributes=0x{attributes:016x}, xfam=0x{xfam:016x}")
    
    def measure_page(self, gpa: int, page_data: bytes, page_type: int = PAGE_TYPE_NORMAL):
        """
        Measure a memory page being added to the TD
        
        Args:
            gpa: Guest Physical Address
            page_data: Page content (4KB)
            page_type: Type of page
        """
        # Measure page metadata
        metadata = struct.pack('<QI', gpa, page_type)
        self.extend_measurement(metadata)
        
        # Measure page content
        if len(page_data) != 4096:
            # Pad or truncate to 4KB
            if len(page_data) < 4096:
                page_data = page_data + b'\x00' * (4096 - len(page_data))
            else:
                page_data = page_data[:4096]
        
        self.extend_measurement(page_data)
        self.pages_measured += 1
        
    def measure_binary_file(self, filepath: str, load_address: int = 0x400000):
        """
        Measure a binary file as it would be loaded into TD memory
        
        Args:
            filepath: Path to the binary file
            load_address: Base address where binary is loaded
        """
        if not os.path.exists(filepath):
            raise FileNotFoundError(f"Binary not found: {filepath}")
        
        with open(filepath, 'rb') as f:
            binary_data = f.read()
        
        print(f"Measuring binary: {filepath}")
        print(f"Size: {len(binary_data)} bytes")
        print(f"Load address: 0x{load_address:016x}")
        
        # Measure in 4KB pages
        offset = 0
        while offset < len(binary_data):
            page_data = binary_data[offset:offset + 4096]
            gpa = load_address + offset
            self.measure_page(gpa, page_data)
            offset += 4096
        
        print(f"Measured {self.pages_measured} pages")
    
    def finalize(self) -> str:
        """Get the final MRTD value"""
        mrtd = self.hasher.hexdigest()
        return mrtd

def calculate_expected_mrtd(binary_path: str, config: dict) -> str:
    """
    Calculate the expected MRTD for a given binary and TD configuration
    
    Args:
        binary_path: Path to the server binary
        config: TD configuration parameters
    
    Returns:
        Hex string of the MRTD (96 hex chars for SHA-384)
    """
    calculator = MRTDCalculator()
    
    # 1. Measure TD configuration
    calculator.measure_td_config(
        attributes=config.get('attributes', 0x0),
        xfam=config.get('xfam', 0x1E7),
        max_vcpus=config.get('max_vcpus', 1)
    )
    
    # 2. Measure initial memory layout
    # Boot structures (simplified)
    calculator.measure_page(0x0, b'BOOT' * 1024, MRTDCalculator.PAGE_TYPE_NORMAL)
    
    # 3. Measure the actual binary
    calculator.measure_binary_file(binary_path, config.get('load_address', 0x400000))
    
    # 4. Additional TD structures
    # Stack pages
    for i in range(config.get('stack_pages', 16)):
        calculator.measure_page(0x7FF00000 + i * 4096, b'\x00' * 4096)
    
    # Heap pages
    for i in range(config.get('heap_pages', 32)):
        calculator.measure_page(0x10000000 + i * 4096, b'\x00' * 4096)
    
    return calculator.finalize()

def verify_mrtd(binary_path: str, expected_mrtd: str, config: dict = {}) -> bool:
    """
    Verify that a binary produces the expected MRTD
    
    Args:
        binary_path: Path to the binary
        expected_mrtd: Expected MRTD value (hex string)
        config: Optional TD configuration
    
    Returns:
        True if MRTD matches, False otherwise
    """
    if not config:
        config = {
            'attributes': 0x0,  # No debug
            'xfam': 0x1E7,      # Standard x86 features
            'max_vcpus': 1,
            'load_address': 0x400000,
            'stack_pages': 16,
            'heap_pages': 32
        }
    
    calculated_mrtd = calculate_expected_mrtd(binary_path, config)
    
    # TDX uses only first 48 bytes (384 bits) of SHA-384
    calculated_mrtd_truncated = calculated_mrtd[:96]  # 48 bytes = 96 hex chars
    expected_mrtd_truncated = expected_mrtd[:96]
    
    match = calculated_mrtd_truncated == expected_mrtd_truncated
    
    print("\n" + "="*60)
    print("MRTD Verification Result:")
    print("="*60)
    print(f"Binary: {binary_path}")
    print(f"Expected MRTD:   {expected_mrtd_truncated}")
    print(f"Calculated MRTD: {calculated_mrtd_truncated}")
    print(f"Match: {'✓ YES' if match else '✗ NO'}")
    print("="*60)
    
    return match

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  Calculate MRTD: python3 calculate_mrtd.py <binary_path>")
        print("  Verify MRTD:   python3 calculate_mrtd.py <binary_path> <expected_mrtd>")
        sys.exit(1)
    
    binary_path = sys.argv[1]
    
    # Default TD configuration
    config = {
        'attributes': 0x0,  # No debug, no key sharing
        'xfam': 0x1E7,      # Standard features
        'max_vcpus': 1,
        'load_address': 0x400000,
        'stack_pages': 16,
        'heap_pages': 32
    }
    
    if len(sys.argv) > 2:
        # Verify mode
        expected_mrtd = sys.argv[2]
        verify_mrtd(binary_path, expected_mrtd, config)
    else:
        # Calculate mode
        mrtd = calculate_expected_mrtd(binary_path, config)
        print(f"\nCalculated MRTD: {mrtd[:96]}")
        
        # Save to file
        output = {
            'binary': binary_path,
            'mrtd': mrtd[:96],
            'config': config,
            'full_hash': mrtd
        }
        
        with open('mrtd_calculation.json', 'w') as f:
            json.dump(output, f, indent=2)
        
        print(f"Full details saved to mrtd_calculation.json")

if __name__ == "__main__":
    main()