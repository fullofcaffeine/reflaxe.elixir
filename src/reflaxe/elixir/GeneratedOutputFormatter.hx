package reflaxe.elixir;

#if (macro || reflaxe_runtime)
import haxe.Json;
import haxe.io.Path;
import haxe.macro.Context;
import sys.FileSystem;
import sys.io.File;

using StringTools;

private typedef GeneratedFilesManifest = {
	var filesGenerated:Array<String>;
}

private typedef FormatterCommandResult = {
	var exitCode:Int;
	var error:Null<String>;
}

private enum GeneratedOutputFormatMode {
	Off;
	Write;
	Check;
}

/**
 * Runs the canonical Elixir formatter after Reflaxe has written all output.
 *
 * Reflaxe's `_GeneratedFiles.json` manifest is the ownership boundary: only
 * compiler-generated `.ex` and `.exs` files are passed to Mix. The formatter
 * is presentation-only and is disabled unless a build explicitly selects
 * `write` or `check` through `reflaxe_elixir_format`.
 */
class GeneratedOutputFormatter {
	public static inline var MODE_DEFINE = "reflaxe_elixir_format";
	public static inline var PROJECT_DEFINE = "reflaxe_elixir_format_project";

	static inline var GENERATED_FILES_MANIFEST = "_GeneratedFiles.json";
	static inline var MAX_COMMAND_LENGTH = 7000;

	public static function run(outputDirectory:Null<String>, sourceMapsEnabled:Bool):Void {
		var mode = resolveMode();
		if (mode == Off)
			return;

		#if sys
		if (mode == Write && sourceMapsEnabled) {
			fail('`-D $MODE_DEFINE=write` cannot be combined with generated source maps. '
				+ "Formatting changes generated line and column positions, which would make the maps stale. "
				+ 'Use `$MODE_DEFINE=check`, `$MODE_DEFINE=off`, or disable source maps for this build.');
		}

		if (outputDirectory == null || outputDirectory.trim().length == 0) {
			fail('`-D $MODE_DEFINE=${modeName(mode)}` requires a generated output directory.');
		}

		var initialCwd = FileSystem.fullPath(Sys.getCwd());
		var outputRoot = absolutePath(outputDirectory, initialCwd);
		if (!FileSystem.exists(outputRoot) || !FileSystem.isDirectory(outputRoot)) {
			fail('Generated output directory does not exist: $outputRoot');
		}

		var files = readGeneratedElixirFiles(outputRoot);
		if (files.length == 0) {
			Sys.println('[reflaxe.elixir] No generated Elixir files to format in $outputRoot.');
			return;
		}

		var projectRoot = resolveProjectRoot(outputRoot, initialCwd);
		var batches = commandBatches(files);
		Sys.println('[reflaxe.elixir] mix format (${modeName(mode)}): ${files.length} generated file' + (files.length == 1 ? "" : "s") + ' in $projectRoot');

		if (mode == Write) {
			// Parse and format every batch in memory before changing any generated file.
			// A syntax error therefore fails the build without leaving partial formatting behind.
			for (batch in batches) {
				runFormatterCommand(projectRoot, ["format", "--force", "--dry-run"].concat(batch), mode, "preflight", batch);
			}
			for (batch in batches) {
				runFormatterCommand(projectRoot, ["format", "--force"].concat(batch), mode, "write", batch);
			}
		} else {
			for (batch in batches) {
				runFormatterCommand(projectRoot, ["format", "--force", "--check-formatted"].concat(batch), mode, "check", batch);
			}
		}
		#else
		fail('`-D $MODE_DEFINE=${modeName(mode)}` requires a sys-capable Haxe macro environment.');
		#end
	}

	static function resolveMode():GeneratedOutputFormatMode {
		var raw = Context.definedValue(MODE_DEFINE);
		if (raw == null || raw.trim().length == 0)
			return Off;

		return switch (raw.trim().toLowerCase()) {
			case "off": Off;
			case "write": Write;
			case "check": Check;
			case invalid:
				fail('Invalid `$MODE_DEFINE` value `$invalid`. Expected one of: off, write, check.');
				Off;
		}
	}

	static function modeName(mode:GeneratedOutputFormatMode):String {
		return switch (mode) {
			case Off: "off";
			case Write: "write";
			case Check: "check";
		}
	}

	#if sys
	static function readGeneratedElixirFiles(outputRoot:String):Array<String> {
		var manifestPath = Path.join([outputRoot, GENERATED_FILES_MANIFEST]);
		if (!FileSystem.exists(manifestPath) || FileSystem.isDirectory(manifestPath)) {
			fail('Cannot format generated output because Reflaxe ownership metadata is missing: $manifestPath\n'
				+ "The formatter will not scan the output tree because that could modify handwritten files.");
		}

		var manifest:GeneratedFilesManifest = try {
			cast Json.parse(File.getContent(manifestPath));
		} catch (error:Dynamic) {
			fail('Cannot parse Reflaxe ownership metadata at $manifestPath: ${Std.string(error)}');
			{filesGenerated: []};
		}

		if (manifest == null || manifest.filesGenerated == null) {
			fail('Reflaxe ownership metadata does not contain `filesGenerated`: $manifestPath');
		}

		var seen:Map<String, Bool> = [];
		var files:Array<String> = [];
		for (generatedPath in manifest.filesGenerated) {
			if (generatedPath == null || generatedPath.length == 0)
				continue;

			var extension = Path.extension(generatedPath).toLowerCase();
			if (extension != "ex" && extension != "exs")
				continue;

			var filePath = absolutePath(generatedPath, outputRoot);
			if (!FileSystem.exists(filePath) || FileSystem.isDirectory(filePath)) {
				fail('Reflaxe ownership metadata references a missing generated file: $filePath');
			}
			if (!seen.exists(filePath)) {
				seen.set(filePath, true);
				files.push(filePath);
			}
		}

		files.sort(Reflect.compare);
		return files;
	}

