package services;

using StringTools;

/**
 * UserService - Demonstrates business logic module in Mix project
 * 
 * This service handles user-related operations and demonstrates how
 * Haxe modules integrate seamlessly with Mix project structure.
 */
@:module
class UserService {
    
    /**
     * Creates a new user with validation
     * Returns {:ok, user} or {:error, reason} tuple
     */
    function createUser(userData: Dynamic): Dynamic {
        // Validate required fields
        if (!isValidUserData(userData)) {
            return {error: "Invalid user data provided"};
        }
        
        // Create user with processed data
        var user = {
            id: generateUserId(),
            name: formatName(userData.name),
            email: normalizeEmail(userData.email),
            age: userData.age != null ? userData.age : 0,
            createdAt: getCurrentTimestamp(),
            status: "active"
        };
        
        return {ok: user};
    }
    
    /**
     * Updates user information with validation
     */
    function updateUser(userId: String, updates: Dynamic): Dynamic {
        if (userId == null || userId.trim().length == 0) {
            return {error: "User ID is required"};
        }
        
        // Simulate user lookup (in real app, this would query database)
        var existingUser = getUserById(userId);
        if (existingUser == null) {
            return {error: "User not found"};
        }
        
        // Apply updates with validation
        var updatedUser = applyUserUpdates(existingUser, updates);
        return {ok: updatedUser};
    }
    
    /**
     * Retrieves user by ID (simulated for example)
     */
    function getUserById(userId: String): Dynamic {
        if (userId == null) return null;
        
        // In real implementation, this would query the database
        // For demo purposes, return a mock user
        return {
            id: userId,
            name: "Mock User",
            email: "mock@example.com",
            age: 25,
            createdAt: getCurrentTimestamp(),
            status: "active"
        };
    }
    
    /**
     * Lists users with pagination (simulated)
     */
    function listUsers(page: Int = 1, perPage: Int = 10): Dynamic {
        // Simulate pagination logic
        var users = [];
        for (i in 0...Std.int(Math.min(perPage, 5))) {
            users.push({
                id: "user_" + (page * perPage + i),
                name: "User " + (i + 1),
                email: "user" + (i + 1) + "@example.com",
                age: 20 + i,
                createdAt: getCurrentTimestamp(),
                status: "active"
            });
        }
        
        return {
            data: users,
            page: page,
            perPage: perPage,
            total: 50 // Mock total
        };
    }
    
    // Private helper functions
    
    @:private
    function isValidUserData(data: Dynamic): Bool {
        if (data == null) return false;
        if (data.name == null || data.name.trim().length == 0) return false;
        if (data.email == null || !isValidEmail(data.email)) return false;
        return true;
    }
    
    @:private
    function isValidEmail(email: String): Bool {
        if (email == null) return false;
        var trimmed = email.trim();
        return trimmed.indexOf("@") > 0 && trimmed.indexOf(".") > 0;
    }
    
    @:private
    function formatName(name: String): String {
        if (name == null) return "";
        return name.trim().split(" ")
            .map(function(word) return word.charAt(0).toUpperCase() + word.substr(1).toLowerCase())
            .join(" ");
    }
    
    @:private
    function normalizeEmail(email: String): String {
        if (email == null) return "";
        return email.trim().toLowerCase();
    }
    
    @:private
    function generateUserId(): String {
        return "usr_" + Std.int(Math.random() * 1000000);
    }
    
    @:private
    function getCurrentTimestamp(): String {
        return "2024-01-01T00:00:00Z"; // Mock timestamp
    }
    
    @:private
    function applyUserUpdates(user: Dynamic, updates: Dynamic): Dynamic {
        var updated = {
            id: user.id,
            name: updates.name != null ? formatName(updates.name) : user.name,
            email: updates.email != null ? normalizeEmail(updates.email) : user.email,
            age: updates.age != null ? updates.age : user.age,
            createdAt: user.createdAt,
            status: updates.status != null ? updates.status : user.status
        };
        
        return updated;
    }
    
    /**
     * Main function for compilation testing
     */
    public static function main(): Void {
        trace("UserService compiled successfully for Mix project!");
    }
}