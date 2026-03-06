#!/usr/bin/env python3

import sys
import csv

def detect_samplesheet_version(samplesheet_path):
    """
    Detect whether a samplesheet is for bcl2fastq2 (v1) or BCL Convert (v2).
    
    Detection Logic:
    
    BCL Convert (v2) is detected by:
        - [BCLConvert_Settings] section, OR
        - [BCLConvert_Data] section
        
    bcl2fastq2 (v1) is detected by:
        - [Reads] section (specifying read lengths), OR
        - IEMFileVersion=4 in header
        - [Settings] and [Data] sections (fallback)
    
    Returns:
        'v1' for bcl2fastq2
        'v2' for BCL Convert
    """
    
    with open(samplesheet_path, 'r') as f:
        content = f.read()
    
    # Priority 1: Check for BCL Convert specific sections (v2)
    if '[BCLConvert_Settings]' in content or '[BCLConvert_Data]' in content:
        return 'v2'
    
    # Priority 2: Check for bcl2fastq2 specific sections (v1)
    if '[Reads]' in content:
        return 'v1'
    
    # Priority 3: Check for explicit version markers
    if 'IEMFileVersion,4' in content or 'IEMFileVersion,4,' in content:
        return 'v1'
    elif 'IEMFileVersion,5' in content or 'IEMFileVersion,5,' in content:
        return 'v2'
    
    # Priority 4: Check for generic section headers
    # [Settings] and [Data] are typically bcl2fastq2 (v1)
    # If we see [Data] but not [BCLConvert_Data], it's likely v1
    if '[Data]' in content and '[BCLConvert_Data]' not in content:
        return 'v1'
    
    # Priority 5: Analyze header row if present
    lines = content.strip().split('\n')
    
    # Find the data section
    data_start = -1
    for i, line in enumerate(lines):
        if line.strip().startswith('[Data]') or line.strip().startswith('[BCLConvert_Data]'):
            data_start = i + 1
            break
    
    if data_start >= 0 and data_start < len(lines):
        header = lines[data_start].lower()
        
        # v1 uses lowercase 'index' and 'index2'
        # v2 uses 'Index' and 'Index2'
        # v1 typically has Sample_Name, v2 doesn't always
        if 'sample_name' in header:
            return 'v1'
        elif 'Index2' in lines[data_start]:  # Capital I suggests v2
            return 'v2'
    
    # Default to v1 (bcl2fastq2) if uncertain for backward compatibility
    return 'v1'

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: detect_samplesheet_version.py <samplesheet.csv>", file=sys.stderr)
        sys.exit(1)
    
    version = detect_samplesheet_version(sys.argv[1])
    print(version)
