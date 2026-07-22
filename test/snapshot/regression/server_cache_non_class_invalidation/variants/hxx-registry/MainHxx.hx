package;

class Main {
	static function main():Void {}

	public static function renderTemplate(assigns:{ready:Bool}):String {
		return CacheTemplate.render(assigns);
	}
}
