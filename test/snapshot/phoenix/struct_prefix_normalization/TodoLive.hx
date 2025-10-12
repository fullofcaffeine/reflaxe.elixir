/**
 * Snapshot: Struct literal prefix normalization inside <App>Web.* modules
 *
 * Ensures zero-arity Module.new() becomes %<App>.Module{} when compiled from
 * within a Phoenix Web module. This derives <App> from the module name.
 */
@:native("TodoAppWeb.TodoLive")
class TodoLive {
    public static function build(): Dynamic {
        var todo = new Todo(); // Should render as %TodoApp.Todo{}
        return todo;
    }
}

/**
 * Minimal schema to make intent clear (not used by compiler logic directly).
 */
@:schema("todos")
class Todo {
    public function new() {}
}

