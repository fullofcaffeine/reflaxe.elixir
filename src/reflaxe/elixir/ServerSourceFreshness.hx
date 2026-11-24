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
 * - Haxe forgets everything that a macro remembers whenever it builds its
 *   macro interpreter again: when a request has other defines than the
 *   request before it, and after a failed build with an error in macro code,
 *   for example a type error in a macro file. Haxe keeps its typed modules in
 *   both cases. The next request has no snapshots and compares nothing, and
 *   every file is a first-time file again. A file that changed with the same
 *   file time more than two seconds before that request then stays old until
 *   it changes again. One server that takes turns between two HXML files with
 *   different defines is not covered across each change.
 * - Haxe can load a module before this macro runs: the few base modules such
 *   as `StdTypes`, and any module that an earlier initialization macro of the
 *   project asks for, for example `--macro haxe.macro.Context.getType("A")` in
 *   front of `-lib reflaxe.elixir`. Haxe has then already decided to reuse the
 *   module in this request. When such a module is a known file that changed,
 *   `refuseStaleReuse` stops the build, and the next build uses the new text.
 *   A first-time file has no snapshot, so this cannot be seen for it.
 * - Some requests record nothing: an editor (display) request, and a request
 *   that stops before Haxe finished typing, for example on a syntax error. A
 *   file that Haxe parsed for the first time in such a request, and that then
 *   changed with the same file time, is still old in the next build. That
 *   build marks it `UNPROVEN`, and the build after it uses the new text. The
 *   display case is in the server-cache test. The other case follows from how
 *   Haxe keeps parsed files; it was not reproduced. A request with an ordinary
 *   type error does reach the end of typing.
 * - The first-time rule compares file times with the clock of this machine. A
 *   file system that stamps files from another clock is outside this rule.
 * - Each request reads every known file, and the server keeps one copy of
 *   each. A file stays known when it leaves the build; it is dropped only
 *   when it is deleted or the server stops.
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
	 * recorded, or null when the last request recorded its files. An editor
	 * (display) request and a request that stops before Haxe finished typing
	 * never reach `recordTypedSources`, but Haxe keeps the files that it parsed
	 * in them. A first-time file must be older than that request to be trusted.
	 */
	@:persistent static var unrecordedSince:Null<Float> = null;

	/** A first-time file is trusted when its last change is before this time, in milliseconds. */
	static var trustedBeforeMs:Float = 0.0;

	/**
	 * The full paths of the known files whose bytes differ from their snapshot
	 * in this request. Not persistent, so each request starts with none.
	 * `refuseStaleReuse` reads it.
	 */
	static var changedThisRequest:Null<Map<String, Bool>> = null;

	/**
	 * Compares every known source file with its snapshot and tells Haxe to
	 * forget each file that differs. Must run before anything asks Haxe for a
	 * type, because Haxe decides about a cached module when it loads it.
	 */
	public static function start():Void {
		#if macro
		final earliestUnrecorded = unrecordedSince;
		final trustedBeforeSeconds = earliestUnrecorded != null ? earliestUnrecorded : Sys.time();
		unrecordedSince = trustedBeforeSeconds;

		// An editor (display) request generates no output and Haxe ends it
		// before typing is complete, so nothing is compared or recorded here.
		// It must still count as an unrecorded request above: Haxe uses the same
		// cache for display and build requests and keeps each file that the
		// display request parsed.
		if (Context.defined("display"))
			return;

		trustedBeforeMs = (trustedBeforeSeconds - FILE_TIME_MARGIN_SECONDS) * 1000.0;

		final known = snapshots;
		if (known != null) {
			final checkStarted = reflaxe.elixir.debug.CompilerPhaseTimings.startEarly();
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
				// `UNPROVEN` holds no bytes; a snapshot of it is read again below and
				// is not a known change. Its file time tells it apart, because a
				// new request makes a new `UNPROVEN` object.
				if (previous != null && previous.modifiedMs >= 0 && previous.bytes.compare(current.bytes) != 0) {
					if (changedThisRequest == null)
						changedThisRequest = new Map();
					changedThisRequest.set(path, true);
				}
				known.set(path, current);
			}
			if (changed.length > 0)
				haxe.macro.CompilationServer.invalidateFiles(changed);
			reflaxe.elixir.debug.CompilerPhaseTimings.finishEarly("source_freshness_check", checkStarted, Lambda.count(known));
		}

		reflaxe.elixir.debug.CompilerPhaseTimings.onAfterTyping("source_freshness_record", recordTypedSources);
		#end
	}

	/**
	 * Stops the build when Haxe used an old copy of a type whose source file
	 * changed with the same file time.
	 *
	 * WHY
	 * - `start` tells Haxe to forget a changed file, but Haxe may have loaded
	 *   the module before `start` ran: for example for a project line
	 *   `--macro haxe.macro.Context.getType("Status")` in front of
	 *   `-lib reflaxe.elixir`. Haxe then keeps the old type in this request,
	 *   and the build would write old Elixir and report success.
	 *
	 * HOW
	 * - A type of a file that changed in this request (`changedThisRequest`)
	 *   is old exactly when Haxe did not type it in this request:
	 *   `ReflectCompiler.wasTypedThisRequest` returns false. This is also true
	 *   for a type that an earlier request typed and did not publish, for
	 *   example an editor's diagnostics request: it holds the text of that
	 *   earlier request. Then this function reports an error that names each
	 *   such module once, and the build writes nothing.
	 * - Haxe has already been told to forget the file, so the next request
	 *   types the module again, and Reflaxe builds it again.
	 *
	 * An ordinary edit, with a new file time, is not stopped: Haxe sees it by
	 * itself and types the module again.
	 */
	public static function refuseStaleReuse(types:Array<ModuleType>):Void {
		#if macro
		final changed = changedThisRequest;
		if (changed == null)
			return;
		final staleNames:Array<String> = [];
		final reportedModules = new Map<String, Bool>();
		// Full path of each source file, or null when it is not a changed file.
		// One file system call per file, not per type.
		final changedPaths = new Map<String, Null<String>>();
		var firstPosition:Null<haxe.macro.Expr.Position> = null;
		for (type in types) {
			final baseType:BaseType = switch (type) {
				case TClassDecl(_.get() => classType): classType;
				case TEnumDecl(_.get() => enumType): enumType;
				case TTypeDecl(_.get() => defType): defType;
				case TAbstract(_.get() => abstractType): abstractType;
			}
			final file = Context.getPosInfos(baseType.pos).file;
			if (file == null || file.length == 0)
				continue;
			if (!changedPaths.exists(file)) {
				final path = changed.exists(file) ? file : try FileSystem.fullPath(file) catch (_:haxe.Exception) null;
				changedPaths.set(file, path != null && changed.exists(path) ? path : null);
			}
			if (changedPaths.get(file) == null || reflaxe.ReflectCompiler.wasTypedThisRequest(baseType))
				continue;
			// An abstract and its implementation class share one module: name it once.
			if (reportedModules.exists(baseType.module))
				continue;
			reportedModules.set(baseType.module, true);
			staleNames.push(baseType.module + " (" + file + ")");
			if (firstPosition == null)
				firstPosition = baseType.pos;
		}
		if (firstPosition == null)
			return;
		Context.error("reflaxe.elixir: the compilation server used an old copy of "
			+ staleNames.join(", ")
			+ ". The file changed with the same file time, and Haxe loaded the module before reflaxe.elixir started,"
			+ " for example for a --macro line in front of -lib reflaxe.elixir."
			+ " This build would write old Elixir, so it writes nothing. Haxe reads the file again in the next build: run the build again.",
			firstPosition);
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
			// The keys are full paths. Haxe names most library files by their
			// full path already, and those need no file system call here.
			if (known.exists(file))
				continue;

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
