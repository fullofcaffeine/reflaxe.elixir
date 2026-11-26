package;

class Main {
	static function main():Void {}

	public static function renderPage(form:Dynamic):String {
		return LateForm.render({form: form});
	}
}
