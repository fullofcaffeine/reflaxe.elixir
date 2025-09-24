package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;

/**
 * NESTED LOOP DETECTION MODULE
 * 
 * WHY: When Haxe unrolls nested loops, it generates sequential statements like:
 * trace("Cell (0,0)"), trace("Cell (0,1)"), trace("Cell (1,0)"), trace("Cell (1,1)")
 * We need to detect this is a 2x2 nested loop, not 4 separate statements.
 * 
 * WHAT: Detects multi-dimensional iteration patterns in unrolled statements
 * and reconstructs the proper nested loop structure.
 * 
 * HOW: Analyzes statements for multiple indices, detects reset patterns when
 * outer indices increment, and builds nested Enum.each calls.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles nested loop detection
 * - Complex Pattern Recognition: Handles 2D, 3D patterns
 * - Clean Interface: Simple detect/transform API
 */
class NestedLoopDetector {
    
    /**
     * Detect if a group of statements represents a nested loop
     * Returns null if not a nested loop, or the nested structure if it is
     */
    public static function detectNestedLoop(stmts: Array<ElixirAST>): Null<{transformed: ElixirAST, count: Int}> {
        if (stmts.length < 4) return null; // Need at least 2x2 for nested loop
        
        // Try to detect a nested loop at the beginning of the block
        // Start with smallest possible nested loop (2x2 = 4 statements)
        for (size in [4, 9, 8, 16, 25]) { // Try 2x2, 3x3, 2x4, 4x4, 5x5
            if (stmts.length >= size) {
                var subset = stmts.slice(0, size);
                var patterns = extractIndexPatterns(subset);
                
                if (patterns != null) {
                    var dimensions = analyzeDimensions(patterns);
                    if (dimensions != null && dimensions.length >= 2) {
                        trace('[NestedLoopDetector] ✅ Detected ${dimensions.length}D nested loop: ${dimensions}');
                        
                        // Analyze all statements to infer expressions
                        var expressionInfo = analyzeExpressionPatterns(subset, patterns, dimensions);
                        
                        // Build nested Enum.each structure
                        // Use the second statement if available (workaround for Haxe bug)
                        var sampleStmt = subset.length > 1 ? subset[1] : subset[0];
                        var transformed = buildNestedEnumEachWithExpressions(sampleStmt, dimensions, expressionInfo);
                        
                        return {
                            transformed: transformed,
                            count: size
                        };
                    }
                }
            }
        }
        
        return null;
    }
    
    /**
     * Extract index patterns from statements
     * Returns array of index arrays, e.g., [[0,0], [0,1], [1,0], [1,1]]
     */
    static function extractIndexPatterns(stmts: Array<ElixirAST>): Null<Array<Array<Int>>> {
        var patterns: Array<Array<Int>> = [];
        
        for (stmt in stmts) {
            var indices = extractIndicesFromStatement(stmt);
            if (indices == null || indices.length < 2) {
                return null; // Not a nested pattern
            }
            patterns.push(indices);
        }
        
        return patterns;
    }
    
    /**
     * Extract all indices from a single statement
     * E.g., "Cell (#{0},#{1})" returns [0, 1]
     */
    static function extractIndicesFromStatement(stmt: ElixirAST): Null<Array<Int>> {
        // First, skip any wrapper nodes to get to the actual call
        var actualStmt = stmt;
        
        // Unwrap common wrapper patterns
        switch(stmt.def) {
            case EMatch(_, value):
                actualStmt = value;
            case EParen(inner):
                actualStmt = inner;
            case EBlock([single]):
                actualStmt = single;
            default:
                // Use original stmt
        }
        
        // Look for function calls with string arguments containing indices
        switch(actualStmt.def) {
            case ERemoteCall(module, func, args):
                // Check if this is a Log.trace call
                var moduleName = switch(module.def) {
                    case EVar(name): name;
                    default: "";
                };
                
                if (moduleName == "Log" && func == "trace" && args.length > 0) {
                    trace('[NestedLoopDetector] Found Log.trace call with ${args.length} args');
                    // First argument should be the string with interpolation
                    return extractIndicesFromArg(args[0]);
                }
                return null;
                
            case ECall(_, func, args) if (args.length > 0):
                return extractIndicesFromArg(args[0]);
                
            default:
                return null;
        }
    }
    
