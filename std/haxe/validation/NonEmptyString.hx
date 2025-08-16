package haxe.validation;

import haxe.functional.Result;

/**
 * Type-safe NonEmptyString domain abstraction with length constraints.
 * 
 * Inspired by Domain-Driven Design and Gleam's type philosophy:
 * - Parse, don't validate: once constructed, the string is guaranteed non-empty
 * - Runtime validation: ensures string validity with minimal performance impact
 * - Strong typing: NonEmptyString != String prevents accidental empty strings
 * 
 * ## Design Principles
 * 
 * 1. **Never Empty**: Strings must have at least one character
 * 2. **Whitespace Handling**: Configurable trimming and whitespace-only validation
 * 3. **Concatenation Safety**: Operations maintain non-empty invariant
 * 4. **Natural Usage**: Behaves like String where possible
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Safe construction with validation
 * var nameResult = NonEmptyString.parse("Alice");
 * switch (nameResult) {
 *     case Ok(name): 
 *         var length = name.length();         // Always >= 1
 *         var upper = name.toUpperCase();     // Still non-empty
 *     case Error(reason): 
 *         trace("Invalid name: " + reason);
 * }
 * 
 * // Direct construction (throws on invalid)
 * var name = new NonEmptyString("Bob");
 * 
 * // Safe operations
 * var fullName = name.concat(new NonEmptyString(" Smith")); // Always non-empty
 * var trimmed = name.safeTrim(); // Result<NonEmptyString, String>
 * 
 * // Functional composition
 * var result = NonEmptyString.parse(userInput)
 *     .flatMap(s -> s.safeTrim())
 *     .map(s -> s.toUpperCase());
 * ```
 * 
 * @see Email, UserId, PositiveInt for other domain abstractions
 */
