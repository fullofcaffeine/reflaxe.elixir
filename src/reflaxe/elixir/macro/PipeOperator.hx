package reflaxe.elixir.macro;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

/**
 * Pipe operator support utilities for @:module contexts
 * Enables native Elixir pipe operator syntax in Haxe code
 */
class PipeOperator {
    
    /**
     * Transform Haxe method chaining to Elixir pipe operator syntax
     * Usage: data.process().format() -> data |> process() |> format()
     */
    public static function transformChaining(expression: String): String {
        var result = expression;
        
        // Convert method chaining patterns to pipe operators
        // Pattern: obj.method1().method2() -> obj |> method1() |> method2()
        
        // Simple regex-like replacement using string operations
        var parts = result.split(".");
        if (parts.length > 1) {
            var transformed = parts[0];
            
            for (i in 1...parts.length) {
                var methodPart = parts[i];
                // Add pipe operator before each method call
                transformed += " |> " + methodPart;
            }
            
            result = transformed;
        }
        
        return result;
    }
    
    /**
     * Process pipe operator expressions and validate syntax
     */
    public static function processPipeExpression(expression: String): String {
        // Pipe operators are native in Elixir, so we mainly validate and pass through
        if (!isValidPipeExpression(expression)) {
            throw 'Invalid pipe operator expression: ${expression}';
        }
        
        return expression.trim();
    }
    
    /**
     * Validate pipe operator syntax
     */
    public static function isValidPipeExpression(expression: String): Bool {
        if (expression == null) {
            return false;
        }
        
        var expr = expression.trim();
        
        // Empty expression is invalid
        if (expr.length == 0) {
            return false;
        }
        
        // Basic validation: should contain |> and have balanced parts
        if (!expr.contains("|>")) {
            return false;
        }
        
        var parts = expr.split("|>");
        if (parts.length < 2) {
            return false;
        }
        
        // Each part should be non-empty when trimmed
        for (part in parts) {
            if (part.trim().length == 0) {
                return false;
            }
        }
        
        // Check for balanced parentheses in each part
        for (part in parts) {
            if (!hasBalancedParentheses(part.trim())) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Check if a string has balanced parentheses
     */
    private static function hasBalancedParentheses(str: String): Bool {
        var openCount = 0;
        
        for (i in 0...str.length) {
            var char = str.charAt(i);
            if (char == "(") {
                openCount++;
            } else if (char == ")") {
                openCount--;
                if (openCount < 0) {
                    return false;
                }
            }
        }
        
        return openCount == 0;
    }
    
    /**
     * Generate pipe operator macro for compile-time processing
     */
    public static macro function pipe(expr: ExprOf<Dynamic>): Expr {
        var exprString = getExpressionString(expr);
        var piped = processPipeExpression(exprString);
        
        // Return the transformed expression as a string literal
        return macro $v{piped};
    }
    
    /**
     * Macro for automatic pipe operator transformation
     * Usage: @:pipe data.process().format()
     */
    public static macro function autoPipe(expr: ExprOf<Dynamic>): Expr {
        var exprString = getExpressionString(expr);
        var piped = transformChaining(exprString);
        
        return macro $v{piped};
    }
    
    /**
     * Support for pipe operator in function calls
     * Usage: |>(data, process, format)
     */
    public static macro function pipeCall(args: Array<Expr>): Expr {
        if (args.length < 2) {
            throw "Pipe call requires at least 2 arguments";
        }
        
        var initial = getExpressionString(args[0]);
        var functions = [for (i in 1...args.length) getExpressionString(args[i])];
        
        var piped = initial;
        for (func in functions) {
            piped += " |> " + func;
        }
        
        return macro $v{piped};
    }
    
    /**
     * Helper function to extract string representation from expression
     */
    private static function getExpressionString(expr: Expr): String {
        return switch (expr.expr) {
            case EConst(CString(s)): s;
            case EConst(CIdent(s)): s;
            case ECall(e, params):
                var funcName = getExpressionString(e);
                var paramStrings = [for (p in params) getExpressionString(p)];
                funcName + "(" + paramStrings.join(", ") + ")";
            case EField(e, field):
                getExpressionString(e) + "." + field;
            case _: 
                // Fallback: use expression position to generate string
                "expression";
        };
    }
    
    /**
     * Pipe operator precedence and associativity handling
     */
    public static function optimizePipeChain(expression: String): String {
        var expr = expression.trim();
        
        // Remove unnecessary parentheses in pipe chains
        expr = StringTools.replace(expr, "( ", "(");
        expr = StringTools.replace(expr, " )", ")");
        
        // Optimize function call patterns
        expr = StringTools.replace(expr, "|> (", "|> ");
        expr = StringTools.replace(expr, ") |>", " |>");
        
        return expr;
    }
    
    /**
     * Generate performance-optimized pipe operator code
     */
    public static function generateOptimizedPipe(expression: String): String {
        var expr = processPipeExpression(expression);
        return optimizePipeChain(expr);
    }
}

#end