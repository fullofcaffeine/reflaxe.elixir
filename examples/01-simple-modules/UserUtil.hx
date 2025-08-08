
using StringTools;

/**
 * UserUtil - Demonstrates public and private functions
 * 
 * This example shows how to use @:private annotation to create
 * private functions (defp in Elixir) alongside public functions,
 * demonstrating proper encapsulation patterns.
 */
@:module
class UserUtil {
    
    /**
     * Public function - creates a new user
     * This will compile to "def create_user(name, email)"
     * Uses private helper functions for validation and formatting
     */
    function createUser(name: String, email: String): Dynamic {
        // Validate inputs using private functions
        if (!isValidName(name)) {
            throw "Invalid name provided";
        }
        
        if (!isValidEmail(email)) {
            throw "Invalid email provided";
        }
        
        // Format and create user using private helpers
        var formattedName = formatName(name);
        var normalizedEmail = normalizeEmail(email);
        
        return {
            name: formattedName,
            email: normalizedEmail,
            id: generateUserId(),
            createdAt: getCurrentTimestamp()
        };
    }
    
    /**
     * Public function - updates user information
     * Demonstrates how public functions can call private helpers
     */
    function updateUser(user: Dynamic, newName: String, newEmail: String): Dynamic {
        var updatedUser = {
            name: user.name,
            email: user.email,
            id: user.id,
            createdAt: user.createdAt
        };
        
        if (newName != null && isValidName(newName)) {
            updatedUser.name = formatName(newName);
        }
        
        if (newEmail != null && isValidEmail(newEmail)) {
            updatedUser.email = normalizeEmail(newEmail);
        }
        
        return updatedUser;
    }
    
    /**
     * Public function - formats user for display
     * Uses private formatting helpers
     */
    function formatUserForDisplay(user: Dynamic): String {
        var displayName = formatDisplayName(user.name);
        var maskedEmail = maskEmail(user.email);
        
        return displayName + " (" + maskedEmail + ")";
    }
    
    // Private helper functions - these compile to "defp" in Elixir
    
    /**
     * Private function - validates user name
     * Compiles to: defp is_valid_name(name)
     */
    @:private
    function isValidName(name: String): Bool {
        if (name == null || name.length == 0) {
            return false;
        }
        
        // Name must be between 1 and 50 characters
        return name.length >= 1 && name.length <= 50;
    }
    
    /**
     * Private function - validates email format
     * Basic email validation for demonstration
     */
    @:private
    function isValidEmail(email: String): Bool {
        if (email == null || email.length == 0) {
            return false;
        }
        
        // Simple email validation - contains @ and .
        return email.indexOf("@") > 0 && email.indexOf(".") > 0;
    }
    
    /**
     * Private function - formats name consistently
     * Trims whitespace and capitalizes properly
     */
    @:private
    function formatName(name: String): String {
        var trimmed = StringTools.trim(name);
        var words = trimmed.split(" ");
        var formatted = [];
        
        for (word in words) {
            if (word.length > 0) {
                var capitalized = word.charAt(0).toUpperCase() + word.substr(1).toLowerCase();
                formatted.push(capitalized);
            }
        }
        
        return formatted.join(" ");
    }
    
    /**
     * Private function - normalizes email to lowercase
     */
    @:private
    function normalizeEmail(email: String): String {
        return StringTools.trim(email).toLowerCase();
    }
    
    /**
     * Private function - generates unique user ID
     * In real implementation, this would use proper UUID generation
     */
    @:private
    function generateUserId(): String {
        return "user_" + Math.floor(Math.random() * 1000000);
    }
    
    /**
     * Private function - gets current timestamp
     * In real implementation, this would use proper datetime functions
     */
    @:private
    function getCurrentTimestamp(): String {
        return "2024-01-01T00:00:00Z";
    }
    
    /**
     * Private function - formats name for display
     */
    @:private
    function formatDisplayName(name: String): String {
        // For display, we might want to show only first name + last initial
        var parts = name.split(" ");
        if (parts.length > 1) {
            return parts[0] + " " + parts[parts.length - 1].charAt(0) + ".";
        }
        return name;
    }
    
    /**
     * Private function - masks email for privacy
     */
    @:private
    function maskEmail(email: String): String {
        var parts = email.split("@");
        if (parts.length != 2) return email;
        
        var username = parts[0];
        var domain = parts[1];
        
        // Show first 2 characters, then stars, then @ and domain
        if (username.length <= 2) {
            return "**@" + domain;
        }
        
        var visible = username.substr(0, 2);
        var stars = "****";
        return visible + stars + "@" + domain;
    }
    
    /**
     * Main function for compilation testing  
     */
    public static function main(): Void {
        trace("UserUtil example compiled successfully!");
        trace("This demonstrates public/private function patterns.");
        trace("Public functions provide the API, private functions handle implementation details.");
    }
}