package services;

import elixir.types.Result;

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
    public static function createUser(userData: NewUserInput): Result<User, String> {
        // Validate required fields
        if (!isValidUserData(userData)) {
            return Error("Invalid user data provided");
        }
        
        // Create user with processed data
        var user: User = {
            id: generateUserId(),
            name: formatName(userData.name),
            email: normalizeEmail(userData.email),
            age: userData.age != null ? userData.age : 0,
            createdAt: getCurrentTimestamp(),
            status: "active"
        };
        
        return Ok(user);
    }
    
    /**
     * Updates user information with validation
     */
    public static function updateUser(userId: String, updates: UserUpdates): Result<User, String> {
        if (userId == null || userId.trim().length == 0) {
            return Error("User ID is required");
        }
        
        // Simulate user lookup (in real app, this would query database)
        var existingUser = getUserById(userId);
        if (existingUser == null) {
            return Error("User not found");
        }
        
        // Apply updates with validation
        var updatedUser = applyUserUpdates(existingUser, updates);
        return Ok(updatedUser);
    }
    
    /**
     * Retrieves user by ID (simulated for example)
     */
    public static function getUserById(userId: String): Null<User> {
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
    public static function listUsers(page: Int = 1, perPage: Int = 10): UserListPage {
        // Simulate pagination logic
        var users: Array<User> = [];
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
    static function isValidUserData(data: NewUserInput): Bool {
        if (data == null) return false;
        if (data.name == null || data.name.trim().length == 0) return false;
        if (data.email == null || !isValidEmail(data.email)) return false;
        return true;
    }
    
    @:private
    static function isValidEmail(email: String): Bool {
        if (email == null) return false;
        var trimmed = email.trim();
        return trimmed.indexOf("@") > 0 && trimmed.indexOf(".") > 0;
    }
    
    @:private
    static function formatName(name: String): String {
        if (name == null) return "";
        return name.trim().split(" ")
            .map(function(word) return word.charAt(0).toUpperCase() + word.substr(1).toLowerCase())
            .join(" ");
    }
    
    @:private
    static function normalizeEmail(email: String): String {
        if (email == null) return "";
        return email.trim().toLowerCase();
    }
    
    @:private
    static function generateUserId(): String {
        return "usr_" + Std.int(Math.random() * 1000000);
    }
    
    @:private
    static function getCurrentTimestamp(): String {
        return "2024-01-01T00:00:00Z"; // Mock timestamp
    }
    
    @:private
    static function applyUserUpdates(user: User, updates: UserUpdates): User {
        var updated: User = {
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

typedef User = {
    var id: String;
    var name: String;
    var email: String;
    var age: Int;
    var createdAt: String;
    var status: String;
}

typedef NewUserInput = {
    var name: String;
    var email: String;
    var ?age: Int;
}

typedef UserUpdates = {
    var ?name: String;
    var ?email: String;
    var ?age: Int;
    var ?status: String;
}

typedef UserListPage = {
    var data: Array<User>;
    var page: Int;
    var perPage: Int;
    var total: Int;
}
