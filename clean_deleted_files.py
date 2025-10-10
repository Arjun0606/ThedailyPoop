#!/usr/bin/env python3
"""Remove references to deleted ad files from Xcode project"""

def clean_project_file():
    project_file = 'PoopDrop.xcodeproj/project.pbxproj'
    
    # Read the file
    with open(project_file, 'r') as f:
        lines = f.readlines()
    
    # Files to remove
    deleted_files = [
        'AdManager.swift',
        'MapBannerAdView.swift',
        'NativeAdCardView.swift'
    ]
    
    # Filter out lines that reference these files
    cleaned_lines = []
    for line in lines:
        should_keep = True
        for deleted_file in deleted_files:
            if deleted_file in line:
                should_keep = False
                break
        if should_keep:
            cleaned_lines.append(line)
    
    # Write back
    with open(project_file, 'w') as f:
        f.writelines(cleaned_lines)
    
    print(f"✅ Cleaned {len(lines) - len(cleaned_lines)} lines referencing deleted ad files")
    print(f"📝 Original: {len(lines)} lines")
    print(f"📝 Cleaned: {len(cleaned_lines)} lines")

if __name__ == "__main__":
    clean_project_file()

