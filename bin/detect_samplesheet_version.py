#!/usr/bin/env python3

import sys
import csv

def detect_samplesheet_version(samplesheet_path):
    """
    Detect whether a samplesheet is for bcl2fastq2 (v1) or BCL Convert (v2).
    
    Detection Logic (priority order):
    
    1. Check for [BCLConvert_Settings] or [BCLConvert_Data] → v2 (PRIMARY MARKER)
       These sections are ONLY present in BCL Convert samplesheets
       
    2. Check for [Data] section (not [BCLConvert_Data]) → v1
       bcl2fastq2 uses [Data], BCL Convert uses [BCLConvert_Data]
       
    3. Check for [Settings] section (not [BCLConvert_Settings]) → v1
       bcl2fastq2 uses [Settings], BCL Convert uses [BCLConvert_Settings]
       
    4. Check for IEMFileVersion= → v1
       Any IEMFileVersion value indicates bcl2fastq2
       
    5. Check for FileFormatVersion,2 → v2
       
    6. Default to v2 (BCL Convert) as the newer standard
    
    Note: [Reads] section can appear in both formats, so it's not used for detection
    
    Returns:
        'v1' for bcl2fastq2
        'v2' for BCL Convert
    """
    
    with open(samplesheet_path, 'r') as f:
        content = f.read()
    
    # Priority 1: Check for BCL Convert specific sections (definitive v2 marker)
    # These sections are ONLY present in BCL Convert samplesheets
    if '[BCLConvert_Settings]' in content or '[BCLConvert_Data]' in content:
        return 'v2'
    
    # Priority 2: Check for [Data] section (v1 marker when not [BCLConvert_Data])
    # If we find [Data] and already checked for [BCLConvert_Data] above, it's v1
    if '[Data]' in content:
        return 'v1'
    
    # Priority 3: Check for [Settings] section (v1 marker when not [BCLConvert_Settings])
    # If we find [Settings] and already checked for [BCLConvert_Settings] above, it's v1
    if '[Settings]' in content:
        return 'v1'
    
    # Priority 4: Check for IEMFileVersion (v1 marker - any version number)
    if 'IEMFileVersion,' in content:
        return 'v1'
    
    # Priority 5: Check for FileFormatVersion=2 (v2 marker)
    if 'FileFormatVersion,2' in content:
        return 'v2'
    
    # Default to v2 (BCL Convert) as the newer standard
    return 'v2'

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: detect_samplesheet_version.py <samplesheet.csv>", file=sys.stderr)
        sys.exit(1)
    
    version = detect_samplesheet_version(sys.argv[1])
    print(version)
