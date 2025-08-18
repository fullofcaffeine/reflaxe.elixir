package;

import elixir.DateTime.NaiveDateTime;
import elixir.DateTime.Date as ElixirDate;
import elixir.DateTime.DateTime as ElixirDateTime;
import elixir.DateTime.TimeUnit;
import elixir.DateTime.TimePrecision;
import elixir.DateTime.ComparisonResult;
import haxe.functional.Result;

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
 * - Uses abstract type over Float for clean encapsulation
 * - No field access issues - abstracts compile away at runtime
 * - Converts to/from NaiveDateTime only when needed for Elixir operations
 * - Month is 0-based (0-11) per Haxe convention
 * - Full type safety with zero runtime overhead
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
		// Convert Haxe's 0-based month to Elixir's 1-based month
		var elixirMonth = month + 1;
		
		// Create NaiveDateTime and extract timestamp
		var result = NaiveDateTime.new_datetime(year, elixirMonth, day, hour, min, sec);
		switch (result) {
			case Ok(dt):
				// Convert NaiveDateTime to timestamp for storage
				this = untyped __elixir__("DateTime.to_unix(DateTime.from_naive!({0}, \"Etc/UTC\"), :millisecond)", dt);
			case Error(reason):
				throw 'Invalid date: $reason';
		}
	}
	
	/**
	 * Convert internal timestamp to NaiveDateTime for Elixir operations
	 */
	private function asNaiveDateTime(): NaiveDateTime {
		var seconds = Math.floor(this / 1000);
		return untyped __elixir__("DateTime.from_unix!({0}, :second) |> DateTime.to_naive()", seconds);
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
		return asNaiveDateTime().hour;
	}
	
	/**
	 * Returns the minutes of this Date (0-59 range) in the local timezone.
	 */
	public function getMinutes(): Int {
		return asNaiveDateTime().minute;
	}
	
	/**
	 * Returns the seconds of this Date (0-59 range) in the local timezone.
	 */
	public function getSeconds(): Int {
		return asNaiveDateTime().second;
	}
	
	/**
	 * Returns the full year of this Date (4 digits) in the local timezone.
	 */
	public function getFullYear(): Int {
		return asNaiveDateTime().year;
	}
	
	/**
	 * Returns the month of this Date (0-11 range) in the local timezone.
	 * Note that the month number is zero-based per Haxe convention.
	 */
	public function getMonth(): Int {
		// Convert Elixir's 1-based month to Haxe's 0-based month
		return asNaiveDateTime().month - 1;
	}
	
	/**
	 * Returns the day of this Date (1-31 range) in the local timezone.
	 */
	public function getDate(): Int {
		return asNaiveDateTime().day;
	}
	
	/**
	 * Returns the day of the week of this Date (0-6 range, where 0 is Sunday)
	 * in the local timezone.
	 */
	public function getDay(): Int {
		// Elixir's Date.day_of_week returns 1-7 (Monday-Sunday)
		// Haxe expects 0-6 (Sunday-Saturday)
		var naiveDateTime = asNaiveDateTime();
		return untyped __elixir__("rem(Date.day_of_week(Date.from_erl!({0} |> NaiveDateTime.to_erl() |> elem(0))), 7)", naiveDateTime);
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
		return asNaiveDateTime().to_string();
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
		var dt = NaiveDateTime.utc_now();
		var timestampMs = untyped __elixir__("DateTime.to_unix(DateTime.from_naive!({0}, \"Etc/UTC\"), :millisecond)", dt);
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
		// Try ISO 8601 first
		var result = NaiveDateTime.from_iso8601(s);
		switch (result) {
			case Ok(dt):
				var timestampMs = untyped __elixir__("DateTime.to_unix(DateTime.from_naive!({0}, \"Etc/UTC\"), :millisecond)", dt);
				return fromTime(timestampMs);
			case Error(_):
				// Try other formats
				throw 'Cannot parse date: $s';
		}
	}
	
	// ========================================
	// Elixir Native API Extensions
	// ========================================
	
	/**
	 * Add time to this date (Elixir-style)
	 * @param amount Amount to add
	 * @param unit Time unit (Second, Minute, Hour, Day, Week)
	 * @return New Date with added time
	 */
	public function add(amount: Int, unit: TimeUnit): Date {
		var naiveDateTime = asNaiveDateTime();
		var newDt = NaiveDateTime.add(naiveDateTime, amount, unit);
		var newTimestamp = untyped __elixir__("DateTime.to_unix(DateTime.from_naive!({0}, \"Etc/UTC\"), :millisecond)", newDt);
		return fromTime(newTimestamp);
	}
	
	/**
	 * Calculate difference between this date and another (Elixir-style)
	 * @param other The other date to compare
	 * @param unit Time unit for the result
	 * @return Difference in the specified unit
	 */
	public function diff(other: Date, unit: TimeUnit): Int {
		var thisNaive = asNaiveDateTime();
		var otherNaive = other.asNaiveDateTime();
		return NaiveDateTime.diff(thisNaive, otherNaive, unit);
	}
	
	/**
	 * Compare this date with another (Elixir-style)
	 * @param other The date to compare with
	 * @return :lt if this < other, :eq if equal, :gt if this > other
	 */
	public function compare(other: Date): ComparisonResult {
		var thisNaive = asNaiveDateTime();
		var otherNaive = other.asNaiveDateTime();
		return NaiveDateTime.compare(thisNaive, otherNaive);
	}
	
	/**
	 * Convert to ISO 8601 string format (Elixir-style)
	 * @return ISO 8601 formatted string
	 */
	public function toIso8601(): String {
		return asNaiveDateTime().to_iso8601();
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
	
	/**
	 * Truncate this date to the specified precision
	 * @param precision The precision to truncate to (Second, Millisecond, Microsecond)
	 * @return New Date truncated to the specified precision
	 */
	public function truncate(precision: TimePrecision): Date {
		var naiveDateTime = asNaiveDateTime();
		var truncated = NaiveDateTime.truncate(naiveDateTime, precision);
		var newTimestamp = untyped __elixir__("DateTime.to_unix(DateTime.from_naive!({0}, \"Etc/UTC\"), :millisecond)", truncated);
		return fromTime(newTimestamp);
	}
	
	// ========================================
	// Conversion Methods
	// ========================================
	
	/**
	 * Convert to Elixir NaiveDateTime
	 */
	public function toNaiveDateTime(): NaiveDateTime {
		return asNaiveDateTime();
	}
	
	/**
	 * Convert to Elixir Date (date only, no time)
	 */
	public function toElixirDate(): ElixirDate {
		var naiveDateTime = asNaiveDateTime();
		return untyped __elixir__("Date.from_erl!({0} |> NaiveDateTime.to_erl() |> elem(0))", naiveDateTime);
	}
	
	/**
	 * Create from Elixir NaiveDateTime
	 */
	public static function fromNaiveDateTime(dt: NaiveDateTime): Date {
		var timestampMs = untyped __elixir__("DateTime.to_unix(DateTime.from_naive!({0}, \"Etc/UTC\"), :millisecond)", dt);
		return fromTime(timestampMs);
	}
	
	/**
	 * Create from Elixir Date
	 */
	public static function fromElixirDate(d: ElixirDate): Date {
		return new Date(d.year, d.month - 1, d.day, 0, 0, 0);
	}
	
	/**
	 * Create from Elixir DateTime (with timezone)
	 */
	public static function fromDateTime(dt: ElixirDateTime): Date {
		// Convert DateTime to NaiveDateTime (loses timezone info)
		var naiveDt = untyped __elixir__("DateTime.to_naive({0})", dt);
		return fromNaiveDateTime(naiveDt);
	}
}