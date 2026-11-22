package;

class Main {
	static function main():Void {}

	public static function renderPage(assigns:{ready:Bool}):String {
		return CacheCardPage.render(assigns);
	}
}
