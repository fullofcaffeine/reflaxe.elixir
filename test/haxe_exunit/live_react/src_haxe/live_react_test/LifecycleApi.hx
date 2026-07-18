package live_react_test;

import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.Term;

/** Typed view of the public native map returned by the SDK lifecycle. */
typedef LifecycleResult = {
	final packageRoot:String;
	final clientMode:Atom;
	final npmReference:String;
	final dependency:Term;
	final changes:Array<Term>;
	final mode:Atom;
	final retainedPackageKeys:Array<String>;
	final retainedLiveReactDependency:Bool;
}

/** Typed view of a public component-registration result map. */
typedef ComponentResult = {
	final changes:Array<Term>;
	final createdFiles:Array<String>;
	final retainedFiles:Array<String>;
}

/** Public generated lifecycle module exercised by these integration tests. */
@:native("HaxePhoenixLiveReact")
extern class LifecycleApi {
	@:native("apply!")
	public static function applyBang(projectRoot:String, options:KeywordList<Term>):LifecycleResult;

	@:native("check!")
	public static function checkBang(projectRoot:String, options:KeywordList<Term>):LifecycleResult;

	@:native("remove!")
	public static function removeBang(projectRoot:String, options:KeywordList<Term>):LifecycleResult;

	@:native("add_component!")
	public static function addComponentBang(projectRoot:String, name:String, options:KeywordList<Term>):ComponentResult;

	@:native("remove_component!")
	public static function removeComponentBang(projectRoot:String, name:String, options:KeywordList<Term>):ComponentResult;
}

/** Public Mix task modules are host APIs, so tests consume them as externs. */
@:native("Mix.Tasks.Haxe.Phoenix.LiveReact")
extern class LiveReactTaskApi {
	public static function run(arguments:Array<String>):Term;
}

@:native("Mix.Tasks.Haxe.Gen.LiveReact")
extern class LiveReactComponentTaskApi {
	public static function run(arguments:Array<String>):Term;
}
