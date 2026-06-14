package;

import sys.db.Sqlite;

class Main {
	public static function main():Void {
		// Negative test: direct Haxe host DB APIs are not supported on BEAM.
		// Use Ecto schemas/query/Repo boundaries instead.
		Sqlite.open("app.db");
	}
}
