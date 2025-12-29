package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.CompilationContext;

/**
 * ArrayBuilder: Handles array declaration and access building
 * 
 * WHY: Separates array-related logic from ElixirASTBuilder
 * - Reduces ElixirASTBuilder complexity
 * - Centralizes array comprehension detection
 * - Handles array access patterns
 * 
 * WHAT: Builds ElixirAST nodes for array operations
 * - TArrayDecl: Array literal declarations [1, 2, 3]
 * - TArray: Array element access arr[index]
 * - Array comprehensions: [for (i in 0...n) expr]
 * 
 * HOW: Detects patterns and generates appropriate AST
 * - Simple arrays become EList
 * - Comprehensions become EFor
 * - Array access becomes EAccess
 */
@:nullSafety(Off)
class ArrayBuilder {
    
    /**
     * Build array declaration expression
     * 
     * @param elements Array elements to include
     * @param context Build context with compilation state
     * @return ElixirASTDef for the array
     */
    public static function buildArrayDecl(elements: Array<TypedExpr>, context: CompilationContext): ElixirASTDef {
        var buildExpression = context.getExpressionBuilder();

        #if debug_ast_builder
        // DISABLED: trace('[DEBUG ArrayBuilder] buildArrayDecl called with ${elements.length} elements');
        #end
        if (elements.length > 0) {
            #if debug_ast_builder
            // DISABLED: trace('[DEBUG ArrayBuilder] First element type: ${reflaxe.elixir.util.EnumReflection.enumConstructor(elements[0].expr)}');
            #end
        }

        #if debug_ast_builder
        // DISABLED: trace('[AST Builder] TArrayDecl with ${elements.length} elements');
        if (elements.length > 0) {
            // DISABLED: trace('[AST Builder] First element type: ${reflaxe.elixir.util.EnumReflection.enumConstructor(elements[0].expr)}');
        }
        #end
        
        // Check for single-element array with TFor (direct comprehension)
        if (elements.length == 1 && elements[0].expr.match(TFor(_))) {
            // This is a comprehension like [for (i in 0...3) expr]
            // Return the TFor directly as EFor, not wrapped in EList
            #if debug_ast_builder
            // DISABLED: trace('[AST Builder] Detected array comprehension, treating as EFor instead of EList');
            #end
            return buildExpression(elements[0]).def;
        }
        
        // Check for single-element array with TBlock (desugared nested comprehension)
        if (elements.length == 1) {
            switch(elements[0].expr) {
                case TBlock(stmts):
                    #if debug_ast_builder
                    // DISABLED: trace('[DEBUG ArrayBuilder] Found single-element array with TBlock containing ${stmts.length} statements');
                    #end
                    // Try to reconstruct comprehension from desugared block
                    var comprehension = ComprehensionBuilder.tryBuildArrayComprehensionFromBlock(stmts, context);
                    #if debug_ast_builder
                    // DISABLED: trace('[DEBUG ArrayBuilder] Comprehension result: ${comprehension != null ? "SUCCESS" : "NULL"}');
                    #end
                    if (comprehension != null) {
                        switch(comprehension.def) {
                            case EFor(_, _, _, _, _):
                                #if debug_ast_builder
                                // DISABLED: trace('[AST Builder] Detected desugared comprehension in single-element array, treating as EFor');
                                #end
                                return comprehension.def;
                            default:
                                // Not a comprehension, proceed with normal list
                        }
                    } else {
                        // Fallback: loose extraction of list-building blocks to avoid emitting
                        // invalid bare concatenations inside array elements.
                        var loose = ComprehensionBuilder.extractListElementsLoose(stmts, context);
                        if (loose != null && loose.length > 0) {
                            #if debug_ast_builder
                            // DISABLED: trace('[AST Builder] Loose extraction produced ' + loose.length + ' element(s) for nested block');
                            #end
                            return EList(loose);
                        }
                    }
                default:
            }
        }
        
        // Normal array processing
        var builtElements = [];
        for (element in elements) {
            builtElements.push(buildExpression(element));
        }
        
        return EList(builtElements);
    }
    
    /**
     * Build array access expression
     * 
     * @param array The array expression to access
     * @param index The index expression
     * @param context Build context with compilation state
     * @return ElixirASTDef for the array access
     */
    public static function buildArrayAccess(array: TypedExpr, index: TypedExpr, context: CompilationContext): ElixirASTDef {
        var buildExpression = context.getExpressionBuilder();
        
        var target = buildExpression(array);
        var key = buildExpression(index);
        
        return EAccess(target, key);
    }
    
    /**
     * Check if an array declaration is actually a comprehension
     * 
     * WHY: Array comprehensions need special handling
     * WHAT: Detects [for (...) ...] patterns
     * HOW: Checks for single TFor element
     */
    public static function isComprehension(elements: Array<TypedExpr>): Bool {
        if (elements.length != 1) return false;
        
        return switch(elements[0].expr) {
            case TFor(_): true;
            case TBlock(stmts): 
                // Could be a desugared comprehension
                // Let ComprehensionBuilder determine
                false; // For now, let buildArrayDecl handle it
            default: false;
        }
    }
}

#end
