package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * LiveViewPreserver: Prevents DCE from removing LiveView methods
 * 
 * WHY: Dead Code Elimination (DCE) removes LiveView static methods (mount, handleEvent, etc.)
 *      because from Haxe's perspective they appear "unused" - they're called by Phoenix
 *      at runtime, not by Haxe code directly.
 * 
 * WHAT: Adds @:keep metadata to all static methods in @:liveview classes to prevent
 *       DCE from removing them. This ensures the methods survive to reach the compiler.
 * 
 * HOW: Called during initialization to process all LiveView classes before DCE runs.
 *      Finds classes with @:liveview metadata and adds @:keep to their static methods.
 * 
 * @see https://github.com/HaxeFoundation/haxe/issues/8131 - DCE and @:keep behavior
 */
class LiveViewPreserver {
    
    /**
     * Initialize the LiveView preservation system
     * Should be called from CompilerInit.Start()
     */
    public static function init(): Void {
        // Register callback for after typing phase but before DCE
        Context.onAfterTyping(preserveLiveViewMethods);
    }
    
    /**
     * Process all types and preserve LiveView methods from DCE
     */
    static function preserveLiveViewMethods(types: Array<ModuleType>): Void {
        for (type in types) {
            switch (type) {
                case TClassDecl(classRef):
                    var cls = classRef.get();
                    
                    // Check if this is a LiveView class
                    if (cls.meta.has(":liveview")) {
                        #if debug_function_collection
                        // DISABLED: trace('[LiveViewPreserver] Processing LiveView class: ${cls.name}');
                        #end
                        
                        // Add @:keep to the class itself
                        if (!cls.meta.has(":keep")) {
                            cls.meta.add(":keep", [], cls.pos);
                            #if debug_function_collection
                            // DISABLED: trace('[LiveViewPreserver]   Added @:keep to class ${cls.name}');
                            #end
                        }
                        
                        // Add @:keep to all static fields (methods)
                        for (field in cls.statics.get()) {
                            if (!field.meta.has(":keep")) {
                                field.meta.add(":keep", [], field.pos);
                                #if debug_function_collection
                                // DISABLED: trace('[LiveViewPreserver]   Added @:keep to static method: ${field.name}');
                                #end
                            }
                        }
                        
                        // Also preserve instance fields if any
                        for (field in cls.fields.get()) {
                            if (!field.meta.has(":keep")) {
                                field.meta.add(":keep", [], field.pos);
                                #if debug_function_collection
                                // DISABLED: trace('[LiveViewPreserver]   Added @:keep to field: ${field.name}');
                                #end
                            }
                        }
                        
                        #if debug_function_collection
                        // DISABLED: trace('[LiveViewPreserver]   Preserved ${cls.statics.get().length} static methods');
                        #end
                    }
                    
                    // Also check for other Phoenix annotations that need preservation
                    // Include component modules so CoreComponents and similar are not DCE'd
                    if (cls.meta.has(":controller") || cls.meta.has(":channel") || 
                        cls.meta.has(":endpoint") || cls.meta.has(":router") ||
                        cls.meta.has(":presence") || cls.meta.has(":socket") ||
                        cls.meta.has(":component") || cls.meta.has(":phoenix.components")) {
                        
                        // Add @:keep to preserve from DCE
                        if (!cls.meta.has(":keep")) {
                            cls.meta.add(":keep", [], cls.pos);
                        }
                        
                        // Preserve all static methods for Phoenix components/modules
                        for (field in cls.statics.get()) {
                            if (!field.meta.has(":keep")) {
                                field.meta.add(":keep", [], field.pos);
                            }
                        }
                    }
                    
                default:
                    // Skip other module types
            }
        }
    }
    
    /**
     * Alternative approach: Build macro for LiveView classes
     * This could be triggered with @:autoBuild on a LiveView base class
     */
    public static function buildLiveView(): Array<Field> {
        var fields = Context.getBuildFields();
        
        // Add @:keep to all static methods
        for (field in fields) {
            if (field.access.contains(AStatic)) {
                if (field.meta == null) field.meta = [];
                
                // Check if @:keep already exists
                var hasKeep = false;
                for (meta in field.meta) {
                    if (meta.name == ":keep" || meta.name == "keep") {
                        hasKeep = true;
                        break;
                    }
                }
                
                // Add @:keep if not present
                if (!hasKeep) {
                    field.meta.push({
                        name: ":keep",
                        params: [],
                        pos: field.pos
                    });
                }
            }
        }
        
        return fields;
    }
}

#end
