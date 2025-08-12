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
        for (caseItem in (cases : Array<Dynamic>)) {
            if (caseItem.values != null) {
                for (value in (caseItem.values : Array<Dynamic>)) {
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
        
        // Check for special pattern types first
        if (isBinaryPattern(patternExpr)) {
            return compileBinaryPattern(patternExpr);
        }
        
        if (isPinPattern(patternExpr)) {
            return compilePinPattern(patternExpr);
        }
        
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
                    for (arg in (call.el : Array<Dynamic>)) {
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
     * Supports advanced list patterns including head|tail syntax
     */
    private function compileArrayPattern(patternExpr: Dynamic): String {
        var arr = patternExpr.expr;
        
        if (arr.el != null) {
            var elements = [];
            var restElement = null;
            var hasRestPattern = false;
            
            // Check for rest patterns and separate elements
            for (i in 0...(arr.el : Array<Dynamic>).length) {
                var element = (arr.el : Array<Dynamic>)[i];
                
                // Check if this is a rest/tail pattern
                if (isRestPattern(element) || isTailPattern(element)) {
                    hasRestPattern = true;
                    // In Elixir, rest pattern is the tail of the list
                    restElement = compilePattern(extractRestVariable(element));
                } else if (!hasRestPattern) {
                    // Only add elements before the rest pattern
                    elements.push(compilePattern(element));
                } else {
                    // Elements after rest pattern in Haxe need special handling
                    // This is not typically supported in Elixir pattern matching
                    trace("Warning: Elements after rest pattern are not supported in Elixir");
                }
            }
            
            // Generate the appropriate Elixir list pattern
            if (restElement != null) {
                if (elements.length > 0) {
                    // [head, elements | tail] pattern
                    return '[${elements.join(", ")} | ${restElement}]';
                } else {
                    // Just the tail variable
                    return restElement;
                }
            } else if (elements.length > 0) {
                // Simple list pattern without rest
                return '[${elements.join(", ")}]';
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
            
            for (field in (obj.fields : Array<Dynamic>)) {
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
            for (element in (tuple.el : Array<Dynamic>)) {
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
        if (guardExpr == null) return "";
        
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
            for (arg in (call.el : Array<Dynamic>)) {
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
    
    private function isTailPattern(expr: Dynamic): Bool {
        // Check if this represents a tail pattern in list matching
        return expr != null && (expr.isTail == true || expr.isRest == true);
    }
    
    private function extractRestVariable(expr: Dynamic): Dynamic {
        // Extract the actual variable from a rest pattern
        if (expr != null && expr.restVar != null) {
            return expr.restVar;
        }
        return expr;
    }
    
    private function getFunctionName(expr: Dynamic): String {
        if (expr == null) return "unknown";
        // Extract function name from TField or similar
        return "func"; // Simplified
    }
    
    /**
     * Check if expression is a binary pattern
     */
    private function isBinaryPattern(expr: Dynamic): Bool {
        if (expr == null) return false;
        
        // Check for binary pattern metadata or special syntax
        if (expr.isBinary == true) return true;
        
        // Check if it's a call to binary construction
        if (getExprType(expr) == "TCall") {
            var call = expr.expr;
            if (call.e != null) {
                var funcExpr = call.e;
                // Check for binary constructor patterns
                if (funcExpr.isBinaryConstructor == true) {
                    return true;
                }
            }
        }
        
        return false;
    }
    
    /**
     * Compile binary pattern: <<a::8, b::binary>> → <<a::8, b::binary>>
     */
    private function compileBinaryPattern(patternExpr: Dynamic): String {
        var result = new StringBuf();
        result.add("<<");
        
        // Extract binary segments
        var segments = [];
        if (patternExpr.segments != null) {
            for (segment in (patternExpr.segments : Array<Dynamic>)) {
                segments.push(compileBinarySegment(segment));
            }
        } else {
            // Fallback for simple binary patterns
            segments.push("_::binary");
        }
        
        result.add(segments.join(", "));
        result.add(">>");
        
        return result.toString();
    }
    
    /**
     * Compile a single binary segment with size and type specifications
     */
    private function compileBinarySegment(segment: Dynamic): String {
        if (segment == null) return "_";
        
        var varName = "_";
        var size = "";
        var type = "integer";
        
        // Extract variable name
        if (segment.variable != null) {
            varName = compilePattern(segment.variable);
        }
        
        // Extract size specification
        if (segment.size != null) {
            size = "::" + Std.string(segment.size);
        }
        
        // Extract type specification
        if (segment.type != null) {
            type = segment.type;
        }
        
        // Build segment pattern
        if (size != "") {
            return '${varName}${size}';
        } else if (type == "binary") {
            return '${varName}::binary';
        } else {
            return '${varName}::${type}';
        }
    }
    
    /**
     * Check if expression is a pin pattern (^variable)
     */
    private function isPinPattern(expr: Dynamic): Bool {
        if (expr == null) return false;
        
        // Check for pin pattern metadata
        if (expr.isPin == true) return true;
        
        // Check for ^ prefix in variable names (special handling)
        if (getExprType(expr) == "TLocal") {
            var local = expr.expr;
            if (local.v != null && local.v.name != null) {
                var name = local.v.name;
                return name.charAt(0) == "^";
            }
        }
        
        return false;
    }
    
    /**
     * Compile pin pattern: ^existing_var → ^existing_var
     */
    private function compilePinPattern(patternExpr: Dynamic): String {
        var varName = "";
        
        if (getExprType(patternExpr) == "TLocal") {
            var local = patternExpr.expr;
            if (local.v != null && local.v.name != null) {
                varName = NamingHelper.toSnakeCase(local.v.name);
                // Remove ^ if it's already in the name
                if (varName.charAt(0) == "^") {
                    varName = varName.substr(1);
                }
            }
        } else {
            // Try to extract variable name from pattern
            varName = compileVariablePattern(patternExpr);
        }
        
        return '^${varName}';
    }
    
    private var compiler: Null<reflaxe.elixir.ElixirCompiler> = null;
    
    public function setCompiler(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    private function compileExpression(expr: Dynamic): String {
        if (expr == null) return "nil";
        if (compiler != null) {
            var result = compiler.compileExpression(expr);
            return result != null ? result : "nil";
        }
        return "expr"; // Fallback
    }
    
    private function indentExpression(expr: String): String {
        if (expr == null) return "";
        return expr.split("\n").map(line -> line.length > 0 ? line : "").join("\n    ");
    }
}

#end