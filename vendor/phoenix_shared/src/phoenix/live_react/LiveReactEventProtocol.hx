package phoenix.live_react;

#if macro
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import phoenix.live_react.macros.LiveReactEventProtocolTypeScript;
import phoenix.live_view.macros.LiveEventProtocolModel;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventProtocolData;
import sys.FileSystem;
import sys.io.File;

using StringTools;
#end

/**
 * Compile-time stock LiveReact projection for a PhoenixHx Live Event Protocol.
 *
 * WHAT
 * - Renders or explicitly exports a TypeScript contract from an existing
 *   `@:liveEventProtocol` enum.
 *
 * WHY
 * - A trusted React boundary should share event names, semantic payload fields,
 *   wire keys, and drift identity with the Haxe browser/server protocol instead
 *   of maintaining a second event definition.
 *
 * HOW
 * - `renderTypeScript(ProfileEvent)` returns deterministic generated source.
 * - `--macro ...exportTypeScript("pkg.ProfileEvent", "path.generated.ts")`
 *   writes a signature-owned file explicitly.
 * - `--macro ...checkTypeScript(...)` verifies drift without writing.
 *
 * Only closed built-in hook payloads are projected automatically. Raw payloads,
 * non-hook origins, and custom codecs fail with an actionable diagnostic and
 * require an application-owned TypeScript adapter.
 */
@:compileTimeOnly
class LiveReactEventProtocol {
	/** Returns deterministic TypeScript source for a protocol enum reference. */
	public static macro function renderTypeScript(protocolRef:Expr):ExprOf<String> {
		var protocol = LiveEventProtocolModel.fromTypeRef(protocolRef);
		return macro $v{LiveReactEventProtocolTypeScript.render(protocol)};
	}

	#if macro
	/**
	 * Explicit command-line exporter for a signature-owned generated `.ts` file.
	 *
	 * Example:
	 * `--macro phoenix.live_react.LiveReactEventProtocol.exportTypeScript("shared.PreferenceEvent", "assets/react-components/preference-events.generated.ts")`
	 */
	public static function exportTypeScript(protocolType:String, outputPath:String):Void {
		var path = validateOutputPath(outputPath);
		var content = renderTypePath(protocolType);
		if (FileSystem.exists(path)) {
			if (FileSystem.isDirectory(path)) {
				Context.fatalError('LiveReact event contract output is a directory: $path', Context.currentPos());
			}
			var existing = File.getContent(path);
			if (!existing.startsWith('/* ${LiveReactEventProtocolTypeScript.GENERATED_SIGNATURE} */')) {
				Context.fatalError('Refusing to overwrite unowned LiveReact event contract $path. Move the hand-owned file or choose a *.generated.ts path.',
					Context.currentPos());
			}
			if (existing == content) {
				return;
			}
		}

		ensureDirectory(Path.directory(path));
		File.saveContent(path, content);
	}

	/** Verifies a generated contract without writing. */
	public static function checkTypeScript(protocolType:String, outputPath:String):Void {
		var path = validateOutputPath(outputPath);
		var expected = renderTypePath(protocolType);
		if (!FileSystem.exists(path) || FileSystem.isDirectory(path)) {
			Context.fatalError('LiveReact event contract is missing: $path. Run exportTypeScript first.', Context.currentPos());
		}
		var actual = File.getContent(path);
		if (actual != expected) {
			Context.fatalError('LiveReact event contract drift detected at $path. Regenerate it from the Haxe Live Event Protocol before building Vite.',
				Context.currentPos());
		}
	}

	static function renderTypePath(protocolType:String):String {
		var resolved = try {
			Context.getType(protocolType);
		} catch (error:Any) {
			Context.fatalError('Unable to resolve Live Event Protocol type "$protocolType": ${Std.string(error)}', Context.currentPos());
			null;
		};
		var protocol:LiveEventProtocolData = LiveEventProtocolModel.fromType(resolved, Context.currentPos());
		return LiveReactEventProtocolTypeScript.render(protocol);
	}

	static function validateOutputPath(outputPath:String):String {
		if (outputPath == null || outputPath.trim() == "") {
			Context.fatalError("LiveReact event contract output path must be a non-empty project-relative *.generated.ts path.", Context.currentPos());
		}
		var normalized = Path.normalize(outputPath);
		if (Path.isAbsolute(normalized) || normalized == ".." || normalized.startsWith("../") || normalized.indexOf("/../") >= 0) {
			Context.fatalError('LiveReact event contract output must stay inside the project: $outputPath', Context.currentPos());
		}
		if (!normalized.endsWith(".generated.ts")) {
			Context.fatalError('LiveReact event contract output must end with .generated.ts: $outputPath', Context.currentPos());
		}
		return normalized;
	}

	static function ensureDirectory(path:String):Void {
		if (path == null || path == "" || path == "." || FileSystem.exists(path)) {
			return;
		}
		ensureDirectory(Path.directory(path));
		FileSystem.createDirectory(path);
	}
	#end
}
