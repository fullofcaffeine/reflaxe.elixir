/**
 * Regression test for UndefinedLocalExtractFromParamsTransforms argument shadowing.
 *
 * WHAT
 * - When a function has an argument named `params`, UndefinedLocalExtractFromParamsTransforms
 *   may synthesize `var = Map.get(params, ...)` binds for any "used but undeclared" locals.
 *
 * WHY
 * - A bug treated function arguments (other than `params`) as undeclared, which could
 *   incorrectly shadow the arguments by extracting them from `params`.
 *
 * EXPECTED
 * - Only truly-missing locals should be extracted from `params`. Existing function args
 *   (e.g. `userId`) must never be synthesized from params.
 */
class Main {
    static function main() {
        // Provide a params map with both "id" and "user_id" keys to make shadowing visible in output.
        var params: Dynamic = untyped __elixir__('%{"id" => "1", "user_id" => "999"}');
        trace(demo(123, params));
    }

    static function demo(userId: Int, params: Dynamic): Dynamic {
        // Ensure `userId` is referenced in the body (it becomes `user_id` in Elixir).
        // The transform must NOT insert: user_id = Map.get(params, "user_id")
        var _ignore = userId;

        // Intentionally reference an undefined local `id` via raw Elixir so the transform has work to do.
        // It SHOULD insert: id = Map.get(params, "id") (with integer conversion).
        return untyped __elixir__('id');
    }
}
