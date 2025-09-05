package haxe.validation;

import haxe.functional.Result;

/**
 * Type-safe PositiveInt domain abstraction with arithmetic safety guarantees.
 * 
 * ## WHY This Type Exists
 * 
 * Positive integers are fundamental to countless programming scenarios where
 * zero and negative values would cause bugs or undefined behavior:
 * 
 * - **Array Indexing**: Negative indices cause crashes or unexpected behavior
 * - **Resource Counts**: -5 users online? 0 bytes of memory? Nonsensical!
 * - **Money/Points**: Negative prices, zero divisions in financial calculations
 * - **Pagination**: Page -1 or page 0 makes no sense in most systems
 * - **Retry Limits**: Can't retry a negative number of times
 * - **Port Numbers**: Network ports must be positive (1-65535)
 * 
 * By enforcing positivity at the type level, we prevent entire categories of:
 * - **Division by zero** errors (divisor is guaranteed > 0)
 * - **Array out-of-bounds** access (size/index guaranteed > 0)
 * - **Infinite loops** from negative counters
 * - **Business logic errors** from impossible values
 * 
 * ## Design Philosophy
 * 
 * - **Parse, don't validate**: Once constructed, always positive - no runtime checks needed
 * - **Arithmetic safety**: Operations that preserve positivity return PositiveInt directly
 * - **Explicit failure handling**: Operations that might violate invariant return Result
 * - **Zero is not positive**: We use > 0, not >= 0, preventing off-by-one errors
 * 
 * ## Real-World Usage Examples
 * 
 * ```haxe
 * // Example 1: Safe Array Operations
 * function getPage<T>(items: Array<T>, pageNum: PositiveInt, pageSize: PositiveInt): Array<T> {
 *     // No need to check for negative page numbers or zero page size!
 *     var startIdx = (pageNum.toInt() - 1) * pageSize.toInt();
 *     var endIdx = startIdx + pageSize.toInt();
 *     return items.slice(startIdx, endIdx);
 * }
 * 
 * // Example 2: Financial Calculations with SafeDiv
 * function calculatePricePerUnit(totalPrice: PositiveInt, units: PositiveInt): Result<PositiveInt, String> {
 *     // safeDiv ensures we only get a PositiveInt if division is exact
 *     return totalPrice.safeDiv(units)
 *         .mapError(err -> "Price must be evenly divisible by units: " + err);
 * }
 * 
 * // Example 3: Retry Logic with Safe Subtraction
 * function retryOperation(retriesLeft: PositiveInt): Result<String, String> {
 *     try {
 *         return Ok(performOperation());
 *     } catch (e: Dynamic) {
 *         // safeSub ensures we don't go negative
 *         switch (retriesLeft.safeSub(new PositiveInt(1))) {
 *             case Ok(newRetries): 
 *                 trace('Retrying... ${newRetries.toInt()} attempts left');
 *                 return retryOperation(newRetries);
 *             case Error(_): 
 *                 return Error("Max retries exceeded");
 *         }
 *     }
 * }
 * 
 * // Example 4: Resource Pool Management
 * class ResourcePool {
 *     var available: PositiveInt;
 *     var inUse: Int = 0;
 *     
 *     public function new(size: PositiveInt) {
 *         this.available = size;
 *     }
 *     
 *     public function acquire(): Result<Resource, String> {
 *         switch (available.safeSub(new PositiveInt(1))) {
 *             case Ok(newAvailable):
 *                 available = newAvailable;
 *                 inUse++;
 *                 return Ok(new Resource());
 *             case Error(_):
 *                 return Error("No resources available");
 *         }
 *     }
 *     
 *     public function release(): Void {
 *         if (inUse > 0) {
 *             available = available.add(new PositiveInt(1));
 *             inUse--;
 *         }
 *     }
 * }
 * 
 * // Example 5: Why SafeDiv Exists - Inventory Distribution
 * function distributeInventory(totalItems: PositiveInt, numStores: PositiveInt): Result<PositiveInt, String> {
 *     // We need EXACT distribution - no items lost due to rounding!
 *     return totalItems.safeDiv(numStores)
 *         .mapError(_ -> {
 *             var remainder = totalItems.mod(numStores);
 *             return 'Cannot evenly distribute ${totalItems.toInt()} items to ${numStores.toInt()} stores. ' +
 *                    '${remainder} items would be left over.';
 *         });
 * }
 * ```
 * 
 * ## Common Patterns
 * 
 * ```haxe
 * // Pattern 1: Parse user input at boundaries
 * function handlePageRequest(pageStr: String): Response {
 *     return PositiveInt.parse(Std.parseInt(pageStr))
 *         .map(page -> renderPage(page))
 *         .unwrapOr(Response.badRequest("Invalid page number"));
 * }
 * 
 * // Pattern 2: Use fromAbs for user-provided values
 * function setRetryCount(userValue: Int): PositiveInt {
 *     // Convert negative inputs to positive automatically
 *     return PositiveInt.fromAbs(userValue)
 *         .unwrapOr(new PositiveInt(3)); // Default to 3 retries
 * }
 * 
 * // Pattern 3: Chain arithmetic operations safely
 * var result = PositiveInt.parse(10)
 *     .flatMap(n -> n.safeSub(new PositiveInt(3)))  // Ok(7)
 *     .map(n -> n.multiply(new PositiveInt(2)))     // Ok(14)
 *     .flatMap(n -> n.safeDiv(new PositiveInt(7))); // Ok(2)
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
     * ## WHY safeDiv Exists (Not Just Regular Division)
     * 
     * This method solves real-world problems where exact division matters:
     * 
     * 1. **Financial Calculations**: When dividing money, you can't lose cents to rounding
     * 2. **Inventory Distribution**: Items must be evenly distributed, no fractional items
     * 3. **Load Balancing**: Tasks must be evenly split across workers
     * 4. **Batch Processing**: Records must divide evenly into batches
     * 
     * Regular division (/) would silently truncate, potentially losing data or money.
     * safeDiv explicitly fails if division isn't exact, forcing you to handle remainders.
     * 
     * ## Example: Why This Matters
     * 
     * ```haxe
     * // BAD: Silent data loss with regular division
     * var itemsPerBox = Std.int(100 / 7);  // 14 items per box
     * var totalInBoxes = itemsPerBox * 7;  // 98 items... where did 2 items go?
     * 
     * // GOOD: Explicit handling with safeDiv
     * var items = new PositiveInt(100);
     * var boxes = new PositiveInt(7);
     * switch (items.safeDiv(boxes)) {
     *     case Ok(perBox): 
     *         // Never happens - 100/7 has remainder
     *     case Error(msg):
     *         var remainder = items.mod(boxes);  // 2 items
     *         trace('Need special handling for ${remainder} extra items');
     * }
     * ```
     * 
     * @param divisor PositiveInt to divide by (guaranteed > 0, no division by zero!)
     * @return Ok(PositiveInt) if evenly divisible and result > 0, Error with details otherwise
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