	static function resolveProjectRoot(outputRoot:String, initialCwd:String):String {
		var explicit = Context.definedValue(PROJECT_DEFINE);
		if (explicit != null && explicit.trim().length > 0) {
			var projectRoot = absolutePath(explicit.trim(), initialCwd);
			if (!FileSystem.exists(projectRoot) || !FileSystem.isDirectory(projectRoot)) {
				fail('`-D $PROJECT_DEFINE=${explicit.trim()}` does not resolve to a directory: $projectRoot');
			}
			return projectRoot;
		}

		var discovered = findProjectRoot(outputRoot);
		if (discovered == null)
			discovered = findProjectRoot(initialCwd);
		if (discovered != null)
			return discovered;

		fail('Could not discover an Elixir formatter project from output `$outputRoot` or working directory `$initialCwd`.\n'
			+ "Expected an ancestor containing `mix.exs` or `.formatter.exs`. "
			+ 'Set `-D $PROJECT_DEFINE=/path/to/project` when output is outside the Mix project.');
		return initialCwd;
	}

	static function findProjectRoot(start:String):Null<String> {
		var current = FileSystem.fullPath(start);
		while (current != null && current.length > 0) {
			if (FileSystem.exists(Path.join([current, "mix.exs"])) || FileSystem.exists(Path.join([current, ".formatter.exs"]))) {
				return current;
			}

			var parent = Path.directory(current);
			if (parent == null || parent.length == 0 || parent == current)
				break;
			current = parent;
		}
		return null;
	}

	static function commandBatches(files:Array<String>):Array<Array<String>> {
		var batches:Array<Array<String>> = [];
		var current:Array<String> = [];
		var currentLength = "mix format --force --check-formatted ".length;

		for (file in files) {
			var addedLength = file.length + 3;
			if (current.length > 0 && currentLength + addedLength > MAX_COMMAND_LENGTH) {
				batches.push(current);
				current = [];
				currentLength = "mix format --force --check-formatted ".length;
			}
			current.push(file);
			currentLength += addedLength;
		}
		if (current.length > 0)
			batches.push(current);
		return batches;
	}

	static function runFormatterCommand(projectRoot:String, args:Array<String>, mode:GeneratedOutputFormatMode, phase:String, files:Array<String>):Void {
		var result = execute(projectRoot, args);
		if (result.error == null && result.exitCode == 0)
			return;

		var command = (["mix"].concat(args)).map(displayArgument).join(" ");
		var detail = result.error != null ? 'Could not execute Mix: ${result.error}' : 'Mix exited with status ${result.exitCode}.';
		var guidance = mode == Check ? 'The generated files are not canonical. Run a build with `-D $MODE_DEFINE=write`, review the formatter-only diff, then rerun check mode.' : "Mix could not parse or format the generated output. Fix the compiler output or project formatter configuration; formatting is not a semantic repair step.";
		fail('Canonical Elixir formatting failed during $phase mode.\n'
			+ 'Working directory: $projectRoot\n'
			+ 'Command: $command\n'
			+ '$detail\n'
			+ "Generated files in this batch:\n  "
			+ files.join("\n  ")
			+ "\n"
			+ guidance
			+ "\n"
			+ "Ensure `mix` is available on PATH and project formatter dependencies have been fetched.");
	}

	static function execute(projectRoot:String, args:Array<String>):FormatterCommandResult {
		var originalCwd = Sys.getCwd();
		var exitCode = -1;
		var commandError:Null<String> = null;
		try {
			Sys.setCwd(projectRoot);
			exitCode = Sys.command("mix", args);
		} catch (error:Dynamic) {
			commandError = Std.string(error);
		}

		try {
			Sys.setCwd(originalCwd);
		} catch (restoreError:Dynamic) {
			if (commandError == null)
				commandError = 'Mix command completed, but the compiler could not restore `$originalCwd`: ${Std.string(restoreError)}';
		}

		return {exitCode: exitCode, error: commandError};
	}

	static function displayArgument(value:String):String {
		return ~/^[A-Za-z0-9_\.\/:=-]+$/.match(value) ? value : Json.stringify(value);
	}

	static function absolutePath(path:String, baseDirectory:String):String {
		var candidate = Path.isAbsolute(path) ? path : Path.join([baseDirectory, path]);
		return FileSystem.fullPath(Path.normalize(candidate));
	}
	#end

	static function fail(message:String):Void {
		Context.error('[reflaxe.elixir] $message', Context.currentPos());
	}
}
#end
