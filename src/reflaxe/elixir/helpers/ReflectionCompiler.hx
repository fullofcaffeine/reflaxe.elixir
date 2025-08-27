package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;import haxe.macro.Expr;
import reflaxe.elixir.ElixirCompiler;import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;
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
    
    var compiler: reflaxe.elixir.ElixirCompiler; // ElixirCompiler reference
    
    /**
     * Create a new reflection compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
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
        // trace("[XRay ReflectionCompiler] DETECT PATTERN START");
        // trace('[XRay ReflectionCompiler] Condition: ${econd.expr}');
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
        // trace('[XRay ReflectionCompiler] Detected: has=${hasReflectOperations}, target=${targetObject}, source=${sourceObject}');
        #end
        
        if (hasReflectOperations && targetObject != null && sourceObject != null) {
            // Generate optimized reflection iteration
            var result = '${targetObject} = Map.merge(${targetObject}, ${sourceObject})';
            
            #if debug_reflection_compiler
            // trace('[XRay ReflectionCompiler] Generated: ${result}');
            // trace("[XRay ReflectionCompiler] DETECT PATTERN END");
            #end
            
            return result;
        }
        
        #if debug_reflection_compiler
        // trace("[XRay ReflectionCompiler] Pattern not detected");
        // trace("[XRay ReflectionCompiler] DETECT PATTERN END");
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
                                if (field == fieldVar || StringTools.contains(field, "field")) {
                                    field = fieldVar;
                                }
                                
                                // Generate Map.put assignment
                                target + " = Map.put(" + target + ", " + field + ", " + value + ")";
                            } else if (methodName == "field" && args.length >= 2) {
                                var source = compiler.compileExpression(args[0]);
                                var field = compiler.compileExpression(args[1]);
                                if (field == fieldVar || StringTools.contains(field, "field")) {
                                    field = fieldVar;
                                }
                                "Map.get(" + source + ", " + field + ")";
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
    
    /**
     * Compile Reflect.fields iteration to idiomatic Elixir
     * 
     * WHY: Transform reflection field iterations to efficient Map operations
     * 
     * WHAT: Detects simple field copying patterns and optimizes them to Map.merge,
     * or falls back to Enum.each with Map.keys for complex patterns
     * 
     * HOW:
     * 1. Check for simple field copying pattern (Reflect.setField(target, field, Reflect.field(source, field)))
     * 2. If simple pattern: generate Map.merge(target, source)
     * 3. If complex pattern: generate Enum.each(Map.keys(source), fn field -> ... end)
     * 
     * @param fieldVar Loop variable name extracted from AST
     * @param sourceObject Source object being read from
     * @param blockExpr Loop body expression
     * @return Generated Elixir code for the iteration
     */
    public function compileReflectFieldsIteration(fieldVar: String, sourceObject: String, blockExpr: TypedExpr): String {
        #if debug_reflection_compiler
        // trace("[XRay ReflectionCompiler] COMPILE ITERATION START");
        // trace('[XRay ReflectionCompiler] fieldVar: ${fieldVar}, sourceObject: ${sourceObject}');
        #end
        
        // Check for simple field copying pattern that can be optimized to Map.merge
        var detectedTargetObject = detectSimpleFieldCopyPattern(blockExpr, sourceObject, fieldVar);
        
        #if debug_reflection_compiler
        // trace('[XRay ReflectionCompiler] Pattern detection result: ${detectedTargetObject}');
        #end
        
        if (detectedTargetObject != null) {
            // Simple field copying pattern - use Map.merge optimization
            var result = detectedTargetObject + " = Map.merge(" + detectedTargetObject + ", " + sourceObject + ")";
            
            #if debug_reflection_compiler
            // trace('[XRay ReflectionCompiler] Generated Map.merge: ${result}');
            // trace("[XRay ReflectionCompiler] COMPILE ITERATION END");
            #end
            
            return result;
        }
        
        // Complex pattern - fall back to Enum.each with Map.keys
        var transformedBody = compileReflectFieldsBody(blockExpr, sourceObject, fieldVar);
        var result = "Enum.each(Map.keys(" + sourceObject + "), fn " + fieldVar + " ->\n" +
                    "  " + transformedBody + "\n" +
                    "end)";
        
        #if debug_reflection_compiler
        // trace('[XRay ReflectionCompiler] Generated Enum.each: ${result.substring(0, 100)}...');
        // trace("[XRay ReflectionCompiler] COMPILE ITERATION END");
        #end
        
        return result;
    }
    
    /**
     * Detect simple field copying pattern for Map.merge optimization
     * 
     * WHY: Simple field copying can be optimized to efficient Map.merge
     * 
     * WHAT: Analyzes loop body to detect Reflect.setField(target, field, Reflect.field(source, field)) patterns
     * 
     * HOW:
     * 1. Check if block contains single Reflect.setField call
     * 2. Verify the value comes from Reflect.field on the same field
     * 3. Extract and return target object name if pattern matches
     * 
     * @param blockExpr Loop body expression to analyze
     * @param sourceObject Source object being read from
     * @param fieldVar Field variable name
     * @return Target object name if simple pattern detected, null otherwise
     */
    private function detectSimpleFieldCopyPattern(blockExpr: TypedExpr, sourceObject: String, fieldVar: String): Null<String> {
        #if debug_reflection_compiler
        // trace("[XRay ReflectionCompiler] DETECT SIMPLE PATTERN START");
        // trace('[XRay ReflectionCompiler] Analyzing block: ${blockExpr.expr}');
        #end
        
        return switch (blockExpr.expr) {
            case TCall(e, args):
                // Direct Reflect.setField call
                var result = detectReflectSetFieldPattern(e, args, sourceObject, fieldVar);
                
                #if debug_reflection_compiler
                // trace('[XRay ReflectionCompiler] TCall pattern result: ${result}');
                // trace("[XRay ReflectionCompiler] DETECT SIMPLE PATTERN END");
                #end
                
                result;
                
            case TBlock(exprs):
                // Block with potentially single setField call
                if (exprs.length == 1) {
                    detectSimpleFieldCopyPattern(exprs[0], sourceObject, fieldVar);
                } else {
                    #if debug_reflection_compiler
                    // trace('[XRay ReflectionCompiler] Complex block with ${exprs.length} expressions');
                    // trace("[XRay ReflectionCompiler] DETECT SIMPLE PATTERN END");
                    #end
                    null; // Complex pattern
                }
                
            case _:
                #if debug_reflection_compiler
                // trace('[XRay ReflectionCompiler] Non-matching pattern: ${blockExpr.expr}');
                // trace("[XRay ReflectionCompiler] DETECT SIMPLE PATTERN END");
                #end
                null;
        };
    }
    
    /**
     * Detect Reflect.setField pattern in method call
     * 
     * WHY: Core pattern detection for Map.merge optimization
     */
    private function detectReflectSetFieldPattern(e: TypedExpr, args: Array<TypedExpr>, sourceObject: String, fieldVar: String): Null<String> {
        return switch (e.expr) {
            case TField(obj, fa):
                var objStr = compiler.compileExpression(obj);
                var methodName = compiler.getFieldName(fa);
                
                if (objStr == "Reflect" && methodName == "setField" && args.length >= 3) {
                    // Check if third argument is Reflect.field call
                    var isReflectFieldCall = isReflectFieldCall(args[2], sourceObject, fieldVar);
                    if (isReflectFieldCall) {
                        // Extract target object from first argument
                        compiler.compileExpression(args[0]);
                    } else {
                        null;
                    }
                } else {
                    null;
                }
            case _:
                null;
        };
    }
    
    /**
     * Check if expression is a Reflect.field call with matching parameters
     * 
     * WHY: Verify that setField value comes from Reflect.field for optimization
     */
    private function isReflectFieldCall(expr: TypedExpr, sourceObject: String, fieldVar: String): Bool {
        return switch (expr.expr) {
            case TCall(e, args):
                switch (e.expr) {
                    case TField(obj, fa):
                        var objStr = compiler.compileExpression(obj);
                        var methodName = compiler.getFieldName(fa);
                        
                        if (objStr == "Reflect" && methodName == "field" && args.length >= 2) {
                            var source = compiler.compileExpression(args[0]);
                            var field = compiler.compileExpression(args[1]);
                            
                            // Check if source and field match expected pattern
                            source == sourceObject && (field == fieldVar || StringTools.contains(field, "field"));
                        } else {
                            false;
                        }
                    case _:
                        false;
                }
            case _:
                false;
        };
    }
    
    /**
     * Compile reflection fields body for complex patterns
     * 
     * WHY: Handle complex reflection operations that can't be optimized to Map.merge
     */
    private function compileReflectFieldsBody(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        return switch (expr.expr) {
            case TBlock(exprs):
                var statements = [];
                for (e in exprs) {
                    var stmt = compileReflectFieldsStatement(e, targetObject, fieldVar);
                    if (stmt != null && stmt != "") {
                        statements.push(stmt);
                    }
                }
                statements.join("\n    ");
            case _:
                compileReflectFieldsStatement(expr, targetObject, fieldVar);
        };
    }
    
    /**
     * Compile individual reflection field statement
     * 
     * WHY: Transform individual reflection operations to Map operations
     */
    private function compileReflectFieldsStatement(expr: TypedExpr, sourceObject: String, fieldVar: String): String {
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
                                
                                // Use fieldVar if field matches pattern
                                if (StringTools.contains(field, "Enum.at")) {
                                    field = fieldVar;
                                }
                                
                                "Map.put(" + target + ", " + field + ", " + value + ")";
                            } else if (methodName == "field" && args.length >= 2) {
                                var source = compiler.compileExpression(args[0]);
                                var field = compiler.compileExpression(args[1]);
                                
                                if (StringTools.contains(field, "Enum.at")) {
                                    field = fieldVar;
                                }
                                
                                "Map.get(" + source + ", " + field + ")";
                            } else {
                                compiler.compileExpression(expr);
                            }
                        } else {
                            compiler.compileExpression(expr);
                        }
                    case _:
                        compiler.compileExpression(expr);
                }
            case TBinop(_, e1, e2):
                var left = compiler.compileExpression(e1);
                var right = compileReflectFieldsStatement(e2, sourceObject, fieldVar);
                left + " = " + right;
            case TVar(v, init):
                // Skip field variable declarations
                var varName = compiler.getOriginalVarName(v);
                if (varName == "field" || StringTools.contains(varName, "field")) {
                    "";
                } else if (init != null) {
                    var value = compiler.compileExpression(init);
                    varName + " = " + value;
                } else {
                    "";
                }
            case _:
                compiler.compileExpression(expr);
        };
    }
    
    /**
     * Check for Reflect.fields iteration patterns in expressions
     * 
     * WHY: Detect reflection patterns in complex expression trees
     * 
     * WHAT: Recursively searches expressions for Reflect.fields usage patterns
     * 
     * HOW: 
     * 1. Scan expression tree for TCall nodes
     * 2. Check if calls are Reflect.fields operations
     * 3. Return true if any reflection patterns found
     * 
     * @param expr Expression tree to analyze
     * @return True if Reflect.fields patterns detected
     */
    public function checkForReflectFieldsInExpression(expr: TypedExpr): Bool {
        #if debug_reflection_compiler
        // trace("[XRay ReflectionCompiler] CHECK EXPRESSION START");
        // trace('[XRay ReflectionCompiler] Checking expr: ${expr.expr}');
        #end
        
        var hasReflectFields = false;
        
        function scanExpression(e: TypedExpr): Void {
            switch (e.expr) {
                case TCall(callExpr, args):
                    switch (callExpr.expr) {
                        case TField(obj, fa):
                            var objStr = compiler.compileExpression(obj);
                            var methodName = compiler.getFieldName(fa);
                            
                            if (objStr == "Reflect" && methodName == "fields") {
                                hasReflectFields = true;
                                
                                #if debug_reflection_compiler
                                // trace("[XRay ReflectionCompiler] ✓ REFLECT.FIELDS FOUND");
                                #end
                            }
                        case _:
                    }
                    
                    // Continue scanning arguments
                    for (arg in args) {
                        scanExpression(arg);
                    }
                    
                case TBlock(exprs):
                    for (expr in exprs) {
                        scanExpression(expr);
                    }
                    
                case TBinop(_, e1, e2):
                    scanExpression(e1);
                    scanExpression(e2);
                    
                case TIf(cond, eif, eelse):
                    scanExpression(cond);
                    scanExpression(eif);
                    if (eelse != null) scanExpression(eelse);
                    
                case TWhile(cond, body, _):
                    scanExpression(cond);
                    scanExpression(body);
                    
                case TFor(v, iterator, body):
                    scanExpression(iterator);
                    scanExpression(body);
                    
                case TVar(_, init):
                    if (init != null) scanExpression(init);
                    
                case _:
                    // No recursive scanning needed for other expression types
            }
        }
        
        scanExpression(expr);
        
        #if debug_reflection_compiler
        // trace('[XRay ReflectionCompiler] Result: ${hasReflectFields}');
        // trace("[XRay ReflectionCompiler] CHECK EXPRESSION END");
        #end
        
        return hasReflectFields;
    }
    
    /**
     * Check if expression list has Reflect.fields iteration patterns
     * 
     * WHY: Detect reflection patterns in arrays of expressions
     * 
     * WHAT: Checks multiple expressions for Reflect.fields usage
     * 
     * HOW: Iterates through expression array and checks each for reflection patterns
     * 
     * @param expressions Array of expressions to check
     * @return True if any expressions contain reflection patterns
     */
    public function hasReflectFieldsIteration(expressions: Array<TypedExpr>): Bool {
        #if debug_reflection_compiler
        // trace("[XRay ReflectionCompiler] CHECK EXPRESSIONS ARRAY START");
        // trace('[XRay ReflectionCompiler] Checking ${expressions.length} expressions');
        #end
        
        for (expr in expressions) {
            if (checkForReflectFieldsInExpression(expr)) {
                #if debug_reflection_compiler
                // trace("[XRay ReflectionCompiler] ✓ REFLECTION FOUND");
                // trace("[XRay ReflectionCompiler] CHECK EXPRESSIONS ARRAY END");
                #end
                return true;
            }
        }
        
        #if debug_reflection_compiler
        // trace("[XRay ReflectionCompiler] No reflection patterns found");
        // trace("[XRay ReflectionCompiler] CHECK EXPRESSIONS ARRAY END");
        #end
        
        return false;
    }
    
    /**
     * Transform reflection statements with proper Map operations
     * 
     * WHY: Convert individual reflection statements to idiomatic Elixir
     * 
     * WHAT: Transforms Reflect calls and assignments to Map operations
     * 
     * HOW:
     * 1. Detect Reflect.setField and Reflect.field calls
     * 2. Convert to Map.put and Map.get operations
     * 3. Handle assignments and variable declarations properly
     * 
     * @param expr Expression to transform
     * @param targetObject Target object for operations
     * @param fieldVar Field variable name
     * @return Transformed Elixir code
     */
    public function transformReflectStatement(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        #if debug_reflection_compiler
        // trace("[XRay ReflectionCompiler] TRANSFORM STATEMENT START");
        // trace('[XRay ReflectionCompiler] Expr: ${expr.expr}, Target: ${targetObject}, Field: ${fieldVar}');
        #end
        
        var result = switch (expr.expr) {
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
                                
                                // Replace complex field expressions with simple variable
                                if (StringTools.contains(field, "Enum.at") || StringTools.contains(field, "field")) {
                                    field = fieldVar;
                                }
                                
                                target + " = Map.put(" + target + ", " + field + ", " + value + ")";
                            } else if (methodName == "field" && args.length >= 2) {
                                var source = compiler.compileExpression(args[0]);
                                var field = compiler.compileExpression(args[1]);
                                
                                if (StringTools.contains(field, "Enum.at") || StringTools.contains(field, "field")) {
                                    field = fieldVar;
                                }
                                
                                "Map.get(" + source + ", " + field + ")";
                            } else {
                                compiler.compileExpression(expr);
                            }
                        } else {
                            compiler.compileExpression(expr);
                        }
                    case _:
                        compiler.compileExpression(expr);
                }
                
            case TBinop(_, e1, e2):
                var left = compiler.compileExpression(e1);
                var right = transformReflectStatement(e2, targetObject, fieldVar);
                left + " = " + right;
                
            case TVar(v, init):
                var varName = compiler.getOriginalVarName(v);
                if (varName == "field" || StringTools.contains(varName, "field")) {
                    ""; // Skip field variable declarations
                } else if (init != null) {
                    var value = transformReflectStatement(init, targetObject, fieldVar);
                    varName + " = " + value;
                } else {
                    "";
                }
                
            case _:
                compiler.compileExpression(expr);
        };
        
        #if debug_reflection_compiler
        // trace('[XRay ReflectionCompiler] Generated: ${result}');
        // trace("[XRay ReflectionCompiler] TRANSFORM STATEMENT END");
        #end
        
        return result;
    }
    
    /**
     * Transform reflection expressions with Map operations
     * 
     * WHY: Handle reflection expressions in complex contexts
     * 
     * WHAT: Transforms reflection expressions while preserving context
     * 
     * HOW: Similar to transformReflectStatement but for expression contexts
     * 
     * @param expr Expression to transform
     * @param targetObject Target object for operations
     * @param fieldVar Field variable name
     * @return Transformed Elixir expression
     */
    public function transformReflectExpression(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        #if debug_reflection_compiler
        // trace("[XRay ReflectionCompiler] TRANSFORM EXPRESSION START");
        // trace('[XRay ReflectionCompiler] Expr: ${expr.expr}');
        #end
        
        var result = switch (expr.expr) {
            case TCall(e, args):
                switch (e.expr) {
                    case TField(obj, fa):
                        var objStr = compiler.compileExpression(obj);
                        var methodName = compiler.getFieldName(fa);
                        
                        if (objStr == "Reflect" && methodName == "field" && args.length >= 2) {
                            var source = compiler.compileExpression(args[0]);
                            var field = compiler.compileExpression(args[1]);
                            
                            if (StringTools.contains(field, "Enum.at") || StringTools.contains(field, "field")) {
                                field = fieldVar;
                            }
                            
                            "Map.get(" + source + ", " + field + ")";
                        } else {
                            compiler.compileExpression(expr);
                        }
                    case _:
                        compiler.compileExpression(expr);
                }
            case _:
                compiler.compileExpression(expr);
        };
        
        #if debug_reflection_compiler
        // trace('[XRay ReflectionCompiler] Generated: ${result}');
        // trace("[XRay ReflectionCompiler] TRANSFORM EXPRESSION END");
        #end
        
        return result;
    }
}

#end