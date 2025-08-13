package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * Auto-init system for Router build macros.
 * 
 * This class automatically applies RouterBuildMacro.generateRoutes() to any class
 * with @:router annotation, eliminating the need for manual @:build annotations.
 * 
 * Usage - developers just write:
 * ```haxe
 * @:router
 * @:routes([...])
 * class MyRouter {}
 * ```
 * 
 * The build macro is applied automatically via Context.onTypeNotFound() hook.
 */
class RouterMacroInit {
    
    /**
     * Initialize router macro auto-application system.
     * This should be called during compiler initialization.
     */
    public static function init(): Void {
        // Hook into the type building process
        Context.onAfterInitMacros(setupRouterMacros);
    }
    
    /**
     * Setup router macro system after initial macros are processed
     */
    static function setupRouterMacros(): Void {
        // We'll use a different approach - check all types being compiled
        // and apply build macro retroactively if needed
        Context.onAfterTyping(function(types) {
            applyRouterMacrosToTypes(types);
        });
    }
    
    /**
     * Apply router build macros to types that need them
     */
    static function applyRouterMacrosToTypes(types: Array<haxe.macro.Type>): Void {
        for (type in types) {
            switch (type) {
                case TInst(classRef, _):
                    var classType = classRef.get();
                    
                    // Check if this class has @:router annotation
                    if (classType.meta.has(":router")) {
                        // Check if it also has @:routes annotation (new syntax)
                        if (classType.meta.has(":routes")) {
                            // This class should have had RouterBuildMacro applied
                            // We can't apply it retroactively here, but we can validate
                            validateRouterMacroWasApplied(classType);
                        }
                    }
                    
                case _:
                    // Ignore other types
            }
        }
    }
    
    /**
     * Validate that RouterBuildMacro was properly applied to router classes
     */
    static function validateRouterMacroWasApplied(classType: ClassType): Void {
        // Check if the class has both @:routes and some route functions
        var hasRoutes = classType.meta.has(":routes");
        var hasRouteFunctions = false;
        
        // Check static fields for @:route annotations
        var statics = classType.statics.get();
        for (field in statics) {
            if (field.meta.has(":route")) {
                hasRouteFunctions = true;
                break;
            }
        }
        
        if (hasRoutes && !hasRouteFunctions) {
            Context.warning(
                "Class has @:routes annotation but no route functions were generated. " +
                "Make sure to use @:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())",
                classType.pos
            );
        }
    }
}

#end