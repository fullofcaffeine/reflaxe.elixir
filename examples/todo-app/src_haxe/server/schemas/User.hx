package server.schemas;

import phoenix.Ecto;

/**
 * User schema for authentication and todo ownership
 * 
 * Provides a simple user model with basic authentication fields
 * and relationship to todos for user-specific task management.
 */
@:schema
@:timestamps
@:keep
class User {
    @:field public var id: Int;
    @:field public var name: String;
    @:field public var email: String;
    @:field public var passwordHash: String;
    @:field public var confirmedAt: Dynamic; // Date type for email confirmation
    @:field public var lastLoginAt: Dynamic; // Date type for tracking activity
    @:field public var active: Bool = true;
    
    // Virtual field for password input (not stored in database)
    @:virtual @:field public var password: String;
    @:virtual @:field public var passwordConfirmation: String;
    
    public function new() {
        this.active = true;
    }
    
    /**
     * Registration changeset for new user creation
     * Includes password validation and hashing
     */
    @:changeset
    @:keep
    public static function registrationChangeset(user: Dynamic, params: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.castChangeset(user, params, [
            "name", "email", "password", "passwordConfirmation"
        ]);
        
        // Basic validations
        changeset = phoenix.Ecto.EctoChangeset.validate_required(changeset, ["name", "email", "password"]);
        changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "name", {min: 2, max: 100});
        var emailPattern = ~/^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        changeset = phoenix.Ecto.EctoChangeset.validate_format(changeset, "email", emailPattern);
        changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "password", {min: 8, max: 128});
        changeset = phoenix.Ecto.EctoChangeset.validate_confirmation(changeset, "password");
        changeset = phoenix.Ecto.EctoChangeset.unique_constraint(changeset, "email");
        
        // Hash password if valid
        if (phoenix.Ecto.EctoChangeset.get_change(changeset, "password") != null) {
            changeset = putPasswordHash(changeset);
        }
        
        return changeset;
    }
    
    /**
     * Update changeset for existing user modifications
     * Allows updating name and email without password changes
     */
    @:changeset
    @:keep
    public static function changeset(user: Dynamic, params: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.castChangeset(user, params, [
            "name", "email", "active"
        ]);
        
        changeset = phoenix.Ecto.EctoChangeset.validate_required(changeset, ["name", "email"]);
        changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "name", {min: 2, max: 100});
        changeset = phoenix.Ecto.EctoChangeset.validate_format(changeset, "email", {pattern: "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$"});
        changeset = phoenix.Ecto.EctoChangeset.unique_constraint(changeset, "email");
        
        return changeset;
    }
    
    /**
     * Password change changeset for updating user passwords
     */
    @:changeset
    public static function passwordChangeset(user: Dynamic, params: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.castChangeset(user, params, [
            "password", "passwordConfirmation"
        ]);
        
        changeset = phoenix.Ecto.EctoChangeset.validate_required(changeset, ["password"]);
        changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "password", {min: 8, max: 128});
        changeset = phoenix.Ecto.EctoChangeset.validate_confirmation(changeset, "password");
        
        if (phoenix.Ecto.EctoChangeset.get_change(changeset, "password") != null) {
            changeset = putPasswordHash(changeset);
        }
        
        return changeset;
    }
    
    /**
     * Email confirmation changeset
     */
    public static function confirmChangeset(user: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.change(user, {confirmedAt: now()});
        return changeset;
    }
    
    /**
     * Login tracking changeset
     */
    public static function loginChangeset(user: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.change(user, {lastLoginAt: now()});
        return changeset;
    }
    
    // Helper functions for authentication
    
    /**
     * Hash password and put in changeset
     */
    static function putPasswordHash(changeset: Dynamic): Dynamic {
        var password = phoenix.Ecto.EctoChangeset.get_change(changeset, "password");
        if (password != null) {
            var hashed = hashPassword(password);
            return phoenix.Ecto.EctoChangeset.put_change(changeset, "passwordHash", hashed);
        }
        return changeset;
    }
    
    /**
     * Hash password using bcrypt (simplified for demo)
     * In production, would use proper bcrypt library
     */
    static function hashPassword(password: String): String {
        // In a real application, use Bcrypt.hash_pwd_salt(password)
        // For demo purposes, using a simple hash (NOT secure)
        return "hashed_" + password;
    }
    
    /**
     * Verify password against hash
     */
    public static function verifyPassword(user: Dynamic, password: String): Bool {
        // In a real application, use Bcrypt.verify_pass(password, user.passwordHash)
        // For demo purposes, simple verification
        return user.passwordHash == "hashed_" + password;
    }
    
    /**
     * Check if user is confirmed
     */
    public static function confirmed(user: Dynamic): Bool {
        return user.confirmedAt != null;
    }
    
    /**
     * Check if user is active
     */
    public static function active(user: Dynamic): Bool {
        return user.active == true;
    }
    
    /**
     * Get current timestamp
     */
    static function now(): Dynamic {
        // Would use DateTime.utc_now() in real Elixir
        return "2024-01-01T00:00:00Z"; // Demo timestamp
    }
    
    /**
     * Create a demo user for development
     */
    public static function createDemoUser(): Dynamic {
        return {
            id: 1,
            name: "Demo User",
            email: "demo@example.com",
            passwordHash: "hashed_demopassword",
            confirmedAt: now(),
            lastLoginAt: now(),
            active: true
        };
    }
    
    /**
     * Display name for user (for UI)
     */
    public static function displayName(user: Dynamic): String {
        return user.name != null && user.name != "" ? user.name : user.email;
    }
    
    /**
     * User initials for avatars
     */
    public static function initials(user: Dynamic): String {
        var name = displayName(user);
        var parts = name.split(" ");
        if (parts.length >= 2) {
            return parts[0].charAt(0).toUpperCase() + parts[1].charAt(0).toUpperCase();
        }
        return name.charAt(0).toUpperCase();
    }
}
