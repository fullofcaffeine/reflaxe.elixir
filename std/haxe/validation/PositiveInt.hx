package haxe.validation;

import haxe.functional.Result;

/**
 * Type-safe PositiveInt domain abstraction with value constraints.
 * 
 * Inspired by Domain-Driven Design and Gleam's type philosophy:
 * - Parse, don't validate: once constructed, the value is guaranteed positive
 * - Runtime safety: validates values to maintain invariants with minimal overhead
 * - Arithmetic safety: All operations maintain the positive invariant
 * 
 * ## Design Principles
 * 
 * 1. **Positive Only**: Values must be > 0 (excludes zero and negatives)
 * 2. **Invariant Preservation**: All arithmetic operations maintain positivity
 * 3. **Safe Operations**: Operations that could violate invariant return Result
 * 4. **Natural Usage**: Behaves like Int where possible
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Safe construction with validation
 * var countResult = PositiveInt.parse(42);
 * switch (countResult) {
 *     case Ok(count): 
 *         var doubled = count * 2;        // Always positive
 *         var sum = count + count;        // Always positive
 *     case Error(reason): 
 *         trace("Invalid count: " + reason);
 * }
 * 
 * // Direct construction (throws on invalid)
 * var count = new PositiveInt(5);
 * 
 * // Safe operations that might fail
 * var subtractResult = count.safeSub(3);  // Ok(2)
 * var invalidResult = count.safeSub(10); // Error("Result would be non-positive")
 * 
 * // Functional composition
 * var result = PositiveInt.parse(userInput)
 *     .flatMap(n -> n.safeSub(1))
 *     .map(n -> n * 3);
 * ```
 * 
 * @see Email, UserId, NonEmptyString for other domain abstractions
 */
