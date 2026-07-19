package;

import elixir.types.Term;
import phoenix.types.Assigns;

/**
 * Application-local strict-HXX contract for the upstream LiveReact component.
 *
 * The Mix dependency owns the real Elixir module. This extern exists only so
 * Haxe can validate the fixed prop shape used by this fixture; compiling it
 * must not emit an empty `LiveReact` module that shadows the dependency.
 */
@:native("LiveReact")
@:component
extern class LiveReactComponentContract {
	@:component
	public static function react(assigns:Assigns<StatusCardLiveReactAssigns>):Term;
}

typedef StatusCardLiveReactAssigns = {
	var id:String;
	var name:String;
	var title:String;
	var ssr:Bool;
}
