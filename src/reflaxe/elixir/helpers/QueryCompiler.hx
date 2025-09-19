package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * QueryCompiler: Compatibility shim for Ecto query transformation
 *
 * WHY: Classes using @:query annotation require transformation at macro-time
 *      to work with Ecto's query DSL. The actual transformation is
 *      handled by the AST transformer, but this builder is needed for
 *      the @:autoBuild macro in Ecto schemas and queries.
 *
 * WHAT: Minimal shim that just returns fields unchanged. The real work
 *       is done by the queryTransformPass in the AST transformation pipeline.
 *
 * HOW: Called via @:autoBuild on Query/Schema classes. Simply passes through
 *      the fields and lets the AST transformer handle the actual
 *      transformation to Ecto query structures.
 *
 * ARCHITECTURE BENEFITS:
 * - Maintains backward compatibility with existing tests
 * - Allows gradual migration to AST-based transformation
 * - Keeps macro-time and AST-time transformations separate
 * - Enables tests to compile while real logic moves to AST pipeline
 *
 * @deprecated This is a temporary compatibility layer that will be removed
 *             once all Ecto query functionality is integrated into the AST pipeline
 */
@:deprecated("Use AST transformation passes instead")
class QueryCompiler {
    /**
     * Build function called by @:autoBuild macro
     *
     * Just returns the fields unchanged - the AST transformer handles everything.
     * The metadata flag set in ElixirCompiler triggers the queryTransformPass
     * which does the actual work of transforming to Ecto query structures.
     *
     * @return The class fields unchanged
     */
    public static function build(): Array<Field> {
        // Get the class fields
        var fields = Context.getBuildFields();

        #if debug_query
        var cls = Context.getLocalClass().get();
        trace('[QueryCompiler] Processing class: ${cls.name} with ${fields.length} fields');
        trace('[QueryCompiler] This is a compatibility shim - actual transformation happens in AST transformer');
        #end

        // Just return fields unchanged - AST transformer does the work
        return fields;
    }
}

#end