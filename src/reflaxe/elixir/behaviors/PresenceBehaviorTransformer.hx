package reflaxe.elixir.behaviors;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirASTBuilder;
import reflaxe.elixir.behaviors.BehaviorTransformer.IBehaviorTransformer;

using StringTools;

/**
 * PresenceBehaviorTransformer: Phoenix.Presence-specific behavior transformations
 * 
 * WHY: Phoenix.Presence has a dual nature - it's both an external module AND
 * a behavior that injects local functions. When a module uses `use Phoenix.Presence`,
 * it injects functions like track/5, update/5, untrack/4 that require self() as 
 * the first argument.
 * 
 * WHAT: This transformer handles the specific rules for Phoenix.Presence:
 * - Detecting when we're inside a @:presence module
 * - Transforming Phoenix.Presence method calls to local calls
 * - Injecting self() as the first argument for specific methods
 * - Handling method overloads based on argument count
 * 
 * HOW:
 * 1. Check if the method call is to Phoenix.Presence (or just Presence)
 * 2. Based on method name and argument count, determine transformation
 * 3. For track/update/untrack, inject self() and make local
 * 4. For list/getByKey, make local but don't inject self()
 * 
 * PHOENIX.PRESENCE SPECIFICS:
 * - track(socket, key, meta) -> track(self(), socket, key, meta)
 * - track(socket, topic, key, meta) -> track(self(), socket, topic, key, meta)
 * - update: similar to track
 * - untrack: similar to track
 * - list: no self() needed
 * - get_by_key: no self() needed
 */
class PresenceBehaviorTransformer implements IBehaviorTransformer {
    
    public function new() {}
    
    /**
     * Transform Phoenix.Presence method calls when inside a @:presence module
     */
    public function transformMethodCall(
        className: String,
        methodName: String,
        args: Array<ElixirAST>,
        isStatic: Bool
    ): Null<ElixirAST> {
        #if debug_behavior_transformer
        trace('[PresenceBehaviorTransformer] ========================================');
        trace('[PresenceBehaviorTransformer] Checking ${className}.${methodName}');
        trace('[PresenceBehaviorTransformer] - isStatic: ${isStatic}');
        trace('[PresenceBehaviorTransformer] - args.length: ${args.length}');
        #end
        
        // Only transform Presence class calls
        if (className != "Presence" && !className.endsWith(".Presence")) {
            #if debug_behavior_transformer
            trace('[PresenceBehaviorTransformer] Not a Presence class (className="${className}"), skipping');
            #end
            return null;
        }
        
        // Convert camelCase to snake_case for Elixir
        var snakeCaseMethod = toSnakeCase(methodName);
        
        #if debug_behavior_transformer
        trace('[PresenceBehaviorTransformer] Method: ${methodName} -> ${snakeCaseMethod}, args: ${args.length}');
        #end
        
        // Determine if this method needs self() injection
        var needsSelfInjection = needsSelf(methodName, args.length);
        
        #if debug_behavior_transformer
        trace('[PresenceBehaviorTransformer] Needs self() injection: ${needsSelfInjection}');
        #end
        
        if (needsSelfInjection) {
            // Create self() call
            var selfCall = {def: ElixirASTDef.ECall(null, "self", []), metadata: {}, pos: null};
            
            // Inject self() as first argument
            var argsWithSelf = [selfCall].concat(args);
            
            // Return local call with self()
            return {def: ElixirASTDef.ECall(null, snakeCaseMethod, argsWithSelf), metadata: {}, pos: null};
        } else {
            // Methods like list, get_by_key don't need self()
            // But they should still be local calls
            return {def: ElixirASTDef.ECall(null, snakeCaseMethod, args), metadata: {}, pos: null};
        }
    }
    
    /**
     * Determine if a Phoenix.Presence method needs self() injection
     * 
     * @param methodName The method being called (in original case)
     * @param argCount Number of arguments
     * @return true if self() should be injected
     */
    function needsSelf(methodName: String, argCount: Int): Bool {
        // Handle @:native annotations - methods might be renamed
        // For example, trackPid has @:native("track")
        var effectiveMethod = resolveNativeMethodName(methodName);
        
        return switch(effectiveMethod) {
            case "track":
                // track needs self() for all overloads
                // 3 args: track(socket, key, meta)
                // 4 args: track(socket/pid, topic, key, meta)
                true;
                
            case "update":
                // update needs self() for all overloads
                // 3 args: update(socket, key, meta)
                // 4 args: update(socket/pid, topic, key, meta)
                true;
                
            case "untrack":
                // untrack needs self() for all overloads
                // 2 args: untrack(socket, key)
                // 3 args: untrack(socket/pid, topic, key)
                true;
                
            case "list", "getByKey", "get_by_key":
                // These don't need self()
                false;
                
            default:
                // Unknown methods - make them local but no self()
                false;
        };
    }
    
    /**
     * Resolve method name considering @:native annotations
     * For example, trackPid has @:native("track"), so it becomes "track"
     */
    function resolveNativeMethodName(methodName: String): String {
        // This would ideally check the actual field metadata
        // For now, we handle known cases
        return switch(methodName) {
            case "trackPid" | "trackUser": "track";
            case "updatePid" | "updateUser": "update";
            case "untrackPid" | "untrackUser": "untrack";
            default: methodName;
        };
    }
    
    /**
     * Convert camelCase to snake_case
     * TODO: This should use the shared utility from the compiler
     */
    function toSnakeCase(str: String): String {
        var result = "";
        for (i in 0...str.length) {
            var char = str.charAt(i);
            if (i > 0 && char == char.toUpperCase() && char != char.toLowerCase()) {
                result += "_" + char.toLowerCase();
            } else {
                result += char.toLowerCase();
            }
        }
        return result;
    }
}

#end