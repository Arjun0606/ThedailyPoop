#!/usr/bin/env python3
import uuid
import sys

# Files to add
files = [
    ("PollManager.swift", "PoopDrop/Managers/PollManager.swift", "Managers"),
    ("DailyPollView.swift", "PoopDrop/Views/DailyPollView.swift", "Views")
]

# Read the project file
with open('PoopDrop.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

for file_name, file_path, group in files:
    # Generate UUIDs for the new file
    file_ref_uuid = uuid.uuid4().hex[:24].upper()
    build_file_uuid = uuid.uuid4().hex[:24].upper()

    # 1. Add PBXFileReference
    file_ref = f'\t\t{file_ref_uuid} /* {file_name} */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};\n'

    pbx_file_ref_end = content.find('/* End PBXFileReference section */')
    content = content[:pbx_file_ref_end] + file_ref + content[pbx_file_ref_end:]

    # 2. Add PBXBuildFile
    build_file = f'\t\t{build_file_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {file_name} */; }};\n'

    pbx_build_file_end = content.find('/* End PBXBuildFile section */')
    content = content[:pbx_build_file_end] + build_file + content[pbx_build_file_end:]

    # 3. Add to group
    group_marker = content.find(f'/* {group} */')
    if group_marker == -1:
        print(f"❌ Could not find {group} group")
        continue

    children_start = content.find('children = (', group_marker)
    children_end = content.find(');', children_start)

    new_child = f'\n\t\t\t\t{file_ref_uuid} /* {file_name} */,'
    content = content[:children_end] + new_child + content[children_end:]

    # 4. Add to PBXSourcesBuildPhase
    sources_phase_start = content.find('/* Sources */ = {')
    files_start = content.find('files = (', sources_phase_start)
    files_end = content.find(');', files_start)

    new_source = f'\n\t\t\t\t{build_file_uuid} /* {file_name} in Sources */,'
    content = content[:files_end] + new_source + content[files_end:]

    print(f"✅ Added {file_name}")

# Write back
with open('PoopDrop.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✅ All files added to Xcode project")

