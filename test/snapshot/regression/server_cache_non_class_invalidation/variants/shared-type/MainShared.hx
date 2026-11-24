package;

import CacheShared;

class Main {
	static function main():Void {}

	public static function renderPage(assigns:{ready:Bool}):String {
		return CacheSharedPage.render(assigns) + CacheSharedQuiet.render(assigns) + CacheSharedInlinePage.render(assigns);
	}

	public static function rowTitle(row:CacheSharedRow):String {
		return CacheSharedRowUser.title(row)
			+ CacheSharedRowUser.scaled(2)
			+ CacheSharedRowUser.rowId(row)
			+ CacheSharedRowUser.toneName(Calm);
	}
}
