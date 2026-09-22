package;

/**
 * Snapshot: DateTools
 *
 * Exercises Haxe stdlib `DateTools` helpers on the Elixir target.
 */
class Main {
	static function main() {
		// ISO weekdays exercise case-local setup before a conditional result.
		var monday = new Date(2024, 0, 1, 12, 0, 0);
		var sunday = new Date(2024, 0, 7, 12, 0, 0);
		if (DateTools.format(monday, "%u") != "1")
			throw "ISO Monday must be weekday 1";
		if (DateTools.format(sunday, "%u") != "7")
			throw "ISO Sunday must be weekday 7";

		var epoch = Date.fromTime(0);
		trace(DateTools.format(epoch, "%Y-%m-%d"));
		trace(DateTools.format(epoch, "%a"));

		var leapFeb = new Date(2024, 1, 1, 0, 0, 0); // Feb 2024
		trace(DateTools.getMonthDays(leapFeb));

		var nextDay = DateTools.delta(epoch, DateTools.days(1));
		trace(nextDay.getTime());

		var built = DateTools.make({
			ms: 123.0,
			seconds: 2,
			minutes: 3,
			hours: 4,
			days: 5
		});
		var parts = DateTools.parse(built);
		trace(parts.days);
		trace(parts.hours);
		trace(DateTools.make(parts));

		#if (elixir || reflaxe_runtime)
		// This target extension is not part of stock Haxe's DateTools API.
		trace(DateTools.makeUtc(1970, 0, 1, 0, 0, 0));
		#end
	}
}
