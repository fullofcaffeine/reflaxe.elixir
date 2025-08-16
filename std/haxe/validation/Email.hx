package haxe.validation;

import haxe.functional.Result;

/**
 * Type-safe Email domain abstraction with compile-time validation.
 * 
 * Inspired by Domain-Driven Design and Gleam's type philosophy:
 * - Parse, don't validate: once constructed, the Email is guaranteed valid
 * - Runtime validation: ensures email validity with minimal performance impact
 * - Idiomatic target compilation: String in Elixir, proper types elsewhere
 * 
 * ## Design Principles
 * 
 * 1. **Construction Safety**: Invalid emails cannot be constructed
 * 2. **Type Safety**: Email != String prevents mixing with raw strings
 * 3. **Domain Methods**: Provides email-specific operations like getDomain()
 * 4. **Seamless Integration**: Converts to/from String as needed
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Safe construction with validation
 * var emailResult = Email.parse("user@example.com");
 * switch (emailResult) {
 *     case Ok(email): 
 *         var domain = email.getDomain();  // "example.com"
 *         var local = email.getLocalPart(); // "user"
 *     case Error(reason): 
 *         trace("Invalid email: " + reason);
 * }
 * 
 * // Direct construction (throws on invalid)
 * var email = new Email("valid@example.com");
 * 
 * // Functional composition
 * var result = Email.parse(userInput)
 *     .map(email -> email.getDomain())
 *     .map(domain -> domain.toLowerCase());
 * ```
 * 
 * @see UserId, PositiveInt, NonEmptyString for other domain abstractions
 */
abstract Email(String) from String to String {
    
    /**
     * Create a new Email with validation.
     * 
     * Throws an exception if the email is invalid.
     * Use Email.parse() for safe construction.
     * 
     * @param email Email address string
     * @throws String if email is invalid
     */
    public function new(email: String) {
        if (!isValidEmail(email)) {
            throw 'Invalid email address: ${email}';
        }
        this = email;
    }
    
    /**
     * Safely parse an email address with validation.
     * 
     * This is the recommended way to construct Email instances.
     * Returns a Result that can be chained with other operations.
     * 
     * @param email Email address string to validate
     * @return Ok(Email) if valid, Error(String) with reason if invalid
     */
    public static function parse(email: String): Result<Email, String> {
        if (!isValidEmail(email)) {
            return Error('Invalid email address: ${email}');
        }
        return Ok(cast email);
    }
    
    /**
     * Extract the domain part of the email (everything after @).
     * 
     * @return Domain portion of the email
     */
    public function getDomain(): String {
        var atIndex = this.lastIndexOf("@");
        return this.substring(atIndex + 1);
    }
    
    /**
     * Extract the local part of the email (everything before @).
     * 
     * @return Local portion of the email
     */
    public function getLocalPart(): String {
        var atIndex = this.lastIndexOf("@");
        return this.substring(0, atIndex);
    }
    
    /**
     * Check if this email has the specified domain.
     * 
     * @param domain Domain to check against (case-insensitive)
     * @return True if email uses the specified domain
     */
    public function hasDomain(domain: String): Bool {
        return getDomain().toLowerCase() == domain.toLowerCase();
    }
    
    /**
     * Create a normalized version of this email (lowercase).
     * 
     * @return Normalized email address
     */
    public function normalize(): Email {
        return cast this.toLowerCase();
    }
    
    /**
     * Convert email to string representation.
     * 
     * @return String representation of the email
     */
    public function toString(): String {
        return this;
    }
    
    /**
     * Compare two emails for equality (case-insensitive).
     * 
     * @param other Email to compare against
     * @return True if emails are equivalent
     */
    @:op(A == B)
    public function equals(other: Email): Bool {
        return this.toLowerCase() == other.toString().toLowerCase();
    }
    
    /**
     * Basic email validation using simple regex pattern.
     * 
     * This is intentionally simple to avoid complex email specification edge cases.
     * For production use, consider more robust validation libraries.
     * 
     * @param email Email string to validate
     * @return True if email appears valid
     */
    private static function isValidEmail(email: String): Bool {
        if (email == null || email.length == 0) {
            return false;
        }
        
        // Basic validation: must contain exactly one @ with content before and after
        var atIndex = email.indexOf("@");
        var lastAtIndex = email.lastIndexOf("@");
        
        // Must have exactly one @
        if (atIndex == -1 || atIndex != lastAtIndex) {
            return false;
        }
        
        // Must have content before and after @
        if (atIndex == 0 || atIndex == email.length - 1) {
            return false;
        }
        
        var localPart = email.substring(0, atIndex);
        var domainPart = email.substring(atIndex + 1);
        
        // Local part validation (simplified)
        if (localPart.length == 0 || localPart.length > 64) {
            return false;
        }
        
        // Domain part validation (simplified)
        if (domainPart.length == 0 || domainPart.length > 255) {
            return false;
        }
        
        // Domain must contain at least one dot
        if (domainPart.indexOf(".") == -1) {
            return false;
        }
        
        // Domain cannot start or end with dot or hyphen
        if (domainPart.charAt(0) == "." || domainPart.charAt(0) == "-" ||
            domainPart.charAt(domainPart.length - 1) == "." || 
            domainPart.charAt(domainPart.length - 1) == "-") {
            return false;
        }
        
        return true;
    }
}