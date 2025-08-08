package test;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;

/**
 * Simple test to understand macro expression structures
 */
class SimpleExpressionTest {
    public static function main() {
        trace("Testing macro expression structures...");
        
        // Test what we actually receive
        var testExpr = macro u -> u.age > 18;
        inspectExpression(testExpr, "u -> u.age > 18");
        
        var testExpr2 = macro function(u) return u.name;
        inspectExpression(testExpr2, "function(u) return u.name");
        
        trace("✅ Expression inspection complete");
    }
    
    static function inspectExpression(expr: Expr, label: String): Void {
        trace('=== ${label} ===');
        if (expr == null) {
            trace("Expression is null!");
            return;
        }
        
        trace('Expression type: ${expr.expr}');
        
        switch (expr.expr) {
            case EFunction(name, f):
                trace('Function with ${f.args.length} args');
                for (i in 0...f.args.length) {
                    trace('  Arg ${i}: ${f.args[i].name}');
                }
                trace('Function body:');
                inspectExpression(f.expr, "  body");
                
            case EBinop(op, e1, e2):
                trace('Binary operation: ${op}');
                trace('Left side:');
                inspectExpression(e1, "  left");
                trace('Right side:');
                inspectExpression(e2, "  right");
                
            case EField(e, field):
                trace('Field access: ${field}');
                trace('Object:');
                inspectExpression(e, "  object");
                
            case EConst(c):
                trace('Constant: ${c}');
                
            case _:
                trace('Other expression type: ${Type.enumConstructor(expr.expr)}');
        }
    }
}

#end