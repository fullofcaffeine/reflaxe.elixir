package reflaxe.elixir;

#if (macro || reflaxe_runtime)
import haxe.io.Bytes;
import haxe.macro.Context;
import haxe.macro.Type;
import sys.FileSystem;
import sys.io.File;

/**
 * What one source file looked like when a server request started: its file
 * time in milliseconds and its complete bytes.
 */
private typedef SourceSnapshot = {
	final modifiedMs:Float;
	final bytes:Bytes;
}

/**
 * Makes a Haxe compilation server read a source file again when the file
 * changed but its file time, in whole seconds, did not.
 *
 * WHY
 * - A compilation server (`haxe --wait`) keeps parsed files and typed modules
 *   in memory. Before it uses one again, it compares the file time with the
 *   time that it stored. Haxe 4.3 reads that time in whole seconds.
 * - So a file that is saved two times within one second looks unchanged after
 *   the second save. The same happens when a tool writes a file and then
 *   restores its file time. The server keeps the old class or enum, Reflaxe
 *   has nothing new to generate, and the build reports success with old
 *   output. A fresh direct build would use the new text.
 * - Haxe makes this decision when it loads a module, which is after the
 *   initialization macros run. An initialization macro can therefore still
 *   tell Haxe to forget a file.
 *
 * WHAT
 * - For each `.hx` file that defines a type of the target build, this class
 *   keeps a snapshot between server requests.
 * - When the next request starts, each of these files is read again. A file
 *   whose snapshot differs is handed to Haxe's
 *   `CompilationServer.invalidateFiles`. Haxe then parses and types it again
 *   in the same request, together with the modules that depend on it.
 * - The snapshot holds the bytes, not a hash of them. Haxe compares bytes with
 *   native code, so the comparison is exact and costs less than the read. The
 *   cost is memory: the server keeps one copy of these source files.
 *
 * HOW
 * - `start` runs from `CompilerInit.Start`, before the compiler asks Haxe for
 *   any type.
 * - A snapshot is taken before Haxe can read the file in that request, so a
 *   change after that moment differs from the snapshot. A snapshot taken after
 *   Haxe read the file could describe a newer text than the one Haxe holds.
 * - A file that this class sees for the first time was already read by Haxe.
 *   Its snapshot is trusted only when the file was last changed well before
 *   the request started. Otherwise the file is marked with `UNPROVEN` and the
 *   next request reads it again once.
 *
 * LIMITS
 * - Only the files of target types are known here. A file that only macro
 *   code imports, an `import.hx` file, and a file that a macro registers with
 *   `Context.registerModuleDependency` are not covered. For these, a tool that
 *   can write the same file two times within one second must start a new
 *   server.
 * - Haxe resets everything that a macro remembers when a request has other
 *   defines than the request before it, but it keeps the typed modules of
 *   both sets of defines. The first request after such a change has no
 *   snapshots and compares nothing. One server that takes turns between two
 *   HXML files with different defines is not covered across each change.
 * - A module that Haxe loads before this macro runs is not covered: the few
 *   base modules such as `StdTypes`, and any module that an earlier
 *   initialization macro of the project asks for, for example
 *   `--macro haxe.macro.Context.getType("A")` in front of `-lib reflaxe.elixir`.
 *   Haxe has then already decided to reuse the module in this request.
 * - A request can stop before Haxe finished typing, for example on a syntax
 *   error. A file that Haxe parsed for the first time in such a request is not
 *   known here until a later request reaches the end of typing. This case
 *   follows from how Haxe keeps parsed files; it was not reproduced. A request
 *   with an ordinary type error does reach the end of typing.
 * - The first-time rule compares file times with the clock of this machine. A
 *   file system that stamps files from another clock is outside this rule.
 * - A fresh compiler process has no snapshots, so a direct build compiles as
 *   before. It only records snapshots that nothing reads.
 */
class ServerSourceFreshness {
	/**
	 * A first-time file is trusted when its last change is at least this many
	 * seconds older than the request. Two seconds is the coarsest file time of
	 * a common file system (FAT), so a write during the request cannot hide
	 * behind rounding.
	 */
	static inline var FILE_TIME_MARGIN_SECONDS = 2.0;

	/**
	 * Marks a file whose text may differ from the text that Haxe holds. No real
	 * file has a negative file time, so this value never equals a snapshot, and
	 * the next request tells Haxe to read the file again.
	 */
	static final UNPROVEN:SourceSnapshot = {modifiedMs: -1.0, bytes: Bytes.alloc(0)};

	// `@:persistent` keeps these values between requests on a compilation server.
	// A new compiler process starts with nothing remembered.
	@:persistent static var snapshots:Null<Map<String, SourceSnapshot>> = null;

