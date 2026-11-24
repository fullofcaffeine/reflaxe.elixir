package;

import CacheShared;

/**
 * Reads the shared types through ordinary Haxe references: a typedef field,
 * an inline function, and the enum. Haxe types it again after each edit of
 * the shared types file.
 */
class CacheSharedRowUser {
	public static function title(row:CacheSharedRow):String {
		return row.label;
	}

	public static function rowId(row:CacheSharedRow):Float {
		return row.id;
	}

	public static function scaled(n:Int):Int {
		return CacheShared.scale(n);
	}

	public static function toneName(tone:CacheSharedTone):String {
		return switch (tone) {
			case Calm: "calm";
			case Loud: "loud";
			case _: "other";
		}
	}
}
