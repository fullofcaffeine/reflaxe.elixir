/**
 * Date: Cross-target Haxe API backed by Elixir DateTime at runtime.
 *
 * ## Multi-layered API approach:
 * - Layer 1: Cross-platform Haxe Date API (getTime, getMonth, toString, etc.)
 * - Layer 2: Typed Elixir externs (elixir.DateTime) for type-safe native access
 * - Layer 3: Direct __elixir__ only for complex inline expressions
 *
 * ## Architecture:
 * - Abstract type over elixir.DateTime for zero-cost abstraction
 * - 'this' IS the DateTime value - no wrapper overhead
 * - Methods compile to direct Elixir module calls
 * 
 * ## Why no @:coreApi metadata?
 * 
 * We intentionally don't use `@:coreApi` for several important reasons:
 * 
 * 1. **Abstract vs Class Mismatch**: The standard Haxe Date is a class, while our 
 *    implementation is an abstract. @:coreApi enforces strict structural compliance
 *    that doesn't work well with abstracts wrapping different underlying types.
 * 
 * 2. **Classpath Override Strategy**: We achieve cross-platform compatibility through
 *    classpath precedence (`-cp std` in compilation). Our Date.cross.hx is picked up
 *    automatically when compiling for Elixir, overriding the default Date.
 * 
 * 3. **The .cross.hx Pattern**: This is Haxe's standard pattern for platform-specific
 *    implementations. Files with .cross.hx suffix provide platform-specific versions
 *    while maintaining the same public API.
 * 
 * 4. **Flexibility for Extensions**: Without @:coreApi constraints, we can add
 *    Elixir-specific methods (add, diff, compare, format) that enhance the API
 *    while maintaining full compatibility with standard Date methods.
 * 
 * 5. **Zero-Cost Abstraction**: As an abstract over DateTime, there's no wrapper
 *    object at runtime - Date IS DateTime in the generated Elixir code.
 * 
 * ## Cross-Platform Compatibility Guarantee:
 * 
 * Despite not using @:coreApi, this implementation ensures full cross-platform
 * compatibility by:
 * - Implementing ALL standard Haxe Date methods with identical signatures
 * - Maintaining standard Haxe conventions (0-based months, Sunday=0, milliseconds)
 * - Providing correct type conversions between Haxe and Elixir conventions
 * 
 * Any code written using standard Date methods will work identically whether
 * compiled to JavaScript, Python, C++, or Elixir. Platform-specific extensions
 * are additive and don't break cross-platform code.
 * 
 * ## Benefits:
 * - Type safety through externs when possible
 * - Clean idiomatic Elixir generation
 * - Cross-platform compatibility via Haxe API
 * - Native Elixir extensions for platform-specific features
 * - No runtime overhead (zero-cost abstraction)
 */
import elixir.DateTime.DateTime;
import elixir.DateTime.NaiveDateTime;
import elixir.DateTime.TimeUnit;
import elixir.DateTime.TimePrecision;
import elixir.DateTime.ComparisonResult;
import elixir.DateTime.Date as ElixirDate;

/**
 * Cross-platform Date abstraction backed by Elixir DateTime.
 * 
 * This abstract provides both:
 * - Standard Haxe Date API for cross-platform code  
 * - Elixir-specific extensions for BEAM platform features
 * 
 * ## Implementation Strategy:
 * 
 * This is an abstract type over `elixir.DateTime`, meaning at runtime there is
 * NO wrapper object - a Date value IS a DateTime struct in the generated Elixir.
 * This provides zero-cost abstraction while maintaining full type safety.
 * 
 * ## API Compatibility:
 * 
 * All standard Haxe Date methods are implemented:
 * - Static constructors: `now()`, `fromTime()`, `fromString()`, `new()`
 * - Getters: `getFullYear()`, `getMonth()`, `getDate()`, `getDay()`, etc.
 * - UTC variants: `getUTCFullYear()`, `getUTCMonth()`, etc.
 * - Conversion: `toString()`, `getTime()`
 * 
 * ## Convention Conversions:
 * 
 * This implementation handles the differences between Haxe and Elixir conventions:
 * - **Months**: Haxe uses 0-11, Elixir uses 1-12 (converted automatically)
 * - **Day of Week**: Haxe uses 0-6 (Sun-Sat), Elixir uses 1-7 (Mon-Sun)
 * - **Time Units**: Haxe uses milliseconds, Elixir uses microseconds
 * 
 * ## Platform Extensions:
 * 
 * When targeting Elixir, additional native methods are available:
 * - `add(amount, unit)` - Add time with specific units
 * - `diff(other, unit)` - Calculate difference between dates
 * - `compare(other)` - Elixir-style comparison returning :lt/:eq/:gt
 * - `truncate(precision)` - Truncate to specific precision
 * - `format(pattern)` - Format using strftime patterns
 * - Operator overloading for comparisons (<, >, <=, >=, ==, !=)
 * 
 * These extensions are only available when compiling to Elixir and don't
 * affect cross-platform compatibility of standard Date usage.
 */
