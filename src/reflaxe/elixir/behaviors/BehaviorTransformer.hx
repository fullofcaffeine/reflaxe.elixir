package reflaxe.elixir.behaviors;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;

/**
 * BehaviorTransformer: Pluggable transformation system for Elixir behaviors
 * 
 * WHY: Elixir behaviors (like Phoenix.Presence, GenServer, etc.) inject local
 * functions into modules that "use" them. These injected functions often have
 * different calling conventions than their module counterparts (e.g., need self()).
 * The compiler shouldn't have hardcoded knowledge of specific behaviors.
 * 
 * WHAT: This class provides a pluggable system where behavior-specific transformations
 * can be registered and applied based on metadata, not hardcoded logic.
 * 
 * HOW: 
 * 1. Behaviors register their transformation rules via metadata
 * 2. When compiling a module with a behavior annotation, we activate that transformer
 * 3. Method calls are passed through the transformer for behavior-specific handling
 * 4. Each behavior can define its own rules without polluting the main compiler
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Each behavior has its own transformer
 * - Open/Closed: Add new behaviors without modifying core compiler
 * - Framework-agnostic: Compiler doesn't know about Phoenix, GenServer, etc.
 * - Testable: Each transformer can be tested independently
 * - Maintainable: Behavior logic is isolated and documented
 */
class BehaviorTransformer {
    /**
     * Registry of behavior transformers
     * Key: behavior name (e.g., "presence", "genserver")
     * Value: transformer instance
     */
    static var transformers: Map<String, IBehaviorTransformer> = new Map();
    
    /**
     * Currently active behavior context
     * Set when compiling a module with a behavior annotation
     */
    public var activeBehavior: Null<String> = null;
    
    /**
     * Constructor
     */
    public function new() {
        // Initialize - no state needed currently
    }
    
    /**
     * Register a behavior transformer
     * Should be called during compiler initialization
     */
    public static function register(name: String, transformer: IBehaviorTransformer): Void {
        transformers.set(name, transformer);
    }
    
    /**
     * Initialize standard behavior transformers
     * Called once during compiler setup
     */
    public static function initialize(): Void {
        // Register Phoenix.Presence transformer
        register("presence", new PresenceBehaviorTransformer());
        
        // Future: Register other behaviors
        // register("genserver", new GenServerBehaviorTransformer());
        // register("supervisor", new SupervisorBehaviorTransformer());
    }
    
    /**
     * Check if a class has a behavior annotation and activate it
     * 
     * @param classType The class being compiled
     * @return The behavior name if found, null otherwise
     */
    public function checkAndActivateBehavior(classType: ClassType): Null<String> {
        // Check for behavior annotations like @:presence, @:genserver, etc.
        #if debug_behavior_transformer
        trace('[BehaviorTransformer.checkAndActivateBehavior] Checking class: ${classType.name}');
        trace('[BehaviorTransformer.checkAndActivateBehavior] Metadata: ${[for (m in classType.meta.get()) m.name]}');
        trace('[BehaviorTransformer.checkAndActivateBehavior] isExtern: ${classType.isExtern}');
        #end
        
        for (meta in classType.meta.get()) {
            var behaviorName = switch(meta.name) {
                case ":presence": "presence";
                case ":genserver": "genserver";
                case ":supervisor": "supervisor";
                // Add more behaviors as needed
                default: null;
            };
            
            if (behaviorName != null) {
                #if debug_behavior_transformer trace('[BehaviorTransformer.checkAndActivateBehavior] Found behavior: ${behaviorName}'); #end
                activeBehavior = behaviorName;
                return behaviorName;
            }
        }
        
        #if debug_behavior_transformer trace('[BehaviorTransformer.checkAndActivateBehavior] No behavior found'); #end
        
        return null;
    }
    
    /**
     * Transform a method call based on active behavior rules
     * 
     * @param className The class being called (e.g., "Presence")
     * @param methodName The method being called (e.g., "track")
     * @param args The arguments to the method
     * @param isStatic Whether this is a static method call
     * @return Transformed AST or null if no transformation needed
     */
    public function transformMethodCall(
        className: String,
        methodName: String,
        args: Array<ElixirAST>,
        isStatic: Bool
    ): Null<ElixirAST> {
        if (activeBehavior == null) {
            return null; // No active behavior, no transformation
        }
        
        var transformer = transformers.get(activeBehavior);
        if (transformer == null) {
            return null; // No transformer for this behavior
        }
        
        // Let the behavior-specific transformer handle it
        return transformer.transformMethodCall(className, methodName, args, isStatic);
    }
    
    /**
     * Deactivate the current behavior context
     * Called after finishing compilation of a behavior module
     */
    public function deactivate(): Void {
        activeBehavior = null;
    }
}

/**
 * Interface for behavior-specific transformers
 * Each behavior implements this to define its transformation rules
 */
interface IBehaviorTransformer {
    /**
     * Transform a method call according to behavior rules
     * 
     * @param className The class being called
     * @param methodName The method being called  
     * @param args The arguments to the method
     * @param isStatic Whether this is a static method call
     * @return Transformed AST or null if no transformation needed
     */
    function transformMethodCall(
        className: String,
        methodName: String,
        args: Array<ElixirAST>,
        isStatic: Bool
    ): Null<ElixirAST>;
}

#end
