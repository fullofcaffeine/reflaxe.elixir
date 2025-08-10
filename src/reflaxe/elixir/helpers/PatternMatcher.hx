package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
import haxe.macro.Expr.Constant;
import haxe.macro.Type;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.FormatHelper;

/**
 * PatternMatcher - Helper for pattern matching compilation
 * Handles switch→case conversion, pattern destructuring, and guard clauses
 */
class PatternMatcher {
    
    public function new() {}
    
    /**
     * Compile switch expression to Elixir case statement
     * @param switchExpr The expression being switched on
     * @param cases Array of case patterns and expressions
     * @param defaultExpr Optional default case expression
     * @return Generated Elixir case statement
     */
    public function compileSwitchExpression(switchExpr: Dynamic, cases: Array<Dynamic>, defaultExpr: Dynamic = null): String {
        var result = new StringBuf();
        var switchValue = compileExpression(switchExpr);
        
        result.add('case ${switchValue} do\n');
        
        // Process each case with proper indentation
        for (caseItem in cases) {
            if (caseItem.values != null) {
                for (value in caseItem.values) {
                    var pattern = compilePattern(value);
                    var guard = compileGuard(caseItem.guard);
                    var caseExpr = compileExpression(caseItem.expr);
                    
                    // Add guard clause if present
                    var guardClause = (guard != null && guard.length > 0) ? ' when ${guard}' : '';
                    
                    result.add('  ${pattern}${guardClause} ->\n');
                    result.add('    ${indentExpression(caseExpr)}\n');
                }
            }
        }
        
        // Add default case if present
        if (defaultExpr != null) {
            var defaultCode = compileExpression(defaultExpr);
            result.add('  _ ->\n');
            result.add('    ${indentExpression(defaultCode)}\n');
        }
        
        result.add('end');
        return result.toString();
    }
    
    /**
     * Compile a pattern for case matching
     * @param patternExpr The pattern expression
     * @return Elixir pattern string
     */
    public function compilePattern(patternExpr: Dynamic): String {
        if (patternExpr == null) return "_";
        
        return switch (getExprType(patternExpr)) {
            // Enum constructor patterns: Some(value) → {:some, value}
            case "TCall":
                compileEnumConstructorPattern(patternExpr);
                
            // Simple enum patterns: None → :none
            case "TField":
                compileEnumFieldPattern(patternExpr);
                
            // Array patterns: [1, 2, 3] → [1, 2, 3]
            case "TArrayDecl":
                compileArrayPattern(patternExpr);
                
            // Object/struct patterns: {x: 1, y: 2} → %{x: 1, y: 2}
            case "TObjectDecl":
                compileObjectPattern(patternExpr);
                
            // Variable patterns: x → x
            case "TLocal":
                compileVariablePattern(patternExpr);
                
            // Constant patterns: 42, "hello" → 42, "hello"
            case "TConst":
                compileConstantPattern(patternExpr);
                
            // Tuple patterns: (a, b) → {a, b}
            case "TTuple":
                compileTuplePattern(patternExpr);
                
            // Wildcard pattern: _ → _
            case "TWildcard":
                "_";
                
            case _:
                // Fallback - treat as expression
                compileExpression(patternExpr);
        }
    }
    
    /**
     * Compile enum constructor pattern: Some(value) → {:some, value}
     */
    private function compileEnumConstructorPattern(patternExpr: Dynamic): String {
        var call = patternExpr.expr;
        
        if (call.e != null && getExprType(call.e) == "TField") {
            var field = call.e;
            var enumField = field.fa;
            
            if (enumField != null && enumField.name != null) {
                var fieldName = NamingHelper.toSnakeCase(enumField.name);
                
                if (call.el != null && call.el.length > 0) {
                    // Parameterized enum: {:tag, args...}
                    var args = [];
                    for (arg in call.el) {
                        args.push(compilePattern(arg));
                    }
                    return '{:${fieldName}, ${args.join(', ')}}';
                } else {
                    // Simple enum: :tag
                    return ':${fieldName}';
                }
            }
        }
        
        return "_"; // Fallback
    }
    
    /**
     * Compile enum field pattern: Status.Ready → :ready
     */
    private function compileEnumFieldPattern(patternExpr: Dynamic): String {
        var field = patternExpr.expr;
        
        if (field.fa != null && field.fa.name != null) {
            var fieldName = NamingHelper.toSnakeCase(field.fa.name);
            return ':${fieldName}';
        }
        
        return "_";
    }
    
    /**
     * Compile array pattern: [1, x, ...rest] → [1, x | rest]
     */
    private function compileArrayPattern(patternExpr: Dynamic): String {
        var arr = patternExpr.expr;
        
        if (arr.el != null) {
            var elements = [];
            var restElement = null;
            
            for (element in arr.el) {
                if (isRestPattern(element)) {
                    restElement = compilePattern(element);
                } else {
                    elements.push(compilePattern(element));
                }
            }
            
            if (restElement != null) {
                return '[${elements.join(', ')} | ${restElement}]';
            } else {
                return '[${elements.join(', ')}]';
            }
        }
        
        return "[]";
    }
    
