#!/usr/bin/env python3
import uuid
import sys

# Read the project file
with open('PoopDrop.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate UUIDs for the new file
file_ref_uuid = uuid.uuid4().hex[:24].upper()
build_file_uuid = uuid.uuid4().hex[:24].upper()

file_name = "ReferralManager.swift"
file_path = "PoopDrop/Managers/ReferralManager.swift"

# 1. Add PBXFileReference
file_ref = f'\t\t{file_ref_uuid} /* {file_name} */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};\n'

# Find the end of PBXFileReference section
pbx_file_ref_end = content.find('/* End PBXFileReference section */')
content = content[:pbx_file_ref_end] + file_ref + content[pbx_file_ref_end:]

# 2. Add PBXBuildFile
build_file = f'\t\t{build_file_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {file_name} */; }};\n'

pbx_build_file_end = content.find('/* End PBXBuildFile section */')
content = content[:pbx_build_file_end] + build_file + content[pbx_build_file_end:]

# 3. Add to Managers group (find the Managers children array)
managers_marker = content.find('/* Managers */')
if managers_marker == -1:
    print("❌ Could not find Managers group")
    sys.exit(1)

# Find the children array after Managers
children_start = content.find('children = (', managers_marker)
children_end = content.find(');', children_start)
managers_children = content[children_start:children_end]

# Add our file reference
new_child = f'\n\t\t\t\t{file_ref_uuid} /* {file_name} */,'
content = content[:children_end] + new_child + content[children_end:]

# 4. Add to PBXSourcesBuildPhase
sources_phase_start = content.find('/* Sources */ = {')
if sources_phase_start == -1:
    print("❌ Could not find Sources build phase")
    sys.exit(1)

files_start = content.find('files = (', sources_phase_start)
files_end = content.find(');', files_start)

new_source = f'\n\t\t\t\t{build_file_uuid} /* {file_name} in Sources */,'
content = content[:files_end] + new_source + content[files_end:]

# Write back
with open('PoopDrop.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print(f"✅ Added {file_name} to Xcode project")
print(f"   FileRef UUID: {file_ref_uuid}")
print(f"   BuildFile UUID: {build_file_uuid}")

