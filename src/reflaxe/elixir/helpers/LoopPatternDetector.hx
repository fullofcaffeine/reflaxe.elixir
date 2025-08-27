#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;

/**
 * Loop pattern classifications for Elixir code generation
 * 
 * Each pattern maps to a specific idiomatic Elixir construct:
 * - IndexedIteration: array[i] loops → Enum.with_index
 * - CharacterIteration: string.charAt(i) loops → Binary comprehensions
 * - CollectionBuilding: conditional array.push → Enum.filter/map
 * - Accumulation: sum += value patterns → Enum.reduce
 * - EarlyTermination: loops with returns → Enum.find
 * - RangeIteration: for(i in start...end) → Range with Enum.each
 * - StateMachine: complex state mutations → Stream.unfold
 * - ComplexPattern: fallback → Module-level helper function
 */
enum LoopPattern {
    IndexedIteration(array: String, indexVar: String);
    CharacterIteration(stringVar: String, indexVar: String);
    CollectionBuilding(condition: String, transform: String);
    Accumulation(accumVar: String, operation: String);
    EarlyTermination(searchCondition: String);
    RangeIteration(start: String, end: String, counterVar: String);
    StateMachine(stateVar: String, updateLogic: String);
    ComplexPattern;
}

/**
 * LoopPatternDetector: Pattern recognition engine for idiomatic Elixir loop generation
 * 
 * WHY: Instead of mechanically translating loop SYNTAX, we need to recognize loop INTENT
 *      and generate the appropriate idiomatic Elixir construct. This prevents complex
 *      Y-combinator patterns and generates code that looks hand-written by Elixir experts.
 * 
 * WHAT: Analyzes Haxe loop AST patterns and classifies them into categories that map
 *       to specific Elixir constructs like Enum.with_index, binary comprehensions,
 *       Enum.reduce, etc. Each pattern has a natural Elixir equivalent.
 * 
 * HOW: Pattern matching on TypedExpr AST nodes to detect common loop intents:
 *      - Index + array access → Enum.with_index
 *      - String charAt/cca → Binary comprehensions  
 *      - Conditional array.push → Enum.filter/map
 *      - Variable accumulation → Enum.reduce
 *      - Complex patterns → Simple module-level recursion
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused only on pattern detection
 * - Open/Closed Principle: Easy to add new patterns without changing existing code
 * - Testability: Each detection method can be unit tested independently
 * - Maintainability: Clear separation between detection and code generation
 * - Performance: Uses optimized BEAM built-ins instead of custom recursion
 * 
 * @see /docs/03-compiler-development/LOOP_COMPILATION_REDESIGN_PRD.md - Complete implementation guide
 */
@:nullSafety(Off)
class LoopPatternDetector {

