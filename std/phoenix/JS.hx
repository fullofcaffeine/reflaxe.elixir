package phoenix;

#if (macro || reflaxe_runtime)

/**
 * Minimal externs for Phoenix.LiveView.JS command builder.
 * Methods map 1:1 to JS command helpers; return type is JS for chaining.
 * Keep options Dynamic to avoid over-constraining API surface.
 */
@:native("Phoenix.LiveView.JS")
extern class JS {
    public function new();

    @:native("add_class") public function addClass(classes:String, ?opts:Dynamic): JS;
    @:native("remove_class") public function removeClass(classes:String, ?opts:Dynamic): JS;
    @:native("toggle_class") public function toggleClass(classes:String, ?opts:Dynamic): JS;
    @:native("show") public function show(?opts:Dynamic): JS;
    @:native("hide") public function hide(?opts:Dynamic): JS;
    @:native("dispatch") public function dispatch(event:String, ?opts:Dynamic): JS;
    @:native("push") public function push(event:String, ?opts:Dynamic): JS;
    @:native("set_attribute") public function setAttribute(name:String, value:String, ?opts:Dynamic): JS;
    @:native("remove_attribute") public function removeAttribute(name:String, ?opts:Dynamic): JS;
}

#end

