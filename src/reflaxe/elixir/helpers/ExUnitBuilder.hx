package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ExUnitBuilder
 *
 * WHAT
 * - Macro invoked via `@:autoBuild` on `exunit.TestCase` to keep ExUnit-related functions alive
 *   through Haxe's DCE so later Elixir AST passes can transform them into idiomatic ExUnit code.
 *
 * WHY
 * - The ExUnit translation happens in the AST pipeline, but Haxe can DCE unused functions before
 *   we reach that phase. Without a macro-time `@:keep`, annotated test/setup functions may be
 *   removed and never make it into the Elixir AST transformer.
 *
 * HOW
 * - Walk local class build fields and add `@:keep` to any function annotated with ExUnit-related
 *   metadata such as `@:test`, `@:setup`, etc.
 * - Return the fields unchanged otherwise; structural ExUnit codegen remains in the AST passes.
 *
 * EXAMPLES
 * Haxe:
 *   @:exunit class MyTest extends TestCase {
 *     @:test function works() { ... }
 *   }
 *
 * Result (macro-time):
 * - `works()` is marked `@:keep` so it survives to the AST-based ExUnit transformer.
 */
class ExUnitBuilder {
    public static function build(): Array<Field> {
        var fields = Context.getBuildFields();

        for (field in fields) {
            switch (field.kind) {
                case FFun(_):
                    var metas = field.meta != null ? field.meta : [];
                    var hasMeta = function(name: String): Bool {
                        for (meta in metas) {
                            if (meta.name == name) {
                                return true;
                            }
                        }
                        return false;
                    };

                    var isTestish =
                        hasMeta("test") || hasMeta(":test")
                        || hasMeta("setup") || hasMeta(":setup")
                        || hasMeta("setupAll") || hasMeta(":setupAll")
                        || hasMeta("teardown") || hasMeta(":teardown")
                        || hasMeta("teardownAll") || hasMeta(":teardownAll");

                    if (!isTestish) {
                        continue;
                    }

                    if (field.meta == null) {
                        field.meta = [];
                    }

                    var hasKeep = false;
                    for (meta in field.meta) {
                        if (meta.name == ":keep" || meta.name == "keep") {
                            hasKeep = true;
                            break;
                        }
                    }

                    if (!hasKeep) {
                        field.meta.push({ name: ":keep", params: [], pos: field.pos });
                    }
                default:
            }
        }

        return fields;
    }
}

#end

