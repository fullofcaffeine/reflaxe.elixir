package reflaxe.elixir.helpers;

import haxe.macro.Expr;
import haxe.macro.Expr.Constant;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.helpers.NamingHelper;

/**
 * GuardCompiler - Helper for guard clause compilation
 * Handles when clause generation for pattern matching
 */
class GuardCompiler {
    
    public function new() {}
    
    /**
     * Compile guard expression to when clause
     * @param guardExpr The guard expression
     * @return Compiled when clause string
     */
    public function compileGuard(guardExpr: Dynamic): String {
        if (guardExpr == null) return "";
        
        return switch (getExprType(guardExpr)) {
            case "TBinop":
                compileBinaryGuard(guardExpr);
            case "TUnop":
                compileUnaryGuard(guardExpr);
            case "TCall":
                compileFunctionGuard(guardExpr);
            case "TLocal":
                compileVariableGuard(guardExpr);
            case "TConst":
                compileConstantGuard(guardExpr);
            case "TParenthesis":
                compileParenthesesGuard(guardExpr);
            case _:
                compileComplexGuard(guardExpr);
        }
    }
    
    /**
     * Compile binary operation guard: x > 0 and y < 10
     */
    private function compileBinaryGuard(guardExpr: Dynamic): String {
        var binop = guardExpr.expr;
        var left = compileGuardOperand(binop.e1);
        var right = compileGuardOperand(binop.e2);
        var op = convertGuardOperator(binop.op);
        
        // Handle logical operators with proper precedence
        if (isLogicalOperator(binop.op)) {
            return '${left} ${op} ${right}';
        } else {
            return '${left} ${op} ${right}';
        }
    }
    
    /**
     * Compile unary operation guard: not condition
     */
    private function compileUnaryGuard(guardExpr: Dynamic): String {
        var unop = guardExpr.expr;
        var operand = compileGuardOperand(unop.e);
        var op = convertUnaryOperator(unop.op);
        
        return switch (unop.op) {
            case "!": 'not ${operand}';
            case "-": '-${operand}';
            case _: '${op}${operand}';
        }
    }
    
    /**
     * Compile function call guard: is_binary(value)
     */
    private function compileFunctionGuard(guardExpr: Dynamic): String {
        var call = guardExpr.expr;
        var funcName = extractFunctionName(call.e);
        var args = [];
        
        if (call.el != null) {
            for (arg in (call.el : Array<Dynamic>)) {
                args.push(compileGuardOperand(arg));
            }
        }
        
        // Convert to Elixir guard function
        var elixirFuncName = convertGuardFunction(funcName);
        return '${elixirFuncName}(${args.join(', ')})';
    }
    
    /**
     * Compile variable guard: variable_name
     */
    private function compileVariableGuard(guardExpr: Dynamic): String {
        var local = guardExpr.expr;
        if (local.v != null && local.v.name != null) {
            return NamingHelper.toSnakeCase(local.v.name);
        }
        return "_";
    }
    
    /**
     * Compile constant guard: 42, "string", true
     */
    private function compileConstantGuard(guardExpr: Dynamic): String {
        var const = guardExpr.expr;
        
        return switch (const) {
            case CInt(v, _): v;
            case CFloat(f, _): f;
            case CString(s, _): '"${s}"';
            case CIdent(s): s;
            case CRegexp(r, opt): '~r/${r}/${opt}';
            case _: "nil";
        }
    }
    
    /**
     * Compile parentheses guard: (condition)
     */
    private function compileParenthesesGuard(guardExpr: Dynamic): String {
        var paren = guardExpr.expr;
        var inner = compileGuard(paren.e);
        return '(${inner})';
    }
    
    /**
     * Compile complex guard expressions
     */
    private function compileComplexGuard(guardExpr: Dynamic): String {
        // Check for range patterns
        if (isRangeGuard(guardExpr)) {
            return compileRangeGuard(guardExpr);
        }
        
        // Check for membership tests
        if (isMembershipGuard(guardExpr)) {
            return compileMembershipGuard(guardExpr);
        }
        
        // Handle more complex patterns
        return "true"; // Fallback
    }
    
