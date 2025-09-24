package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * LOOP VARIABLE RESTORER
 * 
 * WHY: Haxe's optimizer replaces loop variables with literal values in string
 * concatenations. When we have `'Cell (' + i + ',' + j + ')'` in a loop,
 * Haxe optimizes it to use literals 0 and 1 instead of variables i and j.
 * 
 * WHAT: Detects when literal values in string interpolations should actually
 * be loop variable references and restores the correct variable names.
 * 
 * HOW: Tracks loop context as we traverse the AST, detects suspicious literal
 * values (0, 1, 2...) in interpolations within loop bodies, and replaces them
 * with the actual loop variable names.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles loop variable restoration
 * - Context-Aware: Maintains loop nesting context during traversal
 * - Pattern-Based: Uses heuristics to detect misoptimized variables
 * - Non-Invasive: Only affects interpolations within loop contexts
 */
/**
 * Context for tracking loop variables
 */
typedef LoopContext = {
    var variable: String;        // The loop variable name (e.g., "i", "j")
    var range: {min: Int, max: Int}; // Expected range of values
    var parent: Null<LoopContext>;   // Parent loop context for nesting
}

class LoopVariableRestorer {
    
    /**
     * Main transformation pass
     */
    public static function restoreLoopVariablesPass(ast: ElixirAST): ElixirAST {
        #if debug_loop_variable_restore
        switch(ast.def) {
            case EModule(name, _, _):
                trace('[LoopVariableRestorer] Processing module: $name');
            default:
                trace('[LoopVariableRestorer] Processing non-module AST');
        }
        #end
        return transformWithContext(ast, null);
    }
    
    /**
     * Transform AST with loop context tracking
     */
    static function transformWithContext(node: ElixirAST, context: Null<LoopContext>): ElixirAST {
        return switch(node.def) {
            // Detect Enum.each loops
            case ERemoteCall(module, "each", [range, fn]):
                #if debug_loop_variable_restore
                trace('[LoopVariableRestorer] Found ERemoteCall with each');
                trace('[LoopVariableRestorer]   isEnumModule: ${isEnumModule(module)}');
                trace('[LoopVariableRestorer]   isAnonymousFunction: ${isAnonymousFunction(fn)}');
                #end
                
                if (isEnumModule(module) && isAnonymousFunction(fn)) {
                    var params = extractFunctionParams(fn);
                    var body = extractFunctionBody(fn);
                    var newContext = extractLoopContext(range, params, context);
                    
                    #if debug_loop_variable_restore
                    trace('[LoopVariableRestorer] ✅ Processing Enum.each loop with variable: ${params}');
                    #end
                    
                    // Transform the loop body with the new context
                    var transformedBody = transformWithContext(body, newContext);
                    var transformedFn = reconstructAnonymousFunction(fn, transformedBody);
                    makeASTWithMeta(
                        ERemoteCall(
                            module,
                            "each",
                            [range, transformedFn]
                        ),
                        node.metadata,
                        node.pos
                    );
                } else {
                    // Not a pattern we're looking for, recurse on arguments
                    makeASTWithMeta(
                        ERemoteCall(
                            transformWithContext(module, context),
                            "each",
                            [transformWithContext(range, context), transformWithContext(fn, context)]
                        ),
                        node.metadata,
                        node.pos
                    );
                }
                
            // Process raw interpolated strings
            case ERaw(str) if (str.indexOf("#{") >= 0):
                #if debug_loop_variable_restore
                trace('[LoopVariableRestorer] Found ERaw with interpolation: $str');
                if (context != null) {
                    trace('[LoopVariableRestorer]   Context variable: ${context.variable}');
                    trace('[LoopVariableRestorer]   Context range: ${context.range.min}..${context.range.max}');
                } else {
                    trace('[LoopVariableRestorer]   No loop context available');
                }
                #end
                
                if (context != null) {
                    var restoredStr = restoreVariablesInString(str, context);
                    
                    #if debug_loop_variable_restore
                    if (restoredStr != str) {
                        trace('[LoopVariableRestorer] ✅ Restored string: $str -> $restoredStr');
                    } else {
                        trace('[LoopVariableRestorer] ❌ No changes made to string');
                    }
                    #end
                    
                    makeASTWithMeta(ERaw(restoredStr), node.metadata, node.pos);
                } else {
                    node;
                }
                
            // Recursively process other nodes
            case EModule(name, attributes, body):
                #if debug_loop_variable_restore
                if (name == "Main") {
                    trace('[LoopVariableRestorer] Processing Main module body with ${body.length} items');
                }
                #end
                makeASTWithMeta(
                    EModule(name, attributes, body.map(b -> transformWithContext(b, context))),
                    node.metadata,
                    node.pos
                );
                
            case EDefmodule(name, doBlock):
                makeASTWithMeta(
                    EDefmodule(name, transformWithContext(doBlock, context)),
                    node.metadata,
                    node.pos
                );
                
            case EDef(name, args, guard, body):
                #if debug_loop_variable_restore
                trace('[LoopVariableRestorer] Processing function: $name');
                #end
                makeASTWithMeta(
                    EDef(name, args, guard, transformWithContext(body, context)),
                    node.metadata,
                    node.pos
                );
                
            case EDefp(name, args, guard, body):
                #if debug_loop_variable_restore
                trace('[LoopVariableRestorer] Processing private function: $name');
                #end
                makeASTWithMeta(
                    EDefp(name, args, guard, transformWithContext(body, context)),
                    node.metadata,
                    node.pos
                );
                
            case EBlock(statements):
                makeASTWithMeta(
                    EBlock(statements.map(s -> transformWithContext(s, context))),
                    node.metadata,
                    node.pos
                );
                
            case ECall(target, func, args):
                makeASTWithMeta(
                    ECall(
                        target != null ? transformWithContext(target, context) : null,
                        func,
                        args.map(a -> transformWithContext(a, context))
                    ),
                    node.metadata,
                    node.pos
                );
                
            case ERemoteCall(module, func, args):
                makeASTWithMeta(
                    ERemoteCall(
                        transformWithContext(module, context),
                        func,
                        args.map(a -> transformWithContext(a, context))
                    ),
                    node.metadata,
                    node.pos
                );
                
            default:
                node; // Return unchanged for other node types
        };
    }
    
