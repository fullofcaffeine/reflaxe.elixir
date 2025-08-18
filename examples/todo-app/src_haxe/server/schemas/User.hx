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
class User {
    @:field public var id: Int;
    @:field public var name: String;
    @:field public var email: String;
    @:field public var password_hash: String;
    @:field public var confirmed_at: Dynamic; // Date type for email confirmation
    @:field public var last_login_at: Dynamic; // Date type for tracking activity
    @:field public var active: Bool = true;
    
    // Virtual field for password input (not stored in database)
    @:virtual @:field public var password: String;
    @:virtual @:field public var password_confirmation: String;
    
    public function new() {
        this.active = true;
    }
    
    /**
     * Registration changeset for new user creation
     * Includes password validation and hashing
     */
    @:changeset
    public static function registration_changeset(user: Dynamic, params: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.changeset_cast(user, params, [
            "name", "email", "password", "password_confirmation"
        ]);
        
        // Basic validations
        changeset = phoenix.Ecto.EctoChangeset.validate_required(changeset, ["name", "email", "password"]);
        changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "name", {min: 2, max: 100});
        changeset = phoenix.Ecto.EctoChangeset.validate_format(changeset, "email", {pattern: "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$"});
        changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "password", {min: 8, max: 128});
        changeset = phoenix.Ecto.EctoChangeset.validate_confirmation(changeset, "password");
        changeset = phoenix.Ecto.EctoChangeset.unique_constraint(changeset, "email");
        
        // Hash password if valid
        if (phoenix.Ecto.EctoChangeset.get_change(changeset, "password") != null) {
            changeset = put_password_hash(changeset);
        }
        
        return changeset;
    }
    
    /**
     * Update changeset for existing user modifications
     * Allows updating name and email without password changes
     */
    @:changeset
    public static function changeset(user: Dynamic, params: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.changeset_cast(user, params, [
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
    public static function password_changeset(user: Dynamic, params: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.changeset_cast(user, params, [
            "password", "password_confirmation"
        ]);
        
        changeset = phoenix.Ecto.EctoChangeset.validate_required(changeset, ["password"]);
        changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "password", {min: 8, max: 128});
        changeset = phoenix.Ecto.EctoChangeset.validate_confirmation(changeset, "password");
        
        if (phoenix.Ecto.EctoChangeset.get_change(changeset, "password") != null) {
            changeset = put_password_hash(changeset);
        }
        
        return changeset;
    }
    
    /**
     * Email confirmation changeset
     */
    public static function confirm_changeset(user: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.change(user, {confirmed_at: now()});
        return changeset;
    }
    
    /**
     * Login tracking changeset
     */
    public static function login_changeset(user: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.change(user, {last_login_at: now()});
        return changeset;
    }
    
    // Helper functions for authentication
    
    /**
     * Hash password and put in changeset
     */
    static function put_password_hash(changeset: Dynamic): Dynamic {
        var password = phoenix.Ecto.EctoChangeset.get_change(changeset, "password");
        if (password != null) {
            var hashed = hash_password(password);
            return phoenix.Ecto.EctoChangeset.put_change(changeset, "password_hash", hashed);
        }
        return changeset;
    }
    
    /**
     * Hash password using bcrypt (simplified for demo)
     * In production, would use proper bcrypt library
     */
    static function hash_password(password: String): String {
        // In a real application, use Bcrypt.hash_pwd_salt(password)
        // For demo purposes, using a simple hash (NOT secure)
        return "hashed_" + password;
    }
    
    /**
     * Verify password against hash
     */
    public static function verify_password(user: Dynamic, password: String): Bool {
        // In a real application, use Bcrypt.verify_pass(password, user.password_hash)
        // For demo purposes, simple verification
        return user.password_hash == "hashed_" + password;
    }
    
    /**
     * Check if user is confirmed
     */
    public static function confirmed(user: Dynamic): Bool {
        return user.confirmed_at != null;
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
    public static function create_demo_user(): Dynamic {
        return {
            id: 1,
            name: "Demo User",
            email: "demo@example.com",
            password_hash: "hashed_demopassword",
            confirmed_at: now(),
            last_login_at: now(),
            active: true
        };
    }
    
    /**
     * Display name for user (for UI)
     */
    public static function display_name(user: Dynamic): String {
        return user.name != null && user.name != "" ? user.name : user.email;
    }
    
    /**
     * User initials for avatars
     */
    public static function initials(user: Dynamic): String {
        var name = display_name(user);
        var parts = name.split(" ");
        if (parts.length >= 2) {
            return parts[0].charAt(0).toUpperCase() + parts[1].charAt(0).toUpperCase();
        }
        return name.charAt(0).toUpperCase();
    }
}