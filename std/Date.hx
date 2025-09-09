/*
 * Copyright (C)2005-2025 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

/**
 * The Date class provides a cross-platform way to work with dates and times.
 * 
 * For the Elixir target, this uses the native DateTime and NaiveDateTime modules
 * for efficient date/time operations on the BEAM.
 * 
 * ## Usage Example (Haxe)
 * ```haxe
 * var now = Date.now();
 * var timestamp = now.getTime(); // milliseconds since epoch
 * var year = now.getFullYear();
 * ```
 * 
 * ## Generated Idiomatic Elixir
 * ```elixir
 * now = DateTime.utc_now()
 * timestamp = DateTime.to_unix(now, :millisecond)
 * year = now.year
 * ```
 * 
 * @see https://api.haxe.org/Date.html
 */
@:coreApi
class Date {
    /**
     * Internal representation using Elixir's DateTime
     */
    var datetime: Dynamic;
    
    /**
     * Creates a new Date from the current time.
     * @return A new Date instance representing the current time
     */
    public static function now(): Date {
        #if macro
        // At macro/compile time, create a Date with current system time
        // This works because the constructor is available at macro time
        var d = Date.fromTime(Sys.time() * 1000);
        return d;
        #else
        // At runtime, construct a Date wrapper holding Elixir's DateTime
        // WHY: Returning the bare DateTime leads to broken inline expansions like
        // "_this = Date.now(); DateTime.to_unix(this.datetime, :millisecond)".
        // We must return a Haxe Date instance whose `datetime` field points to
        // the Elixir DateTime so that instance methods (getTime, etc.) can
        // reliably reference `this.datetime`.
        var d = new Date(0, 0, 0, 0, 0, 0);
        // We intentionally initialize the private backing field here.
        // @:privateAccess allows accessing a type's private fields from outside
        // their usual visibility. Even though we're inside Date, using it makes
        // the intent explicit and avoids exposing a public setter just for this.
        // This keeps `datetime` encapsulated while constructing a correct
        // wrapper around the Elixir DateTime value.
        @:privateAccess d.datetime = untyped __elixir__('DateTime.utc_now()');
        return d;
        #end
    }
    
    /**
     * Creates a Date from a timestamp.
     * @param t Milliseconds since Unix epoch (January 1, 1970 00:00:00 UTC)
     * @return A new Date instance
     */
    public static function fromTime(t: Float): Date {
        #if macro
        // At macro time, create a Date with timestamp. We cannot call
        // runtime Elixir here, so we stash the value in the private field.
        var d = new Date(1970, 0, 1, 0, 0, 0);
        // @:privateAccess: explicitly write to the private field without
        // introducing public mutators, keeping the type encapsulated.
        @:privateAccess d.datetime = t;
        return d;
        #else
        var d = new Date(0, 0, 0, 0, 0, 0);
        var seconds = Std.int(t / 1000);
        var microseconds = Std.int((t % 1000) * 1000);
        d.datetime = untyped __elixir__('DateTime.from_unix!({0}, :second) |> DateTime.add({1}, :microsecond)', seconds, microseconds);
        return d;
        #end
    }
    