	/**
	 * Start time, in seconds, of the oldest request whose files were not
	 * recorded, or null when the last request recorded its files. A request
	 * that stops before Haxe finished typing never reaches
	 * `recordTypedSources`, but Haxe may keep files that it parsed in that
	 * request. A first-time file must be older than that request to be trusted.
	 */
	@:persistent static var unrecordedSince:Null<Float> = null;

	/** A first-time file is trusted when its last change is before this time, in milliseconds. */
	static var trustedBeforeMs:Float = 0.0;

	/**
	 * Compares every known source file with its snapshot and tells Haxe to
	 * forget each file that differs. Must run before anything asks Haxe for a
	 * type, because Haxe decides about a cached module when it loads it.
	 */
	public static function start():Void {
		#if macro
		// An editor (display) request does not generate output.
		if (Context.defined("display"))
			return;

		final earliestUnrecorded = unrecordedSince;
		final trustedBeforeSeconds = earliestUnrecorded != null ? earliestUnrecorded : Sys.time();
		unrecordedSince = trustedBeforeSeconds;
		trustedBeforeMs = (trustedBeforeSeconds - FILE_TIME_MARGIN_SECONDS) * 1000.0;

		final known = snapshots;
		if (known != null) {
			final changed:Array<String> = [];
			for (path in [for (knownPath in known.keys()) knownPath]) {
				final previous = known.get(path);
				final current = snapshotOf(path);
				if (current == null) {
					// Deleted or unreadable. Haxe reports a missing file by itself.
					known.remove(path);
					changed.push(path);
					continue;
				}
				if (previous == null || !sameSnapshot(previous, current))
					changed.push(path);
				known.set(path, current);
			}
			if (changed.length > 0)
				haxe.macro.CompilationServer.invalidateFiles(changed);
		}

		Context.onAfterTyping(recordTypedSources);
		#end
	}

	/**
	 * Records the source file of each type that Haxe gives to the target and
	 * that has no snapshot yet. Haxe calls this after typing, and again when a
	 * macro adds types later in the same request.
	 */
	static function recordTypedSources(types:Array<ModuleType>):Void {
		var known = snapshots;
		if (known == null)
			snapshots = known = new Map();

		final seenFiles = new Map<String, Bool>();
		for (type in types) {
			final position = switch (type) {
				case TClassDecl(_.get() => classType): classType.pos;
				case TEnumDecl(_.get() => enumType): enumType.pos;
				case TTypeDecl(_.get() => defType): defType.pos;
				case TAbstract(_.get() => abstractType): abstractType.pos;
			}
			final file = Context.getPosInfos(position).file;
			if (file == null || file.length == 0 || seenFiles.exists(file))
				continue;
			seenFiles.set(file, true);

			// A type that a macro defines can name a file that does not exist.
			final path = try FileSystem.fullPath(file) catch (_:haxe.Exception) null;
			if (path == null || known.exists(path))
				continue;
			final first = firstSnapshotOf(path);
			if (first != null)
				known.set(path, first);
		}
		unrecordedSince = null;
	}

	/**
	 * Returns the snapshot for a file that Haxe already read in this request,
	 * or null when the file cannot be read.
	 *
	 * Nothing here saw the file before Haxe did. The file time is the only
	 * evidence: when the last change is older than the request, the text on
	 * disk is the text that Haxe read. The change time (`ctime`) counts too,
	 * because a tool can set the modification time but not the change time.
	 */
	static function firstSnapshotOf(path:String):Null<SourceSnapshot> {
		final stat = try FileSystem.stat(path) catch (_:haxe.Exception) null;
		if (stat == null)
			return null;
		if (Math.max(stat.mtime.getTime(), stat.ctime.getTime()) >= trustedBeforeMs)
			return UNPROVEN;
		final snapshot = snapshotOf(path);
		return snapshot != null ? snapshot : UNPROVEN;
	}

	/** Reads one file and returns its snapshot, or null when it cannot be read. */
	static function snapshotOf(path:String):Null<SourceSnapshot> {
		return try {
			final modifiedMs = FileSystem.stat(path).mtime.getTime();
			{modifiedMs: modifiedMs, bytes: File.getBytes(path)};
		} catch (_:haxe.Exception)
			null;
	}

	/**
	 * The bytes find a new text. The file time also finds a text that changed
	 * and changed back while a request was running, when Haxe may have read the
	 * text in between.
	 */
	static function sameSnapshot(previous:SourceSnapshot, current:SourceSnapshot):Bool {
		return previous.modifiedMs == current.modifiedMs && previous.bytes.compare(current.bytes) == 0;
	}
}
#end
