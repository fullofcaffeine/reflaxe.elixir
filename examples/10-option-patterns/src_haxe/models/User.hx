package models;

/**
 * User data model for demonstration purposes.
 * 
 * This is a simple data structure used in the Option patterns example
 * to show how Option<User> provides type-safe null handling.
 */
class User {
    public var id: Int;
    public var name: String;
    public var email: String;
    public var active: Bool;
    
    /**
     * Create a new User instance.
     * 
     * @param id Unique user identifier
     * @param name User's full name
     * @param email User's email address
     * @param active Whether the user account is active
     */
    public function new(id: Int, name: String, email: String, active: Bool = true) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.active = active;
    }
    
    /**
     * Get a display name for the user.
     * Demonstrates how methods work with Option types.
     * 
     * @return Formatted display name
     */
    public function getDisplayName(): String {
        return active ? name : '${name} (inactive)';
    }
    
    /**
     * Check if the user has a valid email address.
     * Simple validation for demonstration purposes.
     * 
     * @return True if email contains @ symbol
     */
    public function hasValidEmail(): Bool {
        return email != null && email.indexOf("@") > 0;
    }
    
    /**
     * Convert user to string representation for debugging.
     * 
     * @return String representation of the user
     */
    public function toString(): String {
        return 'User(id=${id}, name="${name}", email="${email}", active=${active})';
    }
}