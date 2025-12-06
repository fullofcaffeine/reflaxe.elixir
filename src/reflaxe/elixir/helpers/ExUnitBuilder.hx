package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ExUnitBuilder: Compatibility shim for ExUnit test transformation
 * 
 * WHY: Tests using @:exunit annotation require transformation at macro-time
 *      to work with the ExUnit framework. The actual transformation is
 *      handled by the AST transformer, but this builder is needed for
 *      the @:autoBuild macro in TestCase.
 * 
 * WHAT: Minimal shim that just returns fields unchanged. The real work
 *       is done by the exunitTransformPass in AnnotationTransforms.
 * 
 * HOW: Called via @:autoBuild on TestCase classes. Simply passes through
 *      the fields and lets the AST transformer handle the actual
 *      transformation to ExUnit test structure.
 * 
 * @deprecated This is a temporary compatibility layer that will be removed
 *             once all ExUnit functionality is integrated into the AST pipeline
 */
@:deprecated("Use AST transformation passes instead")
class ExUnitBuilder {
    /**
     * Build function called by @:autoBuild macro
     * 
     * Just returns the fields unchanged - the AST transformer handles everything.
     * The metadata flag set in ElixirCompiler triggers the exunitTransformPass
     * which does the actual work of transforming to ExUnit structure.
     * 
     * @return The class fields unchanged
     */
    public static function build(): Array<Field> {
        // Get the class fields
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();

        #if debug_exunit
        // DISABLED: trace('[ExUnitBuilder] Processing class: ${cls.name} with ${fields.length} fields');
        #end

        // Prevent DCE from removing test functions: add @:keep to fields
        // annotated with test-related metadata so they survive to the AST phase
        for (i in 0...fields.length) {
            var f = fields[i];
            switch (f.kind) {
                case FFun(_):
                    var metas = f.meta != null ? f.meta : [];
                    var has = function(name:String):Bool {
                        for (m in metas) if (m.name == name) return true; return false;
                    };
                    var isTestish = has("test") || has(":test") ||
                                     has("setup") || has(":setup") ||
                                     has("setupAll") || has(":setupAll") ||
                                     has("teardown") || has(":teardown") ||
                                     has("teardownAll") || has(":teardownAll");
                    if (isTestish) {
                        if (f.meta == null) f.meta = [];
                        // Only add if not present
                        var hasKeep = false;
                        for (m in f.meta) if (m.name == ":keep" || m.name == "keep") { hasKeep = true; break; }
                        if (!hasKeep) {
                            f.meta.push({ name: ":keep", params: [], pos: f.pos });
                            #if debug_exunit
                            // DISABLED: trace('[ExUnitBuilder]   Added @:keep to test function: ${f.name}');
                            #end
                        }
                    }
                default:
            }
        }

        return fields;
    }
}

#end
