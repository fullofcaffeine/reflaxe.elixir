/**
 * DateTools (Elixir target)
 *
 * WHAT
 * - Implements Haxe stdlib `DateTools` helpers for working with `Date` values and timestamps.
 *
 * WHY
 * - Many Haxe libraries rely on `DateTools` for formatting, delta arithmetic, and timestamp helpers.
 *
 * HOW
 * - Keep the implementation pure-Haxe where possible so behavior matches Haxe std semantics.
 * - `format/2` implements the same `strftime`-compatible subset as Haxe std.
 */
class DateTools {
    static var DAY_SHORT_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    static var DAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    static var MONTH_SHORT_NAMES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    static var MONTH_NAMES = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ];

    private static function __format_get(d: Date, e: String): String {
        return switch (e) {
            case "%":
                "%";
            case "a":
                DAY_SHORT_NAMES[d.getDay()];
            case "A":
                DAY_NAMES[d.getDay()];
            case "b", "h":
                MONTH_SHORT_NAMES[d.getMonth()];
            case "B":
                MONTH_NAMES[d.getMonth()];
            case "C":
                StringTools.lpad(Std.string(Std.int(d.getFullYear() / 100)), "0", 2);
            case "d":
                StringTools.lpad(Std.string(d.getDate()), "0", 2);
            case "D":
                __format(d, "%m/%d/%y");
            case "e":
                Std.string(d.getDate());
            case "F":
                __format(d, "%Y-%m-%d");
            case "H", "k":
                StringTools.lpad(Std.string(d.getHours()), if (e == "H") "0" else " ", 2);
            case "I", "l":
                var hour = d.getHours() % 12;
                StringTools.lpad(Std.string(hour == 0 ? 12 : hour), if (e == "I") "0" else " ", 2);
            case "m":
                StringTools.lpad(Std.string(d.getMonth() + 1), "0", 2);
            case "M":
                StringTools.lpad(Std.string(d.getMinutes()), "0", 2);
            case "n":
                "\n";
            case "p":
                if (d.getHours() > 11) "PM" else "AM";
            case "r":
                __format(d, "%I:%M:%S %p");
            case "R":
                __format(d, "%H:%M");
            case "s":
                Std.string(Std.int(d.getTime() / 1000));
            case "S":
                StringTools.lpad(Std.string(d.getSeconds()), "0", 2);
            case "t":
                "\t";
            case "T":
                __format(d, "%H:%M:%S");
            case "u":
                var t = d.getDay();
                if (t == 0) "7" else Std.string(t);
            case "w":
                Std.string(d.getDay());
            case "y":
                StringTools.lpad(Std.string(d.getFullYear() % 100), "0", 2);
            case "Y":
                Std.string(d.getFullYear());
            default:
                throw new haxe.exceptions.NotImplementedException("Date.format %" + e + "- not implemented yet.");
        }
    }

    private static function __format(d: Date, f: String): String {
        var result = new StringBuf();
        var p = 0;

        while (true) {
            var nextPercent = f.indexOf("%", p);
            if (nextPercent < 0) break;

            result.addSub(f, p, nextPercent - p);
            result.add(__format_get(d, f.substr(nextPercent + 1, 1)));

            p = nextPercent + 2;
        }

        result.addSub(f, p, f.length - p);
        return result.toString();
    }

    /**
     * Format the date `d` according to the format `f`.
     *
     * The format is compatible with the `strftime` standard format, using the same subset as Haxe std.
     */
    public static function format(d: Date, f: String): String {
        return __format(d, f);
    }

    /**
     * Returns the result of adding timestamp `t` to Date `d`.
     */
    public static inline function delta(d: Date, t: Float): Date {
        return Date.fromTime(d.getTime() + t);
    }

    static var DAYS_OF_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    /**
     * Returns the number of days in the month of Date `d`, including leap years.
     */
    public static function getMonthDays(d: Date): Int {
        var month = d.getMonth();
        var year = d.getFullYear();

        if (month != 1) return DAYS_OF_MONTH[month];

        var isLeap = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
        return isLeap ? 29 : 28;
    }

    /**
     * Converts a number of seconds to a timestamp (milliseconds).
     */
    public static inline function seconds(n: Float): Float {
        return n * 1000.0;
    }

    /**
     * Converts a number of minutes to a timestamp (milliseconds).
     */
    public static inline function minutes(n: Float): Float {
        return n * 60.0 * 1000.0;
    }

    /**
     * Converts a number of hours to a timestamp (milliseconds).
     */
    public static inline function hours(n: Float): Float {
        return n * 60.0 * 60.0 * 1000.0;
    }

    /**
     * Converts a number of days to a timestamp (milliseconds).
     */
    public static inline function days(n: Float): Float {
        return n * 24.0 * 60.0 * 60.0 * 1000.0;
    }

    /**
     * Separate a date-time into several components.
     */
    public static function parse(t: Float) {
        var s = t / 1000;
        var m = s / 60;
        var h = m / 60;
        return {
            ms: t % 1000,
            seconds: Std.int(s % 60),
            minutes: Std.int(m % 60),
            hours: Std.int(h % 24),
            days: Std.int(h / 24),
        };
    }

    /**
     * Build a date-time timestamp from several components.
     */
    public static function make(o: {
        ms: Float,
        seconds: Int,
        minutes: Int,
        hours: Int,
        days: Int
    }) {
        return o.ms + 1000.0 * (o.seconds + 60.0 * (o.minutes + 60.0 * (o.hours + 24.0 * o.days)));
    }

    /**
     * Retrieve a UTC timestamp (milliseconds) from Date components.
     *
     * Takes the same argument sequence as the Date constructor (month is 0-based).
     */
    public static function makeUtc(year: Int, month: Int, day: Int, hour: Int, min: Int, sec: Int): Float {
        return (new Date(year, month, day, hour, min, sec)).getTime();
    }
}

