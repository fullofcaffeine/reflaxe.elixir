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

		queueSourceMapCandidates();

		if (outputDir == null || outputDir.length == 0)
			throw "Generated Elixir output requires a destination directory.";
		var elixirCompiler:ElixirCompiler = cast compiler;
		var publicationStarted = elixirCompiler.phaseTimings.start();
		GeneratedOutputOwnership.publish(compiler, outputDir, candidates, cachedRebuild(), GeneratedOutputFormatter.requiresCompletePreparedOutput());
		elixirCompiler.phaseTimings.finish("output_transaction_including_formatting", publicationStarted);
		// `ElixirCompiler.onOutputComplete` prints the report after the
		// directory pruning and the warm-cache commits.
	}

	/**
	 * Adds rendered `.ex.map` sidecars to the same candidate set as generated
	 * Elixir, so ownership, stale-file deletion, and rollback cover both files.
	 *
	 * Older source-map emission happened after the output transaction. Renaming a
	 * module could therefore remove `old_module.ex` while silently retaining
	 * `old_module.ex.map`. The last writer for a shared module path is retained to
	 * preserve the previous file-per-module behavior until multi-type source-map
	 * composition has its own focused design.
	 */
	function queueSourceMapCandidates():Void {
		var elixirCompiler:ElixirCompiler = cast compiler;
		if (!elixirCompiler.sourceMapOutputEnabled) {
			elixirCompiler.pendingSourceMapWriters = [];
			return;
		}

		var paths:Array<String> = [];
		var contents = new Map<String, String>();
		for (writer in elixirCompiler.pendingSourceMapWriters) {
			if (writer == null)
				continue;
			var path = writer.sourceMapPath();
			if (!contents.exists(path))
				paths.push(path);
			contents.set(path, writer.renderSourceMap());
		}
		elixirCompiler.pendingSourceMapWriters = [];

		// A source map belongs to the types that wrote the file that it maps.
		var ownersByPath = new Map<String, Array<String>>();
		for (candidate in candidates)
			ownersByPath.set(candidate.path, candidate.owners);
		for (path in paths) {
			var content = contents.get(path);
			var mapped = ownersByPath.get(path.substr(0, path.length - ".map".length));
			if (content != null)
				queue(path, content, mapped != null ? mapped : []);
		}
	}

	/** Queues one candidate; live output is never changed from this method. */
	public override function saveFile(path:String, content:StringOrBytes):Void {
		queue(path, content, []);
	}

	/**
	 * Queues one candidate with the types that wrote it (`ReflectCompiler.typeKey`).
	 * An empty `owners` list means "not known"; such a file is never treated as
	 * dropped. See `GeneratedOutputCandidate.owners`.
	 */
	function queue(path:String, content:StringOrBytes, owners:Array<String>):Void {
		candidates.push({path: path, content: content, owners: owners});
	}

	/** Adds the type key of `baseType` to `owners`, once. */
	static function addOwner(owners:Array<String>, baseType:haxe.macro.Type.BaseType):Void {
		var key = ReflectCompiler.typeKey(baseType);
		if (!owners.contains(key))
			owners.push(key);
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
		var owners = new Map<String, Array<String>>();
		for (output in compiler.generateOutputIterator()) {
			var moduleId = output.baseType.moduleId();
			var filename = overrideFilename(moduleId, output.overrideFileName, output.overrideDirectory);
			if (!files.exists(filename)) {
				files.set(filename, []);
				owners.set(filename, []);
			}
			var values = files.get(filename);
			if (values != null)
				values.push(output.data);
			var fileOwners = owners.get(filename);
			if (fileOwners != null)
				addOwner(fileOwners, output.baseType);
		}

		for (filename => values in files) {
			var fileOwners = owners.get(filename);
			queue(filename + compiler.options.fileOutputExtension, joinStringOrBytes(values), fileOwners != null ? fileOwners : []);
		}
	}

	function generateClassCandidates():Void {
		for (output in compiler.generateOutputIterator()) {
			var filename = overrideFilename(output.baseType.globalName(), output.overrideFileName, output.overrideDirectory);
			var fileOwners:Array<String> = [];
			addOwner(fileOwners, output.baseType);
			queue(filename + compiler.options.fileOutputExtension, output.data, fileOwners);
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
