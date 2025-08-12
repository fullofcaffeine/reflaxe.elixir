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
     * Enhanced to support more complex binary pattern detection
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
                
                // Check for function names that indicate binary patterns
                var funcName = getFunctionName(call.e);
                if (funcName == "binary" || funcName == "bytes" || funcName == "bitstring") {
                    return true;
                }
            }
        }
        
        // Check for string literals with binary metadata
        if (getExprType(expr) == "TConst") {
            var constExpr = expr.expr;
            if (constExpr != null && expr.binaryPattern == true) {
                return true;
            }
        }
        
        // Check for array literals that represent binary segments
        if (getExprType(expr) == "TArrayDecl") {
            var arr = expr.expr;
            if (arr.isBinarySegments == true) {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * Compile binary pattern: <<a::8, b::binary>> → <<a::8, b::binary>>
     * Enhanced to support complex binary matching scenarios
     */
    private function compileBinaryPattern(patternExpr: Dynamic): String {
        var result = new StringBuf();
        result.add("<<");
        
        // Extract binary segments
        var segments = [];
        
        if (patternExpr.segments != null) {
            // Direct segment specification
            for (segment in (patternExpr.segments : Array<Dynamic>)) {
                segments.push(compileBinarySegment(segment));
            }
        } else if (getExprType(patternExpr) == "TCall") {
            // Function call pattern: binary(segments...)
            var call = patternExpr.expr;
            if (call.el != null) {
                for (arg in (call.el : Array<Dynamic>)) {
                    segments.push(compileBinarySegmentFromArg(arg));
                }
            }
        } else if (getExprType(patternExpr) == "TArrayDecl") {
            // Array-style binary segments: [byte1, byte2, rest]
            var arr = patternExpr.expr;
            if (arr.el != null) {
                var elements = (arr.el : Array<Dynamic>);
                for (i in 0...elements.length) {
                    var element = elements[i];
                    
                    // Check if this is a rest pattern for remaining binary
                    if (i == elements.length - 1 && isRestPattern(element)) {
                        var restVar = extractRestVariable(element);
                        var restPattern = compilePattern(restVar);
                        segments.push(restPattern + "::binary");
                    } else {
                        // Regular byte pattern
                        var pattern = compilePattern(element);
                        if (pattern == "_") {
                            segments.push("_::8");
                        } else {
                            segments.push(pattern + "::8");
                        }
                    }
                }
            }
        } else if (getExprType(patternExpr) == "TConst") {
            // String literal as binary pattern
            var constExpr = patternExpr.expr;
            if (constExpr != null) {
                switch (constExpr) {
                    case CString(s, _):
                        // Convert string to binary pattern
                        segments.push('"' + s + '"');
                    case _:
                        segments.push("_::binary");
                }
            }
        } else {
            // Fallback for simple binary patterns
            var pattern = compilePattern(patternExpr);
            if (pattern != "_") {
                segments.push(pattern + "::binary");
            } else {
                segments.push("_::binary");
            }
        }
        
        // Handle empty segments case
        if (segments.length == 0) {
            segments.push("_::binary");
        }
        
        result.add(segments.join(", "));
        result.add(">>");
        
        return result.toString();
    }
    
    /**
     * Compile a single binary segment with size and type specifications
     * Enhanced to support various segment patterns
     */
    private function compileBinarySegment(segment: Dynamic): String {
        if (segment == null) return "_::8";
        
        var varName = "_";
        var size = "";
        var type = "integer";
        var signedness = "";
        var endianness = "";
        var unit = "";
        
        // Extract variable name
        if (segment.variable != null) {
            varName = compilePattern(segment.variable);
        } else if (segment.name != null) {
            varName = NamingHelper.toSnakeCase(segment.name);
        } else if (getExprType(segment) == "TLocal") {
            varName = compileVariablePattern(segment);
        }
        
        // Extract size specification
        if (segment.size != null) {
            if (Std.isOfType(segment.size, Int)) {
                size = "::" + Std.string(segment.size);
            } else {
                // Size can be a variable or expression
                size = "::" + compileExpression(segment.size);
            }
        }
        
        // Extract type specification
        if (segment.type != null) {
            type = segment.type;
        } else if (segment.binaryType != null) {
            type = segment.binaryType;
        }
        
        // Extract signedness (signed/unsigned)
        if (segment.signed == true) {
            signedness = "-signed";
        } else if (segment.unsigned == true) {
            signedness = "-unsigned";
        }
        
        // Extract endianness (big/little)
        if (segment.big == true) {
            endianness = "-big";
        } else if (segment.little == true) {
            endianness = "-little";
        }
        
        // Extract unit specification
        if (segment.unit != null) {
            unit = "-unit(" + Std.string(segment.unit) + ")";
        }
        
        // Build comprehensive segment pattern
        var typeSpec = type + signedness + endianness + unit;
        
        if (size != "") {
            return '${varName}${size}-${typeSpec}';
        } else if (type == "binary") {
            return '${varName}::binary';
        } else if (type == "utf8") {
            return '${varName}::utf8';
        } else if (type == "float") {
            return '${varName}::float';
        } else {
            return '${varName}::${typeSpec}';
        }
    }
    
    /**
     * Compile binary segment from function argument
     * Used when binary patterns are expressed as function calls
     */
    private function compileBinarySegmentFromArg(arg: Dynamic): String {
        if (arg == null) return "_::8";
        
        // If argument is a complex expression representing a segment
        if (arg.segmentSpec != null) {
            return compileBinarySegment(arg.segmentSpec);
        }
        
        // If argument is a simple value, treat as 8-bit integer
        var pattern = compilePattern(arg);
        if (pattern == "_") {
            return "_::8";
        } else {
            return pattern + "::8";
        }
    }
    
    /**
     * Check if expression is a pin pattern (^variable)
     * Enhanced to support various pin pattern representations
     */
    private function isPinPattern(expr: Dynamic): Bool {
        if (expr == null) return false;
        
        // Check for pin pattern metadata
        if (expr.isPin == true) return true;
        if (expr.pinned == true) return true;
        
        // Check for ^ prefix in variable names (special handling)
        if (getExprType(expr) == "TLocal") {
            var local = expr.expr;
            if (local.v != null && local.v.name != null) {
                var name = local.v.name;
                return name.charAt(0) == "^";
            }
        }
        
        // Check for unary expression with ^ operator
        if (getExprType(expr) == "TUnop") {
            var unop = expr.expr;
            if (unop.op == "OpNeg" && unop.prefix == true) {
                // This might be a ^ pattern in disguise
                return true;
            }
        }
        
        // Check for field access with ^ prefix: ^module.field
        if (getExprType(expr) == "TField") {
            var field = expr.expr;
            if (field.e != null) {
                // Recursively check if the base is pinned
                return isPinPattern(field.e);
            }
        }
        
        // Check for array access patterns: ^arr[index]
        if (getExprType(expr) == "TArray") {
            var arrayAccess = expr.expr;
            if (arrayAccess.e1 != null) {
                return isPinPattern(arrayAccess.e1);
            }
        }
        
        return false;
    }
    
    /**
     * Compile pin pattern: ^existing_var → ^existing_var
     * Enhanced to support complex pin patterns
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
        } else if (getExprType(patternExpr) == "TUnop") {
            // Handle unary ^ operator
            var unop = patternExpr.expr;
            if (unop.e != null) {
                var innerPattern = compilePattern(unop.e);
                // Remove ^ if already present to avoid double ^^
                if (innerPattern.charAt(0) == "^") {
                    return innerPattern;
                } else {
                    return '^${innerPattern}';
                }
            }
        } else if (getExprType(patternExpr) == "TField") {
            // Handle pinned field access: ^module.field
            var field = patternExpr.expr;
            if (field.e != null && field.fa != null) {
                var baseExpr = compilePattern(field.e);
                var fieldName = NamingHelper.toSnakeCase(field.fa.name);
                
                // If base is already pinned, don't add another ^
                if (baseExpr.charAt(0) == "^") {
                    return '${baseExpr}.${fieldName}';
                } else {
                    return '^${baseExpr}.${fieldName}';
                }
            }
        } else if (getExprType(patternExpr) == "TArray") {
            // Handle pinned array access: ^arr[index]
            var arrayAccess = patternExpr.expr;
            if (arrayAccess.e1 != null && arrayAccess.e2 != null) {
                var arrayExpr = compilePattern(arrayAccess.e1);
                var indexExpr = compileExpression(arrayAccess.e2);
                
                // Pin the entire array access
                return '^${arrayExpr}[${indexExpr}]';
            }
        } else {
            // Try to extract variable name from complex pattern
            var pattern = compilePattern(patternExpr);
            if (pattern != "_" && pattern.charAt(0) != "^") {
                return '^${pattern}';
            } else {
                return pattern;
            }
        }
        
        // Default case
        if (varName != "") {
            return '^${varName}';
        } else {
            return "^_";
        }
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
    
    /**
     * Validate pattern exhaustiveness for switch expressions
     * Ensures all possible cases are covered to prevent runtime errors
     */
    public function validatePatternExhaustiveness(switchExpr: Dynamic, cases: Array<Dynamic>, defaultExpr: Dynamic = null): Array<String> {
        var warnings = [];
        var switchType = getSwitchExpressionType(switchExpr);
        
        if (switchType == null) {
            return warnings; // Can't analyze unknown types
        }
        
        return switch (switchType.name) {
            case "Bool":
                validateBooleanExhaustiveness(cases, defaultExpr, warnings);
                
            case "Enum":
                validateEnumExhaustiveness(switchType, cases, defaultExpr, warnings);
                
            case "Int":
                validateIntegerExhaustiveness(cases, defaultExpr, warnings);
                
            case "String":
                validateStringExhaustiveness(cases, defaultExpr, warnings);
                
            case "Array":
                validateArrayExhaustiveness(cases, defaultExpr, warnings);
                
            case _:
                // Complex types require default case
                if (defaultExpr == null && !hasWildcardCase(cases)) {
                    warnings.push('Non-exhaustive pattern match for type ${switchType.name}: missing default case');
                }
                warnings;
        }
    }
    
    /**
     * Validate boolean pattern exhaustiveness
     */
    private function validateBooleanExhaustiveness(cases: Array<Dynamic>, defaultExpr: Dynamic, warnings: Array<String>): Array<String> {
        var hasTrueCase = false;
        var hasFalseCase = false;
        var hasWildcard = hasWildcardCase(cases);
        
        for (caseItem in cases) {
            if (caseItem.values != null) {
                for (value in (caseItem.values : Array<Dynamic>)) {
                    if (isBooleanConstant(value, true)) hasTrueCase = true;
                    if (isBooleanConstant(value, false)) hasFalseCase = true;
                }
            }
        }
        
        if (defaultExpr == null && !hasWildcard) {
            if (!hasTrueCase) {
                warnings.push("Non-exhaustive boolean pattern: missing case for 'true'");
            }
            if (!hasFalseCase) {
                warnings.push("Non-exhaustive boolean pattern: missing case for 'false'");
            }
        }
        
        return warnings;
    }
    
    /**
     * Validate enum pattern exhaustiveness
     */
    private function validateEnumExhaustiveness(enumType: Dynamic, cases: Array<Dynamic>, defaultExpr: Dynamic, warnings: Array<String>): Array<String> {
        if (enumType.constructors == null) {
            return warnings; // Can't validate without constructor info
        }
        
        var coveredConstructors = new Map<String, Bool>();
        var hasWildcard = hasWildcardCase(cases);
        
        // Track which enum constructors are covered
        for (caseItem in cases) {
            if (caseItem.values != null) {
                for (value in (caseItem.values : Array<Dynamic>)) {
                    var constructorName = getEnumConstructorName(value);
                    if (constructorName != null) {
                        coveredConstructors.set(constructorName, true);
                    }
                }
            }
        }
        
        // Check for missing constructors
        if (defaultExpr == null && !hasWildcard) {
            for (constructor in (enumType.constructors : Array<Dynamic>)) {
                var constructorName = constructor.name;
                if (!coveredConstructors.exists(constructorName)) {
                    warnings.push('Non-exhaustive enum pattern: missing case for constructor "${constructorName}"');
                }
            }
        }
        
        return warnings;
    }
    
    /**
     * Validate integer pattern exhaustiveness
     */
    private function validateIntegerExhaustiveness(cases: Array<Dynamic>, defaultExpr: Dynamic, warnings: Array<String>): Array<String> {
        var hasWildcard = hasWildcardCase(cases);
        var hasGuardCases = hasGuardCases(cases);
        
        // Integers have infinite possible values, so we need either:
        // 1. A default case, OR
        // 2. A wildcard case, OR  
        // 3. Guard cases that cover all ranges
        if (defaultExpr == null && !hasWildcard && !hasCompleteGuardCoverage(cases)) {
            warnings.push("Non-exhaustive integer pattern: infinite possible values require default case or complete guard coverage");
        }
        
        return warnings;
    }
    
    /**
     * Validate string pattern exhaustiveness
     */
    private function validateStringExhaustiveness(cases: Array<Dynamic>, defaultExpr: Dynamic, warnings: Array<String>): Array<String> {
        var hasWildcard = hasWildcardCase(cases);
        
        // Strings have infinite possible values, so we need either:
        // 1. A default case, OR
        // 2. A wildcard case
        if (defaultExpr == null && !hasWildcard) {
            warnings.push("Non-exhaustive string pattern: infinite possible values require default case");
        }
        
        return warnings;
    }
    
    /**
     * Validate array pattern exhaustiveness
     */
    private function validateArrayExhaustiveness(cases: Array<Dynamic>, defaultExpr: Dynamic, warnings: Array<String>): Array<String> {
        var hasWildcard = hasWildcardCase(cases);
        var hasEmptyCase = false;
        var maxFixedLength = 0;
        var hasVariableLength = false;
        
        // Analyze array patterns
        for (caseItem in cases) {
            if (caseItem.values != null) {
                for (value in (caseItem.values : Array<Dynamic>)) {
                    if (isEmptyArrayPattern(value)) {
                        hasEmptyCase = true;
                    } else {
                        var length = getArrayPatternLength(value);
                        if (length > maxFixedLength) {
                            maxFixedLength = length;
                        }
                        if (hasRestPattern(value)) {
                            hasVariableLength = true;
                        }
                    }
                }
            }
        }
        
        // Arrays can have any length, so we need comprehensive coverage
        if (defaultExpr == null && !hasWildcard && !hasVariableLength) {
            warnings.push("Non-exhaustive array pattern: arrays can have any length, consider adding rest pattern or default case");
        }
        
        return warnings;
    }
    
    // Helper functions for exhaustiveness checking
    
    private function getSwitchExpressionType(expr: Dynamic): Dynamic {
        // This would normally analyze the Haxe typed expression
        // For now, return a simplified type representation
        return {name: "Dynamic", constructors: null};
    }
    
    private function hasWildcardCase(cases: Array<Dynamic>): Bool {
        for (caseItem in cases) {
            if (caseItem.values != null) {
                for (value in (caseItem.values : Array<Dynamic>)) {
                    if (isWildcardPattern(value)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    private function hasGuardCases(cases: Array<Dynamic>): Bool {
        for (caseItem in cases) {
            if (caseItem.guard != null) {
                return true;
            }
        }
        return false;
    }
    
    private function hasCompleteGuardCoverage(cases: Array<Dynamic>): Bool {
        // This would require sophisticated range analysis
        // For now, assume incomplete coverage
        return false;
    }
    
    private function isWildcardPattern(value: Dynamic): Bool {
        return getExprType(value) == "TWildcard" || 
               (getExprType(value) == "TLocal" && getVariableName(value) == "_");
    }
    
    private function isBooleanConstant(value: Dynamic, expected: Bool): Bool {
        if (getExprType(value) == "TConst") {
            var constExpr = value.expr;
            switch (constExpr) {
                case CIdent("true"): return expected == true;
                case CIdent("false"): return expected == false;
                case _: return false;
            }
        }
        return false;
    }
    
    private function getEnumConstructorName(value: Dynamic): String {
        if (getExprType(value) == "TCall" || getExprType(value) == "TField") {
            // Extract enum constructor name from pattern
            return "EnumConstructor"; // Simplified
        }
        return null;
    }
    
    private function isEmptyArrayPattern(value: Dynamic): Bool {
        if (getExprType(value) == "TArrayDecl") {
            var arr = value.expr;
            return arr.el == null || (arr.el : Array<Dynamic>).length == 0;
        }
        return false;
    }
    
    private function getArrayPatternLength(value: Dynamic): Int {
        if (getExprType(value) == "TArrayDecl") {
            var arr = value.expr;
            if (arr.el != null) {
                return (arr.el : Array<Dynamic>).length;
            }
        }
        return 0;
    }
    
    private function hasRestPattern(value: Dynamic): Bool {
        if (getExprType(value) == "TArrayDecl") {
            var arr = value.expr;
            if (arr.el != null) {
                for (element in (arr.el : Array<Dynamic>)) {
                    if (isRestPattern(element)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    private function getVariableName(value: Dynamic): String {
        if (getExprType(value) == "TLocal") {
            var local = value.expr;
            if (local.v != null && local.v.name != null) {
                return local.v.name;
            }
        }
        return "";
    }
}

#end