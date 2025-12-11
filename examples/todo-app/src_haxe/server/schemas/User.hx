package server.schemas;

import ecto.Changeset;
import elixir.DateTime.DateTime;

/**
 * User schema for authentication and todo ownership
 * 
 * Provides a simple user model with basic authentication fields
 * and relationship to todos for user-specific task management.
 */
@:native("TodoApp.User")
@:schema("users")
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
    @:keep
    public static function registrationChangeset(user: Dynamic, params: Dynamic): Dynamic {
        return untyped __elixir__('
            {0}
            |> Ecto.Changeset.cast({1}, [:name, :email, :password, :password_confirmation])
            |> Ecto.Changeset.validate_required([:name, :email, :password])
            |> Ecto.Changeset.validate_length(:name, min: 2, max: 100)
            |> Ecto.Changeset.validate_format(:email, ~r/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/)
            |> Ecto.Changeset.validate_length(:password, min: 8, max: 128)
            |> Ecto.Changeset.validate_confirmation(:password)
            |> Ecto.Changeset.unique_constraint(:email)
        ', user, params);
    }
    
    /**
     * Update changeset for existing user modifications
     * Allows updating name and email without password changes
     */
    @:keep
    public static function changeset(user: Dynamic, params: Dynamic): Dynamic {
        var cs: ecto.Changeset<Dynamic, Dynamic> = new ecto.Changeset(user, params);
        cs = cs.validateRequired(["name","email"]);
        cs = cs.validateLength("name", {min: 2, max: 100});
        cs = cs.validateFormat("email", ~/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/);
        cs = cs.uniqueConstraint("email");
        return cs;
    }
    
    /**
     * Password change changeset for updating user passwords
     */
    @:keep
    public static function passwordChangeset(user: Dynamic, params: Dynamic): Dynamic {
        var cs: ecto.Changeset<Dynamic, Dynamic> = new ecto.Changeset(user, params);
        cs = cs.validateRequired(["password"]);
        cs = cs.validateLength("password", {min: 8, max: 128});
        cs = cs.validateConfirmation("password");
        return cs;
    }

    /**
     * Email confirmation changeset
     */
    @:keep
    public static function confirmChangeset(user: Dynamic): Dynamic {
        return Changeset.change(user, {confirmed_at: DateTime.utcNow()});
    }

    /**
     * Login tracking changeset
     */
    @:keep
    public static function loginChangeset(user: Dynamic): Dynamic {
        return Changeset.change(user, {last_login_at: DateTime.utcNow()});
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
    public static function isActive(user: Dynamic): Bool {
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
     * User initials for avatars (uses __elixir__ for clean generation)
     */
    public static function initials(user: Dynamic): String {
        return untyped __elixir__('
            name = TodoApp.User.display_name({0})
            parts = String.split(name, " ")
            if length(parts) >= 2 do
                String.upcase(String.at(Enum.at(parts, 0), 0) || "") <> String.upcase(String.at(Enum.at(parts, 1), 0) || "")
            else
                String.upcase(String.at(name, 0) || "")
            end
        ', user);
    }
}
