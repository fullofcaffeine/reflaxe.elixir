package utils;

using StringTools;

/**
 * StringUtils - String processing utilities for Mix project
 * 
 * This module demonstrates utility functions that can be shared
 * across different parts of a Mix project.
 */
@:module  
class StringUtils {
    
    /**
     * Processes a string with common transformations
     * Trims whitespace, handles case conversion, validates format
     */
    function processString(input: String): String {
        if (input == null) return "";
        
        var processed = input.trim();
        
        if (processed.length == 0) {
            return "[empty]";
        }
        
        // Apply common transformations
        processed = removeExcessWhitespace(processed);
        processed = normalizeCase(processed);
        
        return processed;
    }
    
    /**
     * Formats a display name for user interfaces
     * Capitalizes first letters, handles special cases
     */
    function formatDisplayName(name: String): String {
        if (name == null || name.trim().length == 0) {
            return "Anonymous User";
        }
        
        var parts = name.trim().split(" ");
        var formatted = [];
        
        for (part in parts) {
            if (part.length > 0) {
                var capitalized = part.charAt(0).toUpperCase() + part.substr(1).toLowerCase();
                formatted.push(capitalized);
            }
        }
        
        return formatted.join(" ");
    }
    
    /**
     * Validates and formats email addresses
     */
    function processEmail(email: String): Dynamic {
        if (email == null) {
            return {valid: false, error: "Email is required"};
        }
        
        var trimmed = email.trim();
        
        if (trimmed.length == 0) {
            return {valid: false, error: "Email cannot be empty"};
        }
        
        if (!isValidEmailFormat(trimmed)) {
            return {valid: false, error: "Invalid email format"};
        }
        
        return {
            valid: true,
            email: trimmed.toLowerCase(),
            domain: extractDomain(trimmed),
            username: extractUsername(trimmed)
        };
    }
    
    /**
     * Generates a URL-friendly slug from text
     */
    function createSlug(text: String): String {
        if (text == null) return "";
        
        var slug = text.toLowerCase().trim();
        slug = new EReg("[^a-z0-9\\s-]", "g").replace(slug, "");  // Remove special chars
        slug = new EReg("\\s+", "g").replace(slug, "-");          // Replace spaces with hyphens
        slug = new EReg("-+", "g").replace(slug, "-");            // Collapse multiple hyphens
        
        // Remove leading/trailing hyphens
        while (slug.charAt(0) == "-") {
            slug = slug.substr(1);
        }
        while (slug.charAt(slug.length - 1) == "-") {
            slug = slug.substr(0, slug.length - 1);
        }
        
        return slug;
    }
    
    /**
     * Truncates text to specified length with ellipsis
     */
    function truncate(text: String, maxLength: Int = 100): String {
        if (text == null) return "";
        if (text.length <= maxLength) return text;
        
        var truncated = text.substr(0, maxLength - 3);
        
        // Try to break at a word boundary
        var lastSpace = truncated.lastIndexOf(" ");
        if (lastSpace > Std.int(maxLength * 0.7)) { // Only break if we don't lose too much
            truncated = truncated.substr(0, lastSpace);
        }
        
        return truncated + "...";
    }
    
    /**
     * Masks sensitive information (like email addresses)
     */
    function maskSensitiveInfo(text: String, visibleChars: Int = 2): String {
        if (text == null || text.length <= visibleChars) {
            var repeatCount = text != null ? text.length : 4;
        var result = "";
        for (i in 0...repeatCount) {
            result += "*";
        }
        return result;
        }
        
        var visible = text.substr(0, visibleChars);
        var maskedCount = text.length - visibleChars;
        var masked = "";
        for (i in 0...maskedCount) {
            masked += "*";
        }
        return visible + masked;
    }
    
    // Private helper functions
    
    @:private
    function removeExcessWhitespace(text: String): String {
        // Replace multiple whitespace characters with single space
        return new EReg("\\s+", "g").replace(text, " ");
    }
    
    @:private
    function normalizeCase(text: String): String {
        // Simple case normalization - could be enhanced based on needs
        return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
    }
    
    @:private
    function isValidEmailFormat(email: String): Bool {
        // Basic email validation - in production, use more robust validation
        var atIndex = email.indexOf("@");
        var dotIndex = email.lastIndexOf(".");
        
        return atIndex > 0 && dotIndex > atIndex && dotIndex < email.length - 1;
    }
    
    @:private
    function extractDomain(email: String): String {
        var atIndex = email.indexOf("@");
        return atIndex > 0 ? email.substr(atIndex + 1) : "";
    }
    
    @:private
    function extractUsername(email: String): String {
        var atIndex = email.indexOf("@");
        return atIndex > 0 ? email.substr(0, atIndex) : email;
    }
    
    /**
     * Main function for compilation testing
     */
    public static function main(): Void {
        trace("StringUtils compiled successfully for Mix project!");
    }
}