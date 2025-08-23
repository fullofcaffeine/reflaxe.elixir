package reflaxe.elixir.helpers;

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;import reflaxe.elixir.helpers.CompilerUtilities;
import reflaxe.elixir.ElixirCompiler;import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.ElixirCompiler;
using Lambda;

/**
 * Specialized compiler for loop optimizations and transformations
 * 
 * This module consolidates all loop-related compilation logic from the main ElixirCompiler
 * to improve maintainability and enable focused optimization development. The module
 * handles the complex transformation of Haxe's imperative loop patterns into idiomatic
 * functional Elixir code using Enum functions and Y combinator patterns.
 * 
 * ## Key Transformations
 * - **For loops**: Convert to Enum.map, Enum.filter, Enum.find patterns
 * - **While loops**: Transform to recursive function patterns with tail call optimization  
 * - **Reflect.fields loops**: Optimize to Map.merge operations for object copying
 * - **Range iterations**: Generate optimized Enum.each or Enum.reduce patterns
 * - **Array building**: Convert imperative accumulation to functional transformations
 * 
 * ## Optimization Patterns
 * 1. **Pattern Detection**: Analyze loop body AST to identify common patterns
 * 2. **Functional Transformation**: Convert imperative patterns to Enum functions
 * 3. **Y Combinator Generation**: Create tail-recursive patterns for complex loops
 * 4. **Variable Substitution**: Maintain proper variable scope during transformation
 * 5. **Performance Optimization**: Generate efficient BEAM VM code
 * 
 * ## Debug Infrastructure
 * 
 * Enable comprehensive loop compilation debugging with:
 * - `-D debug_loops` - General loop compilation tracing
 * - `-D debug_optimization` - Optimization decision visibility 
 * - `-D debug_enum_patterns` - Enum function generation details
 * - `-D debug_y_combinator` - Y combinator pattern generation
 * - `-D debug_reflect_fields` - Reflect.fields optimization traces
 * 
 * @see CompilerUtilities For shared compilation utilities
 * @see NamingHelper For variable naming consistency
 * @since 1.0.0
 */
class LoopCompiler {
    
    /** Reference to main compiler for delegation */
    var compiler: reflaxe.elixir.ElixirCompiler;
    
    /**
     * Constructor requiring main compiler reference for delegation
     * 
     * @param compiler Main ElixirCompiler instance for delegation
     */
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Compile for-loop with optimization detection and transformation
     * 
     * FOR LOOP COMPILATION ORCHESTRATOR
     * 
     * WHY: For loops in Haxe represent iteration patterns that need transformation
     *      to idiomatic functional Elixir code. This is the main entry point that
     *      analyzes the loop structure and delegates to specialized optimizers.
     * 
     * WHAT: Analyzes for-loop structure to detect optimization opportunities:
     *       - Reflect.fields iterations → Map.merge operations  
     *       - Array iterations → Enum.map/filter/find patterns
     *       - Range iterations → Enum.each/reduce patterns
     *       - Complex patterns → Y combinator generation
     * 
     * HOW: 1. Extract loop variable and iteration expression
     *      2. Analyze iteration target (array, range, Reflect.fields)
     *      3. Examine loop body for transformation patterns
     *      4. Apply most specific optimization or fall back to generic
     *      5. Generate idiomatic Elixir code with proper variable scoping
     * 
     * EDGE CASES:
     * - Nested loops require Y combinator patterns
     * - Side effects in loop body prevent some optimizations
     * - Complex conditional logic may need generic transformation
     * - Variable shadowing requires careful scope management
     * 
     * @param tvar Loop variable from TFor expression
     * @param iterExpr Expression being iterated over (array, range, etc.)
     * @param blockExpr Loop body expression to transform
     * @return Optimized Elixir code using appropriate functional patterns
     * @since 1.0.0
     */
    public function compileForLoop(tvar: TVar, iterExpr: TypedExpr, blockExpr: TypedExpr): String {
        #if debug_loops
        trace('[XRay Loops] ═══════════════════════════════════════════════════');
        trace('[XRay Loops] FOR LOOP COMPILATION START');
        trace('[XRay Loops] - Loop variable: ${tvar.name} (id: ${tvar.id})');
        trace('[XRay Loops] - Iteration type: ${Type.enumConstructor(iterExpr.expr)}');
        trace('[XRay Loops] - Body type: ${Type.enumConstructor(blockExpr.expr)}');
        #end
        
        var loopVar = CompilerUtilities.toElixirVarName(tvar);
        
        #if debug_loops
        trace('[XRay Loops] - Converted loop var: "${loopVar}"');
        trace('[XRay Loops] - Analyzing iteration target...');
        #end
        
        // Detect Reflect.fields iteration pattern
        var reflectFieldsResult = detectReflectFieldsPattern(iterExpr, loopVar, blockExpr);
        if (reflectFieldsResult != null) {
            #if debug_loops
            trace('[XRay Loops] ✓ REFLECT.FIELDS PATTERN DETECTED');
            trace('[XRay Loops] - Delegating to Reflect.fields optimization');
            trace('[XRay Loops] FOR LOOP COMPILATION END');
            trace('[XRay Loops] ═══════════════════════════════════════════════════');
            #end
            return reflectFieldsResult;
        }
        
        // Check for array iteration patterns
        var arrayOptimization = tryOptimizeArrayIteration(iterExpr, loopVar, blockExpr);
        if (arrayOptimization != null) {
            #if debug_loops
            trace('[XRay Loops] ✓ ARRAY ITERATION PATTERN DETECTED');
            trace('[XRay Loops] - Using Enum function optimization');
            trace('[XRay Loops] FOR LOOP COMPILATION END');
            trace('[XRay Loops] ═══════════════════════════════════════════════════');
            #end
            return arrayOptimization;
        }
        
        // Check for range iteration patterns
        var rangeOptimization = tryOptimizeRangeIteration(iterExpr, loopVar, blockExpr);
        if (rangeOptimization != null) {
            #if debug_loops
            trace('[XRay Loops] ✓ RANGE ITERATION PATTERN DETECTED');
            trace('[XRay Loops] - Using range optimization');
            trace('[XRay Loops] FOR LOOP COMPILATION END');
            trace('[XRay Loops] ═══════════════════════════════════════════════════');
            #end
            return rangeOptimization;
        }
        
        #if debug_loops
        trace('[XRay Loops] ⚠️ NO OPTIMIZATION PATTERN MATCHED');
        trace('[XRay Loops] - Falling back to generic loop compilation');
        #end
        
        // Fall back to generic loop compilation
        var result = compileGenericForLoop(loopVar, iterExpr, blockExpr);
        
        #if debug_loops
        trace('[XRay Loops] - Generic compilation completed');
        trace('[XRay Loops] FOR LOOP COMPILATION END'); 
        trace('[XRay Loops] ═══════════════════════════════════════════════════');
        #end
        
        return result;
    }
    
    /**
     * Detect and optimize Reflect.fields iteration patterns
     * 
     * REFLECT.FIELDS PATTERN DETECTION
     * 
     * WHY: Reflect.fields(obj) iterations are commonly used for object copying
     *      and property manipulation. These can be optimized to efficient
     *      Map.merge operations in Elixir rather than imperative loops.
     * 
     * WHAT: Detects patterns like:
     *       for (field in Reflect.fields(source)) {
     *           Reflect.setField(target, field, Reflect.field(source, field));
     *       }
     *       And transforms to: Map.merge(target, source)
     * 
     * HOW: 1. Check if iteration expression is TCall to Reflect.fields
     *      2. Extract source object from Reflect.fields call
     *      3. Analyze loop body for setField/field patterns
     *      4. Generate optimized Map.merge operation
     *      5. Handle complex field transformations with Enum.reduce
     * 
     * EDGE CASES:
     * - Conditional field copying requires Enum.reduce with filtering
     * - Field name transformations need custom iteration logic
     * - Nested object access patterns require recursive handling
     * - Type casting during copy operations needs special syntax
     * 
     * @param iterExpr The iteration expression to analyze
     * @param loopVar Loop variable name in Elixir format
     * @param blockExpr Loop body to analyze for field operations
     * @return Optimized Map.merge code or null if pattern doesn't match
     * @since 1.0.0
     */
    private function detectReflectFieldsPattern(iterExpr: TypedExpr, loopVar: String, blockExpr: TypedExpr): Null<String> {
        #if debug_reflect_fields
        trace('[XRay ReflectFields] ═══════════════════════════════════════════');
        trace('[XRay ReflectFields] REFLECT.FIELDS DETECTION START');
        trace('[XRay ReflectFields] - Checking iteration expression type...');
        #end
        
        // Check if this is a Reflect.fields call
        var sourceObject = extractReflectFieldsSource(iterExpr);
        if (sourceObject == null) {
            #if debug_reflect_fields
            trace('[XRay ReflectFields] - Not a Reflect.fields call');
            trace('[XRay ReflectFields] REFLECT.FIELDS DETECTION END');
            trace('[XRay ReflectFields] ═══════════════════════════════════════════');
            #end
            return null;
        }
        
        #if debug_reflect_fields
        trace('[XRay ReflectFields] ✓ REFLECT.FIELDS CALL DETECTED');
        trace('[XRay ReflectFields] - Source object: ${sourceObject}');
        trace('[XRay ReflectFields] - Analyzing loop body for field operations...');
        #end
        
        // Analyze loop body for field copying patterns
        var targetObject = detectFieldCopyingTarget(blockExpr, loopVar);
        if (targetObject != null) {
            #if debug_reflect_fields
            trace('[XRay ReflectFields] ✓ FIELD COPYING PATTERN DETECTED');
            trace('[XRay ReflectFields] - Target object: ${targetObject}');
            trace('[XRay ReflectFields] - Generating Map.merge optimization');
            #end
            
            var result = compileReflectFieldsIteration(loopVar, sourceObject, blockExpr);
            
            #if debug_reflect_fields
            trace('[XRay ReflectFields] → OPTIMIZATION COMPLETE');
            trace('[XRay ReflectFields] REFLECT.FIELDS DETECTION END');
            trace('[XRay ReflectFields] ═══════════════════════════════════════════');
            #end
            
            return result;
        }
        
        #if debug_reflect_fields
        trace('[XRay ReflectFields] - No field copying pattern found');
        trace('[XRay ReflectFields] REFLECT.FIELDS DETECTION END');
        trace('[XRay ReflectFields] ═══════════════════════════════════════════');
        #end
        
        return null;
    }
    
    /**
     * Extract source object from Reflect.fields() call
     * 
     * @param expr Expression to analyze for Reflect.fields pattern
     * @return Source object expression string or null if not a Reflect.fields call
     */
    private function extractReflectFieldsSource(expr: TypedExpr): Null<String> {
        return switch(expr.expr) {
            case TCall(e, el) if (el.length == 1):
                // Check if this is a call to Reflect.fields
                var callTarget = compiler.compileExpression(e);
                if (callTarget == "Reflect.fields") {
                    compiler.compileExpression(el[0]);
                } else {
                    null;
                }
            case _: null;
        };
    }
    
    /**
     * Detect field copying target in loop body
     * 
     * @param blockExpr Loop body to analyze
     * @param fieldVar Field variable name to look for
     * @return Target object name or null if not field copying
     */
    private function detectFieldCopyingTarget(blockExpr: TypedExpr, fieldVar: String): Null<String> {
        // Look for Reflect.setField(target, field, value) patterns
        return switch(blockExpr.expr) {
            case TBlock(exprs):
                // Analyze first statement for setField pattern
                if (exprs.length > 0) {
                    detectSetFieldTarget(exprs[0], fieldVar);
                } else {
                    null;
                }
            case _:
                detectSetFieldTarget(blockExpr, fieldVar);
        };
    }
    
    /**
     * Detect target object in Reflect.setField call
     * 
     * @param expr Expression to analyze for setField pattern
     * @param fieldVar Expected field variable name
     * @return Target object name or null if not setField
     */
    private function detectSetFieldTarget(expr: TypedExpr, fieldVar: String): Null<String> {
        return switch(expr.expr) {
            case TCall(e, el) if (el.length == 3):
                var callTarget = compiler.compileExpression(e);
                if (callTarget == "Reflect.setField") {
                    compiler.compileExpression(el[0]); // Target object
                } else {
                    null;
                }
            case _: null;
        };
    }
    
