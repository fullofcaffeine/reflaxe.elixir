package;

import haxe.io.Mime;
import haxe.io.Scheme;

/**
 * Snapshot: official haxe.io.Mime and haxe.io.Scheme fallback.
 *
 * Both enum abstracts must erase to ordinary String values without emitting
 * target runtime modules.
 */
class Main {
	static function main() {
		var mime:String = Mime.ApplicationJson;
		var customMime:Mime = "application/vnd.example+json";
		var customMimeText:String = customMime;
		var scheme:String = Scheme.Https;
		var customScheme:Scheme = "web+demo";
		var customSchemeText:String = customScheme;

		trace(mime);
		trace(customMimeText);
		trace(scheme);
		trace(customSchemeText);
	}
}