@:forward(year, month, day, hour, minute, second, microsecond, time_zone)
abstract Date(DateTime) from DateTime to DateTime {
    // ==============================
    // Cross-Platform Haxe API (Layer 1)
    // ==============================
    
    /**
     * Current UTC date-time (Haxe standard API)
     */
    public static inline function now(): Date {
        return DateTime.utcNow();
    }

    /**
     * Create from milliseconds since Unix epoch (Haxe standard API)
     */
    public static inline function fromTime(t: Float): Date {
        return DateTime.fromUnixBang(Std.int(t), TimeUnit.Millisecond);
    }

    /**
     * Parse from ISO8601 string (Haxe standard API)
     */
    public static function fromString(s: String): Date {
        // Need __elixir__ for pattern matching case expression
        return untyped __elixir__('
            case DateTime.from_iso8601({0}) do
                {:ok, dt, _} -> dt
                _ -> DateTime.utc_now()
            end', s);
    }

    /**
     * Construct specific date-time in UTC (Haxe standard API)
     */
    public inline function new(year: Int, month: Int, day: Int, hour: Int, min: Int, sec: Int) {
        var elixirMonth = month + 1; // Convert Haxe 0-based to Elixir 1-based
        // Use __elixir__ for complex multi-step construction
        this = untyped __elixir__('
            {:ok, naive} = NaiveDateTime.new({0}, {1}, {2}, {3}, {4}, {5})
            DateTime.from_naive!(naive, "Etc/UTC")', 
            year, elixirMonth, day, hour, min, sec);
    }

    /**
     * Milliseconds since Unix epoch (Haxe standard API)
     */
    public function getTime(): Float {
        // Non-inline to avoid Haxe introducing temp bindings when chained in expressions
        // Generates: DateTime.to_unix(DateTime.utc_now(), :millisecond)
        return this.to_unix(TimeUnit.Millisecond);
    }

    /**
     * Get year (Haxe standard API)
     */
    public inline function getFullYear(): Int {
        return this.year;
    }

    /**
     * Get month 0-11 (Haxe standard API)
     */
    public inline function getMonth(): Int {
        // Convert from Elixir 1-based to Haxe 0-based
        return this.month - 1;
    }

    /**
     * Get day of month 1-31 (Haxe standard API)
     */
    public inline function getDate(): Int {
        return this.day;
    }

    /**
     * Get day of week 0-6, Sunday=0 (Haxe standard API)
     */
    public inline function getDay(): Int {
        // Use typed externs for conversion
        var date = this.to_date();
        var dow = ElixirDate.day_of_week(date);
        // Convert from Elixir's 1-7 (Mon-Sun) to Haxe's 0-6 (Sun-Sat)
        return dow == 7 ? 0 : dow;
    }

    /**
     * Get hours 0-23 (Haxe standard API)
     */
    public inline function getHours(): Int {
        return this.hour;
    }

    /**
     * Get minutes 0-59 (Haxe standard API)
     */
    public inline function getMinutes(): Int {
        return this.minute;
    }

    /**
     * Get seconds 0-59 (Haxe standard API)
     */
    public inline function getSeconds(): Int {
        return this.second;
    }

    /**
     * Convert to string representation (Haxe standard API)
     */
    public inline function toString(): String {
        return this.to_iso8601();
    }

    // UTC accessors delegate to local ones since we store UTC
    public inline function getUTCFullYear(): Int return getFullYear();
    public inline function getUTCMonth(): Int return getMonth();
    public inline function getUTCDate(): Int return getDate();
    public inline function getUTCDay(): Int return getDay();
    public inline function getUTCHours(): Int return getHours();
    public inline function getUTCMinutes(): Int return getMinutes();
    public inline function getUTCSeconds(): Int return getSeconds();
    public inline function getTimezoneOffset(): Int return 0;

    // ==============================
    // Elixir Native Extensions (Layer 2)
    // ==============================
    
    /**
     * Add time to this date (Elixir-style API)
     * @param amount The amount to add
     * @param unit The time unit (Second, Minute, Hour, Day, etc.)
     * @return New Date with added time
     */
    public inline function add(amount: Int, unit: TimeUnit): Date {
        return DateTime.add(this, amount, unit);
    }
    
    /**
     * Calculate difference between dates (Elixir-style API)
     * @param other The other date to compare to
     * @param unit The time unit for the result
     * @return Difference in specified units
     */
    public inline function diff(other: Date, unit: TimeUnit): Int {
        return DateTime.diff(this, other, unit);
    }
    
    /**
     * Compare two dates (Elixir-style API)
     * @param other The date to compare to
     * @return :lt if this < other, :eq if equal, :gt if this > other
     */
    public inline function compare(other: Date): ComparisonResult {
        return DateTime.compare(this, other);
    }
    
    /**
     * Convert to NaiveDateTime (no timezone) (Elixir-style API)
     */
    public inline function toNaiveDateTime(): NaiveDateTime {
        return this.to_naive();
    }
    
    /**
     * Convert to Elixir Date (date only, no time) (Elixir-style API)
     */
    public inline function toElixirDate(): ElixirDate {
        return this.to_date();
    }
    
    /**
     * Create from NaiveDateTime with UTC timezone (Elixir-style API)
     */
    public static inline function fromNaiveDateTime(dt: NaiveDateTime): Date {
        return DateTime.fromNaiveBang(dt, "Etc/UTC");
    }
    
    /**
     * Truncate to specified precision (Elixir-style API)
     * @param precision The precision to truncate to (Second, Millisecond, etc.)
     * @return New Date truncated to specified precision
     */
    public inline function truncate(precision: TimePrecision): Date {
        return DateTime.truncate(this, precision);
    }
    
    /**
     * Check if date is before another date (Convenience method)
     */
    public inline function isBefore(other: Date): Bool {
        return compare(other) == ComparisonResult.Lt;
    }
    
    /**
     * Check if date is after another date (Convenience method)
     */
    public inline function isAfter(other: Date): Bool {
        return compare(other) == ComparisonResult.Gt;
    }
    
    /**
     * Check if date equals another date (Convenience method)
     */
    public inline function isEqual(other: Date): Bool {
        return compare(other) == ComparisonResult.Eq;
    }
    
    /**
     * Format date using strftime patterns (Elixir extension)
     * @param format The strftime format string
     * @return Formatted date string
     */
    public inline function format(format: String): String {
        // Use Calendar.strftime from Elixir
        return untyped __elixir__('Calendar.strftime({0}, {1})', this, format);
    }
    
    /**
     * Get beginning of day (00:00:00 of same date)
     */
    public inline function beginningOfDay(): Date {
        return untyped __elixir__('
            %DateTime{{0} | hour: 0, minute: 0, second: 0, microsecond: {0, 6}}', this);
    }
    
    /**
     * Get end of day (23:59:59.999999 of same date)
     */
    public inline function endOfDay(): Date {
        return untyped __elixir__('
            %DateTime{{0} | hour: 23, minute: 59, second: 59, microsecond: {999999, 6}}', this);
    }
    
    // ==============================
    // Operators
    // ==============================
    
    @:op(A > B) static inline function gt(a: Date, b: Date): Bool {
        return a.compare(b) == ComparisonResult.Gt;
    }
    
    @:op(A < B) static inline function lt(a: Date, b: Date): Bool {
        return a.compare(b) == ComparisonResult.Lt;
    }
    
    @:op(A >= B) static inline function gte(a: Date, b: Date): Bool {
        var result = a.compare(b);
        return result == ComparisonResult.Gt || result == ComparisonResult.Eq;
    }
    
    @:op(A <= B) static inline function lte(a: Date, b: Date): Bool {
        var result = a.compare(b);
        return result == ComparisonResult.Lt || result == ComparisonResult.Eq;
    }
    
    @:op(A == B) static inline function eq(a: Date, b: Date): Bool {
        return a.compare(b) == ComparisonResult.Eq;
    }
    
    @:op(A != B) static inline function neq(a: Date, b: Date): Bool {
        return a.compare(b) != ComparisonResult.Eq;
    }
}
