package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.BaseCompiler;

using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * Reflection Compiler for Reflaxe.Elixir
 * 
 * WHY: Reflection operations like Reflect.fields and Reflect.setField need special handling
 * to generate idiomatic Elixir Map operations instead of dynamic field access.
 * This was a large section (~300+ lines) in the main ElixirCompiler.
 * 
 * WHAT: Specialized compilation of reflection operations with pattern detection:
 * - Detect Reflect.fields iteration patterns
 * - Convert Reflect.setField to Map.put operations
 * - Convert Reflect.field to Map.get operations  
 * - Optimize reflection loops to idiomatic Elixir
 * - Handle complex reflection patterns and edge cases
 * 
 * HOW: The compiler detects reflection patterns and transforms them:
 * 1. Scan loop bodies for reflection operations
 * 2. Extract source and target objects from reflection calls
 * 3. Transform to appropriate Map operations
 * 4. Generate idiomatic Elixir iteration patterns
 * 
 * @see documentation/REFLECTION_COMPILATION.md - Complete reflection handling patterns
 */
@:nullSafety(Off)
class ReflectionCompiler {
    
    var compiler: Dynamic; // ElixirCompiler reference
    
    /**
     * Create a new reflection compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: Dynamic) {
        this.compiler = compiler;
    }
    
    /**
     * Detect Reflect.fields pattern in loop conditions and bodies
     * 
     * WHY: Reflection loops need special handling to become idiomatic Elixir
     * 
     * WHAT: Pattern detection for common reflection operations:
     * - Iterating over Reflect.fields result
     * - Using Reflect.setField and Reflect.field in loops
     * - Extracting source and target objects correctly
     * 
     * HOW:
     * 1. Scan loop body for reflection operations
     * 2. Extract source object from Reflect.field calls
     * 3. Extract target object from Reflect.setField calls  
     * 4. Generate optimized Map operations
     * 
     * @param econd Loop condition expression
     * @param ebody Loop body expression
     * @return Generated Elixir code or null if not a reflection pattern
     */
    public function detectReflectFieldsPattern(econd: TypedExpr, ebody: TypedExpr): Null<String> {
        #if debug_reflection_compiler
        trace("[XRay ReflectionCompiler] DETECT PATTERN START");
        trace('[XRay ReflectionCompiler] Condition: ${econd.expr}');
        #end
        
        // Look for patterns where we're iterating over Reflect.fields result
        // The condition is typically: _g < array.length where array = Reflect.fields(obj)
        
        // CRITICAL FIX: Extract BOTH source and target objects for proper Map.merge optimization
        // 
        // BUG ANALYSIS: Previous code extracted only targetObject from Reflect.setField first argument,
        // but then incorrectly passed it as sourceObject to compileReflectFieldsIteration.
        // This caused "o = Map.merge(o, o)" instead of "endpointConfig = Map.merge(endpointConfig, config)".
        //
        // SOLUTION: Extract sourceObject from Reflect.field calls and targetObject from Reflect.setField calls.
        // Pattern: Reflect.setField(target, field, Reflect.field(source, field))
        //          ^^^^^^^^^^^^^^^ extract target    ^^^^^^^^^^^^^^^^^^^ extract source
        var hasReflectOperations = false;
        var targetObject: String = null;  // Object being modified (e.g., endpointConfig)
        var sourceObject: String = null;  // Object being read from (e.g., config)
        
        // Scan the loop body for reflection operations
        var result = scanReflectionOperations(ebody);
        hasReflectOperations = result.hasReflectOperations;
        targetObject = result.targetObject;
        sourceObject = result.sourceObject;
        
        #if debug_reflection_compiler
        trace('[XRay ReflectionCompiler] Detected: has=${hasReflectOperations}, target=${targetObject}, source=${sourceObject}');
        #end
        
        if (hasReflectOperations && targetObject != null && sourceObject != null) {
            // Generate optimized reflection iteration
            var result = '${targetObject} = Map.merge(${targetObject}, ${sourceObject})';
            
            #if debug_reflection_compiler
            trace('[XRay ReflectionCompiler] Generated: ${result}');
            trace("[XRay ReflectionCompiler] DETECT PATTERN END");
            #end
            
            return result;
        }
        
        #if debug_reflection_compiler
        trace("[XRay ReflectionCompiler] Pattern not detected");
        trace("[XRay ReflectionCompiler] DETECT PATTERN END");
        #end
        
        return null;
    }
    