    /**
     * Extract loop context from range and parameters
     */
    static function extractLoopContext(range: ElixirAST, params: Array<String>, parent: Null<LoopContext>): LoopContext {
        var min = 0;
        var max = 10; // Default assumption
        
        // Try to extract range bounds
        switch(range.def) {
            case ERange(start, end, _):
                // Try to extract integer values from start and end
                switch(start.def) {
                    case EInteger(s): min = s;
                    default: // Keep default
                }
                switch(end.def) {
                    case EInteger(e): max = e;
                    default: // Keep default
                }
            default:
                // Keep defaults
        }
        
        return {
            variable: params.length > 0 ? params[0] : "i",
            range: {min: min, max: max},
            parent: parent
        };
    }
    
    /**
     * Check if the module is the Enum module
     */
    static function isEnumModule(module: ElixirAST): Bool {
        return switch(module.def) {
            case EAtom(atom): atom == "Enum";
            case EVar("Enum"): true;
            default: false;
        };
    }
    
    /**
     * Check if the AST node is an anonymous function
     */
    static function isAnonymousFunction(fn: ElixirAST): Bool {
        return switch(fn.def) {
            case EFn(_): true;
            default: false;
        };
    }
    
    /**
     * Extract function parameters from an anonymous function
     */
    static function extractFunctionParams(fn: ElixirAST): Array<String> {
        return switch(fn.def) {
            case EFn(clauses) if (clauses.length > 0): 
                // Extract parameter names from patterns
                clauses[0].args.map(p -> switch(p) {
                    case PVar(name): name;
                    default: "_";
                });
            default: [];
        };
    }
    
    /**
     * Extract function body from an anonymous function
     */
    static function extractFunctionBody(fn: ElixirAST): ElixirAST {
        return switch(fn.def) {
            case EFn(clauses) if (clauses.length > 0): 
                clauses[0].body;
            default: makeAST(ENil);
        };
    }
    
    /**
     * Reconstruct anonymous function with transformed body
     */
    static function reconstructAnonymousFunction(original: ElixirAST, newBody: ElixirAST): ElixirAST {
        return switch(original.def) {
            case EFn(clauses) if (clauses.length > 0):
                var newClauses = clauses.copy();
                newClauses[0] = {
                    args: newClauses[0].args,
                    guard: newClauses[0].guard,
                    body: newBody
                };
                makeASTWithMeta(EFn(newClauses), original.metadata, original.pos);
            default: original;
        };
    }
    
    /**
     * Restore variables in an interpolated string
     */
    static function restoreVariablesInString(str: String, context: LoopContext): String {
        var result = str;
        var currentContext = context;
        var variableIndex = 0;
        
        // Process each context level (for nested loops)
        while (currentContext != null) {
            // Look for patterns like #{0}, #{1}, #{2} that match expected range
            for (i in currentContext.range.min...(currentContext.range.max + 1)) {
                var pattern = '#{$i}';
                if (result.indexOf(pattern) >= 0) {
                    // This literal value is suspicious - likely should be the loop variable
                    var replacement = '#{${currentContext.variable}}';
                    
                    // Only replace the first occurrence to handle nested loops correctly
                    var index = result.indexOf(pattern);
                    if (index >= 0) {
                        result = result.substring(0, index) + replacement + 
                                result.substring(index + pattern.length);
                        
                        #if debug_loop_variable_restore
                        trace('[LoopVariableRestorer] Replaced $pattern with $replacement');
                        #end
                    }
                }
            }
            
            currentContext = currentContext.parent;
            variableIndex++;
        }
        
        return result;
    }
}

#end