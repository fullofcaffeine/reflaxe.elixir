package haxe.validation;

import haxe.functional.Result;

/**
 * Type-safe UserId domain abstraction with alphanumeric validation.
 * 
 * Inspired by Domain-Driven Design and Gleam's type philosophy:
 * - Parse, don't validate: once constructed, the UserId is guaranteed valid
 * - Runtime validation: ensures ID validity with minimal performance impact
 * - Strong typing: UserId != String prevents accidental mixing
 * 
 * ## Design Principles
 * 
 * 1. **Alphanumeric Only**: No special characters, spaces, or symbols
 * 2. **Length Constraints**: Between 3-50 characters for practical use
 * 3. **Case Sensitivity**: Preserves case but allows case-insensitive comparison
 * 4. **Database Safe**: Safe for use as primary keys and in URLs
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Safe construction with validation
 * var userIdResult = UserId.parse("user123");
 * switch (userIdResult) {
 *     case Ok(userId): 
 *         var normalized = userId.normalize(); // Lowercase version
 *         var length = userId.length();        // Character count
 *     case Error(reason): 
 *         trace("Invalid user ID: " + reason);
 * }
 * 
 * // Direct construction (throws on invalid)
 * var userId = new UserId("validUser42");
 * 
 * // Equality comparison
 * var id1 = UserId.parse("User123").unwrap();
 * var id2 = UserId.parse("user123").unwrap();
 * var areEqual = id1.equalsIgnoreCase(id2); // true
 * ```
 * 
 * @see Email, PositiveInt, NonEmptyString for other domain abstractions
 */
abstract UserId(String) from String to String {
    
    /** Minimum allowed length for user IDs */
    private static inline var MIN_LENGTH = 3;
    
    /** Maximum allowed length for user IDs */
    private static inline var MAX_LENGTH = 50;
    
    /**
     * Create a new UserId with validation.
     * 
     * Throws an exception if the user ID is invalid.
     * Use UserId.parse() for safe construction.
     * 
     * @param userId User ID string
     * @throws String if user ID is invalid
     */
    public function new(userId: String) {
        switch (validate(userId)) {
            case Ok(_): this = userId;
            case Error(reason): throw reason;
        }
    }
    
    /**
     * Safely parse a user ID with validation.
     * 
     * This is the recommended way to construct UserId instances.
     * Returns a Result that can be chained with other operations.
     * 
     * @param userId User ID string to validate
     * @return Ok(UserId) if valid, Error(String) with reason if invalid
     */
    public static function parse(userId: String): Result<UserId, String> {
        return switch (validate(userId)) {
            case Ok(_): Ok(cast userId);
            case Error(reason): Error(reason);
        }
    }
    
    /**
     * Get the length of the user ID.
     * 
     * @return Number of characters in the user ID
     */
    public function length(): Int {
        return this.length;
    }
    
    /**
     * Create a normalized (lowercase) version of this user ID.
     * 
     * Useful for case-insensitive lookups while preserving original case.
     * 
     * @return Normalized user ID
     */
    public function normalize(): UserId {
        return cast this.toLowerCase();
    }
    
    /**
     * Check if this user ID starts with the specified prefix.
     * 
     * @param prefix Prefix to check for (case-sensitive)
     * @return True if user ID starts with prefix
     */
    public function startsWith(prefix: String): Bool {
        return this.indexOf(prefix) == 0;
    }
    
    /**
     * Check if this user ID starts with the specified prefix (case-insensitive).
     * 
     * @param prefix Prefix to check for
     * @return True if user ID starts with prefix (ignoring case)
     */
    public function startsWithIgnoreCase(prefix: String): Bool {
        return this.toLowerCase().indexOf(prefix.toLowerCase()) == 0;
    }
    
    /**
     * Convert user ID to string representation.
     * 
     * @return String representation of the user ID
     */
    public function toString(): String {
        return this;
    }
    
    /**
     * Compare two user IDs for exact equality (case-sensitive).
     * 
     * @param other UserId to compare against
     * @return True if user IDs are exactly equal
     */
    @:op(A == B)
    public function equals(other: UserId): Bool {
        return this == other.toString();
    }
    
    /**
     * Compare two user IDs for equality ignoring case.
     * 
     * @param other UserId to compare against
     * @return True if user IDs are equivalent (case-insensitive)
     */
    public function equalsIgnoreCase(other: UserId): Bool {
        return this.toLowerCase() == other.toString().toLowerCase();
    }
    
    /**
     * Compare user IDs lexicographically.
     * 
     * @param other UserId to compare against
     * @return Negative if this < other, positive if this > other, 0 if equal
     */
    @:op(A < B)
    public function compare(other: UserId): Bool {
        return this < other.toString();
    }
    
    /**
     * Validate a user ID string according to our domain rules.
     * 
     * @param userId User ID string to validate
     * @return Ok(()) if valid, Error(String) with reason if invalid
     */
    private static function validate(userId: String): Result<Void, String> {
        if (userId == null) {
            return Error("User ID cannot be null");
        }
        
        if (userId.length == 0) {
            return Error("User ID cannot be empty");
        }
        
        if (userId.length < MIN_LENGTH) {
            return Error('User ID too short: minimum ${MIN_LENGTH} characters, got ${userId.length}');
        }
        
        if (userId.length > MAX_LENGTH) {
            return Error('User ID too long: maximum ${MAX_LENGTH} characters, got ${userId.length}');
        }
        
        // Check for alphanumeric only
        for (i in 0...userId.length) {
            var char = userId.charAt(i);
            if (!isAlphaNumeric(char)) {
                return Error('User ID contains invalid character: "${char}" at position ${i}. Only alphanumeric characters allowed.');
            }
        }
        
        return Ok(null);
    }
    
    /**
     * Check if a character is alphanumeric (A-Z, a-z, 0-9).
     * 
     * @param char Character to check
     * @return True if character is alphanumeric
     */
    private static function isAlphaNumeric(char: String): Bool {
        if (char.length != 1) return false;
        
        var code = char.charCodeAt(0);
        return (code >= 48 && code <= 57) ||  // 0-9
               (code >= 65 && code <= 90) ||  // A-Z
               (code >= 97 && code <= 122);   // a-z
    }
}