    /**
     * Main pattern classification entry point
     * 
     * PATTERN CLASSIFICATION STRATEGY
     * 
     * WHY: Different loop patterns require completely different Elixir approaches.
     *      A generic approach leads to complex, non-idiomatic code.
     * 
     * WHAT: Analyzes loop condition and body to determine the most appropriate
     *       Elixir construct. Prioritizes common patterns first for performance.
     * 
     * HOW: Sequential pattern matching, starting with most specific patterns:
     *      1. Character iteration (very specific: charAt/cca calls)
     *      2. Indexed array access (common: array[i] patterns)
     *      3. Collection building (conditional push operations)
     *      4. Accumulation (variable mutations with operators)
     *      5. Early termination (return/break patterns)
     *      6. Range iteration (simple counter loops)
     *      7. State machines (complex state changes)
     *      8. Fallback to complex pattern
     * 
     * EDGE CASES:
     * - Multiple patterns in one loop (choose most specific)
     * - Nested loops (analyze inner vs outer patterns)
     * - Side effects that prevent optimization
     * - Variable shadowing and scope conflicts
     * 
     * @param condition Loop condition expression (while condition or for range)
     * @param body Loop body expression 
     * @return LoopPattern enum indicating the detected pattern type
     */
    public static function classifyLoopPattern(condition: TypedExpr, body: TypedExpr): LoopPattern {
        #if debug_loops
        // trace('[XRay PatternDetector] ═══════════════════════════════════════════');
        // trace('[XRay PatternDetector] PATTERN CLASSIFICATION START');
        // trace('[XRay PatternDetector] - Analyzing loop for pattern recognition...');
        #end

        // Priority 1: Character iteration (very specific pattern)
        var charPattern = detectCharacterIteration(condition, body);
        if (charPattern != null) {
            #if debug_loops
            // trace('[XRay PatternDetector] ✓ DETECTED: CharacterIteration');
            // trace('[XRay PatternDetector] ═══════════════════════════════════════════');
            #end
            return charPattern;
        }

        // Priority 2: Indexed array access (common pattern)  
        var indexPattern = detectIndexedIteration(condition, body);
        if (indexPattern != null) {
            #if debug_loops
            // trace('[XRay PatternDetector] ✓ DETECTED: IndexedIteration');
            // trace('[XRay PatternDetector] ═══════════════════════════════════════════');
            #end
            return indexPattern;
        }

        // Priority 3: Collection building (filter/map patterns)
        var collectionPattern = detectCollectionBuilding(condition, body);
        if (collectionPattern != null) {
            #if debug_loops
            // trace('[XRay PatternDetector] ✓ DETECTED: CollectionBuilding');
            // trace('[XRay PatternDetector] ═══════════════════════════════════════════');
            #end
            return collectionPattern;
        }

        // Priority 4: Accumulation patterns (reduce)
        var accumPattern = detectAccumulation(condition, body);
        if (accumPattern != null) {
            #if debug_loops
            // trace('[XRay PatternDetector] ✓ DETECTED: Accumulation');
            // trace('[XRay PatternDetector] ═══════════════════════════════════════════');
            #end
            return accumPattern;
        }

        // Priority 5: Early termination (find patterns)
        var terminationPattern = detectEarlyTermination(condition, body);
        if (terminationPattern != null) {
            #if debug_loops
            // trace('[XRay PatternDetector] ✓ DETECTED: EarlyTermination');
            // trace('[XRay PatternDetector] ═══════════════════════════════════════════');
            #end
            return terminationPattern;
        }

        // Priority 6: Range iteration (simple counters)
        var rangePattern = detectRangeIteration(condition, body);
        if (rangePattern != null) {
            #if debug_loops
            // trace('[XRay PatternDetector] ✓ DETECTED: RangeIteration');
            // trace('[XRay PatternDetector] ═══════════════════════════════════════════');
            #end
            return rangePattern;
        }

        // Priority 7: State machine patterns
        var stateMachinePattern = detectStateMachine(condition, body);
        if (stateMachinePattern != null) {
            #if debug_loops
            // trace('[XRay PatternDetector] ✓ DETECTED: StateMachine');
            // trace('[XRay PatternDetector] ═══════════════════════════════════════════');
            #end
            return stateMachinePattern;
        }

        // Fallback: Complex pattern requiring module-level helper
        #if debug_loops
        // trace('[XRay PatternDetector] ⚠️  FALLBACK: ComplexPattern (will generate module helper)');
        // trace('[XRay PatternDetector] ═══════════════════════════════════════════');
        #end
        return ComplexPattern;
    }

    /**
     * Detect character iteration patterns for binary comprehension generation
     * 
     * CHARACTER ITERATION PATTERN DETECTION
     * 
     * WHY: String character iteration is common (JsonPrinter.quote_, etc.) and should
     *      generate idiomatic Elixir using binary comprehensions: `for <<char <- s>>`
     *      instead of complex loops with charAt() calls.
     * 
     * WHAT: Detects loops that iterate through string characters with patterns like:
     *       - Condition: i < string.length
     *       - Body: char = string.charAt(i) or char = string.cca(i)
     *       - Increment: i++ or i = i + 1
     * 
     * HOW: AST analysis to identify:
     *      1. Length-based loop condition (i < s.length)
     *      2. Character access in body (s.charAt(i), s.cca(i))
     *      3. Index increment pattern
     * 
     * @param condition While loop condition expression
     * @param body Loop body expression
     * @return CharacterIteration pattern if detected, null otherwise
     */
    private static function detectCharacterIteration(condition: TypedExpr, body: TypedExpr): Null<LoopPattern> {
        #if debug_loops
        // trace('[XRay PatternDetector] - Checking for character iteration pattern...');
        #end

        // Look for string length comparison in condition (i < s.length)
        var lengthCheck = findStringLengthComparison(condition);
        if (lengthCheck == null) return null;

        // Look for character access in body (s.charAt(i), s.cca(i))
        var charAccess = findCharacterAccess(body, lengthCheck.stringVar, lengthCheck.indexVar);
        if (charAccess == null) return null;

        #if debug_loops
        // trace('[XRay PatternDetector] ✓ Character iteration detected: ${lengthCheck.stringVar}[${lengthCheck.indexVar}]');
        #end

        return CharacterIteration(lengthCheck.stringVar, lengthCheck.indexVar);
    }