abstract NonEmptyString(String) from String to String {
    
    /**
     * Create a new NonEmptyString with validation.
     * 
     * Throws an exception if the string is empty.
     * Use NonEmptyString.parse() for safe construction.
     * 
     * @param value String value (must be non-empty)
     * @throws String if string is empty
     */
    public function new(value: String) {
        if (value == null || value.length == 0) {
            throw 'String cannot be empty or null';
        }
        this = value;
    }
    
    /**
     * Safely parse a string with non-empty validation.
     * 
     * This is the recommended way to construct NonEmptyString instances.
     * Returns a Result that can be chained with other operations.
     * 
     * @param value String value to validate
     * @return Ok(NonEmptyString) if non-empty, Error(String) with reason if empty
     */
    public static function parse(value: String): Result<NonEmptyString, String> {
        if (value == null) {
            return Error("String cannot be null");
        }
        if (value.length == 0) {
            return Error("String cannot be empty");
        }
        return Ok(cast value);
    }
    
    /**
     * Parse a string with trimming and whitespace validation.
     * 
     * Trims whitespace first, then validates the result is non-empty.
     * 
     * @param value String value to trim and validate
     * @return Ok(NonEmptyString) if non-empty after trim, Error otherwise
     */
    public static function parseAndTrim(value: String): Result<NonEmptyString, String> {
        if (value == null) {
            return Error("String cannot be null");
        }
        var trimmed = StringTools.trim(value);
        if (trimmed.length == 0) {
            return Error("String cannot be empty or whitespace-only");
        }
        return Ok(cast trimmed);
    }
    
    /**
     * Get the length of the string (always >= 1).
     * 
     * @return Number of characters in the string
     */
    public function length(): Int {
        return this.length;
    }
    
    /**
     * Concatenate with another NonEmptyString (always results in non-empty).
     * 
     * @param other NonEmptyString to concatenate
     * @return Concatenated string as NonEmptyString
     */
    public function concat(other: NonEmptyString): NonEmptyString {
        return cast (this + other.toString());
    }
    
    /**
     * Concatenate with a regular string.
     * 
     * @param other String to concatenate (can be empty)
     * @return Concatenated string as NonEmptyString
     */
    public function concatString(other: String): NonEmptyString {
        return cast (this + other);
    }
    
    /**
     * Safe trim operation that returns Result to handle empty results.
     * 
     * @return Ok(NonEmptyString) if trimmed result is non-empty, Error if empty
     */
    public function safeTrim(): Result<NonEmptyString, String> {
        var trimmed = StringTools.trim(this);
        if (trimmed.length == 0) {
            return Error("Trimmed string would be empty");
        }
        return Ok(cast trimmed);
    }
    
    /**
     * Convert to uppercase (always remains non-empty).
     * 
     * @return Uppercase version as NonEmptyString
     */
    public function toUpperCase(): NonEmptyString {
        return cast this.toUpperCase();
    }
    
    /**
     * Convert to lowercase (always remains non-empty).
     * 
     * @return Lowercase version as NonEmptyString
     */
    public function toLowerCase(): NonEmptyString {
        return cast this.toLowerCase();
    }
    
    /**
     * Get substring starting from index (safe - maintains non-empty when possible).
     * 
     * @param startIndex Starting position
     * @return Ok(NonEmptyString) if result is non-empty, Error if empty
     */
    public function safeSubstring(startIndex: Int): Result<NonEmptyString, String> {
        if (startIndex < 0) {
            return Error("Start index cannot be negative");
        }
        if (startIndex >= this.length) {
            return Error("Start index beyond string length");
        }
        var result = this.substring(startIndex);
        if (result.length == 0) {
            return Error("Substring would be empty");
        }
        return Ok(cast result);
    }
    
    /**
     * Get substring with start and end indices (safe - maintains non-empty when possible).
     * 
     * @param startIndex Starting position
     * @param endIndex Ending position
     * @return Ok(NonEmptyString) if result is non-empty, Error if empty
     */
    public function safeSubstringRange(startIndex: Int, endIndex: Int): Result<NonEmptyString, String> {
        if (startIndex < 0) {
            return Error("Start index cannot be negative");
        }
        if (endIndex <= startIndex) {
            return Error("End index must be greater than start index");
        }
        if (startIndex >= this.length) {
            return Error("Start index beyond string length");
        }
        var result = this.substring(startIndex, endIndex);
        if (result.length == 0) {
            return Error("Substring would be empty");
        }
        return Ok(cast result);
    }
    
    /**
     * Check if string starts with the specified prefix.
     * 
     * @param prefix Prefix to check for
     * @return True if string starts with prefix
     */
    public function startsWith(prefix: String): Bool {
        return StringTools.startsWith(this, prefix);
    }
    
    /**
     * Check if string ends with the specified suffix.
     * 
     * @param suffix Suffix to check for
     * @return True if string ends with suffix
     */
    public function endsWith(suffix: String): Bool {
        return StringTools.endsWith(this, suffix);
    }
    
    /**
     * Check if string contains the specified substring.
     * 
     * @param substring Substring to search for
     * @return True if string contains substring
     */
    public function contains(substring: String): Bool {
        return this.indexOf(substring) != -1;
    }
    
    /**
     * Replace all occurrences of a search string with replacement.
     * 
     * @param search String to search for
     * @param replacement String to replace with
     * @return Ok(NonEmptyString) if result is non-empty, Error if empty
     */
    public function safeReplace(search: String, replacement: String): Result<NonEmptyString, String> {
        var result = StringTools.replace(this, search, replacement);
        if (result.length == 0) {
            return Error("Replacement would result in empty string");
        }
        return Ok(cast result);
    }
    
    /**
     * Split string by delimiter, keeping only non-empty parts.
     * 
     * @param delimiter String to split by
     * @return Array of NonEmptyString parts (empty array if no non-empty parts)
     */
    public function splitNonEmpty(delimiter: String): Array<NonEmptyString> {
        var parts = this.split(delimiter);
        var result: Array<NonEmptyString> = [];
        
        for (part in parts) {
            if (part.length > 0) {
                result.push(cast part);
            }
        }
        
        return result;
    }
    
    /**
     * Get the first character of the string.
     * 
     * @return First character as single-character NonEmptyString
     */
    public function firstChar(): NonEmptyString {
        return cast this.charAt(0);
    }
    
    /**
     * Get the last character of the string.
     * 
     * @return Last character as single-character NonEmptyString
     */
    public function lastChar(): NonEmptyString {
        return cast this.charAt(this.length - 1);
    }
    
    /**
     * Convert to string representation.
     * 
     * @return String representation
     */
    public function toString(): String {
        return this;
    }
    
    /**
     * Compare two NonEmptyStrings for equality.
     * 
     * @param other NonEmptyString to compare against
     * @return True if strings are equal
     */
    @:op(A == B)
    public function equals(other: NonEmptyString): Bool {
        return this == other.toString();
    }
    
    /**
     * Compare strings lexicographically.
     * 
     * @param other NonEmptyString to compare against
     * @return True if this < other
     */
    @:op(A < B)
    public function lessThan(other: NonEmptyString): Bool {
        return this < other.toString();
    }
    
    /**
     * Concatenate operator.
     * 
     * @param other NonEmptyString to concatenate
     * @return Concatenated string as NonEmptyString
     */
    @:op(A + B)
    public function add(other: NonEmptyString): NonEmptyString {
        return concat(other);
    }
    
    /**
     * Check if this string equals a regular string.
     * 
     * @param value String to compare against
     * @return True if strings are equal
     */
    public function equalsString(value: String): Bool {
        return this == value;
    }
    
    /**
     * Create NonEmptyString from a single character.
     * 
     * @param char Character to create string from
     * @return NonEmptyString containing the character
     */
    public static function fromChar(char: String): Result<NonEmptyString, String> {
        if (char == null || char.length != 1) {
            return Error("Must provide exactly one character");
        }
        return Ok(cast char);
    }
    
    /**
     * Join an array of NonEmptyStrings with a separator.
     * 
     * @param strings Array of NonEmptyStrings to join
     * @param separator Separator string (can be empty)
     * @return Ok(NonEmptyString) if array is non-empty, Error if empty array
     */
    public static function join(strings: Array<NonEmptyString>, separator: String): Result<NonEmptyString, String> {
        if (strings.length == 0) {
            return Error("Cannot join empty array");
        }
        var stringArray = strings.map(s -> s.toString());
        return Ok(cast stringArray.join(separator));
    }
}