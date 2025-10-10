#!/usr/bin/env python3

import re
import uuid

def generate_unique_id():
    """Generate a unique ID similar to Xcode's format"""
    return str(uuid.uuid4()).upper().replace('-', '')[:24]

def read_project_file():
    """Read the project.pbxproj file"""
    with open('PoopDrop.xcodeproj/project.pbxproj', 'r') as f:
        return f.read()

def write_project_file(content):
    """Write the project.pbxproj file"""
    with open('PoopDrop.xcodeproj/project.pbxproj', 'w') as f:
        f.write(content)

def add_file_to_project(content, file_path, group_name):
    """Add a Swift file to the Xcode project"""
    file_name = file_path.split('/')[-1]
    
    # Generate unique IDs
    file_ref_id = generate_unique_id()
    build_file_id = generate_unique_id()
    
    # Add to PBXBuildFile section
    build_file_line = f"\t\t{build_file_id} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {file_name} */; }};"
    
    # Find the last PBXBuildFile entry and add after it
    build_file_pattern = r'(\t\t[A-F0-9]+ /\* .+ in Sources \*/ = \{isa = PBXBuildFile; fileRef = [A-F0-9]+ /\* .+ \*/; \};)\n'
    matches = list(re.finditer(build_file_pattern, content))
    if matches:
        last_match = matches[-1]
        insert_pos = last_match.end()
        content = content[:insert_pos] + build_file_line + '\n' + content[insert_pos:]
    
    # Add to PBXFileReference section
    file_ref_line = f"\t\t{file_ref_id} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = \"<group>\"; }};"
    
    # Find the last PBXFileReference entry and add after it
    file_ref_pattern = r'(\t\t[A-F0-9]+ /\* .+\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = .+\.swift; sourceTree = "<group>"; \};)\n'
    matches = list(re.finditer(file_ref_pattern, content))
    if matches:
        last_match = matches[-1]
        insert_pos = last_match.end()
        content = content[:insert_pos] + file_ref_line + '\n' + content[insert_pos:]
    
    # Add to appropriate PBXGroup section
    group_patterns = {
        'Models': r'(/\* Models \*/ = \{[^}]+children = \([^)]+)(\);)',
        'Managers': r'(/\* Managers \*/ = \{[^}]+children = \([^)]+)(\);)',
        'Views': r'(/\* Views \*/ = \{[^}]+children = \([^)]+)(\);)'
    }
    
    if group_name in group_patterns:
        pattern = group_patterns[group_name]
        replacement = f'\\1\n\t\t\t\t{file_ref_id} /* {file_name} */,\\2'
        content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    # Add to PBXSourcesBuildPhase
    sources_pattern = r'(files = \([^)]+)(\);[^}]+name = Sources;)'
    replacement = f'\\1\n\t\t\t\t{build_file_id} /* {file_name} in Sources */,\\2'
    content = re.sub(sources_pattern, replacement, content, flags=re.DOTALL)
    
    return content

def main():
    print("🔧 Fixing Xcode project by adding missing Swift files...")
    
    # Files to add with their groups
    missing_files = {
        'Managers': [
            'AdManager.swift',
            'AnimationManager.swift', 
            'FartAttackManager.swift',
            'FriendsManager.swift',
            'NotificationHandler.swift',
            'NotificationManager.swift',
            'StoreKitManager.swift'
        ],
        'Models': [
            'Badge.swift',
            'FartAttack.swift',
            'Friendship.swift',
            'Notification.swift',
            'Reaction.swift',
            'UserSession.swift'
        ],
        'Views': [
            'ExternalFartAttackView.swift',
            'FartAttackOnboardingView.swift',
            'FartAttackPromoCard.swift',
            'FartAttackReceivedView.swift',
            'FartAttackShopView.swift',
            'FriendsView.swift',
            'MapBannerAdView.swift',
            'NativeAdCardView.swift',
            'ProfilePictureEditor.swift',
            'ProfileSetupView.swift',
            'SnapchatStyleMapView.swift',
            'StreakView.swift',
            'TryProView.swift'
        ]
    }
    
    # Read current project file
    content = read_project_file()
    
    # Add each missing file
    for group, files in missing_files.items():
        for file_name in files:
            file_path = f"PoopDrop/{group}/{file_name}" if group != 'Views' else f"PoopDrop/Views/{file_name}"
            print(f"Adding {file_name} to {group} group...")
            content = add_file_to_project(content, file_path, group)
    
    # Write the updated project file
    write_project_file(content)
    print("✅ Xcode project updated successfully!")
    print("🚀 Try building the project now.")

if __name__ == "__main__":
    main()
