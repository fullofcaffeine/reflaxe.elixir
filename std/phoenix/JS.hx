package phoenix;

#if (macro || reflaxe_runtime)

import elixir.types.Term;

/**
 * Minimal externs for Phoenix.LiveView.JS command builder.
 * Methods map 1:1 to JS command helpers; return type is JS for chaining.
 * Keep options as raw terms to avoid over-constraining API surface.
 */
@:native("Phoenix.LiveView.JS")
@:elixirStruct
extern class JS {
    public function new();

    @:native("add_class") public function addClass(classes:String, ?opts:Term): JS;
    @:native("remove_class") public function removeClass(classes:String, ?opts:Term): JS;
    @:native("toggle_class") public function toggleClass(classes:String, ?opts:Term): JS;
    @:native("show") public function show(?opts:Term): JS;
    @:native("hide") public function hide(?opts:Term): JS;
    @:native("dispatch") public function dispatch(event:String, ?opts:Term): JS;
    @:native("push") public function push(event:String, ?opts:Term): JS;
    @:native("set_attribute") public function setAttribute(name:String, value:String, ?opts:Term): JS;
    @:native("remove_attribute") public function removeAttribute(name:String, ?opts:Term): JS;
}

#end
