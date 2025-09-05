package haxe.validation;

import haxe.functional.Result;

/**
 * Type-safe NonEmptyString domain abstraction preventing empty string bugs.
 * 
 * ## WHY This Type Exists
 * 
 * Empty strings are a massive source of bugs in production systems:
 * 
 * - **Database Constraints**: Empty names, titles, descriptions violate NOT NULL
 * - **UI Disasters**: Empty labels, buttons, error messages confuse users
 * - **Search Failures**: Empty search queries crash or return everything
 * - **File System Issues**: Empty filenames are invalid on all systems
 * - **API Errors**: Empty required fields cause mysterious 400/500 errors
 * - **Security**: Empty passwords, tokens, or keys create vulnerabilities
 * 
 * Real bugs this prevents:
 * - **Silent Failures**: `user.name = ""` displays as blank in UI
 * - **Whitespace Bugs**: `"   "` passes `!= ""` check but is visually empty
 * - **Trim Disasters**: `userInput.trim()` can produce empty from valid input
 * - **Split Issues**: `"".split(",")` produces `[""]`, not `[]`
 * - **Concatenation Errors**: `"" + "" + ""` is still empty
 * 
 * ## Design Philosophy
 * 
 * - **Never Empty**: Length always >= 1, no exceptions
 * - **Whitespace Aware**: safeTrim() returns Result because `"  "` becomes `""`
 * - **Operation Safety**: Only operations that preserve non-emptiness return NonEmptyString
 * - **Explicit Failure**: Operations that might empty return Result<NonEmptyString, String>
 * 
 * ## Real-World Usage Examples
 * 
 * ```haxe
 * // Example 1: Form Validation
 * function validateForm(data: {name: String, bio: String}): Result<Profile, String> {
 *     // Parse and trim in one step
 *     var nameResult = NonEmptyString.parseAndTrim(data.name);
 *     var bioResult = NonEmptyString.parseAndTrim(data.bio);
 *     
 *     return nameResult.flatMap(name -> 
 *         bioResult.map(bio -> 
 *             Profile.create(name, bio)
 *         )
 *     ).mapError(err -> "Please fill in all required fields");
 * }
 * 
 * // Example 2: The Whitespace Problem - Why safeTrim Returns Result
 * function processComment(comment: NonEmptyString): Result<NonEmptyString, String> {
 *     // User typed "   " (only spaces) - safeTrim would produce empty!
 *     return comment.safeTrim()
 *         .mapError(_ -> "Comment cannot be only whitespace");
 * }
 * 
 * // Example 3: Safe String Operations
 * function buildFullName(first: NonEmptyString, last: NonEmptyString): NonEmptyString {
 *     // Guaranteed non-empty result
 *     return first.concat(new NonEmptyString(" ")).concat(last);
 * }
 * 
 * // Example 4: Search Query Processing
 * function searchProducts(query: String): Result<Array<Product>, String> {
 *     return NonEmptyString.parseAndTrim(query)
 *         .map(q -> {
 *             // Split and keep only non-empty terms
 *             var terms = q.splitNonEmpty(" ");
 *             return ProductRepo.searchByTerms(terms);
 *         })
 *         .mapError(_ -> "Please enter a search query");
 * }
 * 
 * // Example 5: File Path Safety
 * function createFile(dir: NonEmptyString, name: NonEmptyString): Result<File, String> {
 *     // Both dir and name guaranteed non-empty
 *     var ext = NonEmptyString.parse(".txt").unwrap();
 *     var fullPath = dir.concat(new NonEmptyString("/"))
 *                      .concat(name)
 *                      .concat(ext);
 *     return File.create(fullPath.toString());
 * }
 * 
 * // Example 6: Why safeReplace Returns Result
 * function censorBadWords(text: NonEmptyString): Result<NonEmptyString, String> {
 *     // If text is only bad words, replacement could be empty!
 *     return text.safeReplace("badword", "")
 *         .mapError(_ -> "Message contains only inappropriate content");
 * }
 * ```
 * 
 * ## Common Patterns
 * 
 * ```haxe
 * // Pattern 1: Parse and validate at boundaries
 * @:post("/articles")
 * function createArticle(params: {title: String, content: String}): Response {
 *     var titleResult = NonEmptyString.parseAndTrim(params.title);
 *     var contentResult = NonEmptyString.parseAndTrim(params.content);
 *     
 *     return Result.map2(titleResult, contentResult, 
 *         (title, content) -> Article.create(title, content)
 *     ).map(article -> Response.created(article))
 *      .unwrapOr(Response.badRequest("Title and content required"));
 * }
 * 
 * // Pattern 2: Join with guaranteed non-empty result
 * function formatTags(tags: Array<NonEmptyString>): Result<NonEmptyString, String> {
 *     if (tags.length == 0) {
 *         return Error("At least one tag required");
 *     }
 *     return NonEmptyString.join(tags, ", ");
 * }
 * 
 * // Pattern 3: Character access that's always safe
 * function getInitials(name: NonEmptyString): String {
 *     // firstChar() always succeeds because string is non-empty!
 *     return name.firstChar().toUpperCase().toString();
 * }
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
     * ## WHY safeTrim Returns Result (Not Just NonEmptyString)
     * 
     * This is one of the most important methods because whitespace-only strings
     * are a common source of bugs:
     * 
     * ```haxe
     * // The Problem:
     * var userInput = new NonEmptyString("   ");  // Valid - has 3 characters!
     * var trimmed = userInput.trim();             // Returns "" - EMPTY!
     * ```
     * 
     * By returning Result, we force explicit handling of this edge case:
     * 
     * ```haxe
     * switch (userInput.safeTrim()) {
     *     case Ok(trimmed): 
     *         // User entered real content
     *         saveComment(trimmed);
     *     case Error(_):
     *         // User entered only whitespace
     *         showError("Please enter a comment");
     * }
     * ```
     * 
     * @return Ok(NonEmptyString) if trimmed result is non-empty, Error if only whitespace
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