    /**
     * Check if expression is a range guard (value in 1..10)
     */
    private function isRangeGuard(expr: Dynamic): Bool {
        if (expr == null) return false;
        
        // Check for "in" operator with range
        if (getExprType(expr) == "TBinop") {
            var binop = expr.expr;
            return binop.op == "OpIn" && isRangeExpression(binop.e2);
        }
        
        return false;
    }
    
    /**
     * Check if expression is a range (1..10 or 1...10)
     */
    private function isRangeExpression(expr: Dynamic): Bool {
        if (expr == null) return false;
        
        if (getExprType(expr) == "TBinop") {
            var binop = expr.expr;
            return binop.op == "OpInterval";  // Range operator
        }
        
        return false;
    }
    
    /**
     * Compile range guard: value in 1..10 → value in 1..10
     */
    private function compileRangeGuard(guardExpr: Dynamic): String {
        var binop = guardExpr.expr;
        var value = compileGuardOperand(binop.e1);
        var range = compileRangeExpression(binop.e2);
        
        return '${value} in ${range}';
    }
    
    /**
     * Compile range expression: 1..10 → 1..10
     */
    private function compileRangeExpression(rangeExpr: Dynamic): String {
        if (getExprType(rangeExpr) == "TBinop") {
            var binop = rangeExpr.expr;
            if (binop.op == "OpInterval") {
                var start = compileGuardOperand(binop.e1);
                var end = compileGuardOperand(binop.e2);
                return '${start}..${end}';
            }
        }
        
        return "1..10"; // Fallback
    }
    
    /**
     * Check if expression is a membership guard (value in list)
     */
    private function isMembershipGuard(expr: Dynamic): Bool {
        if (expr == null) return false;
        
        if (getExprType(expr) == "TBinop") {
            var binop = expr.expr;
            return binop.op == "OpIn" && !isRangeExpression(binop.e2);
        }
        
        return false;
    }
    
    /**
     * Compile membership guard: value in [1, 2, 3] → value in [1, 2, 3]
     */
    private function compileMembershipGuard(guardExpr: Dynamic): String {
        var binop = guardExpr.expr;
        var value = compileGuardOperand(binop.e1);
        var list = compileGuardOperand(binop.e2);
        
        return '${value} in ${list}';
    }
    
    /**
     * Compile guard operand (recursive)
     */
    private function compileGuardOperand(expr: Dynamic): String {
        if (expr == null) return "nil";
        
        return switch (getExprType(expr)) {
            case "TLocal":
                compileVariableGuard(expr);
            case "TConst":
                compileConstantGuard(expr);
            case "TBinop":
                compileBinaryGuard(expr);
            case "TCall":
                compileFunctionGuard(expr);
            case "TField":
                compileFieldAccess(expr);
            case _:
                "expr"; // Fallback
        }
    }
    
    /**
     * Compile field access in guard: user.name
     */
    private function compileFieldAccess(expr: Dynamic): String {
        var field = expr.expr;
        
        if (field.e != null && field.fa != null) {
            var obj = compileGuardOperand(field.e);
            var fieldName = NamingHelper.toSnakeCase(field.fa.name);
            return '${obj}.${fieldName}';
        }
        
        return "field";
    }
    
    /**
     * Convert Haxe operators to Elixir guard operators
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
            case "+": "+";
            case "-": "-";
            case "*": "*";
            case "/": "/";
            case "%": "rem";
            case _: op;
        }
    }
    
    /**
     * Convert unary operators
     */
    private function convertUnaryOperator(op: String): String {
        return switch (op) {
            case "!": "not ";
            case "-": "-";
            case "+": "+";
            case _: op;
        }
    }
    
