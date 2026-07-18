package phoenix_live_react_tooling;

import elixir.ElixirMap;
import elixir.ElixirString;
import elixir.ErlangFile;
import elixir.File;
import elixir.FileStat;
import elixir.Kernel;
import elixir.System;
import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.NativeException;
import elixir.types.Term;

/** Small reusable typed host primitives shared by lifecycle modules. */
@:keep
@:native("HaxePhoenixLiveReact.Host")
class LiveReactHost {
	static inline final OK:Atom = "ok";
	static inline final ERROR:Atom = "error";
	static inline final REGULAR:Atom = "regular";
	static inline final REASON:Atom = "reason";
	static inline final CD:Atom = "cd";
	static inline final STDERR_TO_STDOUT:Atom = "stderr_to_stdout";

	public static function requireRegularFile(path:String, label:String):Atom {
		var result = File.lstatResult(path);
		var resultTag = tag(result);
		if (resultTag == ERROR)
			return Kernel.raiseValue("expected " + label + " file at " + path + ": " + ErlangFile.formatError(Kernel.elem(result, 1)));
		var stat:FileStat = Kernel.elemAs(result, 1);
		return stat.type == REGULAR ? OK : Kernel.raiseValue("expected " + label + " file at " + path + ", found " + Kernel.toString(stat.type));
	}

	/** Resolve a directory through the OS so symlink escapes are visible. */
	public static function physicalDirectory(path:String):Term {
		try {
			var options:KeywordList<Term> = [{_0: CD, _1: path}, {_0: STDERR_TO_STDOUT, _1: true}];
			var command = System.cmdWithKeywordOptions("pwd", ["-P"], options);
			return command._1 == 0 ? {_0: OK, _1: ElixirString.trim(command._0)} : {_0: ERROR, _1: {_0: "physical_path", _1: ElixirString.trim(command._0)}};
		} catch (error:NativeException) {
			return {_0: ERROR, _1: ElixirMap.getTyped(error, REASON)};
		}
	}

	public static function formatPathError(reason:Term):String {
		if (Kernel.isTuple(reason) && Kernel.tupleSize(reason) == 2 && Kernel.elem(reason, 0) == "physical_path")
			return Kernel.elemAs(reason, 1);
		return ErlangFile.formatError(reason);
	}

	static function tag(value:Term):Atom {
		return Kernel.isTuple(value) ? Kernel.elemAs(value, 0) : value;
	}
}
