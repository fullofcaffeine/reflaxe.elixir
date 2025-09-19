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
        
        #if debug_exunit
        var cls = Context.getLocalClass().get();
        trace('[ExUnitBuilder] Processing class: ${cls.name} with ${fields.length} fields');
        #end
        
        // Just return fields unchanged - AST transformer does the work
        return fields;
    }
}

#end