    /**
     * Creates a Date from a string.
     * @param s A date string in ISO 8601 format
     * @return A new Date instance
     */
    public static function fromString(s: String): Date {
        var d = new Date(0, 0, 0, 0, 0, 0);
        d.datetime = untyped __elixir__('case DateTime.from_iso8601({0}) do
            {:ok, dt, _} -> dt
            _ -> nil
        end', s);
        return d;
    }
    
    /**
     * Creates a new Date instance.
     * @param year The year (4 digits)
     * @param month The month (0-11, where 0 = January)
     * @param day The day of the month (1-31)
     * @param hour The hour (0-23)
     * @param min The minute (0-59)
     * @param sec The second (0-59)
     */
    public function new(year: Int, month: Int, day: Int, hour: Int, min: Int, sec: Int) {
        // Adjust month from Haxe's 0-based to Elixir's 1-based
        var elixirMonth = month + 1;
        
        // Create a NaiveDateTime first, then convert to DateTime with UTC timezone
        datetime = untyped __elixir__('
            {:ok, naive} = NaiveDateTime.new({0}, {1}, {2}, {3}, {4}, {5})
            DateTime.from_naive!(naive, "Etc/UTC")',
            year, elixirMonth, day, hour, min, sec
        );
    }
    
    /**
     * Returns the timestamp of this Date.
     * @return The number of milliseconds since Unix epoch
     */
    extern inline public function getTime(): Float {
        return untyped __elixir__('DateTime.to_unix({0}, :millisecond)', datetime);
    }
    
    /**
     * Returns the year of this Date.
     * @return The year (4 digits)
     */
    extern inline public function getFullYear(): Int {
        return untyped __elixir__('{0}.year', datetime);
    }
    
    /**
     * Returns the month of this Date.
     * @return The month (0-11, where 0 = January)
     */
    extern inline public function getMonth(): Int {
        // Convert from Elixir's 1-based to Haxe's 0-based months
        return untyped __elixir__('{0}.month - 1', datetime);
    }
    
    /**
     * Returns the day of the month of this Date.
     * @return The day (1-31)
     */
    extern inline public function getDate(): Int {
        return untyped __elixir__('{0}.day', datetime);
    }
    
    /**
     * Returns the day of the week of this Date.
     * @return The day of the week (0-6, where 0 = Sunday)
     */
    extern inline public function getDay(): Int {
        // Elixir's Date.day_of_week returns 1-7 (Monday-Sunday)
        // Haxe expects 0-6 (Sunday-Saturday)
        var elixirDay: Int = untyped __elixir__('Date.day_of_week({0})', datetime);
        return elixirDay == 7 ? 0 : elixirDay;
    }
    
    /**
     * Returns the hour of this Date.
     * @return The hour (0-23)
     */
    extern inline public function getHours(): Int {
        return untyped __elixir__('{0}.hour', datetime);
    }
    
    /**
     * Returns the minutes of this Date.
     * @return The minutes (0-59)
     */
    extern inline public function getMinutes(): Int {
        return untyped __elixir__('{0}.minute', datetime);
    }
    
    /**
     * Returns the seconds of this Date.
     * @return The seconds (0-59)
     */
    extern inline public function getSeconds(): Int {
        return untyped __elixir__('{0}.second', datetime);
    }
    
    /**
     * Returns a string representation of this Date.
     * @return An ISO 8601 formatted date string
     */
    extern inline public function toString(): String {
        return untyped __elixir__('DateTime.to_iso8601({0})', datetime);
    }
    
    /**
     * Returns the UTC offset of this Date in minutes.
     * @return The UTC offset in minutes (always 0 for UTC dates)
     */
    extern inline public function getTimezoneOffset(): Int {
        // For now, we always use UTC, so offset is 0
        return 0;
    }
    
    /**
     * Returns the UTC year of this Date.
     * @return The UTC year (4 digits)
     */
    extern inline public function getUTCFullYear(): Int {
        return getFullYear();
    }
    
    /**
     * Returns the UTC month of this Date.
     * @return The UTC month (0-11)
     */
    extern inline public function getUTCMonth(): Int {
        return getMonth();
    }
    
    /**
     * Returns the UTC day of the month of this Date.
     * @return The UTC day (1-31)
     */
    extern inline public function getUTCDate(): Int {
        return getDate();
    }
    
    /**
     * Returns the UTC hour of this Date.
     * @return The UTC hour (0-23)
     */
    extern inline public function getUTCHours(): Int {
        return getHours();
    }
    
    /**
     * Returns the UTC minutes of this Date.
     * @return The UTC minutes (0-59)
     */
    extern inline public function getUTCMinutes(): Int {
        return getMinutes();
    }
    
    /**
     * Returns the UTC seconds of this Date.
     * @return The UTC seconds (0-59)
     */
    extern inline public function getUTCSeconds(): Int {
        return getSeconds();
    }
    
    /**
     * Returns the UTC day of the week of this Date.
     * @return The UTC day of the week (0-6, where 0 = Sunday)
     */
    extern inline public function getUTCDay(): Int {
        return getDay();
    }
}
