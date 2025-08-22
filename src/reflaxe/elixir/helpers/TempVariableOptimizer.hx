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
        if (expressions.length < 3) return null;
        
        // Pattern: [TVar(temp, nil), TSwitch(...), TLocal(temp)]
        var first = expressions[0];
        var last = expressions[expressions.length - 1];
        
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
                switch (expressions[i].expr) {
                    case TSwitch(_, _, _):
                        return tempVarName;
                    case TIf(_, _, _):
                        return tempVarName;
                    case _:
                }
            }
        }
        
        return null;
    }

    public function optimizeTempVariablePattern(tempVarName: String, expressions: Array<TypedExpr>): String {
        // Find the switch expression or if expression (for ternary operators)
        for (i in 1...expressions.length - 1) {
            switch (expressions[i].expr) {
                case TSwitch(switchExpr, cases, defaultExpr):
                    // Transform the switch to return values directly instead of assignments
                    var originalCaseArmContext = compiler.isCompilingCaseArm;
                    compiler.isCompilingCaseArm = true;
                    
                    // Compile the switch expression with case arm context
                    var result = compiler.compileSwitchExpression(switchExpr, cases, defaultExpr);
                    
                    // Restore original context
                    compiler.isCompilingCaseArm = originalCaseArmContext;
                    
                    return result;
                case TIf(condition, thenExpr, elseExpr):
                    var conditionCompiled = compiler.compileExpression(condition);
                    
                    // Extract actual values from temp variable assignments
                    var thenValue = extractValueFromTempAssignment(thenExpr, tempVarName);
                    var elseValue = extractValueFromTempAssignment(elseExpr, tempVarName);
                    
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
        }
        
        return result;
    }

    public function fixTempVariableScoping(code: String, tempVarName: String): String {
        // Fix pattern: if (cond), do: temp_var = val1, else: temp_var = val2\nvar = temp_var
        // Into: var = if (cond), do: val1, else: val2
        var lines = code.split('\n');
        var fixedLines = [];
        var i = 0;
        
        while (i < lines.length) {
            var line = lines[i];
            
            // Look for if expressions with temp variable assignments
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
            
            fixedLines.push(line);
            i++;
        }
        
        return fixedLines.join('\n');
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
}

#end