    /**
     * Detect indexed array iteration patterns for Enum.with_index generation
     * 
     * INDEXED ARRAY ITERATION PATTERN DETECTION
     * 
     * WHY: Array access by index is common but should use Enum.with_index instead
     *      of manual index management. This generates cleaner, more idiomatic code.
     *      CRITICAL: Haxe desugars for loops, creating temp vars like g_counter, g_array
     * 
     * WHAT: Detects loops that access arrays by index with patterns like:
     *       - Condition: i < array.length OR g_counter < g_array (desugared)
     *       - Body: array[i], array.get(i), or Enum.at(array, i)
     *       - Increment: i++ or i = g_counter + offset
     * 
     * @param condition While loop condition expression
     * @param body Loop body expression  
     * @return IndexedIteration pattern if detected, null otherwise
     */
    public static function detectIndexedIteration(condition: TypedExpr, body: TypedExpr): Null<LoopPattern> {
        // Debug: Force trace to understand flow
        // trace('[XRay PatternDetector] detectIndexedIteration called');
        // trace('[XRay PatternDetector] Condition type: ${Type.enumConstructor(condition.expr)}');

        // Look for array length comparison (i < array.length)
        var lengthCheck = findArrayLengthComparison(condition);
        
        // Also check for desugared patterns where we have Enum.at(array, index) in body
        if (lengthCheck == null) {
            // Try to detect desugared pattern by looking for Enum.at in body
            var enumAtPattern = findEnumAtPattern(body);
            if (enumAtPattern != null) {
                #if debug_loops
                // trace('[XRay PatternDetector] ✓ Found Enum.at pattern: ${enumAtPattern.arrayVar}[${enumAtPattern.indexVar}]');
                #end
                return IndexedIteration(enumAtPattern.arrayVar, enumAtPattern.indexVar);
            }
            return null;
        }

        // Look for array access by index (array[i])
        var hasArrayAccess = findArrayAccessByIndex(body, lengthCheck.arrayVar, lengthCheck.indexVar);
        if (!hasArrayAccess) return null;

        #if debug_loops
        // trace('[XRay PatternDetector] ✓ Indexed iteration detected: ${lengthCheck.arrayVar}[${lengthCheck.indexVar}]');
        #end

        return IndexedIteration(lengthCheck.arrayVar, lengthCheck.indexVar);
    }

    /**
     * Detect collection building patterns for Enum.filter/map generation
     * 
     * @param condition Loop condition
     * @param body Loop body
     * @return CollectionBuilding pattern if detected, null otherwise
     */
    private static function detectCollectionBuilding(condition: TypedExpr, body: TypedExpr): Null<LoopPattern> {
        // TODO: Implement collection building detection
        // Look for: if (condition) { result.push(transform(item)); }
        return null;
    }

    /**
     * Detect accumulation patterns for Enum.reduce generation
     * 
     * @param condition Loop condition
     * @param body Loop body
     * @return Accumulation pattern if detected, null otherwise
     */
    private static function detectAccumulation(condition: TypedExpr, body: TypedExpr): Null<LoopPattern> {
        // TODO: Implement accumulation detection
        // Look for: sum += value, count++, etc.
        return null;
    }

    /**
     * Detect early termination patterns for Enum.find generation
     * 
     * @param condition Loop condition
     * @param body Loop body
     * @return EarlyTermination pattern if detected, null otherwise
     */
    private static function detectEarlyTermination(condition: TypedExpr, body: TypedExpr): Null<LoopPattern> {
        // TODO: Implement early termination detection
        // Look for: return, break statements
        return null;
    }

