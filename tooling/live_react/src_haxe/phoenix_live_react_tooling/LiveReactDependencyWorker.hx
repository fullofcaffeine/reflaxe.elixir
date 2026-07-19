package phoenix_live_react_tooling;

import elixir.ElixirMap;
import elixir.ErlangTerm;
import elixir.File;
import elixir.Kernel;
import elixir.System;
import elixir.mix.Mix;
import elixir.mix.Project;
import elixir.mix.Task;
import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.Term;

/**
 * Resolves one LiveReact dependency in a fresh BEAM process.
 *
 * Mix freezes and caches parts of the active project's dependency graph while
 * loading `mix.exs`. Replacing that graph from an already-running Mix task can
 * feed parsed Hex constraints back into code that expects source declarations.
 * This worker starts with an empty Mix project stack, applies the temporary
 * dependency and lock paths through `Mix.Project.in_project/4`, and writes a
 * lossless BEAM-term result for the Haxe-authored parent resolver.
 */
@:keep
@:native("HaxePhoenixLiveReact.DependencyWorker")
class LiveReactDependencyWorker {
	static inline final HEX:Atom = "hex";
	static inline final DEPS:Atom = "deps";
	static inline final LOCKFILE:Atom = "lockfile";
	static inline final DEPS_PATH:Atom = "deps_path";
	static inline final LOCK_CONTENT:Atom = "lock_content";
	static inline final DEPENDENCY_PATH:Atom = "dependency_path";
	static inline final INPUT_ENV = "REFLAXE_LIVE_REACT_RESOLVER_INPUT";
	static inline final OUTPUT_ENV = "REFLAXE_LIVE_REACT_RESOLVER_OUTPUT";

	public static function run():Void {
		var inputPath = requiredEnvironment(INPUT_ENV);
		var outputPath = requiredEnvironment(OUTPUT_ENV);
		var input:Term = ErlangTerm.fromBinary(File.readBang(inputPath));
		var app:Atom = ElixirMap.fetchBangTerm(input, "app");
		var root:String = ElixirMap.fetchBangTerm(input, "root");
		var dependencies:Array<Term> = ElixirMap.fetchBangTerm(input, "dependencies");
		var lockfile:String = ElixirMap.fetchBangTerm(input, "lockfile");
		var depsPath:String = ElixirMap.fetchBangTerm(input, "depsPath");
		var dependencyPath:String = ElixirMap.fetchBangTerm(input, "dependencyPath");

		Mix.start();
		Mix.ensureApplicationBang(HEX);

		var config:KeywordList<Term> = [
			{_0: DEPS, _1: dependencies},
			{_0: LOCKFILE, _1: lockfile},
			{_0: DEPS_PATH, _1: depsPath}
		];

		Project.inProject(app, root, config, function(_projectModule:Term):Term {
			Task.reenable("deps.get");
			return Task.run("deps.get", ["live_react"]);
		});

		var result = ElixirMap.new_();
		result = ElixirMap.putTerm(result, LOCK_CONTENT, File.readBang(lockfile));
		result = ElixirMap.putTerm(result, DEPENDENCY_PATH, dependencyPath);
		File.writeBang(outputPath, ErlangTerm.toBinary(result));
	}

	static function requiredEnvironment(name:String):String {
		var value = System.getEnvVar(name);
		return value == null || value == "" ? Kernel.raiseValue("missing LiveReact resolver worker environment " + name) : value;
	}
}
