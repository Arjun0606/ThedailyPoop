#!/usr/bin/env python3
"""
Script to add Gossip-related files to the Xcode project
"""

import uuid
import sys

def generate_uuid():
    """Generate a 24-character uppercase hex string for Xcode UUIDs"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_xcode_project(pbxproj_path):
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Generate UUIDs for new files
    gossip_model_uuid = generate_uuid()
    gossip_model_build_uuid = generate_uuid()
    gossip_manager_uuid = generate_uuid()
    gossip_manager_build_uuid = generate_uuid()
    gossip_view_uuid = generate_uuid()
    gossip_view_build_uuid = generate_uuid()
    
    # 1. Add file references to PBXFileReference section
    file_ref_section = "/* Begin PBXFileReference section */"
    file_refs = f"""{file_ref_section}
\t\t{gossip_model_uuid} /* Gossip.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Gossip.swift; sourceTree = "<group>"; }};
\t\t{gossip_manager_uuid} /* GossipManager.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = GossipManager.swift; sourceTree = "<group>"; }};
\t\t{gossip_view_uuid} /* GossipFeedView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = GossipFeedView.swift; sourceTree = "<group>"; }};"""
    
    content = content.replace(file_ref_section, file_refs)
    
    # 2. Add to Models group (find the Models children array)
    # Look for the Models group and add Gossip.swift
    models_marker = "F5E8B2F92C9A4E7B00123456 /* Models */,"
    if models_marker in content:
        # Find the Models group section
        models_section_start = content.find("F5E8B2F92C9A4E7B00123456 /* Models */ = {")
        if models_section_start != -1:
            # Find the children array within Models
            children_start = content.find("children = (", models_section_start)
            children_end = content.find(");", children_start)
            if children_start != -1 and children_end != -1:
                # Insert new file reference
                insert_pos = children_end
                new_entry = f"\n\t\t\t\t{gossip_model_uuid} /* Gossip.swift */,"
                content = content[:insert_pos] + new_entry + content[insert_pos:]
    
    # 3. Add to Managers group
    managers_marker = "F5E8B2FA2C9A4E7B00123457 /* Managers */,"
    if managers_marker in content:
        managers_section_start = content.find("F5E8B2FA2C9A4E7B00123457 /* Managers */ = {")
        if managers_section_start != -1:
            children_start = content.find("children = (", managers_section_start)
            children_end = content.find(");", children_start)
            if children_start != -1 and children_end != -1:
                insert_pos = children_end
                new_entry = f"\n\t\t\t\t{gossip_manager_uuid} /* GossipManager.swift */,"
                content = content[:insert_pos] + new_entry + content[insert_pos:]
    
    # 4. Add to Views group
    views_marker = "F5E8B2FB2C9A4E7B00123458 /* Views */,"
    if views_marker in content:
        views_section_start = content.find("F5E8B2FB2C9A4E7B00123458 /* Views */ = {")
        if views_section_start != -1:
            children_start = content.find("children = (", views_section_start)
            children_end = content.find(");", children_start)
            if children_start != -1 and children_end != -1:
                insert_pos = children_end
                new_entry = f"\n\t\t\t\t{gossip_view_uuid} /* GossipFeedView.swift */,"
                content = content[:insert_pos] + new_entry + content[insert_pos:]
    
    # 5. Add to PBXBuildFile section (for compilation)
    build_file_section = "/* Begin PBXBuildFile section */"
    build_files = f"""{build_file_section}
\t\t{gossip_model_build_uuid} /* Gossip.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {gossip_model_uuid} /* Gossip.swift */; }};
\t\t{gossip_manager_build_uuid} /* GossipManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {gossip_manager_uuid} /* GossipManager.swift */; }};
\t\t{gossip_view_build_uuid} /* GossipFeedView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {gossip_view_uuid} /* GossipFeedView.swift */; }};"""
    
    content = content.replace(build_file_section, build_files)
    
    # 6. Add to PBXSourcesBuildPhase (files to compile)
    sources_phase_marker = "/* Begin PBXSourcesBuildPhase section */"
    sources_phase_start = content.find(sources_phase_marker)
    if sources_phase_start != -1:
        # Find the files array within PBXSourcesBuildPhase
        files_start = content.find("files = (", sources_phase_start)
        files_end = content.find(");", files_start)
        if files_start != -1 and files_end != -1:
            insert_pos = files_end
            new_entries = f"""
\t\t\t\t{gossip_model_build_uuid} /* Gossip.swift in Sources */,
\t\t\t\t{gossip_manager_build_uuid} /* GossipManager.swift in Sources */,
\t\t\t\t{gossip_view_build_uuid} /* GossipFeedView.swift in Sources */,"""
            content = content[:insert_pos] + new_entries + content[insert_pos:]
    
    # Write back
    with open(pbxproj_path, 'w') as f:
        f.write(content)
    
    print("✅ Successfully added Gossip files to Xcode project:")
    print(f"   - Gossip.swift (Model)")
    print(f"   - GossipManager.swift (Manager)")
    print(f"   - GossipFeedView.swift (View)")
    print(f"\n💡 Next steps:")
    print(f"   1. Open Xcode and verify the files appear")
    print(f"   2. Build the project (Cmd+B)")
    print(f"   3. If files don't appear, manually add them in Xcode")

if __name__ == "__main__":
    pbxproj_path = "/Users/arjun/poopdrop/PoopDrop.xcodeproj/project.pbxproj"
    try:
        add_files_to_xcode_project(pbxproj_path)
    except Exception as e:
        print(f"❌ Error: {e}")
        print(f"\n💡 If this fails, manually add the files in Xcode:")
        print(f"   1. Right-click on Models folder → Add Files")
        print(f"   2. Select Gossip.swift")
        print(f"   3. Right-click on Managers folder → Add Files")
        print(f"   4. Select GossipManager.swift")
        print(f"   5. Right-click on Views folder → Add Files")
        print(f"   6. Select GossipFeedView.swift")
        sys.exit(1)