abstract PositiveInt(Int) from Int to Int {
    
    /**
     * Create a new PositiveInt with validation.
     * 
     * Throws an exception if the value is not positive.
     * Use PositiveInt.parse() for safe construction.
     * 
     * @param value Integer value (must be > 0)
     * @throws String if value is not positive
     */
    public function new(value: Int) {
        if (value <= 0) {
            throw 'Value must be positive, got: ${value}';
        }
        this = value;
    }
    
    /**
     * Safely parse an integer with positivity validation.
     * 
     * This is the recommended way to construct PositiveInt instances.
     * Returns a Result that can be chained with other operations.
     * 
     * @param value Integer value to validate
     * @return Ok(PositiveInt) if positive, Error(String) with reason if not
     */
    public static function parse(value: Int): Result<PositiveInt, String> {
        if (value <= 0) {
            return Error('Value must be positive, got: ${value}');
        }
        return Ok(cast value);
    }
    
    /**
     * Add two positive integers (always results in positive).
     * 
     * @param other PositiveInt to add
     * @return Sum as PositiveInt
     */
    @:op(A + B)
    public function add(other: PositiveInt): PositiveInt {
        return cast (this + other.toInt());
    }
    
    /**
     * Multiply two positive integers (always results in positive).
     * 
     * @param other PositiveInt to multiply by
     * @return Product as PositiveInt
     */
    @:op(A * B)
    public function multiply(other: PositiveInt): PositiveInt {
        return cast (this * other.toInt());
    }
    
    /**
     * Multiply by a regular integer (must be positive).
     * 
     * @param multiplier Integer to multiply by (must be positive)
     * @return Product as PositiveInt
     * @throws String if multiplier is not positive
     */
    @:op(A * B)
    public function multiplyByInt(multiplier: Int): PositiveInt {
        if (multiplier <= 0) {
            throw 'Multiplier must be positive, got: ${multiplier}';
        }
        return cast (this * multiplier);
    }
    
    /**
     * Safe subtraction that returns Result to handle non-positive results.
     * 
     * @param other PositiveInt to subtract
     * @return Ok(PositiveInt) if result > 0, Error if result <= 0
     */
    public function safeSub(other: PositiveInt): Result<PositiveInt, String> {
        var result = this - other.toInt();
        if (result <= 0) {
            return Error('Subtraction result would be non-positive: ${this} - ${other.toInt()} = ${result}');
        }
        return Ok(cast result);
    }
    
    /**
     * Safe subtraction with regular integer.
     * 
     * @param value Integer to subtract
     * @return Ok(PositiveInt) if result > 0, Error if result <= 0
     */
    public function safeSubInt(value: Int): Result<PositiveInt, String> {
        var result = this - value;
        if (result <= 0) {
            return Error('Subtraction result would be non-positive: ${this} - ${value} = ${result}');
        }
        return Ok(cast result);
    }
    
    /**
     * Safe division that returns Result to handle non-integer or non-positive results.
     * 
     * @param divisor PositiveInt to divide by
     * @return Ok(PositiveInt) if evenly divisible and result > 0, Error otherwise
     */
    public function safeDiv(divisor: PositiveInt): Result<PositiveInt, String> {
        var divisorInt = divisor.toInt();
        if (this % divisorInt != 0) {
            return Error('Division not exact: ${this} / ${divisorInt} has remainder ${this % divisorInt}');
        }
        var result = Std.int(this / divisorInt);
        if (result <= 0) {
            return Error('Division result would be non-positive: ${this} / ${divisorInt} = ${result}');
        }
        return Ok(cast result);
    }
    
    /**
     * Integer division (truncated).
     * 
     * @param divisor PositiveInt to divide by
     * @return Quotient as PositiveInt (guaranteed positive since both operands are positive)
     */
    public function div(divisor: PositiveInt): PositiveInt {
        return cast Std.int(this / divisor.toInt());
    }
    
    /**
     * Modulo operation.
     * 
     * @param divisor PositiveInt to get remainder from
     * @return Remainder (0 to divisor-1)
     */
    @:op(A % B)
    public function mod(divisor: PositiveInt): Int {
        return this % divisor.toInt();
    }
    
    /**
     * Compare two positive integers.
     * 
     * @param other PositiveInt to compare against
     * @return True if this < other
     */
    @:op(A < B)
    public function lessThan(other: PositiveInt): Bool {
        return this < other.toInt();
    }
    
    /**
     * Compare two positive integers.
     * 
     * @param other PositiveInt to compare against
     * @return True if this <= other
     */
    @:op(A <= B)
    public function lessThanOrEqual(other: PositiveInt): Bool {
        return this <= other.toInt();
    }
    
    /**
     * Compare two positive integers.
     * 
     * @param other PositiveInt to compare against
     * @return True if this > other
     */
    @:op(A > B)
    public function greaterThan(other: PositiveInt): Bool {
        return this > other.toInt();
    }
    
    /**
     * Compare two positive integers.
     * 
     * @param other PositiveInt to compare against
     * @return True if this >= other
     */
    @:op(A >= B)
    public function greaterThanOrEqual(other: PositiveInt): Bool {
        return this >= other.toInt();
    }
    
    /**
     * Check equality with another PositiveInt.
     * 
     * @param other PositiveInt to compare against
     * @return True if values are equal
     */
    @:op(A == B)
    public function equals(other: PositiveInt): Bool {
        return this == other.toInt();
    }
    
    /**
     * Get the minimum of two positive integers.
     * 
     * @param other PositiveInt to compare with
     * @return Smaller of the two values
     */
    public function min(other: PositiveInt): PositiveInt {
        return this < other.toInt() ? cast this : other;
    }
    
    /**
     * Get the maximum of two positive integers.
     * 
     * @param other PositiveInt to compare with
     * @return Larger of the two values
     */
    public function max(other: PositiveInt): PositiveInt {
        return this > other.toInt() ? cast this : other;
    }
    
    /**
     * Convert to regular Int.
     * 
     * @return Integer value
     */
    public function toInt(): Int {
        return this;
    }
    
    /**
     * Convert to Float.
     * 
     * @return Float value
     */
    public function toFloat(): Float {
        return this;
    }
    
    /**
     * Convert to string representation.
     * 
     * @return String representation of the value
     */
    public function toString(): String {
        return Std.string(this);
    }
    
    /**
     * Check if this value is equal to a regular integer.
     * 
     * @param value Integer to compare against
     * @return True if values are equal
     */
    public function equalsInt(value: Int): Bool {
        return this == value;
    }
    
    /**
     * Create PositiveInt from the absolute value of an integer.
     * 
     * @param value Integer value (will use absolute value)
     * @return Ok(PositiveInt) if abs(value) > 0, Error if value is 0
     */
    public static function fromAbs(value: Int): Result<PositiveInt, String> {
        var abs = value < 0 ? -value : value;
        return parse(abs);
    }
}