    /**
     * Scan expression for reflection operations
     * 
     * WHY: Need to identify reflection patterns and extract objects
     */
    private function scanReflectionOperations(expr: TypedExpr): {hasReflectOperations: Bool, targetObject: String, sourceObject: String} {
        var hasReflectOperations = false;
        var targetObject: String = null;
        var sourceObject: String = null;
        
        function scan(e: TypedExpr): Void {
            switch (e.expr) {
                case TCall(callExpr, args):
                    switch (callExpr.expr) {
                        case TField(obj, fa):
                            var objStr = compiler.compileExpression(obj);
                            var methodName = compiler.getFieldName(fa);
                            
                            if (objStr == "Reflect") {
                                hasReflectOperations = true;
                                
                                if (methodName == "setField" && args.length >= 3) {
                                    // Extract target object from Reflect.setField(target, field, value)
                                    targetObject = compiler.compileExpression(args[0]);
                                    
                                    // Check if the value is a Reflect.field call for source object
                                    switch (args[2].expr) {
                                        case TCall(valueCallExpr, valueArgs):
                                            switch (valueCallExpr.expr) {
                                                case TField(valueObj, valueFa):
                                                    var valueObjStr = compiler.compileExpression(valueObj);
                                                    var valueMethodName = compiler.getFieldName(valueFa);
                                                    
                                                    if (valueObjStr == "Reflect" && valueMethodName == "field" && valueArgs.length >= 1) {
                                                        // Extract source object from Reflect.field(source, field)
                                                        sourceObject = compiler.compileExpression(valueArgs[0]);
                                                    }
                                                case _:
                                            }
                                        case _:
                                    }
                                } else if (methodName == "field" && args.length >= 1) {
                                    // Extract source object from Reflect.field(source, field)
                                    if (sourceObject == null) {
                                        sourceObject = compiler.compileExpression(args[0]);
                                    }
                                }
                            }
                        case _:
                    }
                case TBlock(exprs):
                    for (expr in exprs) scan(expr);
                case TIf(_, eif, eelse):
                    scan(eif);
                    if (eelse != null) scan(eelse);
                case TBinop(_, e1, e2):
                    scan(e1);
                    scan(e2);
                case TVar(_, init):
                    if (init != null) scan(init);
                case _:
            }
        }
        
        scan(expr);
        return {hasReflectOperations: hasReflectOperations, targetObject: targetObject, sourceObject: sourceObject};
    }
    
    /**
     * Check if loop body contains reflection operations
     * 
     * WHY: Quick check to determine if reflection optimization applies
     */
    public function isReflectFieldsLoop(ebody: TypedExpr): Bool {
        var result = scanReflectionOperations(ebody);
        return result.hasReflectOperations;
    }
    
    /**
     * Optimize Reflect.fields loop to idiomatic Elixir
     * 
     * WHY: Transform reflection loops to efficient Map operations
     */
    public function optimizeReflectFieldsLoop(econd: TypedExpr, ebody: TypedExpr): String {
        var result = detectReflectFieldsPattern(econd, ebody);
        if (result != null) {
            return result;
        }
        
        // Fallback to regular compilation
        return compiler.compileExpression(ebody);
    }
    
    /**
     * Transform reflection operations in loop body
     * 
     * WHY: Convert individual reflection calls to Map operations
     */
    public function transformReflectLoopBody(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        return switch (expr.expr) {
            case TCall(e, args):
                switch (e.expr) {
                    case TField(obj, fa):
                        var objStr = compiler.compileExpression(obj);
                        var methodName = compiler.getFieldName(fa);
                        
                        if (objStr == "Reflect") {
                            if (methodName == "setField" && args.length >= 3) {
                                var target = compiler.compileExpression(args[0]);
                                var field = compiler.compileExpression(args[1]);
                                var value = compiler.compileExpression(args[2]);
                                
                                // Use provided fieldVar if field matches
                                if (field == fieldVar || field.contains("field")) {
                                    field = fieldVar;
                                }
                                
                                // Generate Map.put assignment
                                '${target} = Map.put(${target}, ${field}, ${value})';
                            } else if (methodName == "field" && args.length >= 2) {
                                var source = compiler.compileExpression(args[0]);
                                var field = compiler.compileExpression(args[1]);
                                if (field == fieldVar || field.contains("field")) {
                                    field = fieldVar;
                                }
                                'Map.get(${source}, ${field})';
                            } else {
                                compiler.compileExpression(expr);
                            }
                        } else {
                            compiler.compileExpression(expr);
                        }
                    case _:
                        compiler.compileExpression(expr);
                }
            case _:
                compiler.compileExpression(expr);
        };
    }
}

#end