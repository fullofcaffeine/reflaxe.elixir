#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;

using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * TempVariableOptimizer: Specialized compiler for temporary variable pattern optimization
 * 
 * WHY: Haxe generates temporary variables for ternary operators and switch expressions.
 *      These patterns need optimization to produce idiomatic Elixir code.
 * WHAT: Detects and optimizes temporary variable patterns, converting them to direct
 *       value expressions instead of assignment sequences.
 * HOW: Pattern matches on AST structures to identify temp variable usage, then
 *      generates optimized Elixir that eliminates unnecessary variable assignments.
 */
@:nullSafety(Off)
class TempVariableOptimizer {
    var compiler: ElixirCompiler;

    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }

    public function detectTempVariablePattern(expressions: Array<TypedExpr>): Null<String> {
        #if debug_temp_var
        trace('[TempVariableOptimizer] detectTempVariablePattern called with ${expressions.length} expressions');
        for (i in 0...expressions.length) {
            trace('[TempVariableOptimizer] Expression $i: ${expressions[i].expr}');
        }
        #end
        
        if (expressions.length < 3) {
            #if debug_temp_var
            trace('[TempVariableOptimizer] Not enough expressions for pattern');
            #end
            return null;
        }
        
        // Pattern: [TVar(temp, nil), TSwitch(...), TLocal(temp)]
        var first = expressions[0];
        var last = expressions[expressions.length - 1];
        
        #if debug_temp_var
        trace('[TempVariableOptimizer] First expr: ${first.expr}');
        trace('[TempVariableOptimizer] Last expr: ${last.expr}');
        #end
        
        // Check first: temp_var = nil
        var tempVarName: String = null;
        switch (first.expr) {
            case TVar(tvar, expr):
                var varName = compiler.getOriginalVarName(tvar);
                if ((varName.indexOf("temp_") == 0 || varName.indexOf("temp") == 0) && (expr == null || isNilExpression(expr))) {
                    tempVarName = varName;
                } else {
                    return null;
                }
            case _:
                return null;
        }
        
        // Check last: return temp_var (can be TLocal or TReturn(TLocal))
        var lastVarName: String = null;
        switch (last.expr) {
            case TLocal(v):
                lastVarName = compiler.getOriginalVarName(v);
            case TReturn(expr):
                switch (expr.expr) {
                    case TLocal(v):
                        lastVarName = compiler.getOriginalVarName(v);
                    case _:
                }
            case _:
        }
        
        if (lastVarName == tempVarName) {
            // Check if there's a TSwitch or TIf in between (for ternary operators)
            for (i in 1...expressions.length - 1) {
                var expr = expressions[i];
                
                // CRITICAL FIX: Unwrap TMeta expressions to find underlying TSwitch/TIf
                // Haxe often wraps switch expressions in TMeta for AST preservation
                while (true) {
                    switch (expr.expr) {
                        case TMeta(_, innerExpr):
                            expr = innerExpr;
                        case TSwitch(_, _, _):
                            #if debug_temp_var
                            trace('[TempVariableOptimizer] ✓ Found TSwitch (possibly wrapped in TMeta) - pattern detected');
                            #end
                            return tempVarName;
                        case TIf(_, _, _):
                            #if debug_temp_var
                            trace('[TempVariableOptimizer] ✓ Found TIf (possibly wrapped in TMeta) - pattern detected');
                            #end
                            return tempVarName;
                        case _:
                            break;
                    }
                }
            }
        }
        
        return null;
    }

    public function optimizeTempVariablePattern(tempVarName: String, expressions: Array<TypedExpr>): String {
        #if debug_temp_var
        trace('[TempVariableOptimizer] optimizeTempVariablePattern called with tempVar: ${tempVarName}');
        trace('[TempVariableOptimizer] Number of expressions: ${expressions.length}');
        #end
        
        // Find the switch expression or if expression (for ternary operators)
        for (i in 1...expressions.length - 1) {
            var expr = expressions[i];
            
            // CRITICAL FIX: Unwrap TMeta expressions to find underlying TSwitch/TIf
            // Same as in detection - optimization must handle TMeta-wrapped expressions
            while (true) {
                switch (expr.expr) {
                    case TMeta(_, innerExpr):
                        expr = innerExpr;
                        continue;
                    case TSwitch(switchExpr, cases, defaultExpr):
                        #if debug_temp_var
                        trace('[TempVariableOptimizer] Found TSwitch at index ${i} (unwrapped from TMeta)');
                        trace('[TempVariableOptimizer] Transforming switch to return values directly...');
                        #end
                        
                        // CRITICAL FIX: Transform switch cases to return values directly
                        // instead of generating assignments to temp variables
                        // This prevents variable shadowing in Elixir's scoped case expressions
                        
                        // Transform case bodies to strip temp variable assignments
                        var optimizedCases = transformCasesToDirectReturns(cases, tempVarName);
                        var optimizedDefault = defaultExpr != null ? 
                            stripTempVariableAssignment(defaultExpr, tempVarName) : null;
                        
                        var originalCaseArmContext = compiler.isCompilingCaseArm;
                        compiler.isCompilingCaseArm = true;
                        
                        // Compile the switch with optimized cases that return values directly
                        // The ENTIRE block becomes just the switch expression returning a value
                        var result = compiler.compileSwitchExpression(switchExpr, optimizedCases, optimizedDefault);
                        
                        #if debug_temp_var
                        trace('[TempVariableOptimizer] ✓ OPTIMIZATION COMPLETE - returning pure switch expression');
                        trace('[TempVariableOptimizer] Generated: ${result.substring(0, 100)}...');
                        #end
                        
                        // Restore original context
                        compiler.isCompilingCaseArm = originalCaseArmContext;
                        
                        // Return JUST the switch - it now returns the value directly
                        // No need for temp_result = nil or return temp_result wrapper
                        return result;
                    case TIf(condition, thenExpr, elseExpr):
                        #if debug_temp_var
                        trace('[TempVariableOptimizer] Found TIf at index ${i} (unwrapped from TMeta)');
                        trace('[TempVariableOptimizer] Transforming if to return values directly...');
                        #end
                        
                        var conditionCompiled = compiler.compileExpression(condition);
                        
                        // Extract actual values from temp variable assignments
                        var thenValue = extractValueFromTempAssignment(thenExpr, tempVarName);
                        var elseValue = elseExpr != null ? extractValueFromTempAssignment(elseExpr, tempVarName) : null;
                        
                        if (thenValue != null && elseValue != null) {
                            // Generate direct ternary expression without temp variables
                            return 'if (${conditionCompiled}), do: ${thenValue}, else: ${elseValue}';
                        } else {
                            // If we can't optimize, ensure proper variable scoping
                            var originalCaseArmContext = compiler.isCompilingCaseArm;
                            compiler.isCompilingCaseArm = true;
                            
                            var compiledIf = compiler.compileExpression(expressions[i]);
                            
                            // Ensure temp variable is declared properly
                            var result = '${tempVarName} = nil\n${compiledIf}';
                            
                            compiler.isCompilingCaseArm = originalCaseArmContext;
                            return result;
                        }
                    case _:
                        // Not a TSwitch or TIf, break out of while loop
                        break;
                }
            }
        }
        
        // Fallback: compile normally if pattern detection was wrong
        var compiledStatements = [];
        for (expr in expressions) {
            var compiled = compiler.compileExpression(expr);
            if (compiled != null && compiled.length > 0) {
                compiledStatements.push(compiled);
            }
        }
        
        var result = compiledStatements.join("\n");
        
        // Post-process to fix temp variable scope issues
        if (tempVarName != null) {
            result = fixTempVariableScoping(result, tempVarName);
            
            // Also fix numbered variants (temp_array1, temp_array2, etc.)
            result = fixAllTempVariableVariants(result, tempVarName);
        }
        
        return result;
    }

    public function fixTempVariableScoping(code: String, tempVarName: String): String {
        // PRIORITY FIX: Handle temp_array scoping issues specifically
        // These are caused by ternary operations like: config != null ? [config] : []
        if (tempVarName.indexOf("temp_array") == 0) {
            var result = fixTempArrayScopingIssues(code, tempVarName);
            if (result != code) {
                return result; // If we fixed something, return the fixed version
            }
        }
        
        // Fix pattern: if (cond), do: temp_var = val1, else: temp_var = val2\nvar = temp_var
        // Into: var = if (cond), do: val1, else: val2
        // Also fix block-style patterns:
        // if (cond) do\n  temp_var = val1\nelse\n  temp_var = val2\nend\nvar = temp_var
        var lines = code.split('\n');
        var fixedLines = [];
        var i = 0;
        
        while (i < lines.length) {
            var line = lines[i];
            
            // Handle inline if expressions (original logic)
            if (line.indexOf('if (') == 0 && line.indexOf(', do: ${tempVarName} =') > 0) {
                // Check next line for temp variable usage
                if (i + 1 < lines.length) {
                    var nextLine = lines[i + 1];
                    var pattern = ~/^(\w+)\s*=\s*${tempVarName}\s*$/;
                    if (pattern.match(nextLine)) {
                        var targetVar = pattern.matched(1);
                        
                        // Transform the if expression
                        var transformedLine = line
                            .replace(', do: ${tempVarName} =', ', do:')
                            .replace(', else: ${tempVarName} =', ', else:');
                        
                        fixedLines.push('${targetVar} = ${transformedLine}');
                        i += 2; // Skip the next line since we consumed it
                        continue;
                    }
                }
            }
            
            // Handle block-style if statements (NEW LOGIC)
            if (line.indexOf('if (') == 0 && line.indexOf(') do') > 0) {
                var blockResult = fixBlockStyleIfStatement(lines, i, tempVarName);
                if (blockResult != null) {
                    fixedLines.push(blockResult.transformedCode);
                    i = blockResult.nextIndex;
                    continue;
                }
            }
            
            fixedLines.push(line);
            i++;
        }
        
        return fixedLines.join('\n');
    }
    
    /**
     * Fix block-style if statements with temp variable scoping issues
     * 
     * Pattern:
     * if (condition) do
     *   temp_var = value1  
     * else
     *   temp_var = value2
     * end
     * target_var = temp_var
     * 
     * Transform to:
     * target_var = if (condition), do: value1, else: value2
     */
    private function fixBlockStyleIfStatement(lines: Array<String>, startIndex: Int, tempVarName: String): Null<{transformedCode: String, nextIndex: Int}> {
        var i = startIndex;
        var ifLine = lines[i];
        
        // Extract condition from "if (condition) do"
        var conditionPattern = ~/if \((.*?)\) do/;
        if (!conditionPattern.match(ifLine)) return null;
        var condition = conditionPattern.matched(1);
        
        i++; // Move to next line after "if (condition) do"
        
        // Look for temp variable assignment in if branch
        var thenValue: String = null;
        var elseValue: String = null;
        
        // Parse if branch - look for temp_var assignment
        while (i < lines.length && StringTools.trim(lines[i]) != "else" && StringTools.trim(lines[i]) != "end") {
            var currentLine = StringTools.trim(lines[i]);
            var assignPattern = new EReg('${tempVarName}\\s*=\\s*(.+)', '');
            if (assignPattern.match(currentLine)) {
                thenValue = assignPattern.matched(1);
                break;
            }
            i++;
        }
        
        // Skip to else branch
        while (i < lines.length && StringTools.trim(lines[i]) != "else") {
            i++;
        }
        
        if (i >= lines.length || StringTools.trim(lines[i]) != "else") return null;
        i++; // Move past "else"
        
        // Parse else branch - look for temp_var assignment  
        while (i < lines.length && StringTools.trim(lines[i]) != "end") {
            var currentLine = StringTools.trim(lines[i]);
            var assignPattern = new EReg('${tempVarName}\\s*=\\s*(.+)', '');
            if (assignPattern.match(currentLine)) {
                elseValue = assignPattern.matched(1);
                break;
            }
            i++;
        }
        
        // Skip to end
        while (i < lines.length && StringTools.trim(lines[i]) != "end") {
            i++;
        }
        
        if (i >= lines.length || StringTools.trim(lines[i]) != "end") return null;
        i++; // Move past "end"
        
        // Look for target variable assignment on next line
        if (i >= lines.length) return null;
        var assignmentLine = lines[i];
        var targetPattern = new EReg('^(\\w+)\\s*=\\s*${tempVarName}\\s*$', '');
        if (!targetPattern.match(StringTools.trim(assignmentLine))) return null;
        
        var targetVar = targetPattern.matched(1);
        
        // Validate we have both values
        if (thenValue == null || elseValue == null) return null;
        
        // Create transformed inline if expression
        var transformedCode = '${targetVar} = if (${condition}), do: ${thenValue}, else: ${elseValue}';
        
        return {
            transformedCode: transformedCode,
            nextIndex: i + 1  // Skip the assignment line
        };
    }
    
    /**
     * Fix temp_array scoping issues specifically
     * 
     * WHY: Ternary operations like `config != null ? [config] : []` generate block-style
     *      if statements where temp_array is assigned inside if/else branches but used outside.
     * WHAT: Transforms these to inline if expressions to avoid scoping issues.
     * HOW: Pattern matches the specific temp_array assignment + usage pattern and converts
     *      block-style if to inline form.
     */
    private function fixTempArrayScopingIssues(code: String, tempVarName: String): String {
        // Pattern we're looking for:
        // if ((config != nil)) do
        //   temp_array = [config]
        // else
        //   temp_array = []
        // end
        // args = temp_array
        //
        // Transform to:
        // args = if (config != nil), do: [config], else: []
        
        var lines = code.split('\n');
        var result = [];
        var i = 0;
        
        while (i < lines.length) {
            var line = StringTools.trim(lines[i]);
            
            // Look for if statement that assigns temp_array
            if (line.indexOf('if ((') == 0 && line.indexOf(')) do') > 0) {
                var fixResult = tryFixTempArrayBlock(lines, i, tempVarName);
                if (fixResult != null) {
                    result.push(fixResult.transformedCode);
                    i = fixResult.nextIndex;
                    continue;
                }
            }
            
            result.push(lines[i]);
            i++;
        }
        
        return result.join('\n');
    }
    
    /**
     * Try to fix a specific temp_array block pattern
     */
    private function tryFixTempArrayBlock(lines: Array<String>, startIndex: Int, tempVarName: String): Null<{transformedCode: String, nextIndex: Int}> {
        var i = startIndex;
        if (i >= lines.length) return null;
        
        var ifLine = StringTools.trim(lines[i]);
        
        // Extract condition from "if ((condition)) do"
        var conditionPattern = ~/if \(\((.*?)\)\) do/;
        if (!conditionPattern.match(ifLine)) return null;
        var condition = conditionPattern.matched(1);
        
        i++; // Move past if line
        
        // Look for temp_array assignment in then branch
        var thenValue: String = null;
        while (i < lines.length && StringTools.trim(lines[i]) != "else" && StringTools.trim(lines[i]) != "end") {
            var currentLine = StringTools.trim(lines[i]);
            var assignPattern = new EReg('${tempVarName}\\s*=\\s*(.+)', '');
            if (assignPattern.match(currentLine)) {
                thenValue = assignPattern.matched(1);
                break;
            }
            i++;
        }
        
        if (thenValue == null) return null;
        
        // Skip to else branch
        while (i < lines.length && StringTools.trim(lines[i]) != "else") {
            i++;
        }
        if (i >= lines.length || StringTools.trim(lines[i]) != "else") return null;
        
        i++; // Move past else line
        
        // Look for temp_array assignment in else branch
        var elseValue: String = null;
        while (i < lines.length && StringTools.trim(lines[i]) != "end") {
            var currentLine = StringTools.trim(lines[i]);
            var assignPattern = new EReg('${tempVarName}\\s*=\\s*(.+)', '');
            if (assignPattern.match(currentLine)) {
                elseValue = assignPattern.matched(1);
                break;
            }
            i++;
        }
        
        if (elseValue == null) return null;
        
        // Skip to end
        while (i < lines.length && StringTools.trim(lines[i]) != "end") {
            i++;
        }
        if (i >= lines.length) return null;
        
        i++; // Move past end line
        
        // Look for the target variable assignment: args = temp_array
        if (i < lines.length) {
            var usageLine = StringTools.trim(lines[i]);
            var usagePattern = new EReg('(\\w+)\\s*=\\s*${tempVarName}\\s*$', '');
            if (usagePattern.match(usageLine)) {
                var targetVar = usagePattern.matched(1);
                
                // Generate inline if expression
                var inlineIf = 'if (${condition}), do: ${thenValue}, else: ${elseValue}';
                var transformedCode = '${targetVar} = ${inlineIf}';
                
                return {
                    transformedCode: transformedCode,
                    nextIndex: i + 1
                };
            }
        }
        
        return null;
    }
    
    /**
     * Fix all numbered variants of temp variables (temp_array1, temp_array2, etc.)
     */
    private function fixAllTempVariableVariants(code: String, baseTempVarName: String): String {
        var result = code;
        
        // Find all temp variable variants in the code
        var tempVarPattern = new EReg('(${baseTempVarName}\\d*)\\s*=', 'g');
        var foundVariants = new Map<String, Bool>();
        
        // Extract all temp variable names (temp_array, temp_array1, temp_array2, etc.)
        var pos = 0;
        while (tempVarPattern.matchSub(code, pos)) {
            var varName = tempVarPattern.matched(1);
            foundVariants.set(varName, true);
            pos = tempVarPattern.matchedPos().pos + tempVarPattern.matchedPos().len;
        }
        
        // Apply fix to each variant found
        for (variant in foundVariants.keys()) {
            result = fixTempVariableScoping(result, variant);
        }
        
        return result;
    }

    public function detectTempVariableAssignmentPattern(ifBranch: TypedExpr, elseBranch: Null<TypedExpr>): Null<{varName: String}> {
        // Look for pattern: temp_var = value in both branches
        var thenVarName = extractAssignmentVariable(ifBranch);
        var elseVarName = elseBranch != null ? extractAssignmentVariable(elseBranch) : null;
        
        if (thenVarName != null && (elseVarName == null || thenVarName == elseVarName)) {
            if (thenVarName.indexOf("temp_") == 0 || thenVarName.indexOf("temp") == 0) {
                return {varName: thenVarName};
            }
        }
        
        return null;
    }

    public function detectTempVariableAssignmentSequence(expressions: Array<TypedExpr>): Null<{ifIndex: Int, assignIndex: Int, tempVar: String, targetVar: String}> {
        for (i in 0...expressions.length) {
            switch (expressions[i].expr) {
                case TIf(_, ifBranch, elseBranch):
                    var tempVarPattern = detectTempVariableAssignmentPattern(ifBranch, elseBranch);
                    if (tempVarPattern != null) {
                        // Look for assignment to this temp variable in next expressions
                        for (j in (i + 1)...expressions.length) {
                            switch (expressions[j].expr) {
                                case TBinop(OpAssign, targetExpr, sourceExpr):
                                    var targetVar = extractVariableNameFromExpr(targetExpr);
                                    var sourceVar = extractVariableNameFromExpr(sourceExpr);
                                    
                                    if (sourceVar == tempVarPattern.varName && targetVar != null) {
                                        return {
                                            ifIndex: i,
                                            assignIndex: j,
                                            tempVar: tempVarPattern.varName,
                                            targetVar: targetVar
                                        };
                                    }
                                case _:
                            }
                        }
                    }
                case _:
            }
        }
        return null;
    }

    public function optimizeTempVariableAssignmentSequence(sequence: {ifIndex: Int, assignIndex: Int, tempVar: String, targetVar: String}, expressions: Array<TypedExpr>): String {
        var compiledStatements = [];
        
        for (i in 0...expressions.length) {
            if (i == sequence.ifIndex) {
                // Compile the if expression and transform it
                switch (expressions[i].expr) {
                    case TIf(condition, ifBranch, elseBranch):
                        var conditionCompiled = compiler.compileExpression(condition);
                        var thenValue = extractValueFromTempAssignment(ifBranch, sequence.tempVar);
                        var elseValue = elseBranch != null ? extractValueFromTempAssignment(elseBranch, sequence.tempVar) : "nil";
                        
                        if (thenValue != null && elseValue != null) {
                            var optimizedIf = '${sequence.targetVar} = if (${conditionCompiled}), do: ${thenValue}, else: ${elseValue}';
                            compiledStatements.push(optimizedIf);
                        } else {
                            // Fallback to normal compilation
                            var compiled = compiler.compileExpression(expressions[i]);
                            if (compiled != null && compiled.length > 0) {
                                compiledStatements.push(compiled);
                            }
                        }
                    case _:
                        var compiled = compiler.compileExpression(expressions[i]);
                        if (compiled != null && compiled.length > 0) {
                            compiledStatements.push(compiled);
                        }
                }
            } else if (i == sequence.assignIndex) {
                // Skip the assignment since it's been optimized into the if expression
                continue;
            } else {
                // Normal compilation for other expressions
                var compiled = compiler.compileExpression(expressions[i]);
                if (compiled != null && compiled.length > 0) {
                    compiledStatements.push(compiled);
                }
            }
        }
        
        return compiledStatements.join('\n');
    }

    private function extractValueFromTempAssignment(expr: TypedExpr, tempVarName: String): Null<String> {
        if (expr == null) return null;
        switch (expr.expr) {
            case TBinop(OpAssign, left, right):
                switch (left.expr) {
                    case TLocal(v):
                        var varName = compiler.getOriginalVarName(v);
                        if (varName == tempVarName) {
                            return compiler.compileExpression(right);
                        }
                    case _:
                }
            case _:
        }
        return null;
    }

    private function extractAssignmentVariable(expr: TypedExpr): Null<String> {
        switch (expr.expr) {
            case TBinop(OpAssign, left, _):
                switch (left.expr) {
                    case TLocal(v):
                        return compiler.getOriginalVarName(v);
                    case _:
                }
            case _:
        }
        return null;
    }

    private function extractVariableNameFromExpr(expr: TypedExpr): Null<String> {
        switch (expr.expr) {
            case TLocal(v):
                return compiler.getOriginalVarName(v);
            case _:
        }
        return null;
    }

    private function isNilExpression(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TConst(TNull): true;
            case TConst(TString("")): true;
            case _: false;
        };
    }
    
    /**
     * Transform switch cases to return values directly instead of assignments
     * 
     * WHY: When a switch is used as an expression (temp variable pattern),
     *      case bodies should return values directly, not assign to temp variables
     * 
     * WHAT: Strips assignment patterns from case bodies, leaving just the values
     * 
     * HOW: For each case, detect if the body is an assignment to the temp variable
     *      and extract just the value being assigned
     * 
     * @param cases Original switch cases with potential assignments
     * @param tempVarName Name of the temporary variable to strip
     * @return Transformed cases that return values directly
     */
    private function transformCasesToDirectReturns(
        cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, 
        tempVarName: String
    ): Array<{values: Array<TypedExpr>, expr: TypedExpr}> {
        var optimizedCases = [];
        
        for (caseData in cases) {
            var optimizedExpr = stripTempVariableAssignment(caseData.expr, tempVarName);
            optimizedCases.push({
                values: caseData.values,
                expr: optimizedExpr
            });
        }
        
        return optimizedCases;
    }
    
    /**
     * Strip temp variable assignment from an expression
     * 
     * WHY: Case bodies in temp variable patterns contain assignments like
     *      `temp_result = "value"` which cause variable shadowing in Elixir
     * 
     * WHAT: Extracts the value being assigned, or returns the expression unchanged
     *       if it's not an assignment to the temp variable
     * 
     * HOW: Pattern matches on TBinop(OpAssign) where left side is the temp variable,
     *      returns the right side (the value) directly
     * 
     * @param expr Expression that might contain temp variable assignment
     * @param tempVarName Name of the temporary variable to strip
     * @return The value being assigned, or the original expression
     */
    private function stripTempVariableAssignment(expr: TypedExpr, tempVarName: String): TypedExpr {
        return switch (expr.expr) {
            case TBinop(OpAssign, left, right):
                // Check if this is an assignment to our temp variable
                switch (left.expr) {
                    case TLocal(v):
                        var varName = compiler.getOriginalVarName(v);
                        if (varName == tempVarName) {
                            // Return just the value being assigned
                            return right;
                        }
                        // Not our temp variable, return original
                        expr;
                    case _:
                        expr;
                }
            case TBlock(expressions):
                // Handle block expressions that might contain the assignment
                if (expressions.length == 1) {
                    // Single expression block, recurse
                    var optimized = stripTempVariableAssignment(expressions[0], tempVarName);
                    if (optimized != expressions[0]) {
                        // Create new block with optimized expression
                        {expr: TBlock([optimized]), pos: expr.pos, t: expr.t};
                    } else {
                        expr;
                    }
                } else {
                    // Multi-expression block, check if last one is the assignment
                    var lastIndex = expressions.length - 1;
                    var optimizedLast = stripTempVariableAssignment(expressions[lastIndex], tempVarName);
                    if (optimizedLast != expressions[lastIndex]) {
                        // Create new block with optimized last expression
                        var newExpressions = expressions.copy();
                        newExpressions[lastIndex] = optimizedLast;
                        {expr: TBlock(newExpressions), pos: expr.pos, t: expr.t};
                    } else {
                        expr;
                    }
                }
            case _:
                // Not an assignment, return as-is
                expr;
        };
    }
}

#end