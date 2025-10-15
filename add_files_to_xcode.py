#!/usr/bin/env python3
"""
Script to add new Swift files to Xcode project.pbxproj
"""

import re
import uuid
import sys

def generate_uuid():
    """Generate a unique 24-character hex ID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_xcode():
    project_file = 'PoopDrop.xcodeproj/project.pbxproj'
    
    # Files to add
    files_to_add = [
        {
            'name': 'PointsManager.swift',
            'path': 'PoopDrop/Managers/PointsManager.swift',
            'group_name': 'Managers',
            'group_path': 'PoopDrop/Managers'
        },
        {
            'name': 'DailyLeaderboardView.swift',
            'path': 'PoopDrop/Views/DailyLeaderboardView.swift',
            'group_name': 'Views',
            'group_path': 'PoopDrop/Views'
        },
        {
            'name': 'Poll.swift',
            'path': 'PoopDrop/Models/Poll.swift',
            'group_name': 'Models',
            'group_path': 'PoopDrop/Models'
        }
    ]
    
    # Read project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Backup
    with open(project_file + '.backup', 'w') as f:
        f.write(content)
    print("✅ Created backup: project.pbxproj.backup")
    
    # Find the main group ID and sources build phase ID
    main_group_match = re.search(r'mainGroup = ([A-F0-9]{24});', content)
    if not main_group_match:
        print("❌ Could not find mainGroup")
        return False
    
    # Find Sources build phase
    sources_phase_match = re.search(r'/\* Sources \*/.*?isa = PBXSourcesBuildPhase;.*?files = \((.*?)\);', content, re.DOTALL)
    if not sources_phase_match:
        print("❌ Could not find PBXSourcesBuildPhase")
        return False
    
    sources_phase_id = re.search(r'([A-F0-9]{24}) /\* Sources \*/', content).group(1)
    
    # Process each file
    for file_info in files_to_add:
        name = file_info['name']
        path = file_info['path']
        
        # Check if already exists
        if name in content:
            print(f"⚠️  {name} already in project, skipping")
            continue
        
        # Generate UUIDs
        fileref_id = generate_uuid()
        buildfile_id = generate_uuid()
        
        print(f"\n📝 Adding {name}...")
        print(f"   FileRef ID: {fileref_id}")
        print(f"   BuildFile ID: {buildfile_id}")
        
        # 1. Add PBXFileReference
        fileref_entry = f'\t\t{fileref_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};\n'
        
        # Find end of PBXFileReference section
        fileref_section_end = content.find('/* End PBXFileReference section */')
        content = content[:fileref_section_end] + fileref_entry + content[fileref_section_end:]
        print(f"   ✅ Added PBXFileReference")
        
        # 2. Add PBXBuildFile
        buildfile_entry = f'\t\t{buildfile_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fileref_id} /* {name} */; }};\n'
        
        # Find end of PBXBuildFile section
        buildfile_section_end = content.find('/* End PBXBuildFile section */')
        content = content[:buildfile_section_end] + buildfile_entry + content[buildfile_section_end:]
        print(f"   ✅ Added PBXBuildFile")
        
        # 3. Add to appropriate PBXGroup (Managers, Views, or Models)
        group_name = file_info['group_name']
        
        # Find the group
        group_pattern = rf'/\* {group_name} \*/.*?isa = PBXGroup;.*?children = \((.*?)\);'
        group_match = re.search(group_pattern, content, re.DOTALL)
        
        if group_match:
            group_children = group_match.group(1)
            # Add to end of children array
            new_child_entry = f'\n\t\t\t\t{fileref_id} /* {name} */,'
            
            # Find the position to insert (before the closing parenthesis)
            group_end = group_match.end(1)
            content = content[:group_end] + new_child_entry + content[group_end:]
            print(f"   ✅ Added to {group_name} group")
        else:
            print(f"   ⚠️  Could not find {group_name} group")
        
        # 4. Add to Sources build phase
        sources_pattern = rf'{sources_phase_id} /\* Sources \*/.*?isa = PBXSourcesBuildPhase;.*?files = \((.*?)\);'
        sources_match = re.search(sources_pattern, content, re.DOTALL)
        
        if sources_match:
            new_build_entry = f'\n\t\t\t\t{buildfile_id} /* {name} in Sources */,'
            sources_end = sources_match.end(1)
            content = content[:sources_end] + new_build_entry + content[sources_end:]
            print(f"   ✅ Added to Sources build phase")
        else:
            print(f"   ⚠️  Could not find Sources build phase")
    
    # Write updated content
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("\n" + "="*60)
    print("✅ Successfully updated project.pbxproj")
    print("="*60)
    return True

if __name__ == '__main__':
    try:
        success = add_files_to_xcode()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