    /**
     * Detect range iteration patterns for Range with Enum.each generation
     * 
     * @param condition Loop condition
     * @param body Loop body
     * @return RangeIteration pattern if detected, null otherwise
     */
    private static function detectRangeIteration(condition: TypedExpr, body: TypedExpr): Null<LoopPattern> {
        // TODO: Implement range iteration detection
        // Look for: i < end, simple increment patterns
        return null;
    }

    /**
     * Detect state machine patterns for Stream.unfold generation
     * 
     * @param condition Loop condition
     * @param body Loop body
     * @return StateMachine pattern if detected, null otherwise
     */
    private static function detectStateMachine(condition: TypedExpr, body: TypedExpr): Null<LoopPattern> {
        // TODO: Implement state machine detection
        // Look for: complex state variable mutations
        return null;
    }

    // Helper functions for pattern detection

    /**
     * Detect string length comparison patterns for character iteration
     * 
     * WHY: Character iteration commonly uses `i < s.length` condition pattern.
     *      Need to extract both the index variable and string variable to generate
     *      idiomatic binary comprehension: `for <<char <- s>>`
     * 
     * WHAT: Analyzes binary comparison expressions to find length-based loop conditions.
     *       Handles variations like `i < s.length`, `index < str.length`, etc.
     * 
     * HOW: AST traversal of TBinop expressions with OpLt operator.
     *      Left side must be local variable (index), right side must be field access (.length)
     *      on a string variable.
     * 
     * @param expr Loop condition expression to analyze
     * @return Object with stringVar and indexVar names if detected, null otherwise
     */
    private static function findStringLengthComparison(expr: TypedExpr): Null<{stringVar: String, indexVar: String}> {
        #if debug_loops
        // trace('[XRay PatternDetector] - Analyzing for string length comparison...');
        #end
        
        return switch(expr.expr) {
            case TBinop(OpLt, leftExpr, rightExpr):
                // Left side should be index variable (TLocal)
                var indexVar = switch(leftExpr.expr) {
                    case TLocal(tvar): tvar.name;
                    case _: null;
                };
                
                if (indexVar == null) return null;
                
                // Right side should be string.length field access
                var stringVar = switch(rightExpr.expr) {
                    case TField(objExpr, FInstance(_, _, cf)) if (cf.get().name == "length"):
                        switch(objExpr.expr) {
                            case TLocal(tvar): tvar.name;
                            case _: null;
                        };
                    case _: null;
                };
                
                if (stringVar != null) {
                    #if debug_loops
                    // trace('[XRay PatternDetector] ✓ String length comparison: ${indexVar} < ${stringVar}.length');
                    #end
                    {stringVar: stringVar, indexVar: indexVar};
                } else {
                    null;
                }
                
            case _: null;
        };
    }

    /**
     * Detect character access patterns in loop body
     * 
     * WHY: Character iteration loops access individual characters via charAt(i) or cca(i).
     *      These patterns indicate binary comprehension is appropriate: `for <<char <- s>>`
     * 
     * WHAT: Searches loop body AST for character access method calls on the string variable
     *       using the index variable. Handles both charAt(i) and cca(i) patterns.
     * 
     * HOW: Recursive AST traversal looking for TCall expressions with charAt/cca method names.
     *      Validates that the object is the expected string variable and parameter is the index.
     * 
     * @param body Loop body expression to search
     * @param stringVar Expected string variable name
     * @param indexVar Expected index variable name
     * @return True if character access pattern detected, null otherwise
     */
    private static function findCharacterAccess(body: TypedExpr, stringVar: String, indexVar: String): Null<Bool> {
        #if debug_loops
        // trace('[XRay PatternDetector] - Searching for character access: ${stringVar}.charAt(${indexVar}) or ${stringVar}.cca(${indexVar})');
        #end
        
        function searchExpr(expr: TypedExpr): Bool {
            return switch(expr.expr) {
                case TCall(methodExpr, [paramExpr]):
                    // Check if this is charAt or cca method call
                    switch(methodExpr.expr) {
                        case TField(objExpr, FInstance(_, _, cf)):
                            var methodName = cf.get().name;
                            if (methodName == "charAt" || methodName == "cca") {
                                // Verify object is the string variable
                                var objVar = switch(objExpr.expr) {
                                    case TLocal(tvar): tvar.name;
                                    case _: null;
                                };
                                
                                // Verify parameter is the index variable
                                var paramVar = switch(paramExpr.expr) {
                                    case TLocal(tvar): tvar.name;
                                    case _: null;
                                };
                                
                                if (objVar == stringVar && paramVar == indexVar) {
                                    #if debug_loops
                                    // trace('[XRay PatternDetector] ✓ Character access found: ${stringVar}.${methodName}(${indexVar})');
                                    #end
                                    return true;
                                }
                            }
                            false;
                        case _: false;
                    }
                
                case TBlock(exprs):
                    Lambda.exists(exprs, searchExpr);
                    
                case TIf(condition, ifExpr, elseExpr):
                    searchExpr(condition) || searchExpr(ifExpr) || (elseExpr != null && searchExpr(elseExpr));
                    
                case TVar(tvar, initExpr):
                    initExpr != null && searchExpr(initExpr);
                    
                case TBinop(op, e1, e2):
                    searchExpr(e1) || searchExpr(e2);
                    
                case _: false;
            };
        }
        
        return if (searchExpr(body)) true else null;
    }

