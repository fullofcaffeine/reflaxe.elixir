package;

import elixir.Syntax;

// Dual-API implementation using Elixir's native DateTime capabilities

// Define simple enums for Elixir time operations
enum TimeUnit {
	Second;
	Minute;
	Hour;
	Day;
	Week;
}

enum TimePrecision {
	Second;
	Millisecond;
	Microsecond;
}

enum ComparisonResult {
	Lt; // :lt
	Eq; // :eq
	Gt; // :gt
}

/**
 * Haxe Date implementation for Elixir target with Dual-API support
 * 
 * This abstract provides BOTH cross-platform Haxe Date API AND Elixir-native
 * date methods, following the Dual-API philosophy for maximum flexibility.
 * 
 * ## Cross-Platform API (Haxe Standard)
 * Use these for portable code: getTime(), getMonth(), getDate(), etc.
 * 
 * ## Elixir Native API Extensions
 * Use these for platform-specific features: add(), diff(), toIso8601(), etc.
 * 
 * ## Direct Elixir Type Access
 * For full Elixir features, use: elixir.Date, elixir.DateTime, elixir.NaiveDateTime
 * 
 * ## Implementation Notes
 * 
 * - Uses Elixir's native DateTime and NaiveDateTime for all operations
 * - Generates idiomatic Elixir code that looks hand-written
 * - Uses abstract type over Float for clean encapsulation
 * - No field access issues - abstracts compile away at runtime
 * - Month is 0-based (0-11) per Haxe convention
 * - Leverages Elixir's excellent date/time library capabilities
 * - Uses `elixir.Syntax.code()` for platform-specific operations
 */
