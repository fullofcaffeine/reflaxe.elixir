package reflaxe.elixir.ast.analyzers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.elixir.ast.loop_ir.LoopIR;

/**
 * BaseLoopAnalyzer: Foundation for Loop Pattern Analysis
 *
 * WHY: Common infrastructure for all loop analyzers. Provides shared utilities
 * for AST traversal, pattern matching, and confidence scoring.
 *
 * WHAT: Base class with:
 * - AST traversal helpers
 * - Pattern matching utilities
 * - Confidence calculation framework
 * - Debug tracing infrastructure
 *
 * HOW: Subclasses implement specific pattern detection logic while
 * leveraging common traversal and scoring mechanisms.
 *
 * ARCHITECTURE BENEFITS:
 * - DRY principle for analyzer infrastructure
 * - Consistent confidence scoring across analyzers
 * - Unified debug output format
 * - Testable pattern matching utilities
 */
abstract class BaseLoopAnalyzer {

    /**
     * Analyze a TypedExpr and contribute to LoopIR
     * Subclasses must implement this
     */
    public abstract function analyze(expr: TypedExpr, ir: LoopIR): Void;

    /**
     * Calculate confidence score for this analyzer's findings
     */
    public abstract function calculateConfidence(): Float;

    /**
     * Check if expression matches a specific pattern
     */
    function matchesPattern(expr: TypedExpr, pattern: ExprPattern): Bool {
        return switch(expr.expr) {
            case TConst(TInt(n)):
                switch(pattern) {
                    case IntLiteral(expected): n == expected;
                    case _: false;
                }
            case TLocal(v):
                switch(pattern) {
                    case LocalVar(name): v.name == name || name == "*";
                    case _: false;
                }
            case TBinop(op1, _, _):
                switch(pattern) {
                    case BinaryOp(op2): op1 == op2;
                    case _: false;
                }
            case TCall(_, _):
                switch(pattern) {
                    case FunctionCall: true;
                    case _: false;
                }
            case TField(_, _):
                switch(pattern) {
                    case FieldAccess: true;
                    case _: false;
                }
            case TBlock(_):
                switch(pattern) {
                    case BlockExpr: true;
                    case _: false;
                }
            case TIf(_, _, _):
                switch(pattern) {
                    case Conditional: true;
                    case _: false;
                }
            case TWhile(_, _, _):
                switch(pattern) {
                    case WhileLoop: true;
                    case _: false;
                }
            case TFor(_, _, _):
                switch(pattern) {
                    case ForLoop: true;
                    case _: false;
                }
            case _:
                false;
        }
    }

    /**
     * Find all expressions matching a pattern in AST
     */
    function findAll(expr: TypedExpr, pattern: ExprPattern): Array<TypedExpr> {
        var results = [];

        function traverse(e: TypedExpr) {
            if (matchesPattern(e, pattern)) {
                results.push(e);
            }

            // Traverse children
            switch(e.expr) {
                case TBlock(exprs):
                    for (expr in exprs) traverse(expr);
                case TBinop(_, e1, e2):
                    traverse(e1);
                    traverse(e2);
                case TUnop(_, _, e):
                    traverse(e);
                case TCall(e, args):
                    traverse(e);
                    for (arg in args) traverse(arg);
                case TField(e, _):
                    traverse(e);
                case TIf(cond, then, els):
                    traverse(cond);
                    traverse(then);
                    if (els != null) traverse(els);
                case TWhile(cond, body, _):
                    traverse(cond);
                    traverse(body);
                case TFor(_, iter, body):
                    traverse(iter);
                    traverse(body);
                case TSwitch(e, cases, def):
                    traverse(e);
                    for (c in cases) {
                        for (v in c.values) traverse(v);
                        traverse(c.expr);
                    }
                    if (def != null) traverse(def);
                case TReturn(e) if (e != null):
                    traverse(e);
                case TThrow(e):
                    traverse(e);
                case TTry(e, catches):
                    traverse(e);
                    for (c in catches) traverse(c.expr);
                case TParenthesis(e):
                    traverse(e);
                case TArrayDecl(values):
                    for (v in values) traverse(v);
                case _:
                    // Leaf nodes or unsupported
            }
        }

        traverse(expr);
        return results;
    }

    /**
     * Extract variable names from pattern
     */
    function extractVariableNames(expr: TypedExpr): Array<String> {
        var names = [];

        switch(expr.expr) {
            case TLocal(v):
                names.push(v.name);
            case TVar(v, _):
                names.push(v.name);
            case TBlock(exprs):
                for (e in exprs) {
                    names = names.concat(extractVariableNames(e));
                }
            case _:
                // Continue searching in children
                for (e in findAll(expr, LocalVar("*"))) {
                    switch(e.expr) {
                        case TLocal(v): names.push(v.name);
                        case _:
                    }
                }
        }

        return names;
    }

    /**
     * Check if expression has side effects
     */
    function hasSideEffects(expr: TypedExpr): Bool {
        // Check for IO operations, mutations, etc.
        var hasEffects = false;

        switch(expr.expr) {
            case TCall(e, _):
                // Check if it's a known side-effect function
                switch(e.expr) {
                    case TField(_, FStatic(_, cf)):
                        var name = cf.get().name;
                        hasEffects = name == "trace" || name == "print" ||
                                   name == "println" || name == "push" ||
                                   name == "add" || name == "remove";
                    case _:
                        // Conservative: assume calls have side effects
                        hasEffects = true;
                }
            case TBinop(OpAssign | OpAssignOp(_), _, _):
                hasEffects = true;
            case TUnop(OpIncrement | OpDecrement, _, _):
                hasEffects = true;
            case _:
                // Recursively check children
                for (child in findAll(expr, FunctionCall)) {
                    if (hasSideEffects(child)) {
                        hasEffects = true;
                        break;
                    }
                }
        }

        return hasEffects;
    }

    /**
     * Debug trace helper
     */
    function trace(message: String): Void {
        #if debug_loop_analyzers
        trace('[Analyzer ${Type.getClassName(Type.getClass(this))}] $message');
        #end
    }
}

/**
 * Pattern types for matching
 */
enum ExprPattern {
    IntLiteral(value: Int);
    LocalVar(name: String);  // "*" matches any name
    BinaryOp(op: Binop);
    FunctionCall;
    FieldAccess;
    BlockExpr;
    Conditional;
    WhileLoop;
    ForLoop;
}

#end