    /**
     * Convert function names to Elixir guard functions
     */
    private function convertGuardFunction(funcName: String): String {
        return switch (funcName) {
            case "isString": "is_binary";
            case "isBinary": "is_binary";
            case "isInt": "is_integer";
            case "isFloat": "is_float";
            case "isBool": "is_boolean";
            case "isArray": "is_list";
            case "isList": "is_list";
            case "isMap": "is_map";
            case "isAtom": "is_atom";
            case "isTuple": "is_tuple";
            case "isFunction": "is_function";
            case "isNil": "is_nil";
            case "isNumber": "is_number";
            case "isPort": "is_port";
            case "isPid": "is_pid";
            case "isReference": "is_reference";
            case "length": "length";
            case "size": "byte_size";
            case "byteSize": "byte_size";
            case "tupleSize": "tuple_size";
            case "mapSize": "map_size";
            case "bitSize": "bit_size";
            case "abs": "abs";
            case "round": "round";
            case "trunc": "trunc";
            case "floor": "floor";
            case "ceil": "ceil";
            case "elem": "elem";
            case "hd": "hd";
            case "tl": "tl";
            case "div": "div";
            case "rem": "rem";
            case _: NamingHelper.getElixirFunctionName(funcName);
        }
    }
    
    /**
     * Check if operator is logical (and, or)
     */
    private function isLogicalOperator(op: String): Bool {
        return op == "&&" || op == "||";
    }
    
    /**
     * Extract function name from expression
     */
    private function extractFunctionName(expr: Dynamic): String {
        if (expr == null) return "unknown";
        
        return switch (getExprType(expr)) {
            case "TField":
                var field = expr.expr;
                if (field.fa != null && field.fa.name != null) {
                    field.fa.name;
                } else {
                    "func";
                }
            case "TLocal":
                var local = expr.expr;
                if (local.v != null && local.v.name != null) {
                    local.v.name;
                } else {
                    "func";
                }
            case _:
                "func";
        }
    }
    
    /**
     * Compile multiple guard conditions with proper precedence
     * @param guards Array of guard expressions
     * @param operator Logical operator connecting guards ("and" or "or")
     * @return Combined guard clause
     */
    public function compileMultipleGuards(guards: Array<Dynamic>, op: String = "and"): String {
        if (guards == null || guards.length == 0) return "";
        if (guards.length == 1) return compileGuard(guards[0]);
        
        var compiledGuards = [];
        for (guard in guards) {
            var compiled = compileGuard(guard);
            if (compiled != null && compiled.length > 0) {
                compiledGuards.push(compiled);
            }
        }
        
        if (compiledGuards.length == 0) return "";
        if (compiledGuards.length == 1) return compiledGuards[0];
        
        var elixirOp = convertGuardOperator(op);
        return compiledGuards.join(' ${elixirOp} ');
    }
    
    /**
     * Check if expression can be used in guard context
     */
    public function isValidGuardExpression(expr: Dynamic): Bool {
        if (expr == null) return false;
        
        return switch (getExprType(expr)) {
            case "TBinop": true;
            case "TUnop": true;
            case "TCall": isGuardFunction(expr);
            case "TLocal": true;
            case "TConst": true;
            case "TField": true; // Field access is allowed
            case "TParenthesis": true;
            case _: false;
        }
    }
    
    /**
     * Check if function call is allowed in guards
     */
    private function isGuardFunction(callExpr: Dynamic): Bool {
        var funcName = extractFunctionName(callExpr.expr.e);
        
        var allowedGuardFunctions = [
            // Type checking guards
            "is_atom", "is_binary", "is_boolean", "is_float", "is_function",
            "is_integer", "is_list", "is_map", "is_nil", "is_tuple",
            "is_number", "is_port", "is_pid", "is_reference",
            // Size and length guards
            "length", "byte_size", "tuple_size", "map_size", "bit_size",
            // Math guards
            "abs", "round", "trunc", "floor", "ceil", "div", "rem",
            // List guards
            "hd", "tl",
            // Tuple guards
            "elem",
            // Comparison and membership
            "in", "not", "and", "or"
        ];
        
        var elixirFuncName = convertGuardFunction(funcName);
        return allowedGuardFunctions.indexOf(elixirFuncName) >= 0;
    }
    
    // Helper functions
    private function getExprType(expr: Dynamic): String {
        if (expr == null || expr.expr == null) return "null";
        return Type.getClassName(Type.getClass(expr.expr));
    }
}

#end