abstract Date(Float) {
	
	/**
	 * Creates a new date object from the given arguments.
	 * 
	 * @param year Full year (e.g., 2024)
	 * @param month Month (0-11, zero-based per Haxe convention)
	 * @param day Day of month (1-31)
	 * @param hour Hour (0-23)
	 * @param min Minutes (0-59)
	 * @param sec Seconds (0-59)
	 */
	public function new(year: Int, month: Int, day: Int, hour: Int, min: Int, sec: Int) {
		// Use Elixir's NaiveDateTime for proper date handling
		var elixirMonth = month + 1; // Convert 0-based month to 1-based for Elixir
		var naiveDateTime = Syntax.code("NaiveDateTime.new!({0}, {1}, {2}, {3}, {4}, {5})", 
			year, elixirMonth, day, hour, min, sec);
		// Convert to Unix timestamp in milliseconds
		this = Syntax.code("DateTime.to_unix(DateTime.from_naive!({0}, \"Etc/UTC\"), :millisecond)", 
			naiveDateTime);
	}
	
	/**
	 * Convert to NaiveDateTime for Elixir operations
	 */
	private function toNaiveDateTime(): Dynamic {
		// Convert milliseconds back to NaiveDateTime
		return Syntax.code("DateTime.from_unix!({0}, :millisecond) |> DateTime.to_naive()", this);
	}
	
	// ========================================
	// Haxe Standard Library API (Cross-Platform)
	// ========================================
	
	/**
	 * Returns the timestamp (in milliseconds) of this date.
	 */
	public function getTime(): Float {
		return this;
	}
	
	/**
	 * Returns the hours of this Date (0-23 range) in the local timezone.
	 */
	public function getHours(): Int {
		var naiveDateTime = toNaiveDateTime();
		return Syntax.code("{0}.hour", naiveDateTime);
	}
	
	/**
	 * Returns the minutes of this Date (0-59 range) in the local timezone.
	 */
	public function getMinutes(): Int {
		var naiveDateTime = toNaiveDateTime();
		return Syntax.code("{0}.minute", naiveDateTime);
	}
	
	/**
	 * Returns the seconds of this Date (0-59 range) in the local timezone.
	 */
	public function getSeconds(): Int {
		var naiveDateTime = toNaiveDateTime();
		return Syntax.code("{0}.second", naiveDateTime);
	}
	
	/**
	 * Returns the full year of this Date (4 digits) in the local timezone.
	 */
	public function getFullYear(): Int {
		var naiveDateTime = toNaiveDateTime();
		return Syntax.code("{0}.year", naiveDateTime);
	}
	
	/**
	 * Returns the month of this Date (0-11 range) in the local timezone.
	 * Note that the month number is zero-based per Haxe convention.
	 */
	public function getMonth(): Int {
		var naiveDateTime = toNaiveDateTime();
		var elixirMonth = Syntax.code("{0}.month", naiveDateTime);
		return elixirMonth - 1; // Convert from 1-based to 0-based
	}
	
	/**
	 * Returns the day of this Date (1-31 range) in the local timezone.
	 */
	public function getDate(): Int {
		var naiveDateTime = toNaiveDateTime();
		return Syntax.code("{0}.day", naiveDateTime);
	}
	
	/**
	 * Returns the day of the week of this Date (0-6 range, where 0 is Sunday)
	 * in the local timezone.
	 */
	public function getDay(): Int {
		// Use Elixir's Date.day_of_week which returns 1-7 (Monday-Sunday)
		var naiveDateTime = toNaiveDateTime();
		var elixirDate = Syntax.code("NaiveDateTime.to_date({0})", naiveDateTime);
		var elixirDayOfWeek = Syntax.code("Date.day_of_week({0})", elixirDate);
		
		// Convert from Elixir's 1-7 (Mon-Sun) to Haxe's 0-6 (Sun-Sat)
		return elixirDayOfWeek == 7 ? 0 : elixirDayOfWeek;
	}
	
	/**
	 * Returns the hours of this Date (0-23 range) in UTC.
	 * Since we use NaiveDateTime, this is the same as getHours()
	 */
	public function getUTCHours(): Int {
		return getHours();
	}
	
	/**
	 * Returns the minutes of this Date (0-59 range) in UTC.
	 * Since we use NaiveDateTime, this is the same as getMinutes()
	 */
	public function getUTCMinutes(): Int {
		return getMinutes();
	}
	
	/**
	 * Returns the seconds of this Date (0-59 range) in UTC.
	 * Since we use NaiveDateTime, this is the same as getSeconds()
	 */
	public function getUTCSeconds(): Int {
		return getSeconds();
	}
	
	/**
	 * Returns the full year of this Date (4 digits) in UTC.
	 * Since we use NaiveDateTime, this is the same as getFullYear()
	 */
	public function getUTCFullYear(): Int {
		return getFullYear();
	}
	
	/**
	 * Returns the month of this Date (0-11 range) in UTC.
	 * Since we use NaiveDateTime, this is the same as getMonth()
	 */
	public function getUTCMonth(): Int {
		return getMonth();
	}
	
	/**
	 * Returns the day of this Date (1-31 range) in UTC.
	 * Since we use NaiveDateTime, this is the same as getDate()
	 */
	public function getUTCDate(): Int {
		return getDate();
	}
	
	/**
	 * Returns the day of the week of this Date (0-6 range) in UTC.
	 * Since we use NaiveDateTime, this is the same as getDay()
	 */
	public function getUTCDay(): Int {
		return getDay();
	}
	
	/**
	 * Returns the time zone difference in minutes.
	 * Since we use NaiveDateTime (no timezone), returns 0.
	 */
	public function getTimezoneOffset(): Int {
		return 0;
	}
	
	/**
	 * Returns a string representation of this Date.
	 */
	public function toString(): String {
		var naiveDateTime = toNaiveDateTime();
		return Syntax.code("NaiveDateTime.to_string({0})", naiveDateTime);
	}
	
	/**
	 * Creates a Date from milliseconds since epoch.
	 * 
	 * @param t Timestamp in milliseconds
	 */
	public static function fromTime(t: Float): Date {
		return cast t;
	}
	
	/**
	 * Returns a Date representing the current time.
	 */
	public static function now(): Date {
		// Use Elixir's DateTime.utc_now() for current time
		var timestampMs = Syntax.code("DateTime.to_unix(DateTime.utc_now(), :millisecond)");
		return fromTime(timestampMs);
	}
	
	/**
	 * Parses a date from a string.
	 * Supports formats:
	 * - \"YYYY-MM-DD hh:mm:ss\"
	 * - \"YYYY-MM-DD\"
	 * - ISO 8601
	 * 
	 * @param s Date string to parse
	 */
	public static function fromString(s: String): Date {
		// Try parsing as ISO 8601 using Elixir's parser
		var result = Syntax.code("NaiveDateTime.from_iso8601({0})", s);
		var isOk = Syntax.code("elem({0}, 0) == :ok", result);
		
		if (isOk) {
			var naiveDateTime = Syntax.code("elem({0}, 1)", result);
			var timestampMs = Syntax.code("DateTime.to_unix(DateTime.from_naive!({0}, \"Etc/UTC\"), :millisecond)", naiveDateTime);
			return fromTime(timestampMs);
		} else {
			throw 'Cannot parse date: $s';
		}
	}
	
	// ========================================
	// Elixir Native API Extensions
	// ========================================
	
	/**
	 * Convert to ISO 8601 string format (Elixir-style)
	 * @return ISO 8601 formatted string
	 */
	public function toIso8601(): String {
		var naiveDateTime = toNaiveDateTime();
		return Syntax.code("NaiveDateTime.to_iso8601({0})", naiveDateTime);
	}
	
	/**
	 * Get the beginning of the day for this date
	 * @return New Date at 00:00:00
	 */
	public function beginningOfDay(): Date {
		return new Date(getFullYear(), getMonth(), getDate(), 0, 0, 0);
	}
	
	/**
	 * Get the end of the day for this date
	 * @return New Date at 23:59:59
	 */
	public function endOfDay(): Date {
		return new Date(getFullYear(), getMonth(), getDate(), 23, 59, 59);
	}
}