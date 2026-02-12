package;

/**
 * Snapshot: DateTools
 *
 * Exercises Haxe stdlib `DateTools` helpers on the Elixir target.
 */
class Main {
	static function main() {
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

		trace(DateTools.makeUtc(1970, 0, 1, 0, 0, 0));
	}
}
