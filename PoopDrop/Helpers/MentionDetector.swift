import Foundation

/// A utility for detecting and parsing @mentions in text
/// Clean, reusable, and testable
struct MentionDetector {
    
    // MARK: - Core Detection
    
    /// Extracts all @username mentions from text
    /// Returns array of usernames WITHOUT the @ symbol
    /// Example: "Hey @Sarah and @Jake!" → ["Sarah", "Jake"]
    static func extractMentions(from text: String) -> [String] {
        // Regex pattern: @ followed by alphanumeric characters and underscores
        // Matches: @username, @user_name, @user123
        // Does NOT match: @, @@, @123 (must start with letter)
        let pattern = "@([a-zA-Z][a-zA-Z0-9_]*)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)
        
        var mentions: [String] = []
        for match in matches {
            // Capture group 1 is the username (without @)
            if let usernameRange = Range(match.range(at: 1), in: text) {
                let username = String(text[usernameRange])
                // Only add unique mentions
                if !mentions.contains(username) {
                    mentions.append(username)
                }
            }
        }
        
        return mentions
    }
    
    // MARK: - Validation
    
    /// Validates if a username is properly formatted
    /// Rules: 3-20 chars, starts with letter, alphanumeric + underscore
    static func isValidUsername(_ username: String) -> Bool {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        
        // Length check
        guard trimmed.count >= 3 && trimmed.count <= 20 else {
            return false
        }
        
        // Pattern check: starts with letter, alphanumeric + underscore
        let pattern = "^[a-zA-Z][a-zA-Z0-9_]*$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return false
        }
        
        let nsRange = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        return regex.firstMatch(in: trimmed, options: [], range: nsRange) != nil
    }
    
    // MARK: - Rich Text Processing
    
    /// Splits text into segments, marking which parts are mentions
    /// Used for rendering tappable @mentions in SwiftUI
    /// Example: "Hey @Sarah!" → [.text("Hey "), .mention("Sarah"), .text("!")]
    static func parseTextSegments(from text: String) -> [TextSegment] {
        let pattern = "@([a-zA-Z][a-zA-Z0-9_]*)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [.text(text)]
        }
        
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)
        
        var segments: [TextSegment] = []
        var currentIndex = text.startIndex
        
        for match in matches {
            guard let matchRange = Range(match.range, in: text),
                  let usernameRange = Range(match.range(at: 1), in: text) else {
                continue
            }
            
            // Add text before mention
            if currentIndex < matchRange.lowerBound {
                let beforeText = String(text[currentIndex..<matchRange.lowerBound])
                if !beforeText.isEmpty {
                    segments.append(.text(beforeText))
                }
            }
            
            // Add mention (without @)
            let username = String(text[usernameRange])
            segments.append(.mention(username))
            
            currentIndex = matchRange.upperBound
        }
        
        // Add remaining text
        if currentIndex < text.endIndex {
            let remainingText = String(text[currentIndex...])
            if !remainingText.isEmpty {
                segments.append(.text(remainingText))
            }
        }
        
        return segments.isEmpty ? [.text(text)] : segments
    }
    
    // MARK: - Text Segment Model
    
    enum TextSegment: Identifiable {
        case text(String)
        case mention(String) // Username without @
        
        var id: String {
            switch self {
            case .text(let str):
                return "text_\(str)"
            case .mention(let username):
                return "mention_\(username)"
            }
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension MentionDetector {
    static func runTests() {
        print("🧪 Testing MentionDetector...")
        
        // Test 1: Basic extraction
        let test1 = extractMentions(from: "Hey @Sarah and @Jake!")
        assert(test1 == ["Sarah", "Jake"], "Test 1 failed: \(test1)")
        print("✅ Test 1: Basic extraction")
        
        // Test 2: No duplicates
        let test2 = extractMentions(from: "@Sarah and @Sarah again")
        assert(test2 == ["Sarah"], "Test 2 failed: \(test2)")
        print("✅ Test 2: Duplicate removal")
        
        // Test 3: Underscores and numbers
        let test3 = extractMentions(from: "Hey @sarah_123 and @john_doe")
        assert(test3 == ["sarah_123", "john_doe"], "Test 3 failed: \(test3)")
        print("✅ Test 3: Underscores and numbers")
        
        // Test 4: Invalid mentions (starting with number)
        let test4 = extractMentions(from: "Invalid: @123abc")
        assert(test4 == [], "Test 4 failed: \(test4)")
        print("✅ Test 4: Invalid mentions filtered")
        
        // Test 5: Empty text
        let test5 = extractMentions(from: "")
        assert(test5 == [], "Test 5 failed: \(test5)")
        print("✅ Test 5: Empty text")
        
        // Test 6: No mentions
        let test6 = extractMentions(from: "Just regular text")
        assert(test6 == [], "Test 6 failed: \(test6)")
        print("✅ Test 6: No mentions")
        
        // Test 7: Username validation
        assert(isValidUsername("Sarah") == true, "Test 7a failed")
        assert(isValidUsername("sa") == false, "Test 7b failed (too short)")
        assert(isValidUsername("a".repeating(21)) == false, "Test 7c failed (too long)")
        assert(isValidUsername("123abc") == false, "Test 7d failed (starts with number)")
        print("✅ Test 7: Username validation")
        
        // Test 8: Text segmentation
        let test8 = parseTextSegments(from: "Hey @Sarah and @Jake!")
        assert(test8.count == 5, "Test 8 failed: expected 5 segments, got \(test8.count)")
        print("✅ Test 8: Text segmentation")
        
        print("🎉 All MentionDetector tests passed!")
    }
}

extension String {
    func repeating(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}
#endif

