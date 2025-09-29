package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.CompilationContext;

/**
 * SubstitutionHelpers: Variable Substitution and Null Coalescing Utilities
 * 
 * WHY: Centralize variable substitution and null coalescing logic
 * - Separate transformation concerns from main AST builder
 * - Provide reusable substitution utilities
 * - Handle null coalescing patterns consistently
 * 
 * WHAT: Variable replacement and null coalescing transformations
 * - Replace null coalescing variables in expressions
 * - Substitute variables with replacement expressions
 * - Build expressions with variable substitutions
 * 
 * HOW: Recursive AST traversal and transformation
 * - Pattern match on AST nodes to find target variables
 * - Replace matched variables with substitutions
 * - Preserve expression structure during transformation
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused on substitution operations
 * - Testability: Can test substitution logic independently
 * - Reusability: Used by multiple compilation phases
 */
class SubstitutionHelpers {
    
    /**
     * Replace null coalescing variable references with initialization expression
     * 
     * WHY: Null coalescing patterns need variable substitution
     * WHAT: Replaces references to temporary null coal vars with their init expr
     * HOW: Recursively traverses and replaces matching TLocal references
     */
    public static function replaceNullCoalVar(expr: TypedExpr, varId: Int, initExpr: TypedExpr): TypedExpr {
        return switch(expr.expr) {
            case TBinop(OpNullCoal, {expr: TLocal(v)}, defaultExpr) if (v.id == varId):
                // Replace the entire null coalescing with a conditional
                {
                    expr: TIf(
                        {expr: TBinop(OpNotEq, initExpr, {expr: TConst(TNull), t: expr.t, pos: expr.pos}), t: expr.t, pos: expr.pos},
                        initExpr,
                        defaultExpr
                    ),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TLocal(v) if (v.id == varId):
                // Direct reference to the variable - replace with init expression
                initExpr;
                
            case TBlock(exprs):
                // Recursively process block expressions
                {expr: TBlock(exprs.map(e -> replaceNullCoalVar(e, varId, initExpr))), t: expr.t, pos: expr.pos};
                
            case TIf(cond, thenExpr, elseExpr):
                // Process all branches
                {
                    expr: TIf(
                        replaceNullCoalVar(cond, varId, initExpr),
                        replaceNullCoalVar(thenExpr, varId, initExpr),
                        elseExpr != null ? replaceNullCoalVar(elseExpr, varId, initExpr) : null
                    ),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TCall(e, el):
                // Process function and arguments
                {
                    expr: TCall(
                        replaceNullCoalVar(e, varId, initExpr),
                        el.map(arg -> replaceNullCoalVar(arg, varId, initExpr))
                    ),
                    t: expr.t,
                    pos: expr.pos
                };
                
            default:
                // For other expressions, return as-is
                // Could add more cases as needed
                expr;
        };
    }
    
    /**
     * Substitute all occurrences of a variable with a replacement expression
     * 
     * WHY: Loop variables and other patterns need variable substitution
     * WHAT: Replaces all TLocal references to a variable with replacement expr
     * HOW: Recursive traversal with pattern matching on TLocal
     */
    public static function substituteVariable(expr: TypedExpr, varToReplace: TVar, replacement: TypedExpr): TypedExpr {
        return switch(expr.expr) {
            case TLocal(v) if (v.id == varToReplace.id):
                replacement;
                
            case TBlock(exprs):
                {expr: TBlock(exprs.map(e -> substituteVariable(e, varToReplace, replacement))), t: expr.t, pos: expr.pos};
                
            case TCall(e, el):
                {
                    expr: TCall(
                        substituteVariable(e, varToReplace, replacement),
                        el.map(arg -> substituteVariable(arg, varToReplace, replacement))
                    ),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TIf(cond, thenExpr, elseExpr):
                {
                    expr: TIf(
                        substituteVariable(cond, varToReplace, replacement),
                        substituteVariable(thenExpr, varToReplace, replacement),
                        elseExpr != null ? substituteVariable(elseExpr, varToReplace, replacement) : null
                    ),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TBinop(op, e1, e2):
                {
                    expr: TBinop(
                        op,
                        substituteVariable(e1, varToReplace, replacement),
                        substituteVariable(e2, varToReplace, replacement)
                    ),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TUnop(op, postFix, e):
                {
                    expr: TUnop(op, postFix, substituteVariable(e, varToReplace, replacement)),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TField(e, fa):
                {
                    expr: TField(substituteVariable(e, varToReplace, replacement), fa),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TArrayDecl(el):
                {
                    expr: TArrayDecl(el.map(e -> substituteVariable(e, varToReplace, replacement))),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TObjectDecl(fields):
                {
                    expr: TObjectDecl(fields.map(f -> {
                        name: f.name,
                        expr: substituteVariable(f.expr, varToReplace, replacement)
                    })),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TSwitch(e, cases, edef):
                {
                    expr: TSwitch(
                        substituteVariable(e, varToReplace, replacement),
                        cases.map(c -> {
                            values: c.values.map(v -> substituteVariable(v, varToReplace, replacement)),
                            expr: substituteVariable(c.expr, varToReplace, replacement)
                        }),
                        edef != null ? substituteVariable(edef, varToReplace, replacement) : null
                    ),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TFor(v, e1, e2):
                // Don't substitute inside the loop variable binding
                if (v.id == varToReplace.id) {
                    expr; // The loop variable shadows the outer one
                } else {
                    {
                        expr: TFor(
                            v,
                            substituteVariable(e1, varToReplace, replacement),
                            substituteVariable(e2, varToReplace, replacement)
                        ),
                        t: expr.t,
                        pos: expr.pos
                    };
                }
                
            case TWhile(econd, e, normalWhile):
                {
                    expr: TWhile(
                        substituteVariable(econd, varToReplace, replacement),
                        substituteVariable(e, varToReplace, replacement),
                        normalWhile
                    ),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TParenthesis(e):
                {
                    expr: TParenthesis(substituteVariable(e, varToReplace, replacement)),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TReturn(e):
                {
                    expr: TReturn(e != null ? substituteVariable(e, varToReplace, replacement) : null),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TThrow(e):
                {
                    expr: TThrow(substituteVariable(e, varToReplace, replacement)),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TTry(e, catches):
                {
                    expr: TTry(
                        substituteVariable(e, varToReplace, replacement),
                        catches.map(c -> {
                            v: c.v,
                            expr: c.v.id == varToReplace.id ? c.expr : substituteVariable(c.expr, varToReplace, replacement)
                        })
                    ),
                    t: expr.t,
                    pos: expr.pos
                };
                
            case TVar(v, init):
                // Don't substitute if this declares the same variable
                if (v.id == varToReplace.id) {
                    expr;
                } else {
                    {
                        expr: TVar(v, init != null ? substituteVariable(init, varToReplace, replacement) : null),
                        t: expr.t,
                        pos: expr.pos
                    };
                }
                
            default:
                expr; // Return unchanged for other cases
        };
    }
    
    /**
     * Build an expression with variable substitution applied
     * 
     * WHY: Some contexts need to compile with variable replacements
     * WHAT: Compiles an expression after applying variable substitution
     * HOW: Apply substitution then delegate to main builder
     * 
     * @param expr The expression to build
     * @param loopVar Optional loop variable to substitute
     * @param context Compilation context
     */
    public static function buildWithSubstitution(expr: TypedExpr, loopVar: Null<TVar>, context: CompilationContext): ElixirAST {
        if (loopVar != null) {
            // Apply substitution before building
            // TODO: Implement the actual substitution logic
            // For now, just delegate to regular build
        }
        
        // Delegate to main builder
        return ElixirASTBuilder.buildFromTypedExpr(expr, context);
    }
}

#end