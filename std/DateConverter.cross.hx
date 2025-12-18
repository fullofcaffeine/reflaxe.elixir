package;

import elixir.Date as ElixirDate;
import elixir.DateTime as ElixirDateTime;
import elixir.NaiveDateTime;

/**
 * Utility class for converting between Haxe Date and Elixir date types
 * 
 * Provides seamless conversion between:
 * - Haxe Date (cross-platform)
 * - Elixir Date (date only)
 * - Elixir DateTime (with timezone)
 * - Elixir NaiveDateTime (without timezone)
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Convert Haxe Date to Elixir Date
 * var haxeDate = Date.now();
 * var elixirDate = DateConverter.toElixirDate(haxeDate);
 * 
 * // Convert Elixir DateTime to Haxe Date
 * var elixirDateTime = ElixirDateTime.utc_now();
 * var haxeDate = DateConverter.fromDateTime(elixirDateTime);
 * 
 * // Format date for display
 * var formatted = DateConverter.formatDate(haxeDate, "YYYY-MM-DD");
 * ```
 */
class DateConverter {
	
	// ========================================
	// From Haxe Date to Elixir Types
	// ========================================
	
	/**
	 * Convert Haxe Date to Elixir Date (date only, no time)
	 */
	public static function toElixirDate(date: Date): ElixirDate {
		return date.toElixirDate();
	}
	
	/**
	 * Convert Haxe Date to Elixir NaiveDateTime
	 */
	public static function toNaiveDateTime(date: Date): NaiveDateTime {
		return date.toNaiveDateTime();
	}
	
	/**
	 * Convert Haxe Date to Elixir DateTime with UTC timezone
	 */
	public static function toDateTime(date: Date, timezone: String = "Etc/UTC"): ElixirDateTime {
		var naive = date.toNaiveDateTime();
		// Convert NaiveDateTime to DateTime with timezone
		return untyped __elixir__("DateTime.from_naive!({0}, {1})", naive, timezone);
	}
	
	// ========================================
	// From Elixir Types to Haxe Date
	// ========================================
	
	/**
	 * Convert Elixir Date to Haxe Date (time set to 00:00:00)
	 */
	public static function fromElixirDate(date: ElixirDate): Date {
		return Date.fromElixirDate(date);
	}
	
	/**
	 * Convert Elixir NaiveDateTime to Haxe Date
	 */
	public static function fromNaiveDateTime(datetime: NaiveDateTime): Date {
		return Date.fromNaiveDateTime(datetime);
	}
	
	/**
	 * Convert Elixir DateTime to Haxe Date
	 */
	public static function fromDateTime(datetime: ElixirDateTime): Date {
		// Convert to NaiveDateTime first (loses timezone info)
		var naive = untyped __elixir__("DateTime.to_naive({0})", datetime);
		return Date.fromNaiveDateTime(naive);
	}
	
	// ========================================
	// Formatting Utilities
	// ========================================
	
	/**
	 * Format a Haxe Date to string using common patterns
	 * 
	 * Patterns:
	 * - "YYYY-MM-DD" - Date only
	 * - "YYYY-MM-DD HH:mm:ss" - Date and time
	 * - "ISO" - ISO 8601 format
	 * 
	 * @param date The date to format
	 * @param pattern Format pattern
	 */
	public static function formatDate(date: Date, pattern: String): String {
		var year = date.getFullYear();
		var month = StringTools.lpad(Std.string(date.getMonth() + 1), "0", 2);
		var day = StringTools.lpad(Std.string(date.getDate()), "0", 2);
		var hour = StringTools.lpad(Std.string(date.getHours()), "0", 2);
		var min = StringTools.lpad(Std.string(date.getMinutes()), "0", 2);
		var sec = StringTools.lpad(Std.string(date.getSeconds()), "0", 2);
		
		return switch (pattern) {
			case "YYYY-MM-DD":
				'$year-$month-$day';
			case "YYYY-MM-DD HH:mm:ss":
				'$year-$month-$day $hour:$min:$sec';
			case "ISO":
				date.toNaiveDateTime().to_iso8601();
			default:
				date.toString();
		}
	}
	
	/**
	 * Parse a date string to Haxe Date
	 * Supports ISO 8601 and common formats
	 */
	public static function parseDate(dateString: String): Date {
		return Date.fromString(dateString);
	}
	
	// ========================================
	// Date Arithmetic
	// ========================================
	
	/**
	 * Add days to a date
	 */
	public static function addDays(date: Date, days: Int): Date {
		var elixirDate = date.toElixirDate();
		var newDate = ElixirDate.add(elixirDate, days);
		return fromElixirDate(newDate);
	}
	
	/**
	 * Calculate difference between two dates in days
	 */
	public static function daysBetween(date1: Date, date2: Date): Int {
		var d1 = date1.toElixirDate();
		var d2 = date2.toElixirDate();
		return ElixirDate.diff(d1, d2);
	}
	
	/**
	 * Check if a date is in the past
	 */
	public static function isPast(date: Date): Bool {
		var now = Date.now();
		return date.getTime() < now.getTime();
	}
	
	/**
	 * Check if a date is in the future
	 */
	public static function isFuture(date: Date): Bool {
		var now = Date.now();
		return date.getTime() > now.getTime();
	}
	
	/**
	 * Check if a date is today
	 */
	public static function isToday(date: Date): Bool {
		var today = Date.now();
		var d1 = date.toElixirDate();
		var d2 = today.toElixirDate();
		return ElixirDate.compare(d1, d2) == elixir.ComparisonResult.Eq;
	}
	
}
