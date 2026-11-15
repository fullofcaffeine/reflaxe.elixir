package;

class Main {
	static function main():Void {
		Sys.println(HookName.HookNameNotes.note());
	}

	public static function renderTemplate(assigns:{ready:Bool}):String {
		return CacheTemplate.render(assigns);
	}
}