    /**
     * Compile object/struct pattern: {x: 1, y: y} → %{x: 1, y: y}
     */
    private function compileObjectPattern(patternExpr: Dynamic): String {
        var obj = patternExpr.expr;
        
        if (obj.fields != null) {
            var fields = [];
            
            for (field in obj.fields) {
                var fieldName = field.name;
                var fieldValue = compilePattern(field.expr);
                
                // Convert camelCase to snake_case for Elixir
                var elixirFieldName = NamingHelper.toSnakeCase(fieldName);
                fields.push('${elixirFieldName}: ${fieldValue}');
            }
            
            // Check if this is a struct pattern
            if (patternExpr.structType != null) {
                var structName = NamingHelper.getElixirModuleName(patternExpr.structType);
                return '%${structName}{${fields.join(', ')}}';
            } else {
                return '%{${fields.join(', ')}}';
            }
        }
        
        return "%{}";
    }
    
    /**
     * Compile variable pattern: x → x
     */
    private function compileVariablePattern(patternExpr: Dynamic): String {
        var local = patternExpr.expr;
        
        if (local.v != null && local.v.name != null) {
            return NamingHelper.toSnakeCase(local.v.name);
        }
        
        return "_";
    }
    
    /**
     * Compile constant pattern: 42, "hello", true → 42, "hello", true
     */
    private function compileConstantPattern(patternExpr: Dynamic): String {
        var const = patternExpr.expr;
        
        return switch (const) {
            case CInt(v, _): v;
            case CFloat(f, _): f;
            case CString(s, _): '"${s}"';
            case CIdent(s): s;
            case CRegexp(r, opt): '~r/${r}/${opt}';
            case _: "nil"; // Handle other constants later
        }
    }
    
    /**
     * Compile tuple pattern: (a, b, c) → {a, b, c}
     */
    private function compileTuplePattern(patternExpr: Dynamic): String {
        var tuple = patternExpr.expr;
        
        if (tuple.el != null) {
            var elements = [];
            for (element in tuple.el) {
                elements.push(compilePattern(element));
            }
            return '{${elements.join(', ')}}';
        }
        
        return "{}";
    }
    
    /**
     * Compile guard clause expression
     * @param guardExpr The guard expression (can be null)
     * @return Guard clause string or null
     */
    public function compileGuard(guardExpr: Dynamic): String {
        if (guardExpr == null) return null;
        
        return switch (getExprType(guardExpr)) {
            case "TBinop":
                compileBinaryGuard(guardExpr);
            case "TCall":
                compileFunctionGuard(guardExpr);
            case "TLocal":
                compileVariableGuard(guardExpr);
            case _:
                compileExpression(guardExpr);
        }
    }
    
    /**
     * Compile binary operation guard: x > 0 → x > 0
     */
    private function compileBinaryGuard(guardExpr: Dynamic): String {
        var binop = guardExpr.expr;
        var left = compileExpression(binop.e1);
        var right = compileExpression(binop.e2);
        var op = convertGuardOperator(binop.op);
        
        return '${left} ${op} ${right}';
    }
    
    /**
     * Compile function call guard: isValid(x) → is_valid(x)
     */
    private function compileFunctionGuard(guardExpr: Dynamic): String {
        var call = guardExpr.expr;
        var funcName = getFunctionName(call.e);
        var args = [];
        
        if (call.el != null) {
            for (arg in call.el) {
                args.push(compileExpression(arg));
            }
        }
        
        var elixirFuncName = NamingHelper.getElixirFunctionName(funcName);
        return '${elixirFuncName}(${args.join(', ')})';
    }
    
    /**
     * Compile variable guard: x → x
     */
    private function compileVariableGuard(guardExpr: Dynamic): String {
        return compileVariablePattern(guardExpr);
    }
    
    /**
     * Convert guard operators to Elixir equivalents
     */
    private function convertGuardOperator(op: String): String {
        return switch (op) {
            case "==": "==";
            case "!=": "!=";
            case ">": ">";
            case "<": "<";
            case ">=": ">=";
            case "<=": "<=";
            case "&&": "and";
            case "||": "or";
            case "!": "not";
            case _: op;
        }
    }
    
    // Helper functions
    private function getExprType(expr: Dynamic): String {
        if (expr == null || expr.expr == null) return "null";
        return Type.getClassName(Type.getClass(expr.expr));
    }
    
    private function isRestPattern(expr: Dynamic): Bool {
        return expr != null && expr.isRest == true;
    }
    
    private function getFunctionName(expr: Dynamic): String {
        if (expr == null) return "unknown";
        // Extract function name from TField or similar
        return "func"; // Simplified
    }
    
    private var compiler: reflaxe.elixir.ElixirCompiler;
    
    public function setCompiler(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    private function compileExpression(expr: Dynamic): String {
        if (expr == null) return "nil";
        if (compiler != null) {
            return compiler.compileExpression(expr);
        }
        return "expr"; // Fallback
    }
    
    private function indentExpression(expr: String): String {
        if (expr == null) return "";
        return expr.split("\n").map(line -> line.length > 0 ? line : "").join("\n    ");
    }
}

#end