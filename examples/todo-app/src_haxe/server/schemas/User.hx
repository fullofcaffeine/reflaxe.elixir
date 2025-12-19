package server.schemas;

import ecto.ChangesetBridge as CS;
import elixir.DateTime.DateTime;
import ecto.Changeset;
import elixir.types.Term;

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
    @:field public var confirmedAt: Null<DateTime>;
    @:field public var lastLoginAt: Null<DateTime>;
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
    public static function registrationChangeset(user: User, params: Term): Changeset<User, Term> {
        return CS.registration(user, params);
    }
    
    /**
     * Update changeset for existing user modifications
     * Allows updating name and email without password changes
     */
    @:keep
    public static function changeset(user: User, params: Term): Changeset<User, Term> {
        return CS.update(user, params);
    }
    
    /**
     * Password change changeset for updating user passwords
     */
    @:keep
    public static function passwordChangeset(user: User, params: Term): Changeset<User, Term> {
        return CS.password(user, params);
    }

    /**
     * Email confirmation changeset
     */
    @:keep
    public static function confirmChangeset(user: User): Changeset<User, {confirmed_at: DateTime}> {
        return CS.change(user, {confirmed_at: DateTime.utcNow()});
    }

    /**
     * Login tracking changeset
     */
    @:keep
    public static function loginChangeset(user: User): Changeset<User, {last_login_at: DateTime}> {
        return CS.change(user, {last_login_at: DateTime.utcNow()});
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
    public static function verifyPassword(user: User, password: String): Bool {
        // In a real application, use Bcrypt.verify_pass(password, user.passwordHash)
        // For demo purposes, simple verification
        return user.passwordHash == "hashed_" + password;
    }
    
    /**
     * Check if user is confirmed
     */
    public static function confirmed(user: User): Bool {
        return user.confirmedAt != null;
    }
    
    /**
     * Check if user is active
     */
    public static function isActive(user: User): Bool {
        return user.active == true;
    }

    /**
     * Create a demo user for development
     */
    public static function createDemoUser(): User {
        var user = new User();
        user.id = 1;
        user.name = "Demo User";
        user.email = "demo@example.com";
        user.passwordHash = "hashed_demopassword";
        user.confirmedAt = DateTime.utcNow();
        user.lastLoginAt = DateTime.utcNow();
        user.active = true;
        return user;
    }
    
    /**
     * Display name for user (for UI)
     */
    public static function displayName(user: User): String {
        return user.name != null && user.name != "" ? user.name : user.email;
    }
    
    /**
     * User initials for avatars (pure Haxe; no __elixir__ injections in apps)
     */
    public static function initials(user: User): String {
        var name = displayName(user);
        if (name == null || name == "") return "";
        var parts = name.split(" ");
        var firstChar = parts[0].charAt(0);
        var secondChar = (parts.length >= 2) ? parts[1].charAt(0) : "";
        var initials = firstChar + secondChar;
        return initials.toUpperCase();
    }
}
