package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.BaseCompiler;
import reflaxe.elixir.helpers.NamingHelper;

using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * LiveView Compiler for Reflaxe.Elixir
 * 
 * WHY: Phoenix LiveView is the modern way to build interactive web applications.
 * This compiler enables type-safe LiveView development in Haxe with full
 * compile-time checking of events, assigns, and socket operations.
 * 
 * WHAT: Handles compilation of classes annotated with @:liveview:
 * - Generates Phoenix.LiveView modules with callbacks
 * - mount/3, handle_event/3, handle_info/2 callbacks
 * - render/1 function with HEEx templates
 * - Socket assigns type safety
 * - PubSub integration
 * 
 * HOW:
 * 1. Extract LiveView metadata and options
 * 2. Generate module with use Phoenix.LiveView
 * 3. Compile callback functions with proper signatures
 * 4. Handle HXX template compilation
 * 5. Ensure socket operations are type-safe
 * 
 * @see documentation/LIVEVIEW_INTEGRATION.md - Complete LiveView guide
 */
@:nullSafety(Off)
class LiveViewCompiler {
    
    var compiler: Dynamic; // ElixirCompiler reference
    
    /**
     * Create a new LiveView compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: Dynamic) {
        this.compiler = compiler;
    }
    
    /**
     * Compile a class annotated with @:liveview
     * 
     * WHY: LiveView modules need specific structure with callbacks
     * and proper Phoenix.LiveView usage.
     * 
     * WHAT: Generates a complete LiveView module including:
     * - Module definition with use Phoenix.LiveView
     * - mount/3 callback for initialization
     * - handle_event/3 for user interactions
     * - handle_info/2 for PubSub messages
     * - render/1 with HEEx template
     * - Helper functions for assigns manipulation
     * 
     * HOW:
     * 1. Extract LiveView configuration from metadata
     * 2. Generate module with proper use statement
     * 3. Compile each callback with correct signature
     * 4. Process HXX templates to HEEx
     * 5. Add helper functions for socket operations
     * 
     * @param classType The class type information
     * @param varFields Variable fields (component state)
     * @param funcFields Function fields (callbacks and helpers)
     * @return Generated Phoenix LiveView module code
     */
    public function compileLiveViewClass(
        classType: ClassType,
        varFields: Array<Dynamic>, // ClassVarData
        funcFields: Array<Dynamic>  // ClassFuncData
    ): String {
        
        #if debug_liveview
        trace('[LiveViewCompiler] Compiling LiveView class: ${classType.name}');
        trace('[LiveViewCompiler] Functions: ${funcFields.length}');
        #end
        
        var moduleName = compiler.getModuleName(classType);
        var appName = extractAppName(moduleName);
        
        // Generate module header
        var result = 'defmodule ${moduleName} do\n';
        result += '  use ${appName}Web, :live_view\n\n';
        
        // Add alias for CoreComponents if needed
        if (needsCoreComponents(funcFields)) {
            result += '  alias ${appName}Web.CoreComponents\n\n';
        }
        
        // Compile LiveView callbacks
        result += compileLiveViewCallbacks(funcFields);
        
        // Compile helper functions
        for (funcField in funcFields) {
            if (!isLiveViewCallback(funcField.name)) {
                result += compiler.compileFunction(funcField, true) + '\n';
            }
        }
        
        result += 'end\n';
        
        #if debug_liveview
        trace('[LiveViewCompiler] Generated LiveView: ${result.substring(0, 200)}...');
        #end
        
        return result;
    }
    
    // ================== Private Helper Methods ==================
    
    /**
     * Extract application name from module name
     */
    private function extractAppName(moduleName: String): String {
        // Extract "TodoApp" from "TodoAppWeb.TodoLive"
        var parts = moduleName.split(".");
        if (parts.length > 0) {
            var webPart = parts[0];
            if (webPart.endsWith("Web")) {
                return webPart.substring(0, webPart.length - 3);
            }
        }
        return "App"; // Fallback
    }
    
    /**
     * Check if CoreComponents alias is needed
     */
    private function needsCoreComponents(funcFields: Array<Dynamic>): Bool {
        // Check if any function uses CoreComponents
        for (funcField in funcFields) {
            if (funcField.name == "render") {
                // Would need to analyze the render function body
                return true; // For now, always include
            }
        }
        return false;
    }
    
    /**
     * Compile LiveView callback functions
     */
    private function compileLiveViewCallbacks(funcFields: Array<Dynamic>): String {
        var result = "";
        
        // Standard LiveView callbacks in order
        var callbacks = ["mount", "render", "handle_event", "handle_info", "handle_params"];
        
        for (callbackName in callbacks) {
            for (funcField in funcFields) {
                if (funcField.name == callbackName) {
                    result += compileLiveViewCallback(funcField, callbackName) + '\n';
                }
            }
        }
        
        return result;
    }
    
    /**
     * Compile a specific LiveView callback
     */
    private function compileLiveViewCallback(funcField: Dynamic, callbackName: String): String {
        // LiveView callbacks have specific signatures
        return switch (callbackName) {
            case "mount":
                // mount(params, session, socket)
                compiler.compileFunction(funcField, true);
                
            case "render":
                // render(assigns) - may include HXX template
                compileRenderFunction(funcField);
                
            case "handle_event":
                // handle_event(event, params, socket)
                compiler.compileFunction(funcField, true);
                
            case "handle_info":
                // handle_info(msg, socket)
                compiler.compileFunction(funcField, true);
                
            case "handle_params":
                // handle_params(params, uri, socket)
                compiler.compileFunction(funcField, true);
                
            default:
                compiler.compileFunction(funcField, true);
        };
    }
    
    /**
     * Compile render function with HXX support
     */
    private function compileRenderFunction(funcField: Dynamic): String {
        // Check if this uses HXX template
        // For now, delegate to main compiler
        return compiler.compileFunction(funcField, true);
    }
    
    /**
     * Check if a function name is a LiveView callback
     */
    private function isLiveViewCallback(name: String): Bool {
        return switch (name) {
            case "mount", "render", "handle_event", "handle_info", "handle_params":
                true;
            case "terminate", "update":
                true; // Additional callbacks
            default:
                false;
        };
    }
}

#end