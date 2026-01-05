package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.naming.ElixirAtom;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.TypeUtils;
import reflaxe.elixir.ast.builders.CoreExprBuilder;

/**
 * LiteralBuilder: Handles literal and constant expression building
 * 
 * WHY: Separates literal handling logic from the main ElixirASTBuilder
 * - Reduces ElixirASTBuilder size for maintainability
 * - Provides focused handling of constant expressions
 * - Encapsulates atom detection and special literal handling
 * 
 * WHAT: Builds ElixirAST nodes for literal values
 * - String literals (with atom detection)
 * - This references
 * - Other constants via CoreExprBuilder delegation
 * 
 * HOW: Pattern matches on TConstant values and generates appropriate AST
 * - Detects Atom-typed strings and generates atoms
 * - Handles 'this' references based on context
 * - Delegates standard constants to CoreExprBuilder
 */
@:nullSafety(Off)
class LiteralBuilder {
    
    /**
     * Build literal/constant expressions
     * 
     * @param c The constant to build
     * @param expr The full typed expression (for type information)
     * @param context Build context with compilation state
     * @return ElixirASTDef for the literal
     */
    public static function buildConst(c: TConstant, expr: TypedExpr, context: CompilationContext): ElixirASTDef {
        switch(c) {
            case TString(s):
                return buildStringLiteral(s, expr);
                
            case TThis:
                return buildThisReference(context);
                
            default:
                // Delegate to CoreExprBuilder for other constants
                // Returns ElixirAST, but we need ElixirASTDef
                var ast = CoreExprBuilder.buildConst(c);
                return ast.def;
        }
    }
    
    /**
     * Build string literal with atom detection
     * 
     * WHY: Strings with Atom type should generate atoms, not strings
     * WHAT: Checks if string has elixir.types.Atom type
     * HOW: Inspects the expression type to detect Atom abstract
     */
    static function buildStringLiteral(s: String, expr: TypedExpr): ElixirASTDef {
        var isAtom = TypeUtils.isElixirAtomType(expr.t);
        
        if (isAtom) {
            #if debug_atom_generation
            #if debug_ast_builder
            #end
            #end
            // Generate atom for Atom-typed strings
            return EAtom(s);
        } else {
            #if debug_atom_generation
            #if debug_ast_builder
            #end
            #end
            // Regular string
            return EString(s);
        }
    }
    
    /**
     * Build 'this' reference based on context
     *
     * WHY: 'this' has different meanings in different contexts
     * WHAT: Generates appropriate variable reference for 'this'
     * HOW: Checks context to determine correct variable name, defaults to "struct" for instance methods
     */
    static function buildThisReference(context: CompilationContext): ElixirASTDef {
        // Handle 'this' references - use the receiver parameter name from context
        // In instance methods, this refers to the first parameter (struct)
        #if debug_exunit
        #end

        if (context.isInClassMethodContext && context.currentReceiverParamName != null) {
            return EVar(context.currentReceiverParamName);
        } else if (context.isInExUnitTest) {
            // In ExUnit tests, 'this' should refer to the test context
            // This will be used for instance field access patterns
            #if debug_exunit
            #end
            return EVar("context");
        } else if (context.currentReceiverParamName != null) {
            // FALLBACK: Even if isInClassMethodContext flag is not set,
            // if we have a receiver parameter name, use it!
            // This handles cases where context flags are lost due to inlining or nested contexts
            #if debug_exunit
            #end
            return EVar(context.currentReceiverParamName);
        } else {
            // DEFAULT FOR INSTANCE CLASSES: In Elixir, instance methods ALWAYS get "struct" as first parameter
            // This is a safe fallback - if TConst(TThis) appears and we're not in a static context, use "struct"
            #if debug_exunit
            #end
            return EVar("struct");
        }
    }
}

#end
