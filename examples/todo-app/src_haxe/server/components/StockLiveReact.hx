package server.components;

import elixir.types.Term;
import phoenix.types.Assigns;

/**
 * Props that the todo application's one React island sends to stock LiveReact.
 *
 * LiveReact itself accepts additional application-defined props, but strict HXX
 * validation needs a concrete shape at each application boundary. Keeping this
 * list local means a misspelled or wrongly typed prop fails during the Haxe
 * build without pretending that these are the only props LiveReact supports.
 */
typedef TodoInsightsLiveReactAssigns = {
	var id:String;
	var name:String;
	var title:String;
	var total:Int;
	var completed:Int;
	var pending:Int;
	var visible:Int;
	var filter:String;
	var ssr:Bool;
}

/**
 * App-local strict-HXX declaration of the stock `LiveReact.react/1` component.
 *
 * Strict component discovery intentionally trusts application declarations,
 * not compiler standard-library roots. This `extern` declaration tells Haxe
 * that the module is supplied by the upstream Mix dependency; it does not emit
 * or replace an Elixir `LiveReact` module in the generated application.
 */
@:native("LiveReact")
@:component
extern class StockLiveReact {
	/** Render this application's closed Todo insights prop shape. */
	@:component
	public static function react(assigns:Assigns<TodoInsightsLiveReactAssigns>):Term;
}