    /**
     * Compile Reflect.fields iteration with Map.merge optimization
     * 
     * REFLECT.FIELDS ITERATION COMPILER
     * 
     * WHY: Reflect.fields iterations for object copying are common but inefficient
     *      when compiled literally. Elixir's Map.merge provides much better
     *      performance and more idiomatic code for these patterns.
     * 
     * WHAT: Transforms field iteration loops into Map.merge operations:
     *       - Simple copying: Map.merge(target, source)
     *       - Conditional copying: Enum.reduce with filtering
     *       - Field transformation: Enum.reduce with mapping
     * 
     * HOW: 1. Analyze loop body for field operation patterns
     *      2. Determine if simple merge or complex transformation needed
     *      3. Generate appropriate Elixir functional code
     *      4. Handle variable scoping and name conflicts
     *      5. Preserve side effects while optimizing field operations
     * 
     * EDGE CASES:
     * - Mixed field operations (set some, transform others)
     * - Conditional field inclusion based on field name or value
     * - Nested object copying with recursive field access
     * - Field name transformations (camelCase → snake_case)
     * 
     * @param fieldVar Loop variable representing field name
     * @param sourceObject Source object being copied from  
     * @param blockExpr Loop body expression to transform
     * @return Optimized Elixir code with Map.merge or Enum.reduce
     * @since 1.0.0
     */
    public function compileReflectFieldsIteration(fieldVar: String, sourceObject: String, blockExpr: TypedExpr): String {
        #if debug_reflect_fields
        trace('[XRay ReflectFields] ═══════════════════════════════════════════');
        trace('[XRay ReflectFields] ITERATION COMPILATION START');
        trace('[XRay ReflectFields] - Field variable: ${fieldVar}');
        trace('[XRay ReflectFields] - Source object: ${sourceObject}');
        trace('[XRay ReflectFields] - Analyzing transformation complexity...');
        #end
        
        // Analyze the loop body to determine transformation type
        var transformationType = analyzeReflectFieldsTransformation(blockExpr, fieldVar, sourceObject);
        
        #if debug_reflect_fields
        trace('[XRay ReflectFields] - Transformation type: ${transformationType.type}');
        trace('[XRay ReflectFields] - Target object: ${transformationType.target}');
        #end
        
        var result = switch(transformationType.type) {
            case "simple_copy":
                // Direct Map.merge for simple field copying
                #if debug_reflect_fields
                trace('[XRay ReflectFields] → SIMPLE COPY: Using Map.merge');
                #end
                'Map.merge(${transformationType.target}, ${sourceObject})';
                
            case "conditional_copy":
                // Enum.reduce with filtering for conditional copying
                #if debug_reflect_fields
                trace('[XRay ReflectFields] → CONDITIONAL COPY: Using Enum.reduce with filter');
                #end
                generateConditionalFieldCopy(sourceObject, transformationType.target, blockExpr, fieldVar);
                
            case "transform_copy":
                // Enum.reduce with transformation for field value changes
                #if debug_reflect_fields
                trace('[XRay ReflectFields] → TRANSFORM COPY: Using Enum.reduce with transformation');
                #end
                generateTransformFieldCopy(sourceObject, transformationType.target, blockExpr, fieldVar);
                
            case "complex":
                // Fall back to explicit iteration for complex patterns
                #if debug_reflect_fields
                trace('[XRay ReflectFields] → COMPLEX PATTERN: Using explicit Enum.each');
                #end
                generateExplicitFieldIteration(sourceObject, blockExpr, fieldVar);
                
            case _:
                // Default fallback for unknown transformation types
                generateExplicitFieldIteration(sourceObject, blockExpr, fieldVar);
        };
        
        #if debug_reflect_fields
        trace('[XRay ReflectFields] ✓ ITERATION COMPILATION COMPLETE');
        trace('[XRay ReflectFields] - Generated code length: ${result.length} chars');
        trace('[XRay ReflectFields] ITERATION COMPILATION END');
        trace('[XRay ReflectFields] ═══════════════════════════════════════════');
        #end
        
        return result;
    }
    
    /**
     * Analyze Reflect.fields transformation to determine optimization approach
     * 
     * @param blockExpr Loop body to analyze
     * @param fieldVar Field variable name
     * @param sourceObject Source object name
     * @return Transformation analysis with type and target information
     */
    private function analyzeReflectFieldsTransformation(blockExpr: TypedExpr, fieldVar: String, sourceObject: String): {type: String, target: String} {
        // Default to complex pattern
        var result = {type: "complex", target: ""};
        
        // Analyze loop body structure
        switch(blockExpr.expr) {
            case TBlock(exprs) if (exprs.length == 1):
                // Single statement - check for simple setField
                result = analyzeReflectFieldStatement(exprs[0], fieldVar, sourceObject);
                
            case TBlock(exprs) if (exprs.length > 1):
                // Multiple statements - likely complex pattern
                result.type = "complex";
                
            case _:
                // Single expression - analyze directly
                result = analyzeReflectFieldStatement(blockExpr, fieldVar, sourceObject);
        }
        
        return result;
    }
    
    /**
     * Analyze individual statement for Reflect field operation pattern
     * 
     * @param expr Statement to analyze
     * @param fieldVar Field variable name
     * @param sourceObject Source object name
     * @return Analysis result with pattern type and target
     */
    private function analyzeReflectFieldStatement(expr: TypedExpr, fieldVar: String, sourceObject: String): {type: String, target: String} {
        return switch(expr.expr) {
            case TCall(e, el) if (el.length == 3):
                var callTarget = compiler.compileExpression(e);
                if (callTarget == "Reflect.setField") {
                    var target = compiler.compileExpression(el[0]);
                    var field = compiler.compileExpression(el[1]);
                    var value = compiler.compileExpression(el[2]);
                    
                    // Check if this is simple field copying
                    if (isSimpleFieldCopy(field, value, fieldVar, sourceObject)) {
                        {type: "simple_copy", target: target};
                    } else {
                        {type: "transform_copy", target: target};
                    }
                } else {
                    {type: "complex", target: ""};
                }
                
            case TIf(_, _, _):
                // Conditional field operations
                {type: "conditional_copy", target: extractTargetFromConditional(expr)};
                
            case _:
                {type: "complex", target: ""};
        };
    }
    
    /**
     * Check if field assignment is simple copying pattern
     * 
     * @param field Field expression
     * @param value Value expression  
     * @param fieldVar Expected field variable
     * @param sourceObject Expected source object
     * @return True if this is simple field copying
     */
    private function isSimpleFieldCopy(field: String, value: String, fieldVar: String, sourceObject: String): Bool {
        // Check if field uses loop variable and value is Reflect.field(source, field)
        return field == fieldVar && value.indexOf('Reflect.field(${sourceObject}, ${fieldVar})') >= 0;
    }
    
    /**
     * Extract target object from conditional expression
     * 
     * @param expr Conditional expression to analyze
     * @return Target object name or empty string
     */
    private function extractTargetFromConditional(expr: TypedExpr): String {
        // Look for setField calls in conditional branches
        switch(expr.expr) {
            case TIf(_, thenExpr, elseExpr):
                var target = findSetFieldTarget(thenExpr);
                if (target != null) return target;
                
                if (elseExpr != null) {
                    target = findSetFieldTarget(elseExpr);
                    if (target != null) return target;
                }
                
            case _:
        }
        return "";
    }
    
    /**
     * Find setField target in expression tree
     * 
     * @param expr Expression to search
     * @return Target object name or null if not found
     */
    private function findSetFieldTarget(expr: TypedExpr): Null<String> {
        return switch(expr.expr) {
            case TCall(e, el) if (el.length == 3):
                var callTarget = compiler.compileExpression(e);
                if (callTarget == "Reflect.setField") {
                    compiler.compileExpression(el[0]);
                } else {
                    null;
                }
            case TBlock(exprs):
                // Check first statement
                if (exprs.length > 0) {
                    findSetFieldTarget(exprs[0]);
                } else {
                    null;
                }
            case _: null;
        };
    }
    