    /**
     * Detect array length comparison patterns for indexed iteration
     * 
     * WHY: Array iteration commonly uses `i < array.length` condition pattern.
     *      Need to extract both the index variable and array variable to generate
     *      idiomatic Enum.with_index pattern.
     * 
     * WHAT: Analyzes binary comparison expressions to find length-based loop conditions
     *       for array access patterns. Handles variations like `i < arr.length`.
     * 
     * HOW: AST traversal of TBinop expressions with OpLt operator.
     *      Left side must be local variable (index), right side must be field access (.length)
     *      on an array variable.
     * 
     * @param expr Loop condition expression to analyze  
     * @return Object with arrayVar and indexVar names if detected, null otherwise
     */
    private static function findArrayLengthComparison(expr: TypedExpr): Null<{arrayVar: String, indexVar: String}> {
        #if debug_loops
        // trace('[XRay PatternDetector] - Analyzing for array length comparison...');
        #end
        
        return switch(expr.expr) {
            case TBinop(OpLt, leftExpr, rightExpr):
                // Left side should be index variable (TLocal)
                var indexVar = switch(leftExpr.expr) {
                    case TLocal(tvar): tvar.name;
                    case _: null;
                };
                
                if (indexVar == null) return null;
                
                // Right side should be array.length field access
                var arrayVar = switch(rightExpr.expr) {
                    case TField(objExpr, FInstance(_, _, cf)) if (cf.get().name == "length"):
                        switch(objExpr.expr) {
                            case TLocal(tvar): tvar.name;
                            case _: null;
                        };
                    case _: null;
                };
                
                if (arrayVar != null) {
                    #if debug_loops
                    // trace('[XRay PatternDetector] ✓ Array length comparison: ${indexVar} < ${arrayVar}.length');
                    #end
                    {arrayVar: arrayVar, indexVar: indexVar};
                } else {
                    null;
                }
                
            case _: null;
        };
    }

    /**
     * Detect Enum.at patterns in desugared loops
     * 
     * WHY: When Haxe desugars for loops, it often generates Enum.at(array, index) patterns.
     *      These are clear indicators of indexed iteration that should use Enum.with_index.
     * 
     * WHAT: Searches for Enum.at(array, index) calls in the loop body and extracts
     *       the array and index variable names.
     * 
     * HOW: Recursive AST traversal looking for TCall with Enum.at pattern.
     * 
     * @param body Loop body to search
     * @return Object with arrayVar and indexVar if pattern found, null otherwise
     */
    private static function findEnumAtPattern(body: TypedExpr): Null<{arrayVar: String, indexVar: String}> {
        // Debug: Always trace to understand what we're looking at
        // trace('[XRay PatternDetector] - Looking for Enum.at pattern in body...');
        // trace('[XRay PatternDetector] Body expr type: ${Type.enumConstructor(body.expr)}');
        
        var result: {arrayVar: String, indexVar: String} = null;
        
        function searchExpr(expr: TypedExpr): Bool {
            return switch(expr.expr) {
                case TCall(func, [arrayExpr, indexExpr]):
                    // Check if this is Enum.at
                    switch(func.expr) {
                        case TField(obj, FStatic(classType, cf)):
                            if (classType.get().name == "Enum" && cf.get().name == "at") {
                                // Extract array variable
                                var arrayVar = switch(arrayExpr.expr) {
                                    case TLocal(tvar): tvar.name;
                                    case _: null;
                                };
                                
                                // Extract index variable (could be direct var or expression)
                                var indexVar = switch(indexExpr.expr) {
                                    case TLocal(tvar): tvar.name;
                                    case _: null;
                                };
                                
                                if (arrayVar != null && indexVar != null) {
                                    result = {arrayVar: arrayVar, indexVar: indexVar};
                                    #if debug_loops
                                    // trace('[XRay PatternDetector] ✓ Found Enum.at(${arrayVar}, ${indexVar})');
                                    #end
                                    return true;
                                }
                            }
                            false;
                        case _: false;
                    }
                    
                case TVar(tvar, init):
                    // Also check variable assignments like: item = Enum.at(array, i)
                    if (init != null) searchExpr(init) else false;
                    
                case TBlock(exprs):
                    Lambda.exists(exprs, searchExpr);
                    
                case TBinop(_, e1, e2):
                    searchExpr(e1) || searchExpr(e2);
                    
                case _: false;
            }
        }
        
        searchExpr(body);
        return result;
    }
    
