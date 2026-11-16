package reflaxe.elixir;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Type.ClassType;
import reflaxe.ReflectCompiler;

/**
 * Keeps one result for each class between Haxe compilation-server requests,
 * and computes it again only for a class that Haxe typed again.
 *
 * WHAT
 * - A whole-program scan, such as `PrivateMethodExports.collect`, reads the
 *   typed body of every class in every request. On a warm request after a
 *   one-class edit, Haxe typed only that class and the classes that depend on
 *   it. This cache gives the scan the result of each other class from the last
 *   request, so the scan reads only the classes that Haxe typed again.
 *
 * WHY
 * - Measured on the todo-app under a server, each of the two scans that use
 *   this cache took 0.2 to 0.3 s of every warm request, also when no file
 *   changed. The time grows with the size of the program, not of the edit.
 *
 * WHEN A KEPT RESULT IS CORRECT
 * - The result may depend only on the typed body of the class and on
 *   declarations that its module depends on. Haxe types a module again when its
 *   source file, or a module that it depends on (also through an inlined call),
 *   changed. `ReflectCompiler.wasTypedThisRequest` reports these classes.
 * - Results come only from the last request, and only when that request
 *   published its output (`commit`). If a request fails, the next request
 *   computes every class again. Haxe also types the modules of a failed request
 *   again, so this costs one slow request and no correctness.
 * - The cache lives in a `@:persistent` static of its owner. Haxe starts a new
 *   macro context, with empty statics, when the defines change. A result thus
 *   never crosses from one define set to another. Haxe keeps the statics when
 *   only the working directory or the class paths change, for example for a
 *   second project on the same server; the cache then drops its results.
 * - The key holds the source module, the Haxe path, and the source file. A class
 *   that a request does not see is dropped at `commit`.
 *
 * EXAMPLE
 * - A person edits a string in `AuditLogLive`. Haxe types `AuditLogLive` and
 *   `TodoAppRouter` again. The scan reads these two classes and takes the kept
 *   results of the other 140 classes.
 *
 * `-D reflaxe_elixir_no_kept_class_results` computes every class in every
 * request, as before this cache existed.
 */
class ClassResultCache<T> {
	var kept:Map<String, T> = new Map();
	var next:Map<String, T> = new Map();
	var requestOpen = false;
	var identity = "";

	public function new() {}

	/**
	 * Starts a request. When the previous request did not reach `commit`, its
	 * kept results are dropped, so that each class is computed again.
	 */
	public function begin():Void {
		var current = requestIdentity();
		if (requestOpen || current != identity)
			kept = new Map();
		identity = current;
		next = new Map();
		requestOpen = true;
	}

	/**
	 * Returns the result for `classType`: the kept result when Haxe did not type
	 * the class again in this request, otherwise `compute(classType)`.
	 */
	public function resultFor(classType:ClassType, compute:ClassType->T):T {
		var known = reuse(classType);
		if (known != null)
			return known;
		var result = compute(classType);
		record(classType, result);
		return result;
	}

	/**
	 * Returns the kept result for `classType` and keeps it for the next request,
	 * or returns null when Haxe typed the class again or nothing was kept.
	 */
	public function reuse(classType:ClassType):Null<T> {
		var key = keyFor(classType);
		var known = kept.get(key);
		if (known == null || mustCompute(classType))
			return null;
		next.set(key, known);
		return known;
	}

	/** Stores a result that this request computed or observed for `classType`. */
	public function record(classType:ClassType, result:T):Void {
		next.set(keyFor(classType), result);
	}

	/** Makes the results of this request the kept results for the next one. */
	public function commit():Void {
		if (!requestOpen)
			return;
		kept = next;
		next = new Map();
		requestOpen = false;
	}

	/** The project of this request: the working directory and the class paths. */
	static function requestIdentity():String {
		return Sys.getCwd() + "\u0000" + Context.getClassPath().join("\u0000");
	}

	static function mustCompute(classType:ClassType):Bool {
		#if reflaxe_elixir_no_kept_class_results
		return true;
		#else
		return ReflectCompiler.wasTypedThisRequest(classType);
		#end
	}

	static function keyFor(classType:ClassType):String {
		var realPath = classType.meta.extract(":realPath");
		var path = classType.pack.concat([classType.name]).join(".");
		if (realPath.length > 0 && realPath[0].params != null && realPath[0].params.length > 0) {
			switch (realPath[0].params[0].expr) {
				case EConst(CString(value, _)):
					path = value;
				case _:
			}
		}
		return classType.module + "\u0000" + path + "\u0000" + Context.getPosInfos(classType.pos).file;
	}
}
#end
