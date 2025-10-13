/**
 * Success-case alignment sanity snapshot
 *
 * WHAT
 * - Ensures case clauses generated for idiomatic Result Ok branch keep binder usage consistent
 *   and do not introduce temp or mismatched names. This is a focused sanity snapshot to
 *   accompany the absolute success-binder alignment passes.
 *
 * WHY
 * - Regressions previously caused binder/body mismatches in {:ok, v} branches. While the
 *   absolute passes correct late issues, this snapshot ensures success branches remain clean.
 */

@:elixirIdiomatic
enum ApiResult<T,E> {
    Ok(value: T);
    Error(reason: E);
}

typedef Todo = { var id:Int; var text:String; }

class Main {
    static function broadcast(todo: Todo): Void {}

    static function process(res: ApiResult<Todo, String>): String {
        return switch (res) {
            case Ok(updatedTodo):
                // Body should reference the same binder (snake-case in Elixir)
                broadcast(updatedTodo);
                "ok";
            case Error(reason):
                reason;
        };
    }

    static function main() {
        var todo: Todo = { id: 1, text: "x" };
        var r: ApiResult<Todo, String> = Ok(todo);
        process(r);
    }
}