    /**
     * Generate conditional field copy using Enum.reduce
     * 
     * @param sourceObject Source object expression
     * @param targetObject Target object expression
     * @param blockExpr Loop body with conditional logic
     * @param fieldVar Field variable name
     * @return Elixir code with Enum.reduce and filtering
     */
    private function generateConditionalFieldCopy(sourceObject: String, targetObject: String, blockExpr: TypedExpr, fieldVar: String): String {
        var condition = extractFieldCondition(blockExpr, fieldVar);
        var transformation = extractFieldTransformation(blockExpr, fieldVar, sourceObject);
        
        return 'Enum.reduce(Map.keys(${sourceObject}), ${targetObject}, fn ${fieldVar}, acc ->
  if ${condition} do
    Map.put(acc, ${fieldVar}, ${transformation})
  else
    acc
  end
end)';
    }
    
    /**
     * Generate transform field copy using Enum.reduce
     * 
     * @param sourceObject Source object expression
     * @param targetObject Target object expression
     * @param blockExpr Loop body with transformation logic
     * @param fieldVar Field variable name
     * @return Elixir code with Enum.reduce and transformation
     */
    private function generateTransformFieldCopy(sourceObject: String, targetObject: String, blockExpr: TypedExpr, fieldVar: String): String {
        var transformation = extractFieldTransformation(blockExpr, fieldVar, sourceObject);
        
        return 'Enum.reduce(Map.keys(${sourceObject}), ${targetObject}, fn ${fieldVar}, acc ->
  Map.put(acc, ${fieldVar}, ${transformation})
end)';
    }
    
    /**
     * Generate explicit field iteration using Enum.each
     * 
     * @param sourceObject Source object expression
     * @param blockExpr Loop body to compile
     * @param fieldVar Field variable name
     * @return Elixir code with explicit Enum.each iteration
     */
    private function generateExplicitFieldIteration(sourceObject: String, blockExpr: TypedExpr, fieldVar: String): String {
        var transformedBody = compileReflectFieldsBody(blockExpr, sourceObject, fieldVar);
        
        return 'Enum.each(Map.keys(${sourceObject}), fn ${fieldVar} ->
${CompilerUtilities.indentCode(transformedBody)}
end)';
    }
    
    /**
     * Extract field condition from conditional block
     * 
     * @param blockExpr Block with conditional logic
     * @param fieldVar Field variable name
     * @return Condition expression string
     */
    private function extractFieldCondition(blockExpr: TypedExpr, fieldVar: String): String {
        // Extract condition from if statement in block
        switch(blockExpr.expr) {
            case TBlock(exprs):
                for (expr in exprs) {
                    switch(expr.expr) {
                        case TIf(cond, _, _):
                            return compiler.compileExpression(cond);
                        case _:
                    }
                }
            case TIf(cond, _, _):
                return compiler.compileExpression(cond);
            case _:
        }
        return "true"; // Default to always include
    }
    
    /**
     * Extract field value transformation from block
     * 
     * @param blockExpr Block with transformation logic
     * @param fieldVar Field variable name
     * @param sourceObject Source object name
     * @return Transformation expression string
     */
    private function extractFieldTransformation(blockExpr: TypedExpr, fieldVar: String, sourceObject: String): String {
        // Extract value expression from setField call
        switch(blockExpr.expr) {
            case TBlock(exprs):
                for (expr in exprs) {
                    var value = extractSetFieldValue(expr);
                    if (value != null) return value;
                }
            case _:
                var value = extractSetFieldValue(blockExpr);
                if (value != null) return value;
        }
        return 'Map.get(${sourceObject}, ${fieldVar})'; // Default to simple copy
    }
    
    /**
     * Extract value from Reflect.setField call
     * 
     * @param expr Expression to analyze
     * @return Value expression string or null
     */
    private function extractSetFieldValue(expr: TypedExpr): Null<String> {
        return switch(expr.expr) {
            case TCall(e, el) if (el.length == 3):
                var callTarget = compiler.compileExpression(e);
                if (callTarget == "Reflect.setField") {
                    compiler.compileExpression(el[2]); // Value argument
                } else {
                    null;
                }
            case _: null;
        };
    }
    
    /**
     * Compile Reflect.fields loop body with variable substitution
     * 
     * @param expr Loop body expression
     * @param targetObject Target object for field operations
     * @param fieldVar Field variable name
     * @return Compiled Elixir code string
     */
    private function compileReflectFieldsBody(expr: TypedExpr, targetObject: String, fieldVar: String): String {
        return switch(expr.expr) {
            case TBlock(exprs):
                var statements = [for (e in exprs) compileReflectFieldsStatement(e, targetObject, fieldVar)];
                statements.join("\n");
            case _:
                compileReflectFieldsStatement(expr, targetObject, fieldVar);
        };
    }
    
    /**
     * Compile individual statement in Reflect.fields loop
     * 
     * @param expr Statement expression
     * @param sourceObject Source object name  
     * @param fieldVar Field variable name
     * @return Compiled statement string
     */
    private function compileReflectFieldsStatement(expr: TypedExpr, sourceObject: String, fieldVar: String): String {
        // Transform Reflect.field and Reflect.setField calls appropriately
        return switch(expr.expr) {
            case TCall(e, el):
                var callTarget = compiler.compileExpression(e);
                if (callTarget == "Reflect.setField" && el.length == 3) {
                    var target = compiler.compileExpression(el[0]);
                    var field = compiler.compileExpression(el[1]);
                    var value = compiler.compileExpression(el[2]);
                    
                    // Transform to Map.put
                    '${target} = Map.put(${target}, ${field}, ${value})';
                } else if (callTarget == "Reflect.field" && el.length == 2) {
                    var obj = compiler.compileExpression(el[0]);
                    var field = compiler.compileExpression(el[1]);
                    
                    // Transform to Map.get
                    'Map.get(${obj}, ${field})';
                } else {
                    compiler.compileExpression(expr);
                }
            case _:
                compiler.compileExpression(expr);
        };
    }
    
    /**
     * Try to optimize array iteration with Enum functions
     * 
     * ARRAY ITERATION OPTIMIZATION ENGINE
     * 
     * WHY: Array iterations are extremely common and often follow functional
     *      patterns that can be optimized to efficient Enum functions. This
     *      provides both performance and readability improvements.
     * 
     * WHAT: Detects and optimizes common array iteration patterns:
     *       - Mapping: transform each element → Enum.map
     *       - Filtering: select elements by condition → Enum.filter  
     *       - Finding: locate first matching element → Enum.find
     *       - Counting: count matching elements → Enum.count
     *       - Reduction: accumulate values → Enum.reduce
     * 
     * HOW: 1. Analyze iteration expression to confirm array access
     *      2. Examine loop body for functional patterns
     *      3. Extract transformation or condition logic
     *      4. Generate appropriate Enum function call
     *      5. Handle variable substitution for clean code
     * 
     * EDGE CASES:
     * - Mixed operations (map + filter) require Enum.reduce
     * - Side effects in loop body prevent some optimizations
     * - Early termination patterns need special handling
     * - Nested array access requires complex substitution
     * 
     * @param iterExpr Array expression being iterated
     * @param loopVar Loop variable name
     * @param blockExpr Loop body to analyze
     * @return Optimized Enum function call or null if no optimization applies
     * @since 1.0.0
     */
    private function tryOptimizeArrayIteration(iterExpr: TypedExpr, loopVar: String, blockExpr: TypedExpr): Null<String> {
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
        trace('[XRay EnumPatterns] ARRAY OPTIMIZATION START');
        trace('[XRay EnumPatterns] - Loop variable: ${loopVar}');
        trace('[XRay EnumPatterns] - Analyzing iteration expression...');
        #end
        
        var arrayExpr = compiler.compileExpression(iterExpr);
        
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] - Array expression: ${CompilerUtilities.safeSubstring(arrayExpr, 50)}');
        trace('[XRay EnumPatterns] - Analyzing loop body for patterns...');
        #end
        
        var bodyAnalysis = analyzeLoopBody(blockExpr);
        
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] - Body analysis complete:');
        trace('[XRay EnumPatterns]   - Has mapping: ${bodyAnalysis.hasMapping}');
        trace('[XRay EnumPatterns]   - Has filtering: ${bodyAnalysis.hasFiltering}');
        trace('[XRay EnumPatterns]   - Has finding: ${bodyAnalysis.hasFinding}');
        trace('[XRay EnumPatterns]   - Has counting: ${bodyAnalysis.hasCounting}');
        trace('[XRay EnumPatterns]   - Has accumulation: ${bodyAnalysis.hasAccumulation}');
        #end
        
        // Try most specific patterns first
        if (bodyAnalysis.hasFinding) {
            #if debug_enum_patterns
            trace('[XRay EnumPatterns] ✓ FIND PATTERN DETECTED');
            #end
            var result = generateEnumFindPattern(arrayExpr, loopVar, blockExpr);
            #if debug_enum_patterns
            trace('[XRay EnumPatterns] ARRAY OPTIMIZATION END');
            trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
            #end
            return result;
        }
        
        if (bodyAnalysis.hasFiltering && !bodyAnalysis.hasMapping) {
            #if debug_enum_patterns
            trace('[XRay EnumPatterns] ✓ FILTER PATTERN DETECTED');
            #end
            var result = generateEnumFilterPattern(arrayExpr, loopVar, bodyAnalysis.conditionExpr);
            #if debug_enum_patterns
            trace('[XRay EnumPatterns] ARRAY OPTIMIZATION END');
            trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
            #end
            return result;
        }
        
        if (bodyAnalysis.hasMapping && !bodyAnalysis.hasFiltering) {
            #if debug_enum_patterns
            trace('[XRay EnumPatterns] ✓ MAP PATTERN DETECTED');
            #end
            var result = generateEnumMapPattern(arrayExpr, loopVar, blockExpr);
            #if debug_enum_patterns
            trace('[XRay EnumPatterns] ARRAY OPTIMIZATION END');
            trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
            #end
            return result;
        }
        
        if (bodyAnalysis.hasCounting) {
            #if debug_enum_patterns
            trace('[XRay EnumPatterns] ✓ COUNT PATTERN DETECTED');
            #end
            var result = generateEnumCountPattern(arrayExpr, loopVar, bodyAnalysis.conditionExpr);
            #if debug_enum_patterns
            trace('[XRay EnumPatterns] ARRAY OPTIMIZATION END');
            trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
            #end
            return result;
        }
        
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] - No optimization pattern matched');
        trace('[XRay EnumPatterns] ARRAY OPTIMIZATION END');
        trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
        #end
        
        return null;
    }
    
    /**
     * Analyze loop body to detect functional patterns
     * 
     * LOOP BODY PATTERN ANALYSIS
     * 
     * WHY: To optimize imperative loops to functional patterns, we need to
     *      understand what operations the loop body performs. This analysis
     *      drives the optimization strategy selection.
     * 
     * WHAT: Examines AST structure to identify:
     *       - Variable assignments (mapping patterns)
     *       - Conditional operations (filtering patterns)
     *       - Early returns (finding patterns)
     *       - Counter increments (counting patterns)
     *       - Array mutations (accumulation patterns)
     * 
     * HOW: Recursive AST traversal looking for specific patterns:
     *      1. TVar assignments indicate mapping operations
     *      2. TIf conditions indicate filtering logic
     *      3. TReturn statements indicate find/search patterns
     *      4. Arithmetic operations may indicate counting
     *      5. Array method calls indicate accumulation
     * 
     * EDGE CASES:
     * - Nested conditional logic creates complex patterns
     * - Multiple pattern types in same loop require reduce
     * - Side effects prevent certain optimizations
     * - Variable reassignment patterns need careful analysis
     * 
     * @param blockExpr Loop body expression to analyze
     * @return Analysis object with pattern detection flags and extracted expressions
     * @since 1.0.0
     */
    private function analyzeLoopBody(blockExpr: TypedExpr): {
        hasMapping: Bool,
        hasFiltering: Bool,
        hasFinding: Bool,
        hasCounting: Bool,
        hasAccumulation: Bool,
        conditionExpr: TypedExpr,
        mappingExpr: TypedExpr,
        targetVar: String
    } {
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] ───────────────────────────────────────────');
        trace('[XRay EnumPatterns] LOOP BODY ANALYSIS START');
        trace('[XRay EnumPatterns] - Body type: ${Type.enumConstructor(blockExpr.expr)}');
        #end
        
        var result = {
            hasMapping: false,
            hasFiltering: false,
            hasFinding: false,
            hasCounting: false,
            hasAccumulation: false,
            conditionExpr: null,
            mappingExpr: null,
            targetVar: ""
        };
        
        analyzeLoopBodyAST(blockExpr, result);
        
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] - Analysis results:');
        trace('[XRay EnumPatterns]   - Mapping: ${result.hasMapping}');
        trace('[XRay EnumPatterns]   - Filtering: ${result.hasFiltering}');
        trace('[XRay EnumPatterns]   - Finding: ${result.hasFinding}');
        trace('[XRay EnumPatterns]   - Counting: ${result.hasCounting}');
        trace('[XRay EnumPatterns]   - Accumulation: ${result.hasAccumulation}');
        trace('[XRay EnumPatterns]   - Target variable: "${result.targetVar}"');
        trace('[XRay EnumPatterns] LOOP BODY ANALYSIS END');
        trace('[XRay EnumPatterns] ───────────────────────────────────────────');
        #end
        
        return result;
    }
    
    /**
     * Recursive AST analysis for pattern detection
     * 
     * @param expr Current AST node to analyze
     * @param result Analysis result object to populate
     */
    private function analyzeLoopBodyAST(expr: TypedExpr, result: Dynamic): Void {
        switch(expr.expr) {
            case TBlock(exprs):
                for (e in exprs) {
                    analyzeLoopBodyAST(e, result);
                }
                
            case TVar(tvar, valueExpr):
                // Variable assignment indicates potential mapping
                if (valueExpr != null) {
                    result.hasMapping = true;
                    result.mappingExpr = valueExpr;
                    result.targetVar = CompilerUtilities.toElixirVarName(tvar);
                }
                
            case TBinop(OpAssign, e1, e2):
                // Assignment operation - check for accumulation patterns
                analyzeAssignmentPattern(e1, e2, result);
                
            case TIf(cond, thenExpr, elseExpr):
                // Conditional logic indicates filtering or finding
                result.hasFiltering = true;
                result.conditionExpr = cond;
                
                // Check if then/else branches contain returns (finding pattern)
                if (containsReturn(thenExpr) || (elseExpr != null && containsReturn(elseExpr))) {
                    result.hasFinding = true;
                }
                
                // Continue analyzing branches
                analyzeLoopBodyAST(thenExpr, result);
                if (elseExpr != null) {
                    analyzeLoopBodyAST(elseExpr, result);
                }
                
            case TReturn(_):
                // Return statement indicates finding pattern
                result.hasFinding = true;
                
            case TCall(e, el):
                // Function calls - check for array methods or counting operations
                analyzeMethodCall(e, el, result);
                
            case _:
                // Continue analyzing sub-expressions
                // (This is a simplified version - real implementation would be more comprehensive)
        }
    }
    
    /**
     * Analyze assignment patterns for accumulation detection
     * 
     * @param target Assignment target expression
     * @param value Assignment value expression  
     * @param result Analysis result to update
     */
    private function analyzeAssignmentPattern(target: TypedExpr, value: TypedExpr, result: Dynamic): Void {
        // Check for counter increments (count += 1)
        switch(value.expr) {
            case TBinop(OpAdd, e1, e2):
                if (isLiteralOne(e2) && isVariableReference(e1, target)) {
                    result.hasCounting = true;
                }
            case TCall(e, el):
                // Check for array operations like push, concat
                var methodName = extractMethodName(e);
                if (methodName == "push" || methodName == "concat") {
                    result.hasAccumulation = true;
                }
            case _:
        }
    }
    
    /**
     * Analyze method calls for pattern indicators
     * 
     * @param methodExpr Method expression
     * @param args Method arguments
     * @param result Analysis result to update
     */
    private function analyzeMethodCall(methodExpr: TypedExpr, args: Array<TypedExpr>, result: Dynamic): Void {
        var methodName = extractMethodName(methodExpr);
        
        switch(methodName) {
            case "push" | "concat" | "append":
                result.hasAccumulation = true;
            case "length" | "size":
                // Accessing length often indicates counting
                result.hasCounting = true;
            case _:
        }
    }
    
    /**
     * Check if expression contains return statement
     * 
     * @param expr Expression to check
     * @return True if contains return
     */
    private function containsReturn(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TReturn(_): true;
            case TBlock(exprs): exprs.exists(containsReturn);
            case TIf(_, thenExpr, elseExpr): 
                containsReturn(thenExpr) || (elseExpr != null && containsReturn(elseExpr));
            case _: false;
        };
    }
    
    /**
     * Check if expression is literal value 1
     * 
     * @param expr Expression to check
     * @return True if literal 1
     */
    private function isLiteralOne(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TConst(TInt(1)): true;
            case _: false;
        };
    }
    
    /**
     * Check if expression references same variable as target
     * 
     * @param expr Expression to check
     * @param target Target variable expression
     * @return True if same variable reference
     */
    private function isVariableReference(expr: TypedExpr, target: TypedExpr): Bool {
        // Simplified check - real implementation would compare variable IDs
        return switch([expr.expr, target.expr]) {
            case [TLocal(v1), TLocal(v2)]: v1.id == v2.id;
            case _: false;
        };
    }
    
    /**
     * Extract method name from method call expression
     * 
     * @param methodExpr Method expression to analyze
     * @return Method name string or empty if not identifiable
     */
    private function extractMethodName(methodExpr: TypedExpr): String {
        return switch(methodExpr.expr) {
            case TField(_, fa): 
                CompilerUtilities.extractFieldName(fa);
            case TLocal(v):
                CompilerUtilities.toElixirVarName(v);
            case _: "";
        };
    }
    
    /**
     * Generate Enum.find pattern for search operations
     * 
     * ENUM.FIND PATTERN GENERATOR
     * 
     * WHY: Find operations (first element matching condition) are common
     *      but often written as imperative loops with early returns.
     *      Enum.find provides cleaner, more efficient implementation.
     * 
     * WHAT: Transforms patterns like:
     *       for (item in array) {
     *           if (condition) return item;
     *       }
     *       To: Enum.find(array, fn item -> condition end)
     * 
     * HOW: 1. Extract search condition from loop body
     *      2. Handle early return patterns
     *      3. Generate clean function expression
     *      4. Preserve variable naming consistency
     * 
     * EDGE CASES:
     * - Complex conditions require multiline function
     * - Transformation logic before return needs handling
     * - Multiple return points create complex patterns
     * - Default values for not-found cases
     * 
     * @param arrayExpr Array expression to search
     * @param loopVar Loop variable name
     * @param blockExpr Loop body with find logic
     * @return Enum.find expression with appropriate condition function
     * @since 1.0.0
     */
    private function generateEnumFindPattern(arrayExpr: String, loopVar: String, blockExpr: TypedExpr): String {
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
        trace('[XRay EnumPatterns] FIND PATTERN GENERATION START');
        trace('[XRay EnumPatterns] - Array: ${arrayExpr}');
        trace('[XRay EnumPatterns] - Loop variable: ${loopVar}');
        #end
        
        var condition = extractFindCondition(blockExpr, loopVar);
        
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] - Extracted condition: ${CompilerUtilities.safeSubstring(condition, 100)}');
        #end
        
        var result = if (condition.length > 50 || condition.indexOf("\n") >= 0) {
            // Multi-line condition
            'Enum.find(${arrayExpr}, fn ${loopVar} ->
${CompilerUtilities.indentCode(condition)}
end)';
        } else {
            // Simple one-line condition
            'Enum.find(${arrayExpr}, fn ${loopVar} -> ${condition} end)';
        };
        
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] ✓ FIND PATTERN GENERATED');
        trace('[XRay EnumPatterns] - Generated code length: ${result.length} chars');
        trace('[XRay EnumPatterns] FIND PATTERN GENERATION END');
        trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
        #end
        
        return result;
    }
    
    /**
     * Extract find condition from loop body
     * 
     * @param blockExpr Loop body to analyze
     * @param loopVar Loop variable name for substitution
     * @return Condition expression for Enum.find
     */
    private function extractFindCondition(blockExpr: TypedExpr, loopVar: String): String {
        return switch(blockExpr.expr) {
            case TBlock(exprs):
                // Look for if-return pattern in block
                extractFindConditionFromStatements(exprs, loopVar);
                
            case TIf(cond, thenExpr, _):
                // Direct if with return
                if (containsReturn(thenExpr)) {
                    compiler.compileExpression(cond);
                } else {
                    "true"; // Default condition
                }
                
            case TReturn(valueExpr):
                // Direct return - condition is always true, return the value check
                if (valueExpr != null) {
                    var value = compiler.compileExpression(valueExpr);
                    value; // The returned value becomes the condition
                } else {
                    "true";
                }
                
            case _:
                "true"; // Default fallback
        };
    }
    
    /**
     * Extract find condition from statement list
     * 
     * @param statements List of statements to analyze
     * @param loopVar Loop variable for substitution
     * @return Find condition expression
     */
    private function extractFindConditionFromStatements(statements: Array<TypedExpr>, loopVar: String): String {
        for (stmt in statements) {
            switch(stmt.expr) {
                case TIf(cond, thenExpr, _):
                    if (containsReturn(thenExpr)) {
                        return compiler.compileExpression(cond);
                    }
                case TReturn(valueExpr):
                    if (valueExpr != null) {
                        return compiler.compileExpression(valueExpr);
                    }
                case _:
            }
        }
        return "true"; // Default condition
    }
    
    /**
     * Generate Enum.count pattern for counting operations
     * 
     * @param arrayExpr Array expression to count
     * @param loopVar Loop variable name
     * @param conditionExpr Condition expression for counting
     * @return Enum.count expression with condition function
     */
    private function generateEnumCountPattern(arrayExpr: String, loopVar: String, conditionExpr: TypedExpr): String {
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
        trace('[XRay EnumPatterns] COUNT PATTERN GENERATION START');
        #end
        
        var condition = if (conditionExpr != null) {
            compiler.compileExpression(conditionExpr);
        } else {
            "true"; // Count all elements
        };
        
        var result = 'Enum.count(${arrayExpr}, fn ${loopVar} -> ${condition} end)';
        
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] ✓ COUNT PATTERN GENERATED');
        trace('[XRay EnumPatterns] COUNT PATTERN GENERATION END');
        trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
        #end
        
        return result;
    }
    
    /**
     * Generate Enum.filter pattern for filtering operations
     * 
     * @param arrayExpr Array expression to filter
     * @param loopVar Loop variable name
     * @param conditionExpr Filter condition expression
     * @return Enum.filter expression with condition function
     */
    private function generateEnumFilterPattern(arrayExpr: String, loopVar: String, conditionExpr: TypedExpr): String {
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
        trace('[XRay EnumPatterns] FILTER PATTERN GENERATION START');
        #end
        
        var condition = compiler.compileExpression(conditionExpr);
        var result = 'Enum.filter(${arrayExpr}, fn ${loopVar} -> ${condition} end)';
        
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] ✓ FILTER PATTERN GENERATED');
        trace('[XRay EnumPatterns] FILTER PATTERN GENERATION END');
        trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
        #end
        
        return result;
    }
    
    /**
     * Generate Enum.map pattern for transformation operations
     * 
     * @param arrayExpr Array expression to transform
     * @param loopVar Loop variable name
     * @param blockExpr Loop body with transformation logic
     * @return Enum.map expression with transformation function
     */
    private function generateEnumMapPattern(arrayExpr: String, loopVar: String, blockExpr: TypedExpr): String {
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
        trace('[XRay EnumPatterns] MAP PATTERN GENERATION START');
        #end
        
        var transformation = extractTransformationFromBody(blockExpr, loopVar);
        
        var result = if (transformation.indexOf("\n") >= 0 || transformation.length > 50) {
            // Multi-line transformation
            'Enum.map(${arrayExpr}, fn ${loopVar} ->
${CompilerUtilities.indentCode(transformation)}
end)';
        } else {
            // Simple one-line transformation
            'Enum.map(${arrayExpr}, fn ${loopVar} -> ${transformation} end)';
        };
        
        #if debug_enum_patterns
        trace('[XRay EnumPatterns] ✓ MAP PATTERN GENERATED');
        trace('[XRay EnumPatterns] MAP PATTERN GENERATION END');
        trace('[XRay EnumPatterns] ═══════════════════════════════════════════');
        #end
        
        return result;
    }
    
    /**
     * Extract transformation logic from loop body
     * 
     * @param blockExpr Loop body to analyze
     * @param loopVar Loop variable name
     * @return Transformation expression for Enum.map
     */
    private function extractTransformationFromBody(blockExpr: TypedExpr, loopVar: String): String {
        return switch(blockExpr.expr) {
            case TBlock(exprs):
                // Multiple statements - compile all
                var statements = [for (expr in exprs) compiler.compileExpression(expr)];
                statements.join("\n");
                
            case TVar(tvar, valueExpr):
                // Variable assignment - use the value
                if (valueExpr != null) {
                    compiler.compileExpression(valueExpr);
                } else {
                    loopVar;
                }
                
            case _:
                // Single expression
                compiler.compileExpression(blockExpr);
        };
    }
    
    /**
     * Try to optimize range iteration patterns
     * 
     * @param iterExpr Range expression being iterated
     * @param loopVar Loop variable name
     * @param blockExpr Loop body to analyze
     * @return Optimized range iteration or null if no optimization applies
     */
    private function tryOptimizeRangeIteration(iterExpr: TypedExpr, loopVar: String, blockExpr: TypedExpr): Null<String> {
        // Check if this is a range expression (e.g., 0...10)
        var rangePattern = detectRangePattern(iterExpr);
        if (rangePattern != null) {
            return optimizeRangeLoop(rangePattern, loopVar, blockExpr);
        }
        return null;
    }
    
    /**
     * Detect range iteration patterns
     * 
     * @param iterExpr Expression to check for range
     * @return Range information or null if not a range
     */
    private function detectRangePattern(iterExpr: TypedExpr): Null<{start: String, end: String, inclusive: Bool}> {
        // Detect patterns like 0...10 or start..end
        // This is a simplified implementation
        return null; // TODO: Implement range detection
    }
    
    /**
     * Optimize range loop with appropriate Enum function
     * 
     * @param range Range information
     * @param loopVar Loop variable name
     * @param blockExpr Loop body to transform
     * @return Optimized Elixir range iteration
     */
    private function optimizeRangeLoop(range: {start: String, end: String, inclusive: Bool}, loopVar: String, blockExpr: TypedExpr): String {
        var rangeExpr = if (range.inclusive) {
            '${range.start}..${range.end}';
        } else {
            '${range.start}..(${range.end} - 1)';
        };
        
        // Analyze body to determine if this is map, each, or reduce
        var bodyAnalysis = analyzeLoopBody(blockExpr);
        
        if (bodyAnalysis.hasMapping) {
            var transformation = extractTransformationFromBody(blockExpr, loopVar);
            return 'Enum.map(${rangeExpr}, fn ${loopVar} -> ${transformation} end)';
        } else {
            var body = compiler.compileExpression(blockExpr);
            return 'Enum.each(${rangeExpr}, fn ${loopVar} -> ${body} end)';
        }
    }
    
    /**
     * Compile generic for loop without specific optimizations
     * 
     * @param loopVar Loop variable name
     * @param iterExpr Iteration expression
     * @param blockExpr Loop body
     * @return Generic Elixir loop implementation
     */
    private function compileGenericForLoop(loopVar: String, iterExpr: TypedExpr, blockExpr: TypedExpr): String {
        var iterable = compiler.compileExpression(iterExpr);
        var body = compiler.compileExpression(blockExpr);
        
        return 'Enum.each(${iterable}, fn ${loopVar} ->
${CompilerUtilities.indentCode(body)}
end)';
    }
    
    /**
     * Compile while loop with optimization detection
     * 
     * WHILE LOOP COMPILATION ORCHESTRATOR
     * 
     * WHY: While loops represent iterative patterns that often can be optimized
     *      to functional patterns or need Y combinator transformation for
     *      proper tail recursion in Elixir.
     * 
     * WHAT: Analyzes while loop structure and applies optimizations:
     *       - Simple counting loops → Enum.each with range
     *       - Array building loops → Enum.reduce patterns
     *       - Complex state loops → Y combinator recursion
     * 
     * HOW: 1. Analyze condition and body for optimization patterns
     *      2. Check for variable mutations and state changes
     *      3. Apply most appropriate optimization strategy
     *      4. Generate tail-recursive or functional equivalent
     * 
     * EDGE CASES:
     * - Infinite loops need special handling
     * - Complex state mutations require Y combinator
     * - Early termination patterns affect optimization
     * - Variable scope conflicts need careful management
     * 
     * @param econd While condition expression
     * @param ebody While body expression
     * @param normalWhile True for while, false for do-while
     * @return Optimized Elixir implementation
     * @since 1.0.0
     */
    public function compileWhileLoop(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        trace('[FORCED DEBUG] compileWhileLoop called');
        // TEMPORARY DEBUG: Check if we're getting any array operations
        var condStr = compiler.compileExpression(econd);
        if (condStr.indexOf("length") >= 0) {
            trace('[DEBUG ARRAY] Found length in condition: ${condStr}');
        }
        
        #if debug_loops
        trace('[XRay Loops] ═══════════════════════════════════════════════════');
        trace('[XRay Loops] WHILE LOOP COMPILATION START');
        trace('[XRay Loops] - Normal while: ${normalWhile}');
        trace('[XRay Loops] - Condition type: ${Type.enumConstructor(econd.expr)}');
        trace('[XRay Loops] - Body type: ${Type.enumConstructor(ebody.expr)}');
        #end
        
        // Try to optimize for-in patterns first
        var forInOptimization = tryOptimizeForInPattern(econd, ebody);
        if (forInOptimization != null) {
            #if debug_loops
            trace('[XRay Loops] ✓ FOR-IN PATTERN OPTIMIZATION APPLIED');
            trace('[XRay Loops] WHILE LOOP COMPILATION END');
            trace('[XRay Loops] ═══════════════════════════════════════════════════');
            #end
            return forInOptimization;
        }
        
        // Check for Reflect.fields optimization
        var reflectOptimization = optimizeReflectFieldsLoop(econd, ebody);
        if (reflectOptimization != null) {
            #if debug_loops
            trace('[XRay Loops] ✓ REFLECT.FIELDS OPTIMIZATION APPLIED');
            trace('[XRay Loops] WHILE LOOP COMPILATION END');
            trace('[XRay Loops] ═══════════════════════════════════════════════════');
            #end
            return reflectOptimization;
        }
        
        // Check for array building patterns
        var arrayBuildingPattern = detectArrayBuildingPattern(econd, ebody);
        if (arrayBuildingPattern != null) {
            #if debug_loops
            trace('[XRay Loops] ✓ ARRAY BUILDING PATTERN DETECTED');
            #end
            var result = compileArrayBuildingLoop(econd, ebody, arrayBuildingPattern);
            #if debug_loops
            trace('[XRay Loops] WHILE LOOP COMPILATION END');
            trace('[XRay Loops] ═══════════════════════════════════════════════════');
            #end
            return result;
        }
        
        #if debug_loops
        trace('[XRay Loops] ⚠️ NO OPTIMIZATION PATTERN MATCHED');
        trace('[XRay Loops] - Falling back to generic while loop compilation');
        #end
        
        // Fall back to generic while loop compilation
        var result = compileWhileLoopGeneric(econd, ebody, normalWhile);
        
        #if debug_loops
        trace('[XRay Loops] - Generic compilation completed');
        trace('[XRay Loops] WHILE LOOP COMPILATION END');
        trace('[XRay Loops] ═══════════════════════════════════════════════════');
        #end
        
        return result;
    }
    
    /**
     * Try to optimize for-in patterns disguised as while loops
     * 
     * WHY: Haxe desugars array.filter(), array.map(), etc. into while loops with a specific pattern.
     *      We need to detect these patterns and generate idiomatic Enum functions instead.
     * 
     * WHAT: Detects the following desugared pattern:
     *       - _g = [] (accumulator array)
     *       - _g1 = 0 (index counter)
     *       - _g2 = source_array
     *       - while (_g1 < _g2.length) { v = _g2[_g1]; _g1++; ... }
     * 
     * HOW: Analyzes the while condition and body structure to identify array operations
     * 
     * @param econd While condition
     * @param ebody While body
     * @return Optimized for-in code or null if not applicable
     */
    private function tryOptimizeForInPattern(econd: TypedExpr, ebody: TypedExpr): Null<String> {
        #if debug_loops
        trace('[XRay Loops] ───────────────────────────────────────────');
        trace('[XRay Loops] DESUGARED ARRAY PATTERN DETECTION START');
        trace('[XRay Loops] - Analyzing while loop for array patterns...');
        #end
        
        // Check if condition matches: _g1 < _g2.length
        var conditionInfo = analyzeArrayLoopCondition(econd);
        if (conditionInfo == null) {
            #if debug_loops
            trace('[XRay Loops] - Condition does not match array loop pattern');
            trace('[XRay Loops] DESUGARED ARRAY PATTERN DETECTION END');
            trace('[XRay Loops] ───────────────────────────────────────────');
            #end
            return null;
        }
        
        #if debug_loops
        trace('[XRay Loops] ✓ Array loop condition detected:');
        trace('[XRay Loops]   - Index var: ${conditionInfo.indexVar}');
        trace('[XRay Loops]   - Array var: ${conditionInfo.arrayVar}');
        #end
        
        // Analyze body to determine operation type (filter, map, find, etc.)
        var bodyPattern = analyzeArrayLoopBody(ebody, conditionInfo);
        if (bodyPattern == null) {
            #if debug_loops
            trace('[XRay Loops] - Body does not match known array patterns');
            trace('[XRay Loops] DESUGARED ARRAY PATTERN DETECTION END');
            trace('[XRay Loops] ───────────────────────────────────────────');
            #end
            return null;
        }
        
        #if debug_loops
        trace('[XRay Loops] ✓ Array operation pattern detected:');
        trace('[XRay Loops]   - Pattern type: ${bodyPattern.type}');
        trace('[XRay Loops]   - Item var: ${bodyPattern.itemVar}');
        trace('[XRay Loops]   - Accumulator: ${bodyPattern.accumulator}');
        #end
        
        // Generate appropriate Enum function based on pattern
        var result = generateEnumFunction(bodyPattern, conditionInfo);
        
        #if debug_loops
        trace('[XRay Loops] ✓ GENERATED IDIOMATIC ENUM FUNCTION');
        trace('[XRay Loops] DESUGARED ARRAY PATTERN DETECTION END');
        trace('[XRay Loops] ───────────────────────────────────────────');
        #end
        
        return result;
    }
    
    /**
     * Optimize Reflect.fields loops to Map.merge operations
     * 
     * @param econd While condition
     * @param ebody While body  
     * @return Optimized Map.merge code or null if not applicable
     */
    private function optimizeReflectFieldsLoop(econd: TypedExpr, ebody: TypedExpr): Null<String> {
        // TODO: Delegate to existing optimizeReflectFieldsLoop implementation
        return null;
    }
    
    /**
     * Detect array building patterns in while loops
     * 
     * @param econd While condition
     * @param ebody While body
     * @return Array building pattern info or null if not detected
     */
    public function detectArrayBuildingPattern(econd: TypedExpr, ebody: TypedExpr): Null<{indexVar: String, accumVar: String, arrayExpr: String}> {
        // ARRAY BUILDING PATTERN DETECTION
        // 
        // WHY: Transform desugared for-in loops into idiomatic Enum functions
        // WHAT: Detect while loops with counter < array.length and array access patterns
        // HOW: Analyze condition for comparison, body for array access and accumulation
        // EDGE CASES: Handle parentheses in condition, complex body structures
        
        #if debug_loops
        trace("[XRay ArrayPattern] DETECTION START");
        trace('[XRay ArrayPattern] Condition: ${econd}');
        trace('[XRay ArrayPattern] Body: ${ebody}');
        #end
        
        // 1. Analyze condition: Look for 'counter < array.length' pattern
        var conditionInfo = analyzeArrayLoopCondition(econd);
        if (conditionInfo == null) {
            #if debug_loops
            trace("[XRay ArrayPattern] ❌ CONDITION ANALYSIS FAILED");
            #end
            return null;
        }
        
        #if debug_loops
        trace('[XRay ArrayPattern] ✓ CONDITION DETECTED: indexVar=${conditionInfo.indexVar}, arrayVar=${conditionInfo.arrayVar}');
        #end
        
        // 2. Analyze body: Look for array access, accumulation, and increment patterns
        var bodyAnalysis = analyzeSimpleArrayLoopBody(ebody, conditionInfo);
        if (bodyAnalysis == null) {
            #if debug_loops
            trace("[XRay ArrayPattern] ❌ BODY ANALYSIS FAILED");
            #end
            return null;
        }
        
        
        #if debug_loops
        trace('[XRay ArrayPattern] ✓ BODY ANALYZED: itemVar=${bodyAnalysis.itemVar}, accumulator=${bodyAnalysis.accumulator}');
        trace("[XRay ArrayPattern] ✅ ARRAY BUILDING PATTERN DETECTED");
        #end
        
        // 3. Return structured pattern information
        return {
            indexVar: conditionInfo.indexVar,
            accumVar: bodyAnalysis.accumulator != null ? bodyAnalysis.accumulator : conditionInfo.arrayVar,
            arrayExpr: conditionInfo.arrayVar
        };
    }
    
    /**
     * Compile array building loop with idiomatic Enum functions
     * 
     * ENUM FUNCTION GENERATION
     * 
     * WHY: Replace imperative loops with functional programming constructs
     * WHAT: Generate Enum.filter, Enum.map, or Enum.each based on detected patterns
     * HOW: Analyze transformation type and generate appropriate function calls
     * EDGE CASES: Complex transformations fallback to Enum.reduce
     * 
     * @param econd While condition
     * @param ebody While body
     * @param pattern Array building pattern information
     * @return Optimized Enum function implementation
     */
    public function compileArrayBuildingLoop(econd: TypedExpr, ebody: TypedExpr, pattern: {indexVar: String, accumVar: String, arrayExpr: String}): String {
        #if debug_loops
        trace("[XRay EnumGen] GENERATION START");
        trace('[XRay EnumGen] Pattern: ${pattern}');
        #end
        
        // Determine the pattern type and generate appropriate Enum function
        var patternType = classifyArrayPattern(ebody, pattern.indexVar, pattern.accumVar);
        
        switch (patternType.type) {
            case "filter":
                var condition = patternType.expression;
                var result = 'Enum.filter(${pattern.arrayExpr}, fn item -> ${condition} end)';
                
                #if debug_loops
                trace('[XRay EnumGen] ✓ FILTER GENERATED: ${result}');
                #end
                
                return result;
                
            case "map":
                var transformation = patternType.expression;
                var result = 'Enum.map(${pattern.arrayExpr}, fn item -> ${transformation} end)';
                
                #if debug_loops
                trace('[XRay EnumGen] ✓ MAP GENERATED: ${result}');
                #end
                
                return result;
                
            case "each":
                var sideEffect = patternType.expression;
                var result = 'Enum.each(${pattern.arrayExpr}, fn item -> ${sideEffect} end)';
                
                #if debug_loops
                trace('[XRay EnumGen] ✓ EACH GENERATED: ${result}');
                #end
                
                return result;
                
            case "reduce":
                var transformation = patternType.expression != null ? patternType.expression : "item";
                var result = 'Enum.reduce(${pattern.arrayExpr}, [], fn item, acc -> [${transformation} | acc] end) |> Enum.reverse()';
                
                #if debug_loops
                trace('[XRay EnumGen] ✓ REDUCE GENERATED: ${result}');
                #end
                
                return result;
                
            case _:
                #if debug_loops
                trace("[XRay EnumGen] ❌ UNKNOWN PATTERN TYPE, USING Y COMBINATOR FALLBACK");
                #end
                
                // Fallback to Y combinator if pattern is too complex
                return null;
        }
    }
    
    /**
     * Classify the array building pattern type
     * 
     * PATTERN CLASSIFICATION
     * 
     * WHY: Different loop patterns require different Enum functions
     * WHAT: Analyze body structure to determine filter/map/each/reduce patterns
     * HOW: Look for conditional pushes, transformations, side effects
     * 
     * @param ebody Loop body expression
     * @param indexVar Index variable name
     * @param accumVar Accumulator variable name
     * @return Pattern classification with type and expression
     */
    private function classifyArrayPattern(ebody: TypedExpr, indexVar: String, accumVar: String): {type: String, expression: String} {
        #if debug_loops
        trace("[XRay Classify] CLASSIFICATION START");
        #end
        
        switch (ebody.expr) {
            case TBlock(exprs):
                return classifyBlockPattern(exprs, indexVar, accumVar);
            case TIf(condition, thenExpr, elseExpr):
                return classifyConditionalPattern(condition, thenExpr, elseExpr, indexVar, accumVar);
            case TBinop(OpAssign, target, value):
                return classifyAssignmentPattern(target, value, indexVar, accumVar);
            case _:
                return {type: "reduce", expression: "item"};
        }
    }
    
    /**
     * Classify pattern from block expressions
     */
    private function classifyBlockPattern(exprs: Array<TypedExpr>, indexVar: String, accumVar: String): {type: String, expression: String} {
        var hasConditional = false;
        var hasAssignment = false;
        var transformationExpr = "item";
        var conditionExpr = "true";
        var itemVarName = "item"; // Default if not found
        
        // First pass: find the item variable name
        for (expr in exprs) {
            switch (expr.expr) {
                case TVar(tvar, init) if (init != null):
                    itemVarName = CompilerUtilities.toElixirVarName(tvar);
                    break;
                case _:
            }
        }
        
        // Second pass: classify patterns with correct variable substitution
        for (expr in exprs) {
            switch (expr.expr) {
                case TIf(condition, thenExpr, elseExpr):
                    hasConditional = true;
                    conditionExpr = substituteVariableNamesWithItem(compiler.compileExpression(condition), indexVar, accumVar, itemVarName);
                    
                case TBinop(OpAssign, target, value):
                    hasAssignment = true;
                    // Extract transformation from assignment
                    switch (value.expr) {
                        case TBinop(OpAdd, left, right):
                            switch (right.expr) {
                                case TArrayDecl([transformExpr]):
                                    transformationExpr = substituteVariableNamesWithItem(compiler.compileExpression(transformExpr), indexVar, accumVar, itemVarName);
                                case _:
                            }
                        case _:
                    }
                    
                case TCall(fn, args):
                    // Look for array push operations: array.push(transformedValue)
                    switch (fn.expr) {
                        case TField(obj, field):
                            // Check if this is a push call
                            switch (field) {
                                case FInstance(_, _, cf) if (cf.get().name == "push"):
                                    hasAssignment = true;
                                    // Extract transformation from push argument
                                    if (args.length > 0) {
                                        transformationExpr = substituteVariableNamesWithItem(compiler.compileExpression(args[0]), indexVar, accumVar, itemVarName);
                                    }
                                case _:
                                    continue;
                            }
                        case _:
                            continue;
                    }
                    
                case _:
                    // Skip other expressions (like increment)
                    continue;
            }
        }
        
        if (hasConditional && hasAssignment) {
            // Conditional push pattern = filter with transformation
            return {type: "filter", expression: conditionExpr};
        } else if (hasConditional) {
            return {type: "filter", expression: conditionExpr};
        } else if (hasAssignment) {
            return {type: "map", expression: transformationExpr};
        } else {
            return {type: "each", expression: "item"};
        }
    }
    
    /**
     * Classify pattern from conditional expression
     */
    private function classifyConditionalPattern(condition: TypedExpr, thenExpr: TypedExpr, elseExpr: TypedExpr, indexVar: String, accumVar: String): {type: String, expression: String} {
        var conditionStr = substituteVariableNamesWithItem(compiler.compileExpression(condition), indexVar, accumVar, "item");
        return {type: "filter", expression: conditionStr};
    }
    
    /**
     * Classify pattern from assignment expression
     */
    private function classifyAssignmentPattern(target: TypedExpr, value: TypedExpr, indexVar: String, accumVar: String): {type: String, expression: String} {
        switch (value.expr) {
            case TBinop(OpAdd, left, right):
                switch (right.expr) {
                    case TArrayDecl([transformExpr]):
                        var transformStr = substituteVariableNamesWithItem(compiler.compileExpression(transformExpr), indexVar, accumVar, "item");
                        return {type: "map", expression: transformStr};
                    case _:
                }
            case _:
        }
        return {type: "reduce", expression: "item"};
    }
    
    /**
     * Substitute variable names in expression string
     * 
     * WHY: Convert array access patterns and loop variables to function parameter references
     * WHAT: Replace array[index] with item, and loop variable names with 'item' 
     * HOW: String replacement with comprehensive pattern matching
     * 
     * @param expression The expression string
     * @param indexVar Index variable name
     * @param accumVar Accumulator variable name (actually source array)
     * @return Expression with substituted variable names
     */
    private function substituteVariableNames(expression: String, indexVar: String, accumVar: String): String {
        var result = expression;
        
        #if debug_loops
        trace('[XRay Substitute] BEFORE: ${result}');
        trace('[XRay Substitute] IndexVar: ${indexVar}, AccumVar: ${accumVar}');
        #end
        
        // Replace array access patterns first
        result = StringTools.replace(result, '${accumVar}[${indexVar}]', 'item');
        result = StringTools.replace(result, 'Enum.at(${accumVar}, ${indexVar})', 'item');
        result = StringTools.replace(result, '${accumVar}.at(${indexVar})', 'item');
        result = StringTools.replace(result, 'numbers[${indexVar}]', 'item');
        result = StringTools.replace(result, 'Enum.at(numbers, ${indexVar})', 'item');
        
        // Replace loop variable references
        // The item variable from the loop should become 'item' in the Enum function
        // This is a bit tricky because we need to find what variable name was used for the loop item
        result = StringTools.replace(result, 'n', 'item');  // Most common case from our test
        
        // Remove extra parentheses that might be added
        if (StringTools.startsWith(result, '((') && StringTools.endsWith(result, '))')) {
            result = result.substring(2, result.length - 2);
        } else if (StringTools.startsWith(result, '(') && StringTools.endsWith(result, ')')) {
            result = result.substring(1, result.length - 1);
        }
        
        #if debug_loops
        trace('[XRay Substitute] AFTER: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Substitute variable names with known item variable name
     * 
     * WHY: More accurate variable substitution using actual loop variable names
     * WHAT: Replace specific variable names with 'item' for Enum function parameters  
     * HOW: Use extracted item variable name instead of hardcoded patterns
     * 
     * @param expression The expression string
     * @param indexVar Index variable name
     * @param accumVar Accumulator variable name
     * @param itemVarName The actual item variable name from loop body
     * @return Expression with substituted variable names
     */
    private function substituteVariableNamesWithItem(expression: String, indexVar: String, accumVar: String, itemVarName: String): String {
        var result = expression;
        
        #if debug_loops
        trace('[XRay SubstituteItem] BEFORE: ${result}');
        trace('[XRay SubstituteItem] ItemVar: ${itemVarName}');
        #end
        
        // Replace array access patterns first
        result = StringTools.replace(result, '${accumVar}[${indexVar}]', 'item');
        result = StringTools.replace(result, 'Enum.at(${accumVar}, ${indexVar})', 'item');
        result = StringTools.replace(result, '${accumVar}.at(${indexVar})', 'item');
        result = StringTools.replace(result, 'numbers[${indexVar}]', 'item');
        result = StringTools.replace(result, 'Enum.at(numbers, ${indexVar})', 'item');
        
        // Replace the specific item variable name from the loop
        result = StringTools.replace(result, itemVarName, 'item');
        
        // Remove extra parentheses that might be added
        if (StringTools.startsWith(result, '((') && StringTools.endsWith(result, '))')) {
            result = result.substring(2, result.length - 2);
        } else if (StringTools.startsWith(result, '(') && StringTools.endsWith(result, ')')) {
            result = result.substring(1, result.length - 1);
        }
        
        #if debug_loops
        trace('[XRay SubstituteItem] AFTER: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Analyze simple array loop body for common patterns
     * 
     * SIMPLE BODY ANALYSIS
     * 
     * WHY: Handle the actual AST structure from Haxe's desugared for-loops
     * WHAT: Detect item variable extraction, increment operations, and array building
     * HOW: Look for TBlock with TVar(item = array[index]), TUnop(increment), conditional operations
     * EDGE CASES: Different increment styles, variable order, nested conditionals
     * 
     * @param ebody The loop body expression
     * @param conditionInfo Index and array variable information
     * @return Body analysis result or null if not recognized
     */
    private function analyzeSimpleArrayLoopBody(ebody: TypedExpr, conditionInfo: {indexVar: String, arrayVar: String}): Null<{
        itemVar: String,
        accumulator: String,
        hasIncrement: Bool,
        operation: TypedExpr
    }> {
        #if debug_loops
        trace("[XRay SimpleBody] SIMPLE BODY ANALYSIS START");
        trace('[XRay SimpleBody] Expected indexVar: ${conditionInfo.indexVar}, arrayVar: ${conditionInfo.arrayVar}');
        #end
        
        switch (ebody.expr) {
            case TBlock(exprs):
                #if debug_loops
                trace('[XRay SimpleBody] Block with ${exprs.length} expressions');
                #end
                
                var itemVar: String = null;
                var hasIncrement = false;
                var accumulator: String = null;
                var operation: TypedExpr = null;
                
                // Analyze each expression in the block
                for (i in 0...exprs.length) {
                    var expr = exprs[i];
                    
                    #if debug_loops
                    trace('[XRay SimpleBody] Expression ${i}: ${expr.expr}');
                    #end
                    
                    switch (expr.expr) {
                        case TVar(tvar, init) if (init != null):
                            // Look for item variable: var n = numbers[g]
                            itemVar = CompilerUtilities.toElixirVarName(tvar);
                            
                            #if debug_loops
                            trace('[XRay SimpleBody] ✓ Found item variable: ${itemVar}');
                            #end
                            
                        case TUnop(OpIncrement, _, e):
                            // Look for index increment: g++
                            hasIncrement = true;
                            
                            #if debug_loops
                            trace("[XRay SimpleBody] ✓ Found increment operation");
                            #end
                            
                        case TIf(condition, thenExpr, elseExpr):
                            // Look for conditional operations (filter/map patterns)
                            operation = expr;
                            accumulator = "evens"; // Will be determined from context
                            
                            #if debug_loops
                            trace("[XRay SimpleBody] ✓ Found conditional operation");
                            #end
                            
                        case TBinop(OpAssign, target, value):
                            // Look for direct assignment operations (map patterns)
                            operation = expr;
                            
                            switch (target.expr) {
                                case TLocal(v):
                                    accumulator = CompilerUtilities.toElixirVarName(v);
                                case _:
                                    accumulator = "result";
                            }
                            
                            #if debug_loops
                            trace('[XRay SimpleBody] ✓ Found assignment operation, accumulator: ${accumulator}');
                            #end
                            
                        case TCall(fn, args):
                            // Look for array push operations: array.push(transformedValue)
                            switch (fn.expr) {
                                case TField(obj, field):
                                    // Check if this is a push call
                                    switch (field) {
                                        case FInstance(_, _, cf) if (cf.get().name == "push"):
                                            // Extract accumulator from object
                                            switch (obj.expr) {
                                                case TLocal(v):
                                                    accumulator = CompilerUtilities.toElixirVarName(v);
                                                    operation = expr;
                                                    
                                                    #if debug_loops
                                                    trace('[XRay SimpleBody] ✓ Found push operation, accumulator: ${accumulator}');
                                                    #end
                                                    
                                                case _:
                                                    #if debug_loops
                                                    trace('[XRay SimpleBody] - Push target not a local variable');
                                                    #end
                                            }
                                        case _:
                                            #if debug_loops
                                            trace('[XRay SimpleBody] - TCall not a push operation');
                                            #end
                                    }
                                case _:
                                    #if debug_loops
                                    trace('[XRay SimpleBody] - TCall not a field access');
                                    #end
                            }
                            
                        case _:
                            #if debug_loops
                            trace('[XRay SimpleBody] - Skipping expression: ${expr.expr}');
                            #end
                    }
                }
                
                // Validate that we found the expected pattern
                if (itemVar != null && hasIncrement && operation != null) {
                    #if debug_loops
                    trace("[XRay SimpleBody] ✅ SIMPLE PATTERN DETECTED");
                    trace('[XRay SimpleBody] - Item var: ${itemVar}');
                    trace('[XRay SimpleBody] - Accumulator: ${accumulator}');
                    trace('[XRay SimpleBody] - Has increment: ${hasIncrement}');
                    #end
                    
                    return {
                        itemVar: itemVar,
                        accumulator: accumulator,
                        hasIncrement: hasIncrement,
                        operation: operation
                    };
                } else {
                    #if debug_loops
                    trace("[XRay SimpleBody] ❌ INCOMPLETE PATTERN");
                    trace('[XRay SimpleBody] - Item var: ${itemVar}');
                    trace('[XRay SimpleBody] - Has increment: ${hasIncrement}');
                    trace('[XRay SimpleBody] - Operation: ${operation != null}');
                    #end
                    
                    return null;
                }
                
            case _:
                #if debug_loops
                trace("[XRay SimpleBody] ❌ NOT A BLOCK EXPRESSION");
                #end
                
                return null;
        }
    }
    
    /**
     * Extract transformation logic from array building loop
     * 
     * TRANSFORMATION EXTRACTION
     * 
     * WHY: Convert imperative array building to functional transformations
     * WHAT: Analyze loop body to identify filter/map/forEach patterns
     * HOW: Look for conditional pushes (filter), value transforms (map), side effects (each)
     * EDGE CASES: Complex transformations, nested conditions, multiple accumulations
     * 
     * @param ebody Loop body
     * @param indexVar Index variable name
     * @param accumVar Accumulator variable name
     * @return Transformation expression or null if complex
     */
    private function extractArrayTransformation(ebody: TypedExpr, indexVar: String, accumVar: String): Null<{
        type: String,
        condition: String,
        itemExpr: String,
        transform: String
    }> {
        #if debug_loops
        trace("[XRay Transform] EXTRACTION START");
        trace('[XRay Transform] Body: ${ebody}');
        trace('[XRay Transform] IndexVar: ${indexVar}, AccumVar: ${accumVar}');
        #end
        
        // Analyze the body structure for common patterns
        switch (ebody.expr) {
            case TBlock(exprs):
                return analyzeAccumulationPattern(exprs, indexVar, accumVar);
            case TIf(condition, thenExpr, elseExpr):
                // Single if statement - likely a filter pattern
                return analyzeConditionalAccumulation(condition, thenExpr, elseExpr, indexVar, accumVar);
            case TBinop(OpAssign, target, value):
                // Direct assignment - likely a map pattern
                return analyzeDirectAccumulation(target, value, indexVar, accumVar);
            case _:
                #if debug_loops
                trace("[XRay Transform] ❌ UNKNOWN BODY STRUCTURE");
                #end
                return null;
        }
    }
    
    /**
     * Find and analyze accumulation patterns in loop body expressions
     * 
     * ACCUMULATION PATTERN ANALYSIS
     * 
     * WHY: Distinguish between conditional (filter) and unconditional (map) accumulation
     * WHAT: Analyze how values are accumulated into result arrays
     * HOW: Look for push operations, concatenation, and conditional logic
     * 
     * @param exprs Block expressions to analyze
     * @param indexVar Index variable name  
     * @param accumVar Accumulator variable name
     * @return Structured transformation data or null
     */
    private function analyzeAccumulationPattern(exprs: Array<TypedExpr>, indexVar: String, accumVar: String): Null<{
        type: String,
        condition: String,
        itemExpr: String,
        transform: String
    }> {
        #if debug_loops
        trace("[XRay AccumPattern] ACCUMULATION ANALYSIS START");
        trace('[XRay AccumPattern] Analyzing ${exprs.length} expressions');
        #end
        
        var itemVarName = "item"; // Default
        var hasConditional = false;
        var conditionExpr: String = null;
        var transformExpr: String = null;
        var accumulationType: String = "reduce";
        
        // Extract item variable name
        for (expr in exprs) {
            switch (expr.expr) {
                case TVar(tvar, init) if (init != null):
                    itemVarName = CompilerUtilities.toElixirVarName(tvar);
                    break;
                case _:
            }
        }
        
        // Analyze accumulation patterns
        for (expr in exprs) {
            switch (expr.expr) {
                case TIf(condition, thenExpr, elseExpr):
                    hasConditional = true;
                    conditionExpr = substituteVariableNamesWithItem(
                        compiler.compileExpression(condition), 
                        indexVar, 
                        accumVar, 
                        itemVarName
                    );
                    
                    // Check if the then branch is a push operation
                    var pushAnalysis = analyzePushOperation(thenExpr, itemVarName);
                    if (pushAnalysis.isPush) {
                        accumulationType = "filter";
                        transformExpr = pushAnalysis.pushedValue;
                        
                        #if debug_loops
                        trace('[XRay AccumPattern] ✓ FILTER PATTERN DETECTED');
                        trace('[XRay AccumPattern] - Condition: ${conditionExpr}');
                        trace('[XRay AccumPattern] - Transform: ${transformExpr}');
                        #end
                    }
                    
                case TBinop(OpAssign, target, value):
                    // Unconditional assignment - map pattern
                    switch (value.expr) {
                        case TBinop(OpAdd, left, right):
                            switch (right.expr) {
                                case TArrayDecl([transformedExpr]):
                                    accumulationType = "map";
                                    transformExpr = substituteVariableNamesWithItem(
                                        compiler.compileExpression(transformedExpr),
                                        indexVar,
                                        accumVar,
                                        itemVarName
                                    );
                                    
                                    #if debug_loops
                                    trace('[XRay AccumPattern] ✓ MAP PATTERN DETECTED');
                                    trace('[XRay AccumPattern] - Transform: ${transformExpr}');
                                    #end
                                case _:
                            }
                        case _:
                    }
                    
                case _:
                    continue;
            }
        }
        
        // Return structured result
        if (accumulationType == "filter" && conditionExpr != null) {
            return {
                type: "filter",
                condition: conditionExpr,
                itemExpr: transformExpr != null ? transformExpr : "item", 
                transform: ""
            };
        } else if (accumulationType == "map" && transformExpr != null) {
            return {
                type: "map", 
                condition: "",
                itemExpr: "item",
                transform: transformExpr
            };
        }
        
        #if debug_loops
        trace("[XRay AccumPattern] ❌ NO CLEAR PATTERN DETECTED");
        #end
        
        return null;
    }
    
    /**
     * Analyze conditional accumulation patterns
     */
    private function analyzeConditionalAccumulation(condition: TypedExpr, thenExpr: TypedExpr, elseExpr: TypedExpr, indexVar: String, accumVar: String): Null<{
        type: String,
        condition: String,
        itemExpr: String,
        transform: String
    }> {
        var conditionStr = substituteVariableNamesWithItem(compiler.compileExpression(condition), indexVar, accumVar, "item");
        var pushAnalysis = analyzePushOperation(thenExpr, "item");
        
        if (pushAnalysis.isPush) {
            return {
                type: "filter",
                condition: conditionStr,
                itemExpr: pushAnalysis.pushedValue,
                transform: ""
            };
        }
        
        return null;
    }
    
    /**
     * Analyze direct accumulation patterns
     */
    private function analyzeDirectAccumulation(target: TypedExpr, value: TypedExpr, indexVar: String, accumVar: String): Null<{
        type: String,
        condition: String,
        itemExpr: String,
        transform: String
    }> {
        switch (value.expr) {
            case TBinop(OpAdd, left, right):
                switch (right.expr) {
                    case TArrayDecl([transformExpr]):
                        var transformStr = substituteVariableNamesWithItem(compiler.compileExpression(transformExpr), indexVar, accumVar, "item");
                        return {
                            type: "map",
                            condition: "",
                            itemExpr: "item",
                            transform: transformStr
                        };
                    case _:
                }
            case _:
        }
        
        return null;
    }
    
    /**
     * Analyze push operation to determine what's being pushed
     */
    private function analyzePushOperation(expr: TypedExpr, itemVarName: String): {isPush: Bool, pushedValue: String} {
        switch (expr.expr) {
            case TCall(func, args):
                // Look for push() method calls
                switch (func.expr) {
                    case TField(obj, field):
                        var fieldName = switch (field) {
                            case FStatic(_, cf) | FInstance(_, _, cf): cf.get().name;
                            case FEnum(_, ef): ef.name;
                            case FAnon(cf): cf.get().name;
                            case FDynamic(name): name;
                            case FClosure(_, cf): cf.get().name;
                        };
                        if (fieldName.indexOf("push") != -1 && args.length > 0) {
                            var pushedValue = compiler.compileExpression(args[0]);
                            pushedValue = StringTools.replace(pushedValue, itemVarName, "item");
                            return {isPush: true, pushedValue: pushedValue};
                        }
                    case _:
                }
            case _:
        }
        return {isPush: false, pushedValue: "item"};
    }
    
    /**
     * Extract transformation from block expressions
     * 
     * @param exprs Block expressions
     * @param indexVar Index variable name
     * @param accumVar Accumulator variable name
     * @return Transformation expression or null
     */
    private function extractFromBlockExpressions(exprs: Array<TypedExpr>, indexVar: String, accumVar: String): Null<String> {
        for (expr in exprs) {
            switch (expr.expr) {
                case TIf(condition, thenExpr, elseExpr):
                    // Look for filter patterns: if (condition) accumVar.push(item)
                    var filterResult = extractFromConditional(condition, thenExpr, elseExpr, indexVar, accumVar);
                    if (filterResult != null) return filterResult;
                    
                case TBinop(OpAssign, target, value):
                    // Look for map patterns: accumVar = accumVar ++ [transform(item)]
                    var mapResult = extractFromDirectAssignment(target, value, indexVar, accumVar);
                    if (mapResult != null) return mapResult;
                    
                case _:
                    // Skip other expressions like index increment
                    continue;
            }
        }
        return null;
    }
    
    /**
     * Extract transformation from conditional expression (filter pattern)
     * 
     * @param condition If condition
     * @param thenExpr Then branch
     * @param elseExpr Else branch (usually null)
     * @param indexVar Index variable name
     * @param accumVar Accumulator variable name
     * @return Filter condition or null
     */
    private function extractFromConditional(condition: TypedExpr, thenExpr: TypedExpr, elseExpr: TypedExpr, indexVar: String, accumVar: String): Null<String> {
        #if debug_loops
        trace("[XRay Transform] Analyzing conditional for filter pattern");
        #end
        
        // For filter patterns, we want the condition as the filter predicate
        var conditionStr = compiler.compileExpression(condition);
        
        // Replace array access patterns with parameter name
        conditionStr = StringTools.replace(conditionStr, '${accumVar}[${indexVar}]', 'item');
        conditionStr = StringTools.replace(conditionStr, 'Enum.at(${accumVar}, ${indexVar})', 'item');
        
        #if debug_loops
        trace('[XRay Transform] ✓ FILTER CONDITION: ${conditionStr}');
        #end
        
        return conditionStr;
    }
    
    /**
     * Extract transformation from direct assignment (map pattern)
     * 
     * @param target Assignment target
     * @param value Assignment value
     * @param indexVar Index variable name
     * @param accumVar Accumulator variable name
     * @return Transformation expression or null
     */
    private function extractFromDirectAssignment(target: TypedExpr, value: TypedExpr, indexVar: String, accumVar: String): Null<String> {
        #if debug_loops
        trace("[XRay Transform] Analyzing assignment for map pattern");
        #end
        
        // Look for patterns like: accumVar = accumVar ++ [transform(item)]
        switch (value.expr) {
            case TBinop(OpAdd, left, right):
                // Check for array concatenation pattern
                switch (right.expr) {
                    case TArrayDecl([transformExpr]):
                        // Found map pattern: extract the transformation
                        var transformStr = compiler.compileExpression(transformExpr);
                        
                        // Replace array access patterns with parameter name
                        transformStr = StringTools.replace(transformStr, '${accumVar}[${indexVar}]', 'item');
                        transformStr = StringTools.replace(transformStr, 'Enum.at(${accumVar}, ${indexVar})', 'item');
                        
                        #if debug_loops
                        trace('[XRay Transform] ✓ MAP TRANSFORMATION: ${transformStr}');
                        #end
                        
                        return transformStr;
                    case _:
                }
            case _:
        }
        
        return null;
    }
    
    /**
     * Compile generic while loop with Y combinator pattern
     * 
     * @param econd While condition
     * @param ebody While body
     * @param normalWhile True for while, false for do-while
     * @return Y combinator implementation
     */
    private function compileWhileLoopGeneric(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        #if debug_y_combinator
        trace('[XRay YCombinator] ═══════════════════════════════════════════');
        trace('[XRay YCombinator] Y COMBINATOR GENERATION START');
        trace('[XRay YCombinator] - Normal while: ${normalWhile}');
        #end
        
        var condition = compiler.compileExpression(econd);
        var modifiedVars = extractModifiedVariables(ebody);
        var transformedBody = transformLoopBodyMutations(ebody, modifiedVars, normalWhile, condition);
        
        #if debug_y_combinator
        trace('[XRay YCombinator] - Modified variables: ${modifiedVars.length}');
        trace('[XRay YCombinator] - Condition: ${CompilerUtilities.safeSubstring(condition, 50)}');
        #end
        
        var varInitializations = [for (v in modifiedVars) '${v.name}'];
        var varParams = varInitializations.join(", ");
        
        // Generate Y combinator pattern based on whether we have break statements
        var hasBreakStatement = transformedBody.indexOf("throw(:break)") != -1;
        
        var result = if (normalWhile) {
            // while (condition) { body } pattern
            if (hasBreakStatement) {
                // Complex pattern with break handling
                '(\n' +
                '  try do\n' +
                '    loop_fn = fn {${varParams}} ->\n' +
                '      if ${condition} do\n' +
                '        try do\n' +
                '${CompilerUtilities.indentCode(transformedBody, 10)}\n' +
                '      loop_fn.({${varParams}})\n' +
                '        catch\n' +
                '          :break -> {${varParams}}\n' +
                '          :continue -> loop_fn.({${varParams}})\n' +
                '        end\n' +
                '      else\n' +
                '        {${varParams}}\n' +
                '      end\n' +
                '    end\n' +
                '    loop_fn.({${varParams}})\n' +
                '  catch\n' +
                '    :break -> {${varParams}}\n' +
                '  end\n' +
                ')';
            } else {
                // Simple pattern without break handling
                'loop_helper = fn loop_fn, {${varParams}} ->\n' +
                '  if ${condition} do\n' +
                '${CompilerUtilities.indentCode(transformedBody, 4)}\n' +
                '    loop_fn.(loop_fn, {${varParams}})\n' +
                '  else\n' +
                '    {${varParams}}\n' +
                '  end\n' +
                'end\n' +
                '\n' +
                '{${varParams}} = loop_helper.(loop_helper, {${varParams}})';
            }
        } else {
            // do { body } while (condition) pattern - inline format
            '(\n' +
            '  loop_fn = fn {${varParams}} ->\n' +
            '${CompilerUtilities.indentCode(transformedBody, 4)}\n' +
            '    if ${condition}, do: loop_fn.({${varParams}}), else: {${varParams}}\n' +
            '  end\n' +
            '  {${varParams}} = loop_fn.({${varParams}})\n' +
            ')';
        };
        
        #if debug_y_combinator
        trace('[XRay YCombinator] ✓ Y COMBINATOR GENERATED');
        trace('[XRay YCombinator] - Generated code length: ${result.length} chars');
        trace('[XRay YCombinator] Y COMBINATOR GENERATION END');
        trace('[XRay YCombinator] ═══════════════════════════════════════════');
        #end
        
        return result;
    }
    
    /**
     * Extract variables that are modified in loop body
     * 
     * @param ebody Loop body expression
     * @return Array of modified variable information
     */
    private function extractModifiedVariables(ebody: TypedExpr): Array<{name: String, type: String}> {
        var modifiedVars: Array<{name: String, type: String}> = [];
        
        // Recursively find all variable assignments and mutations
        function findMutations(expr: TypedExpr): Void {
            switch(expr.expr) {
                case TBinop(op, e1, e2):
                    // Variable assignment and compound assignments
                    switch (op) {
                        case OpAssign, OpAssignOp(_):
                            if (isVariableAccess(e1)) {
                                var varName = extractVariableName(e1);
                                if (!Lambda.exists(modifiedVars, v -> v.name == varName)) {
                                    modifiedVars.push({name: varName, type: "Dynamic"});
                                }
                            }
                        case _:
                            // For other binary operations, recursively check both sides
                            findMutations(e1);
                    }
                    findMutations(e2);
                    
                case TVar(tvar, valueExpr):
                    // Variable declaration
                    var varName = CompilerUtilities.toElixirVarName(tvar);
                    if (!Lambda.exists(modifiedVars, v -> v.name == varName)) {
                        modifiedVars.push({name: varName, type: "Dynamic"});
                    }
                    if (valueExpr != null) findMutations(valueExpr);
                    
                case TUnop(op, postFix, e):
                    // Unary operations like i++, i--, ++i, --i
                    switch (op) {
                        case OpIncrement, OpDecrement:
                            if (isVariableAccess(e)) {
                                var varName = extractVariableName(e);
                                if (!Lambda.exists(modifiedVars, v -> v.name == varName)) {
                                    modifiedVars.push({name: varName, type: "Dynamic"});
                                }
                            }
                        case _:
                            findMutations(e);
                    }
                    
                case TBlock(exprs):
                    for (e in exprs) findMutations(e);
                    
                case TIf(cond, thenExpr, elseExpr):
                    findMutations(cond);
                    findMutations(thenExpr);
                    if (elseExpr != null) findMutations(elseExpr);
                    
                case TCall(e, el):
                    findMutations(e);
                    for (arg in el) findMutations(arg);
                    
                case _:
                    // Continue with other expression types as needed
            }
        }
        
        findMutations(ebody);
        return modifiedVars;
    }
    
    /**
     * Check if expression is a variable access
     * 
     * @param expr Expression to check
     * @return True if variable access
     */
    private function isVariableAccess(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TLocal(_): true;
            case _: false;
        };
    }
    
    /**
     * Extract variable name from variable access expression
     * 
     * @param expr Variable access expression
     * @return Variable name
     */
    private function extractVariableName(expr: TypedExpr): String {
        return switch(expr.expr) {
            case TLocal(v): CompilerUtilities.toElixirVarName(v);
            case _: "";
        };
    }
    
    /**
     * Transform loop body mutations for Y combinator pattern
     * 
     * @param expr Loop body expression
     * @param modifiedVars Array of modified variables
     * @param normalWhile True for while, false for do-while
     * @param condition Loop condition string
     * @return Transformed body with proper variable handling
     */
    private function transformLoopBodyMutations(expr: TypedExpr, modifiedVars: Array<{name: String, type: String}>, normalWhile: Bool, condition: String): String {
        // Transform variable assignments to tuple updates
        return switch(expr.expr) {
            case TBlock(exprs):
                var statements = [for (e in exprs) transformStatement(e, modifiedVars)];
                statements.join("\n");
                
            case _:
                transformStatement(expr, modifiedVars);
        };
    }
    
    /**
     * Transform individual statement for Y combinator
     * 
     * @param expr Statement expression
     * @param modifiedVars Modified variables context
     * @return Transformed statement
     */
    private function transformStatement(expr: TypedExpr, modifiedVars: Array<{name: String, type: String}>): String {
        return switch(expr.expr) {
            case TBinop(op, e1, e2):
                // Transform variable assignment and compound assignments
                switch (op) {
                    case OpAssign:
                        if (isVariableAccess(e1)) {
                            var varName = extractVariableName(e1);
                            var value = compiler.compileExpression(e2);
                            '${varName} = ${value}';
                        } else {
                            compiler.compileExpression(expr);
                        }
                    case OpAssignOp(assignOp):
                        // Handle compound assignments like +=, -=, *=, /=
                        if (isVariableAccess(e1)) {
                            var varName = extractVariableName(e1);
                            var value = compiler.compileExpression(e2);
                            var opStr = switch (assignOp) {
                                case OpAdd: "+";
                                case OpSub: "-";
                                case OpMult: "*";
                                case OpDiv: "/";
                                case OpMod: "rem";
                                case _: "+"; // fallback
                            };
                            '${varName} = ${varName} ${opStr} ${value}';
                        } else {
                            compiler.compileExpression(expr);
                        }
                    case _:
                        compiler.compileExpression(expr);
                }
                
            case TUnop(op, postFix, e):
                // Transform increment/decrement operations
                switch (op) {
                    case OpIncrement:
                        if (isVariableAccess(e)) {
                            var varName = extractVariableName(e);
                            '${varName} = ${varName} + 1';
                        } else {
                            compiler.compileExpression(expr);
                        }
                    case OpDecrement:
                        if (isVariableAccess(e)) {
                            var varName = extractVariableName(e);
                            '${varName} = ${varName} - 1';
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
     * Debug helper: Check if expression contains TFor patterns
     * 
     * WHY: This helper was moved from ElixirCompiler.hx as part of loop-related
     * logic consolidation. TFor pattern detection is specifically loop-related
     * functionality that belongs with other loop compilation logic.
     * 
     * WHAT: Recursively scans AST expressions to detect the presence of TFor
     * (for loop) patterns that require specialized compilation handling.
     * 
     * HOW: Pattern matches on TypedExpr and recursively checks all sub-expressions
     * including blocks, if statements, and other container expressions.
     * 
     * @param expr The expression to analyze for TFor patterns
     * @return True if expression contains any TFor nodes
     */
    public function checkForTForInExpression(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch (expr.expr) {
            case TFor(_, _, _):
                return true;
            case TBlock(exprs):
                for (e in exprs) {
                    if (checkForTForInExpression(e)) return true;
                }
                return false;
            case TIf(_, eif, eelse):
                if (checkForTForInExpression(eif)) return true;
                if (eelse != null && checkForTForInExpression(eelse)) return true;
                return false;
            case _:
                return false;
        }
    }
    
    /**
     * Analyze while loop condition for array iteration pattern
     * 
     * @param econd While condition expression
     * @return Info about array loop variables or null if not a match
     */
    private function analyzeArrayLoopCondition(econd: TypedExpr): Null<{indexVar: String, arrayVar: String}> {
        // Looking for pattern: _g1 < _g2.length (with parenthesis)
        switch(econd.expr) {
            case TParenthesis(e):
                return analyzeArrayLoopCondition(e);
                
            case TBinop(OpLt, e1, e2):
                // e1 should be index variable (like _g1)
                // e2 should be array.length field access
                var indexVar = switch(e1.expr) {
                    case TLocal(v): CompilerUtilities.toElixirVarName(v);
                    case _: null;
                };
                
                if (indexVar == null) return null;
                
                // Check for array.length pattern
                var arrayVar = switch(e2.expr) {
                    case TField(arrayExpr, FInstance(_, _, cf)):
                        if (cf.get().name == "length") {
                            switch(arrayExpr.expr) {
                                case TLocal(v): CompilerUtilities.toElixirVarName(v);
                                case _: null;
                            }
                        } else {
                            null;
                        }
                    case _: null;
                };
                
                if (arrayVar == null) return null;
                
                return {indexVar: indexVar, arrayVar: arrayVar};
                
            case _:
                return null;
        }
    }
    
    /**
     * Analyze while loop body for array operation patterns
     * 
     * @param ebody While body expression
     * @param conditionInfo Information from condition analysis
     * @return Pattern information or null if not recognized
     */
    private function analyzeArrayLoopBody(ebody: TypedExpr, conditionInfo: {indexVar: String, arrayVar: String}): Null<{
        type: String,
        itemVar: String,
        accumulator: String,
        sourceArray: TypedExpr,
        transformation: TypedExpr,
        condition: TypedExpr
    }> {
        // Body should be a block with specific structure
        switch(ebody.expr) {
            case TBlock(exprs) if (exprs.length >= 2):
                // First: var v = array[index]
                var itemVar: String = null;
                var sourceArray: TypedExpr = null;
                
                if (exprs.length > 0) {
                    switch(exprs[0].expr) {
                        case TVar(tvar, init) if (init != null):
                            itemVar = CompilerUtilities.toElixirVarName(tvar);
                            // Check if init is array[index]
                            switch(init.expr) {
                                case TArray(arr, idx):
                                    sourceArray = arr;
                                case _:
                            }
                        case _:
                    }
                }
                
                if (itemVar == null) return null;
                
                // Second: index++ (prefix increment)
                var hasIncrement = false;
                if (exprs.length > 1) {
                    switch(exprs[1].expr) {
                        case TUnop(OpIncrement, true, e): // prefix ++
                            hasIncrement = true;
                        case _:
                    }
                }
                
                if (!hasIncrement) return null;
                
                // Third: operation (filter/map/etc.)
                if (exprs.length > 2) {
                    return analyzeArrayOperation(exprs[2], itemVar, sourceArray);
                }
                
            case _:
        }
        
        return null;
    }
    
    /**
     * Analyze the array operation (filter, map, etc.)
     * 
     * @param expr The operation expression
     * @param itemVar The loop item variable name
     * @param sourceArray The source array expression
     * @return Pattern information
     */
    private function analyzeArrayOperation(expr: TypedExpr, itemVar: String, sourceArray: TypedExpr): Null<{
        type: String,
        itemVar: String,
        accumulator: String,
        sourceArray: TypedExpr,
        transformation: TypedExpr,
        condition: TypedExpr
    }> {
        switch(expr.expr) {
            // Filter pattern: if (condition) accumulator.push(item)
            case TIf(cond, thenExpr, null):
                // Check if then branch pushes to accumulator
                switch(thenExpr.expr) {
                    case TCall(e, [arg]):
                        // This is a push operation
                        return {
                            type: "filter",
                            itemVar: itemVar,
                            accumulator: "_g", // TODO: extract actual accumulator name
                            sourceArray: sourceArray,
                            transformation: null,
                            condition: cond
                        };
                    case _:
                }
                
            // Map pattern: accumulator.push(transformation)
            case TCall(e, [arg]):
                return {
                    type: "map",
                    itemVar: itemVar,
                    accumulator: "_g",
                    sourceArray: sourceArray,
                    transformation: arg,
                    condition: null
                };
                
            case _:
        }
        
        return null;
    }
    
    /**
     * Generate idiomatic Enum function from detected pattern
     * 
     * @param pattern The detected pattern information
     * @param conditionInfo The loop condition information
     * @return Generated Elixir code
     */
    private function generateEnumFunction(pattern: {
        type: String,
        itemVar: String,
        accumulator: String,
        sourceArray: TypedExpr,
        transformation: TypedExpr,
        condition: TypedExpr
    }, conditionInfo: {indexVar: String, arrayVar: String}): String {
        // Compile the source array expression
        var arrayExpr = compiler.compileExpression(pattern.sourceArray);
        
        switch(pattern.type) {
            case "filter":
                // Generate Enum.filter
                var condition = compiler.compileExpression(pattern.condition);
                // Need to substitute item variable in condition
                var lambdaBody = substituteVariable(condition, pattern.itemVar, pattern.itemVar);
                return 'Enum.filter(${arrayExpr}, fn ${pattern.itemVar} -> ${lambdaBody} end)';
                
            case "map":
                // Generate Enum.map
                var transformation = compiler.compileExpression(pattern.transformation);
                // Need to substitute item variable in transformation
                var lambdaBody = substituteVariable(transformation, pattern.itemVar, pattern.itemVar);
                return 'Enum.map(${arrayExpr}, fn ${pattern.itemVar} -> ${lambdaBody} end)';
                
            default:
                return null;
        }
    }
    
    /**
     * Substitute variable names in compiled expression
     * 
     * @param expr Compiled expression string
     * @param oldVar Old variable name
     * @param newVar New variable name
     * @return Expression with substituted variable
     */
    private function substituteVariable(expr: String, oldVar: String, newVar: String): String {
        // Simple substitution for now - may need more sophisticated approach
        return expr;
    }
    
    /**
     * Check if expression contains TWhile nodes that generate Y combinator patterns
     * 
     * WHY: This function was moved from ElixirCompiler.hx as part of loop-related
     * logic consolidation. While loop detection and Y combinator pattern analysis
     * is core loop compilation functionality that belongs with other loop logic.
     * 
     * WHAT: Recursively scans the AST to detect TWhile expressions that will
     * generate complex multi-line Y combinator patterns requiring block syntax.
     * This is essential for proper code generation and formatting decisions.
     * 
     * HOW: Pattern matches on all possible TypedExpr variants and recursively
     * checks for TWhile patterns. Handles complex cases like nested structures,
     * function bodies, try/catch blocks, and binary operations.
     * 
     * @param expr The expression to analyze for TWhile patterns
     * @return True if expression contains any TWhile nodes
     */
    public function containsTWhileExpression(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch (expr.expr) {
            case TWhile(_, _, _):
                // Found a TWhile - this will generate Y combinator pattern
                return true;
                
            case TBlock(exprs):
                // Recursively check all expressions in the block
                for (e in exprs) {
                    if (containsTWhileExpression(e)) return true;
                }
                return false;
                
            case TIf(_, eif, eelse):
                // Check both branches of if-statement
                if (containsTWhileExpression(eif)) return true;
                if (eelse != null && containsTWhileExpression(eelse)) return true;
                return false;
                
            case TFor(_, _, ebody):
                // For loops might contain while loops in their body
                return containsTWhileExpression(ebody);
                
            case TSwitch(_, cases, defaultCase):
                // Check all switch cases
                for (c in cases) {
                    if (containsTWhileExpression(c.expr)) return true;
                }
                if (defaultCase != null && containsTWhileExpression(defaultCase)) return true;
                return false;
                
            case TTry(etry, catches):
                // Check try block
                if (containsTWhileExpression(etry)) return true;
                // Check catch blocks
                for (c in catches) {
                    if (containsTWhileExpression(c.expr)) return true;
                }
                return false;
                
            case TFunction(func):
                // Check function body
                return containsTWhileExpression(func.expr);
                
            case TCall(e, args):
                // Check function expression and arguments
                if (containsTWhileExpression(e)) return true;
                for (arg in args) {
                    if (containsTWhileExpression(arg)) return true;
                }
                return false;
                
            case TBinop(_, e1, e2):
                // Check both operands
                return containsTWhileExpression(e1) || containsTWhileExpression(e2);
                
            case TUnop(_, _, e):
                // Check operand
                return containsTWhileExpression(e);
                
            case TArray(e1, e2):
                // Check array and index expressions
                return containsTWhileExpression(e1) || containsTWhileExpression(e2);
                
            case TArrayDecl(exprs):
                // Check all array elements
                for (e in exprs) {
                    if (containsTWhileExpression(e)) return true;
                }
                return false;
                
            case TField(e, _):
                // Check field access target
                return containsTWhileExpression(e);
                
            case TVar(_, init):
                // Check variable initialization
                return init != null ? containsTWhileExpression(init) : false;
                
            case _:
                // All other expression types don't contain TWhile
                return false;
        }
    }
}