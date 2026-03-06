#!/usr/bin/env python3

import sys
import csv

def detect_samplesheet_version(samplesheet_path):
    """
    Detect whether a samplesheet is IEMFileVersion 4 (v1) or 5 (v2) format.
    
    v1 format:
        - Has [Data] section
        - Columns include: Sample_ID, Sample_Name, index, index2
        
    v2 format:
        - Has [BCLConvert_Data] section
        - Columns include: Sample_ID, Index, Index2
    
    Returns:
        'v1' for IEMFileVersion 4
        'v2' for IEMFileVersion 5
    """
    
    with open(samplesheet_path, 'r') as f:
        content = f.read()
    
    # Check for explicit version markers
    if 'IEMFileVersion,4' in content or 'IEMFileVersion,4,' in content:
        return 'v1'
    elif 'IEMFileVersion,5' in content or 'IEMFileVersion,5,' in content:
        return 'v2'
    
    # Check for section headers
    if '[BCLConvert_Data]' in content:
        return 'v2'
    elif '[Data]' in content:
        return 'v1'
    
    # If no clear markers, analyze the header row
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
        # Also v1 has Sample_Name, v2 doesn't typically
        if 'sample_name' in header:
            return 'v1'
        elif 'Index2' in lines[data_start]:  # Capital I suggests v2
            return 'v2'
    
    # Default to v1 if uncertain
    return 'v1'

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: detect_samplesheet_version.py <samplesheet.csv>", file=sys.stderr)
        sys.exit(1)
    
    version = detect_samplesheet_version(sys.argv[1])
    print(version)
