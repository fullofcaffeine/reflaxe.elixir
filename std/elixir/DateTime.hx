package elixir;

/**
 * Elixir DateTime type externs
 * 
 * Provides type-safe access to Elixir's DateTime, Date, and NaiveDateTime modules
 * for working with dates and times in Phoenix/Ecto applications.
 */

/**
 * A date in the ISO calendar (year, month, day)
 */
@:native("Date")
extern class Date {
    var year: Int;
    var month: Int;
    var day: Int;
    
    /**
     * Returns the current date in UTC
     */
    static function utc_today(): Date;
    
    /**
     * Creates a new date
     */
    static function new_date(year: Int, month: Int, day: Int): haxe.functional.Result<Date, String>;
    
    /**
     * Converts a date to a string
     */
    function to_string(): String;
    
    /**
     * Compares two dates
     */
    static function compare(date1: Date, date2: Date): ComparisonResult;
    
    /**
     * Adds days to a date
     */
    static function add(date: Date, days: Int): Date;
    
    /**
     * Calculate difference between two dates in days
     */
    static function diff(date1: Date, date2: Date): Int;

    /**
     * Day of week for a date (1..7 Monday..Sunday)
     */
    @:native("day_of_week")
    static function day_of_week(date: Date): Int;
}

/**
 * A datetime with timezone information
 */
@:native("DateTime")
extern class DateTime {
    var year: Int;
    var month: Int;
    var day: Int;
    var hour: Int;
    var minute: Int;
    var second: Int;
    var microsecond: {value: Int, precision: Int};
    var time_zone: String;
    var zone_abbr: String;
    var utc_offset: Int;
    var std_offset: Int;
    
    /**
     * Returns the current datetime in UTC
     */
    @:native("utc_now")
    static function utcNow(): DateTime;
    
    /**
     * Creates a new datetime from Unix timestamp
     */
    static function from_unix(timestamp: Int, ?unit: TimeUnit): haxe.functional.Result<DateTime, String>;
    
    /**
     * Converts to Unix timestamp
     */
    function to_unix(?unit: TimeUnit): Int;
    
    /**
     * Converts a datetime to a string
     */
    function to_string(): String;
    
    /**
     * Converts to ISO8601 string format
     */
    function to_iso8601(): String;

    @:native("to_naive")
    function to_naive(): NaiveDateTime;

    @:native("to_date")
    function to_date(): Date;
    
    /**
     * Parses an ISO8601 string to DateTime
     */
    static function from_iso8601(string: String): haxe.functional.Result<DateTime, String>;

    @:native("from_unix!")
    static function fromUnixBang(timestamp: Int, ?unit: TimeUnit): DateTime;

    @:native("from_naive!")
    static function fromNaiveBang(naive: NaiveDateTime, timezone: String): DateTime;
    
    /**
     * Compares two datetimes
     */
    static function compare(datetime1: DateTime, datetime2: DateTime): ComparisonResult;
    
    /**
     * Adds time to a datetime
     */
    static function add(datetime: DateTime, amount: Int, unit: TimeUnit): DateTime;
    
    /**
     * Calculate difference between two datetimes
     */
    static function diff(datetime1: DateTime, datetime2: DateTime, unit: TimeUnit): Int;
    
    /**
     * Truncates a datetime to a given precision
     */
    static function truncate(datetime: DateTime, precision: TimePrecision): DateTime;
}

/**
 * A datetime without timezone information
 */
@:native("NaiveDateTime")
extern class NaiveDateTime {
    var year: Int;
    var month: Int;
    var day: Int;
    var hour: Int;
    var minute: Int;
    var second: Int;
    var microsecond: {value: Int, precision: Int};
    
    /**
     * Returns the current naive datetime in UTC
     */
    static function utc_now(): NaiveDateTime;
    
    /**
     * Returns the current naive datetime in local time
     */
    static function local_now(): NaiveDateTime;
    
    /**
     * Creates a new naive datetime
     */
    static function new_datetime(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, ?microsecond: {value: Int, precision: Int}): haxe.functional.Result<NaiveDateTime, String>;
    
    /**
     * Converts a naive datetime to a string
     */
    function to_string(): String;
    
    /**
     * Converts to ISO8601 string format
     */
    function to_iso8601(): String;
    
    /**
     * Parses an ISO8601 string to NaiveDateTime
     */
    static function from_iso8601(string: String): haxe.functional.Result<NaiveDateTime, String>;
    
    /**
     * Compares two naive datetimes
     */
    static function compare(datetime1: NaiveDateTime, datetime2: NaiveDateTime): ComparisonResult;
    
    /**
     * Adds time to a naive datetime
     */
    static function add(datetime: NaiveDateTime, amount: Int, unit: TimeUnit): NaiveDateTime;
    
    /**
     * Calculate difference between two naive datetimes
     */
    static function diff(datetime1: NaiveDateTime, datetime2: NaiveDateTime, unit: TimeUnit): Int;
    
    /**
     * Truncates a naive datetime to a given precision
     */
    static function truncate(datetime: NaiveDateTime, precision: TimePrecision): NaiveDateTime;
}

/**
 * Time units for datetime operations
 * 
 * Uses the Atom type for type-safe atom generation in Elixir.
 * These compile to proper Elixir atoms (:second, :millisecond, etc.)
 * not string literals.
 */
enum abstract TimeUnit(elixir.types.Atom) to elixir.types.Atom {
    var Second = "second";
    var Millisecond = "millisecond";
    var Microsecond = "microsecond";
    var Nanosecond = "nanosecond";
    var Minute = "minute";
    var Hour = "hour";
    var Day = "day";
    var Week = "week";
}

/**
 * Time precision for truncation
 */
enum abstract TimePrecision(elixir.types.Atom) to elixir.types.Atom {
    var Second = "second";
    var Millisecond = "millisecond";
    var Microsecond = "microsecond";
}

/**
 * Result of date/time comparison
 */
enum abstract ComparisonResult(elixir.types.Atom) to elixir.types.Atom {
    var Lt = "lt";  // Less than
    var Eq = "eq";  // Equal
    var Gt = "gt";  // Greater than
}
