package repositories;

import haxe.ds.Option;
import haxe.ds.OptionTools;
import haxe.functional.Result;
import models.User;

using haxe.ds.OptionTools;
using haxe.functional.Result.ResultTools;

/**
 * User repository demonstrating Option<T> patterns for database operations.
 * 
 * This repository shows how to use Option<T> instead of null returns,
 * providing type-safe database access patterns that prevent null pointer exceptions.
 * 
 * Key patterns demonstrated:
 * - Option<User> for nullable database results
 * - Conversion between Option and Result types
 * - Safe chaining of database operations
 * - Integration with BEAM-friendly patterns
 */
class UserRepository {
    // Simulated in-memory database for demonstration
    static var users: Array<User> = [
        new User(1, "Alice Johnson", "alice@example.com", true),
        new User(2, "Bob Smith", "bob@example.com", true),
        new User(3, "Charlie Brown", "charlie@example.com", false),
        new User(4, "Diana Prince", "diana@example.com", true)
    ];
    
    /**
     * Find a user by ID.
     * 
     * Returns Option<User> instead of null, making the possibility of
     * "not found" explicit in the type system.
     * 
     * @param id User ID to search for
     * @return Some(user) if found, None if not found
     */
    public static function find(id: Int): Option<User> {
        if (id <= 0) {
            return None;
        }
        
        for (user in users) {
            if (user.id == id) {
                return Some(user);
            }
        }
        
        return None;
    }
    
    /**
     * Find a user by email address.
     * 
     * Demonstrates email-based lookup with Option return type.
     * 
     * @param email Email address to search for
     * @return Some(user) if found, None if not found
     */
    public static function findByEmail(email: String): Option<User> {
        if (email == null || email == "") {
            return None;
        }
        
        for (user in users) {
            if (user.email == email) {
                return Some(user);
            }
        }
        
        return None;
    }
    
    /**
     * Find the first active user.
     * 
     * Demonstrates filtering with Option return.
     * 
     * @return Some(user) if any active user exists, None otherwise
     */
    public static function findFirstActive(): Option<User> {
        for (user in users) {
            if (user.active) {
                return Some(user);
            }
        }
        
        return None;
    }
    
    /**
     * Get user email safely.
     * 
     * Demonstrates chaining Option operations to safely extract nested data.
     * 
     * @param id User ID
     * @return Some(email) if user exists, None otherwise
     */
    public static function getUserEmail(id: Int): Option<String> {
        return find(id).map(user -> user.email);
    }
    
    /**
     * Get user display name with fallback.
     * 
     * Shows how to use unwrap() to provide default values.
     * 
     * @param id User ID
     * @return Display name or "Unknown User" if not found
     */
    public static function getUserDisplayName(id: Int): String {
        return find(id)
            .map(user -> user.getDisplayName())
            .unwrap("Unknown User");
    }
    
    /**
     * Check if a user exists and is active.
     * 
     * Demonstrates Option chaining with boolean logic.
     * 
     * @param id User ID
     * @return True if user exists and is active
     */
    public static function isUserActive(id: Int): Bool {
        return find(id)
            .map(user -> user.active)
            .unwrap(false);
    }
    
    /**
     * Update user email with validation.
     * 
     * Demonstrates converting Option to Result for error handling.
     * 
     * @param id User ID
     * @param newEmail New email address
     * @return Ok(user) if successful, Error(message) if failed
     */
    public static function updateEmail(id: Int, newEmail: String): Result<User, String> {
        if (newEmail == null || newEmail.indexOf("@") < 0) {
            return Error("Invalid email format");
        }
        
        return find(id)
            .toResult("User not found")
            .map(user -> {
                user.email = newEmail;
                user;
            });
    }
    
    /**
     * Get users by status (active/inactive).
     * 
     * Demonstrates filtering with Option integration.
     * 
     * @param active Whether to get active or inactive users
     * @return Array of users matching the status
     */
    public static function getUsersByStatus(active: Bool): Array<User> {
        var result = [];
        for (user in users) {
            if (user.active == active) {
                result.push(user);
            }
        }
        return result;
    }
    
    /**
     * Create a new user with validation.
     * 
     * Demonstrates Result type for creation operations that can fail.
     * 
     * @param name User name
     * @param email Email address
     * @return Ok(user) if created successfully, Error(message) if validation failed
     */
    public static function create(name: String, email: String): Result<User, String> {
        if (name == null || name == "") {
            return Error("Name is required");
        }
        
        if (email == null || email.indexOf("@") < 0) {
            return Error("Valid email is required");
        }
        
        // Check if email already exists
        switch (findByEmail(email)) {
            case Some(_): return Error("Email already exists");
            case None: // Continue with creation
        }
        
        // Generate new ID (in real app, this would be done by database)
        var newId = users.length + 1;
        var newUser = new User(newId, name, email, true);
        users.push(newUser);
        
        return Ok(newUser);
    }
}