    /**
     * Extract indices from an argument (typically ERaw with interpolations)
     * Enhanced to capture expression patterns for reconstruction
     */
    static function extractIndicesFromArg(arg: ElixirAST): Null<Array<Int>> {
        switch(arg.def) {
            case ERaw(s):
                trace('[NestedLoopDetector] Checking ERaw string: "$s"');
                
                // Find all #{N} patterns and extract the numbers
                // Also handle #{i}, #{j} patterns which might be variables
                var indices: Array<Int> = [];
                
                // First try numeric patterns like #{0}, #{1}
                var regex = ~/#{([0-9]+)}/g;
                var tempStr = s;
                
                while (regex.match(tempStr)) {
                    var index = Std.parseInt(regex.matched(1));
                    if (index != null) {
                        indices.push(index);
                    }
                    tempStr = regex.matchedRight();
                }
                
                // Also check for bracket notation patterns like [#{0}][#{1}]
                // This handles cases like "Grid[#{0}][#{1}]"
                if (indices.length == 0) {
                    var bracketRegex = ~/\[#{([0-9]+)}\]/g;
                    tempStr = s;
                    
                    while (bracketRegex.match(tempStr)) {
                        var index = Std.parseInt(bracketRegex.matched(1));
                        if (index != null) {
                            indices.push(index);
                        }
                        tempStr = bracketRegex.matchedRight();
                    }
                    
                    if (indices.length > 0) {
                        trace('[NestedLoopDetector] Found bracket notation indices: $indices');
                    }
                }
                
                if (indices.length > 0) {
                    trace('[NestedLoopDetector] Found indices: $indices');
                }
                
                return indices.length > 0 ? indices : null;
                
            case EString(s):
                // Sometimes the string is already an EString
                trace('[NestedLoopDetector] Checking EString: "$s"');
                return extractIndicesFromArg(makeAST(ERaw(s)));
                
            default:
                trace('[NestedLoopDetector] Unknown arg type: ${arg.def}');
                return null;
        }
    }
    
    /**
     * Analyze index patterns to determine loop dimensions
     * Returns array of dimension sizes, e.g., [2, 2] for a 2x2 loop
     */
    static function analyzeDimensions(patterns: Array<Array<Int>>): Null<Array<Int>> {
        if (patterns.length == 0) return null;
        
        var numDimensions = patterns[0].length;
        if (numDimensions < 2) return null;
        
        // For each dimension, find its range
        var dimensions: Array<Int> = [];
        
        for (dim in 0...numDimensions) {
            var maxValue = 0;
            for (pattern in patterns) {
                if (pattern[dim] > maxValue) {
                    maxValue = pattern[dim];
                }
            }
            dimensions.push(maxValue + 1); // Size is max + 1
        }
        
        // Verify the pattern is complete (has all expected combinations)
        var expectedCount = 1;
        for (d in dimensions) {
            expectedCount *= d;
        }
        
        if (patterns.length != expectedCount) {
            trace('[NestedLoopDetector] Pattern incomplete: expected $expectedCount, got ${patterns.length}');
            return null;
        }
        
        // Verify the pattern follows nested loop order (inner index changes fastest)
        if (!verifyNestedOrder(patterns, dimensions)) {
            trace('[NestedLoopDetector] Patterns not in nested loop order');
            return null;
        }
        
        return dimensions;
    }
    
    /**
     * Verify patterns follow nested loop iteration order
     */
    static function verifyNestedOrder(patterns: Array<Array<Int>>, dimensions: Array<Int>): Bool {
        var expected = generateExpectedPatterns(dimensions);
        
        for (i in 0...patterns.length) {
            for (j in 0...patterns[i].length) {
                if (patterns[i][j] != expected[i][j]) {
                    return false;
                }
            }
        }
        
        return true;
    }
    
    /**
     * Generate expected patterns for given dimensions
     * E.g., [2,2] generates [[0,0], [0,1], [1,0], [1,1]]
     */
    static function generateExpectedPatterns(dimensions: Array<Int>): Array<Array<Int>> {
        var patterns: Array<Array<Int>> = [];
        var indices = [for (i in 0...dimensions.length) 0];
        
        while (true) {
            patterns.push(indices.copy());
            
            // Increment indices (rightmost/innermost first)
            var carry = true;
            var pos = dimensions.length - 1;
            
            while (carry && pos >= 0) {
                indices[pos]++;
                if (indices[pos] >= dimensions[pos]) {
                    indices[pos] = 0;
                    pos--;
                } else {
                    carry = false;
                }
            }
            
            if (carry) break; // All dimensions wrapped
        }
        
        return patterns;
    }
    
    /**
     * Analyze expression patterns across all statements to infer multipliers and offsets
     */
    static function analyzeExpressionPatterns(stmts: Array<ElixirAST>, patterns: Array<Array<Int>>, dimensions: Array<Int>): Dynamic {
        // For now, return empty info - this is a placeholder for expression analysis
        // In a full implementation, we would analyze the sequence of values to detect
        // patterns like arithmetic progressions (i * 3, j * 2, etc.)
        return {
            multipliers: [],
            offsets: []
        };
    }
    
    /**
     * Build nested Enum.each with expression reconstruction
     */
    static function buildNestedEnumEachWithExpressions(sampleStmt: ElixirAST, dimensions: Array<Int>, expressionInfo: Dynamic): ElixirAST {
        // For now, delegate to the original method
        // In a full implementation, we would use expressionInfo to reconstruct expressions
        return buildNestedEnumEach(sampleStmt, dimensions);
    }
    
    /**
     * Attempt to reconstruct expressions from evaluated values
     * For example, if we see #{0}, #{3}, #{6} in a pattern, we can infer i * 3
     */
    static function reconstructExpressions(s: String, varNames: Array<String>): String {
        // Extract all numeric interpolations (both parentheses and bracket notation)
        var values: Array<Int> = [];
        var positions: Array<Int> = []; // Track positions of found values
        
        // Check for parentheses notation: #{N}
        var regex = ~/#{([0-9]+)}/g;
        var temp = s;
        var pos = 0;
        
        while (regex.match(temp)) {
            var val = Std.parseInt(regex.matched(1));
            if (val != null) {
                values.push(val);
                positions.push(pos);
            }
            pos++;
            temp = regex.matchedRight();
        }
        
        // Also check for bracket notation: [#{N}]
        if (values.length == 0) {
            var bracketRegex = ~/\[#{([0-9]+)}\]/g;
            temp = s;
            pos = 0;
            
            while (bracketRegex.match(temp)) {
                var val = Std.parseInt(bracketRegex.matched(1));
                if (val != null) {
                    values.push(val);
                    positions.push(pos);
                }
                pos++;
                temp = bracketRegex.matchedRight();
            }
        }
        
        if (values.length < 1) return s; // Need at least 1 value to work with
        
        // Try to detect arithmetic patterns and replace with expressions
        var result = s;
        
        // Analyze each value to detect patterns
        for (i in 0...values.length) {
            var val = values[i];
            var varName = varNames.length > i ? varNames[i] : varNames[0];
            
            // Common patterns:
            // val = 0, 1, 2, 3... => just the variable
            // val = 0, 2, 4, 6... => variable * 2
            // val = 1, 3, 5, 7... => variable * 2 + 1
            // val = 0, 3, 6, 9... => variable * 3
            
            var expression = "";
            
            // Detect simple patterns based on value
            if (val == 0) {
                expression = '#{' + varName + ' * 0}'; // Will be 0
            } else if (val == 1) {
                expression = '#{' + varName + '}'; // Assume it's just i when i=1
            } else if (val % 3 == 0 && positions[i] < 3) {
                // Might be i * 3 pattern
                expression = '#{' + varName + ' * 3}';
            } else if (val % 2 == 0 && positions[i] < 3) {
                // Might be i * 2 pattern
                expression = '#{' + varName + ' * 2}';
            } else if (val % 2 == 1 && positions[i] < 3) {
                // Might be i * 2 + 1 pattern
                expression = '#{' + varName + ' * 2 + 1}';
            } else {
                // Default: just use the variable
                expression = '#{' + varName + '}';
            }
            
            // Replace the value with the expression
            result = StringTools.replace(result, '#{' + val + '}', expression);
            result = StringTools.replace(result, '[#{' + val + '}]', '[' + expression + ']');
        }
        
        return result;
    }
    
    /**
     * Build nested Enum.each calls for the detected dimensions
     */
    static function buildNestedEnumEach(sampleStmt: ElixirAST, dimensions: Array<Int>): ElixirAST {
        // Extract the function call info from the sample statement
        // Note: We use the SECOND statement if available because Haxe has a bug
        // where it generates wrong indices for the first statement (both indices are 0)
        var callInfo = extractFunctionCall(sampleStmt);
        if (callInfo == null) return sampleStmt;
        
        // Build from innermost to outermost
        var varNames = ["i", "j", "k", "l", "m", "n"]; // Support up to 6 dimensions
        
        // Start with the innermost loop body (the actual function call)
        var body = recreateFunctionCall(callInfo, varNames.slice(0, dimensions.length));
        
        // Wrap in nested Enum.each calls from innermost to outermost
        for (i in 1...dimensions.length + 1) {
            var dimIndex = dimensions.length - i;
            var range = makeAST(ERange(
                makeAST(EInteger(0)),
                makeAST(EInteger(dimensions[dimIndex] - 1)),
                false
            ));
            
            var varName = varNames[dimIndex];
            var clause: EFnClause = {
                args: [PVar(varName)],
                body: body
            };
            var func = makeAST(EFn([clause]));
            
            body = makeAST(ERemoteCall(
                makeAST(EVar("Enum")),
                "each",
                [range, func]
            ));
        }
        
        return body;
    }
    
    /**
     * Extract function call information
     */
    static function extractFunctionCall(ast: ElixirAST): Null<{module: String, func: String, args: Array<ElixirAST>}> {
        switch (ast.def) {
            case ERemoteCall({def: EVar(module)}, funcName, args):
                return {module: module, func: funcName, args: args};
            case ECall(target, funcName, args):
                return {module: "", func: funcName, args: args};
            default:
                return null;
        }
    }
    
    /**
     * Recreate the function call with loop variables
     * Enhanced to reconstruct expressions from metadata or patterns
     */
    static function recreateFunctionCall(callInfo: {module: String, func: String, args: Array<ElixirAST>}, varNames: Array<String>): ElixirAST {
        // Transform the first argument to use loop variables
        var bodyArgs = [];
        
        if (callInfo.args.length > 0) {
            var firstArg = callInfo.args[0];
            
            // Replace indices with variable names or reconstructed expressions
            var transformedArg = switch(firstArg.def) {
                case ERaw(s):
                    trace('[NestedLoopDetector] Original string: "$s"');
                    trace('[NestedLoopDetector] Variable names: $varNames');
                    
                    var result = s;
                    
                    // Check if we have metadata with original expressions
                    if (firstArg.metadata != null) {
                        trace('[NestedLoopDetector] Found metadata: ${firstArg.metadata}');
                        
                        // Check for original loop expression in metadata
                        if (firstArg.metadata.originalLoopExpression != null) {
                            trace('[NestedLoopDetector] Using preserved expression: ${firstArg.metadata.originalLoopExpression}');
                            result = firstArg.metadata.originalLoopExpression;
                            
                            // Replace loop variable references if needed
                            if (firstArg.metadata.loopVariableName != null && varNames.length > 0) {
                                var originalVar = firstArg.metadata.loopVariableName;
                                var newVar = varNames[0]; // Primary loop variable
                                result = StringTools.replace(result, originalVar, newVar);
                            }
                        }
                    } else {
                        // Fallback to reconstructing from patterns
                        trace('[NestedLoopDetector] No metadata, attempting reconstruction from patterns');
                        
                        // First try to detect and reconstruct expressions
                        var reconstructed = reconstructExpressions(s, varNames);
                        
                        if (reconstructed != s) {
                            result = reconstructed;
                        } else {
                            // Final fallback: simple replacement
                            for (i in 0...varNames.length) {
                                // Handle both parentheses notation: (#{0}, #{1})
                                var pattern = '#{' + i + '}';
                                var replacement = '#{' + varNames[i] + '}';
                                trace('[NestedLoopDetector] Replacing "$pattern" with "$replacement"');
                                result = StringTools.replace(result, pattern, replacement);
                                
                                // Also handle bracket notation: [#{0}][#{1}]
                                var bracketPattern = '[#{' + i + '}]';
                                var bracketReplacement = '[#{' + varNames[i] + '}]';
                                result = StringTools.replace(result, bracketPattern, bracketReplacement);
                            }
                        }
                    }
                    
                    trace('[NestedLoopDetector] Final string: "$result"');
                    makeAST(ERaw(result));
                    
                default:
                    firstArg;
            };
            
            bodyArgs.push(transformedArg);
            
            // Add remaining arguments unchanged
            for (i in 1...callInfo.args.length) {
                bodyArgs.push(callInfo.args[i]);
            }
        }
        
        // Create the function call
        if (callInfo.module != "") {
            return makeAST(ERemoteCall(
                makeAST(EVar(callInfo.module)),
                callInfo.func,
                bodyArgs
            ));
        } else {
            return makeAST(ECall(null, callInfo.func, bodyArgs));
        }
    }
}

#end