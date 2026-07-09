package haxe.io;

/**
 * Path (Elixir target)
 *
 * WHAT
 * - Canonical Haxe `haxe.io.Path` helpers for path parsing and normalization.
 *
 * WHY
 * - User target code can depend on `haxe.io.Path`, while compiler macro code
 *   already uses the upstream pure-Haxe API during eval. Keeping this override
 *   pure Haxe preserves macro/eval behavior and lets Reflaxe emit target code.
 *
 * HOW
 * - Mirror the Haxe 4.3 API shape with string operations only.
 * - Avoid BEAM-specific APIs so the class remains safe in macro contexts.
 */
@:native("Haxe.IO.Path")
class Path {
	public var dir:Null<String>;
	public var file:String;
	public var ext:Null<String>;
	public var backslash:Bool;

	public function new(path:String) {
		backslash = false;

		if (path == "." || path == "..") {
			dir = path;
			file = "";
			ext = null;
		} else {
			var slashIndex = path.lastIndexOf("/");
			var backslashIndex = path.lastIndexOf("\\");
			if (slashIndex < backslashIndex) {
				dir = path.substr(0, backslashIndex);
				path = path.substr(backslashIndex + 1);
				backslash = true;
			} else if (backslashIndex < slashIndex) {
				dir = path.substr(0, slashIndex);
				path = path.substr(slashIndex + 1);
			} else {
				dir = null;
			}

			var dotIndex = path.lastIndexOf(".");
			if (dotIndex != -1) {
				ext = path.substr(dotIndex + 1);
				file = path.substr(0, dotIndex);
			} else {
				ext = null;
				file = path;
			}
		}
	}

	public function toString():String {
		var directoryPrefix = (dir == null) ? "" : dir + (backslash ? "\\" : "/");
		var extensionSuffix = (ext == null) ? "" : "." + ext;
		return directoryPrefix + file + extensionSuffix;
	}

	public static function withoutExtension(path:String):String {
		var parsedPath = new Path(path);
		parsedPath.ext = null;
		return parsedPath.toString();
	}

	public static function withoutDirectory(path:String):String {
		var parsedPath = new Path(path);
		parsedPath.dir = null;
		return parsedPath.toString();
	}

	public static function directory(path:String):String {
		var parsedPath = new Path(path);
		return parsedPath.dir == null ? "" : parsedPath.dir;
	}

	public static function extension(path:String):String {
		var parsedPath = new Path(path);
		return parsedPath.ext == null ? "" : parsedPath.ext;
	}

	public static function withExtension(path:String, extension:String):String {
		var parsedPath = new Path(path);
		parsedPath.ext = extension;
		return parsedPath.toString();
	}

	public static function join(paths:Array<String>):String {
		var filteredPaths:Array<String> = [];
		for (path in paths) {
			if (path != null && path != "")
				filteredPaths.push(path);
		}
		if (filteredPaths.length == 0)
			return "";

		var result = filteredPaths[0];
		for (index in 1...filteredPaths.length) {
			result = addTrailingSlash(result) + filteredPaths[index];
		}
		return normalize(result);
	}

	public static function normalize(path:String):String {
		var slash = "/";
		path = path.split("\\").join(slash);
		if (path == slash)
			return slash;

		var target:Array<String> = [];
		for (part in path.split(slash)) {
			if (part == ".." && target.length > 0 && target[target.length - 1] != "..") {
				target = withoutLastPart(target);
			} else if (part == "") {
				if (target.length > 0 || path.charCodeAt(0) == slash.charCodeAt(0)) {
					target.push(part);
				}
			} else if (part != ".") {
				target.push(part);
			}
		}

		var collapsed = target.join(slash);
		var result = "";
		var colon = false;
		var slashes = false;
		for (index in 0...collapsed.length) {
			var code = collapsed.charCodeAt(index);
			if (code == ":".code) {
				result += ":";
				colon = true;
			} else if (code == "/".code && !colon) {
				slashes = true;
			} else {
				colon = false;
				if (slashes) {
					result += "/";
					slashes = false;
				}
				result += String.fromCharCode(code);
			}
		}

		return result;
	}

	static function withoutLastPart(parts:Array<String>):Array<String> {
		var result:Array<String> = [];
		var previousPart = "";
		var hasPreviousPart = false;
		for (part in parts) {
			if (hasPreviousPart)
				result.push(previousPart);
			previousPart = part;
			hasPreviousPart = true;
		}
		return result;
	}

	public static function addTrailingSlash(path:String):String {
		if (path.length == 0)
			return "/";

		var slashIndex = path.lastIndexOf("/");
		var backslashIndex = path.lastIndexOf("\\");
		if (slashIndex < backslashIndex) {
			return backslashIndex == path.length - 1 ? path : path + "\\";
		}
		return slashIndex == path.length - 1 ? path : path + "/";
	}

	public static function removeTrailingSlashes(path:String):String {
		var trimmedLength = path.length;
		var trimming = true;
		for (offset in 0...path.length) {
			if (trimming) {
				var index = path.length - 1 - offset;
				var code = path.charCodeAt(index);
				if (code == '/'.code || code == '\\'.code)
					trimmedLength = index;
				else
					trimming = false;
			}
		}
		return path.substr(0, trimmedLength);
	}

	public static function isAbsolute(path:String):Bool {
		if (StringTools.startsWith(path, "/"))
			return true;
		if (path.charAt(1) == ":")
			return true;
		return StringTools.startsWith(path, "\\\\");
	}
}
