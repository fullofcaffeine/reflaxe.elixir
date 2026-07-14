package reflaxe.elixir;

#if (macro || reflaxe_runtime)
import haxe.io.BytesBuffer;
import reflaxe.BaseCompiler;
import reflaxe.ReflectCompiler;
import reflaxe.elixir.GeneratedOutputOwnership.GeneratedOutputCandidate;
import reflaxe.output.OutputManager;
import reflaxe.output.StringOrBytes;

using reflaxe.helpers.BaseTypeHelper;

/**
 * Reflaxe output manager that publishes Elixir files through one ownership
 * transaction instead of writing modules directly into the destination tree.
 *
 * The class deliberately keeps Reflaxe's file-per-module/class/single/manual
 * generation semantics. Its only behavioral change is publication: `saveFile`
 * records candidates in memory, and `GeneratedOutputOwnership` validates and
 * commits the complete set after generation has succeeded.
 */
class GeneratedOutputManager extends OutputManager {
	var candidates:Array<GeneratedOutputCandidate> = [];

	public function new(compiler:BaseCompiler) {
		super(compiler);
	}

	/** Collects the full target output and publishes it as one recoverable set. */
	public override function generateFiles():Void {
		candidates = [];

		switch (compiler.options.fileOutputType) {
			case Manual:
				compiler.generateFilesManually();

			case SingleFile:
				generateSingleFileCandidate();

			case FilePerModule:
				generateModuleCandidates();

			case FilePerClass:
				generateClassCandidates();
		}

		for (path => prioritizedContent in compiler.extraFiles) {
			var priorities:Array<Int> = [];
			for (priority => content in prioritizedContent) {
				if (content != null && StringTools.trim(content).length > 0)
					priorities.push(priority);
			}
			priorities.sort((left, right) -> left - right);

			var sections:Array<String> = [];
			for (priority in priorities) {
				var content = prioritizedContent.get(priority);
				if (content != null && StringTools.trim(content).length > 0)
					sections.push(content);
			}
			saveFile(path, sections.join("\n\n"));
		}

		if (outputDir == null || outputDir.length == 0)
			throw "Generated Elixir output requires a destination directory.";
		GeneratedOutputOwnership.publish(compiler, outputDir, candidates, cachedRebuild());
	}

	/** Queues one candidate; live output is never changed from this method. */
	public override function saveFile(path:String, content:StringOrBytes):Void {
		candidates.push({path: path, content: content});
	}

	function generateSingleFileCandidate():Void {
		var configured = outputDir;
		var filename = compiler.options.defaultOutputFilename;
		if (configured != null
			&& (compiler.options.fileOutputExtension.length == 0
				|| StringTools.endsWith(configured, compiler.options.fileOutputExtension))) {
			filename = haxe.io.Path.withoutDirectory(configured);
			// Reflaxe's public outputDir property is managed by its base output manager.
			// Single-file Elixir output is not a supported application profile, so reject
			// a direct file destination rather than publishing against the wrong root.
			throw 'Transactional Elixir output requires a directory; received single-file destination `$configured` for `$filename`.';
		}

		var values:Array<StringOrBytes> = [];
		for (output in compiler.generateOutputIterator())
			values.push(output.data);
		saveFile(filename, joinStringOrBytes(values));
	}

	function generateModuleCandidates():Void {
		var files:Map<String, Array<StringOrBytes>> = [];
		for (output in compiler.generateOutputIterator()) {
			var moduleId = output.baseType.moduleId();
			var filename = overrideFilename(moduleId, output.overrideFileName, output.overrideDirectory);
			if (!files.exists(filename))
				files.set(filename, []);
			var values = files.get(filename);
			if (values != null)
				values.push(output.data);
		}

		for (filename => values in files)
			saveFile(filename + compiler.options.fileOutputExtension, joinStringOrBytes(values));
	}

	function generateClassCandidates():Void {
		for (output in compiler.generateOutputIterator()) {
			var filename = overrideFilename(output.baseType.globalName(), output.overrideFileName, output.overrideDirectory);
			saveFile(filename + compiler.options.fileOutputExtension, output.data);
		}
	}

	static function overrideFilename(defaultName:String, overrideName:Null<String>, overrideDirectory:Null<String>):String {
		var directory = overrideDirectory != null && overrideDirectory.length > 0 ? overrideDirectory + "/" : "";
		return directory + (overrideName != null ? overrideName : defaultName);
	}

	static function joinStringOrBytes(values:Array<StringOrBytes>):StringOrBytes {
		var strings:Array<String> = [];
		var bytes = [];
		for (value in values) {
			switch (value.data()) {
				case String(content):
					strings.push(content);
				case Bytes(content):
					bytes.push(content);
			}
		}

		if (strings.length > 0 && bytes.length > 0)
			throw "Cannot combine string and byte output in one generated file.";
		if (strings.length > 0)
			return strings.join("\n\n");
		if (bytes.length > 0) {
			var buffer = new BytesBuffer();
			for (content in bytes)
				buffer.add(content);
			return buffer.getBytes();
		}
		return "";
	}

	static function cachedRebuild():Bool {
		#if !reflaxe.disallow_build_cache_check
		return ReflectCompiler.isCachedRebuild;
		#else
		return false;
		#end
	}
}
#end
