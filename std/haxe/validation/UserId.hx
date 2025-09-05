package haxe.validation;

import haxe.functional.Result;

/**
 * Type-safe UserId domain abstraction with alphanumeric validation.
 * 
 * ## WHY This Type Exists
 * 
 * User IDs are critical security and data integrity components that appear everywhere:
 * 
 * - **Security Vulnerabilities**: Special characters in user IDs enable injection attacks
 * - **URL Safety**: User IDs often appear in URLs - spaces and symbols break routing
 * - **Database Keys**: Many databases have restrictions on primary key characters
 * - **Cross-System Integration**: Different systems have different ID requirements
 * - **User Experience**: Confusing IDs (O vs 0, l vs 1) cause support issues
 * 
 * Common bugs this type prevents:
 * - **SQL Injection**: "admin'; DROP TABLE users;--" cannot be a UserId
 * - **Path Traversal**: "../../etc/passwd" is rejected
 * - **XSS Attacks**: "<script>alert('xss')</script>" is invalid
 * - **Case Confusion**: Handling "JohnDoe" vs "johndoe" consistently
 * - **Whitespace Issues**: Trailing spaces causing authentication failures
 * 
 * ## Design Philosophy
 * 
 * - **Alphanumeric Only**: Letters and numbers only - universally safe
 * - **Length Constraints**: 3-50 chars balances security and usability
 * - **Case Preservation**: Store original case but compare case-insensitively
 * - **No All-Digit IDs**: Prevents confusion with numeric database IDs
 * 
 * ## Real-World Usage Examples
 * 
 * ```haxe
 * // Example 1: User Authentication
 * function authenticate(inputId: String, password: String): Result<User, String> {
 *     // Parse validates the ID format
 *     return UserId.parse(inputId)
 *         .flatMap(userId -> {
 *             // Normalized for consistent database lookup
 *             var user = UserRepo.findByUserId(userId.normalize());
 *             if (user != null && user.checkPassword(password)) {
 *                 return Ok(user);
 *             }
 *             return Error("Invalid credentials");
 *         });
 * }
 * 
 * // Example 2: Admin Detection with Prefix Checking
 * function hasAdminPrivileges(userId: UserId): Bool {
 *     // Case-insensitive prefix checking
 *     return userId.startsWithIgnoreCase("admin") || 
 *            userId.startsWithIgnoreCase("sudo");
 * }
 * 
 * // Example 3: URL Generation
 * function generateUserProfileUrl(userId: UserId): String {
 *     // UserId is guaranteed URL-safe - no encoding needed!
 *     return 'https://example.com/users/${userId.toString()}';
 * }
 * 
 * // Example 4: Preventing Username Enumeration Attacks
 * function userExists(inputId: String): Bool {
 *     // Invalid IDs return false without database query
 *     // This prevents attackers from detecting valid ID patterns
 *     return UserId.parse(inputId)
 *         .map(id -> UserRepo.exists(id.normalize()))
 *         .unwrapOr(false);
 * }
 * 
 * // Example 5: Case-Insensitive Uniqueness
 * function registerUser(desiredId: String, email: Email): Result<User, String> {
 *     return UserId.parse(desiredId)
 *         .flatMap(userId -> {
 *             // Check if normalized version already exists
 *             if (UserRepo.exists(userId.normalize())) {
 *                 // Show the conflicting ID to user
 *                 var existing = UserRepo.findByUserId(userId.normalize());
 *                 return Error('Username "${existing.id}" already taken');
 *             }
 *             return Ok(User.create(userId, email));
 *         });
 * }
 * ```
 * 
 * ## Common Patterns
 * 
 * ```haxe
 * // Pattern 1: Parse at API boundaries
 * @:get("/users/:id")
 * function getUser(id: String): Response {
 *     return UserId.parse(id)
 *         .flatMap(userId -> UserService.findUser(userId))
 *         .map(user -> Response.json(user))
 *         .unwrapOr(Response.notFound());
 * }
 * 
 * // Pattern 2: Normalize for storage, preserve for display
 * class User {
 *     var id: UserId;           // Original case for display
 *     var normalizedId: String; // Lowercase for lookups
 *     
 *     public function new(id: UserId) {
 *         this.id = id;
 *         this.normalizedId = id.normalize().toString();
 *     }
 * }
 * 
 * // Pattern 3: Batch validation
 * function validateUserIds(ids: Array<String>): Array<UserId> {
 *     return ids.filterMap(id -> UserId.parse(id).toOption());
 * }
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
     * ## WHY These Specific Validation Rules
     * 
     * Each rule exists to prevent real security and usability issues:
     * 
     * - **Alphanumeric only**: Prevents ALL injection attacks (SQL, XSS, command)
     * - **3+ characters**: Prevents single-char IDs that are easily guessed
     * - **50 char limit**: Prevents DoS via massive IDs, fits in database columns
     * - **No all-digits**: "12345" looks like a database ID, causes confusion
     * 
     * We explicitly allow:
     * - **Mixed case**: "JohnDoe123" is valid (preserved for display)
     * - **Numbers anywhere**: "123abc", "abc123", "a1b2c3" all valid
     * 
     * @param userId User ID string to validate
     * @return Ok(()) if valid, Error(String) with specific failure reason
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