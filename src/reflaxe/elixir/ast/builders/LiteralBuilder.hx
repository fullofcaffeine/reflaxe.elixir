package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.naming.ElixirAtom;
import reflaxe.elixir.CompilationContext;
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
        // Check if this string has the Atom type
        var isAtom = false;
        
        #if debug_atom_generation
        #if debug_ast_builder
        trace('[Atom Debug TConst] String "${s}" with type: ${expr.t}');
        #end
        #end
        
        switch(expr.t) {
            case TAbstract(ref, _):
                var abstractType = ref.get();
                #if debug_atom_generation
                #if debug_ast_builder
                trace('[Atom Debug TConst] Abstract type: ${abstractType.pack.join(".")}.${abstractType.name}');
                #end
                #end
                
                // Check if this is the Atom abstract type
                if (abstractType.pack.join(".") == "elixir.types" && abstractType.name == "Atom") {
                    isAtom = true;
                    #if debug_atom_generation
                    #if debug_ast_builder
                    trace('[Atom Debug TConst] DETECTED: String is Atom type!');
                    #end
                    #end
                }
                
            case _:
                #if debug_atom_generation
                #if debug_ast_builder
                trace('[Atom Debug TConst] Not an abstract type: ${expr.t}');
                #end
                #end
                // Not an abstract type
        }
        
        if (isAtom) {
            #if debug_atom_generation
            #if debug_ast_builder
            trace('[Atom Debug TConst] Generating atom :${s}');
            #end
            #end
            // Generate atom for Atom-typed strings
            return EAtom(s);
        } else {
            #if debug_atom_generation
            #if debug_ast_builder
            trace('[Atom Debug TConst] Generating string "${s}"');
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
     * HOW: Checks context to determine correct variable name
     */
    static function buildThisReference(context: CompilationContext): ElixirASTDef {
        // Handle 'this' references - use the receiver parameter name from context
        // In instance methods, this refers to the first parameter (struct)
        #if debug_exunit
        trace('[AST Builder] TThis: isInClassMethodContext=${context?.isInClassMethodContext}, isInExUnitTest=${context?.isInExUnitTest}, receiverParam=${context?.currentReceiverParamName}, context exists=${context != null}');
        #end
        
        if (context.isInClassMethodContext && context.currentReceiverParamName != null) {
            return EVar(context.currentReceiverParamName);
        } else if (context.isInExUnitTest) {
            // In ExUnit tests, 'this' should refer to the test context
            // This will be used for instance field access patterns
            #if debug_exunit
            trace('[AST Builder] Using "context" for ExUnit test');
            #end
            return EVar("context");
        } else {
            // For now, generate a placeholder that will cause a compile error
            // This helps identify where instance variables are being used inappropriately
            #if debug_exunit
            trace('[AST Builder] No context available - using placeholder');
            #end
            return EVar("__instance_variable_not_available_in_this_context__");
        }
    }
}

#end