import phoenix.live_view.LiveEventProtocol;

@:liveEventProtocol("ProfileHookEvents")
enum ProfileHookEvent {
	@:hookEvent("clipboard_copied")
	ClipboardCopied(message:String);

	Ping;

	TodoSelected(todoId:Int, fromHook:Bool);

	TagsChanged(tags:Array<String>);
}

class Main {
	static final manifest = LiveEventProtocol.manifest(ProfileHookEvent);
	static final hash = LiveEventProtocol.hash(ProfileHookEvent);

	static function assertThat(condition:Bool, message:String):Void {
		if (!condition) {
			throw message;
		}
	}

	static function main():Void {
		assertThat(manifest.indexOf("protocol ProfileHookEvent") >= 0, "protocol name missing");
		assertThat(manifest.indexOf("companion ProfileHookEvents") >= 0, "companion name missing");
		assertThat(manifest.indexOf("event hook ClipboardCopied clipboard_copied (message:String->message:string)") >= 0, "clipboard event missing");
		assertThat(manifest.indexOf("event hook Ping ping ()") >= 0, "ping event missing");
		assertThat(manifest.indexOf("event hook TodoSelected todo_selected (todoId:Int->todo_id:int, fromHook:Bool->from_hook:bool)") >= 0,
			"multi-field event missing");
		assertThat(manifest.indexOf("event hook TagsChanged tags_changed (tags:Array<String>->tags:string_array)") >= 0, "array field missing");
		assertThat(hash.length == 40, "manifest hash should be sha1");
	}
}