    /**
     * Detect array access by index patterns in loop body
     * 
     * WHY: Indexed array iteration accesses elements via array[i] or array.get(i).
     *      These patterns indicate Enum.with_index is appropriate for idiomatic Elixir.
     * 
     * WHAT: Searches loop body AST for array access expressions using the index variable.
     *       Handles both bracket notation and method call patterns.
     * 
     * HOW: Recursive AST traversal looking for TArray expressions (array[index]) or
     *      TCall expressions with "get" method name. Validates object and parameter names.
     * 
     * @param body Loop body expression to search
     * @param arrayVar Expected array variable name
     * @param indexVar Expected index variable name  
     * @return True if array access pattern detected, false otherwise
     */
    private static function findArrayAccessByIndex(body: TypedExpr, arrayVar: String, indexVar: String): Bool {
        #if debug_loops
        // trace('[XRay PatternDetector] - Searching for array access: ${arrayVar}[${indexVar}] or ${arrayVar}.get(${indexVar})');
        #end
        
        function searchExpr(expr: TypedExpr): Bool {
            return switch(expr.expr) {
                // Array bracket access: array[index]
                case TArray(arrayExpr, indexExpr):
                    var arrVar = switch(arrayExpr.expr) {
                        case TLocal(tvar): tvar.name;
                        case _: null;
                    };
                    
                    var idxVar = switch(indexExpr.expr) {
                        case TLocal(tvar): tvar.name;
                        case _: null;
                    };
                    
                    if (arrVar == arrayVar && idxVar == indexVar) {
                        #if debug_loops
                        // trace('[XRay PatternDetector] ✓ Array bracket access: ${arrayVar}[${indexVar}]');
                        #end
                        return true;
                    }
                    false;
                
                // Array method access: array.get(index)
                case TCall(methodExpr, [paramExpr]):
                    switch(methodExpr.expr) {
                        case TField(objExpr, FInstance(_, _, cf)) if (cf.get().name == "get"):
                            var objVar = switch(objExpr.expr) {
                                case TLocal(tvar): tvar.name;
                                case _: null;
                            };
                            
                            var paramVar = switch(paramExpr.expr) {
                                case TLocal(tvar): tvar.name;
                                case _: null;
                            };
                            
                            if (objVar == arrayVar && paramVar == indexVar) {
                                #if debug_loops
                                // trace('[XRay PatternDetector] ✓ Array method access: ${arrayVar}.get(${indexVar})');
                                #end
                                return true;
                            }
                            false;
                        case _: false;
                    }
                
                case TBlock(exprs):
                    Lambda.exists(exprs, searchExpr);
                    
                case TIf(condition, ifExpr, elseExpr):
                    searchExpr(condition) || searchExpr(ifExpr) || (elseExpr != null && searchExpr(elseExpr));
                    
                case TVar(tvar, initExpr):
                    initExpr != null && searchExpr(initExpr);
                    
                case TBinop(op, e1, e2):
                    searchExpr(e1) || searchExpr(e2);
                    
                case TCall(callExpr, params):
                    searchExpr(callExpr) || Lambda.exists(params, searchExpr);
                    
                case _: false;
            };
        }
        
        return searchExpr(body);
    }
}

#end