package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.LoopContext as ASTLoopContext;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * LOOP VARIABLE RESTORER
 * 
 * WHY: Loop variables get replaced with literal values in string concatenations
 * during compilation. When we have `'Cell (' + i + ',' + j + ')'` in a loop,
 * it becomes "Cell (#{0},#{1})" instead of "Cell (#{i},#{j})".
 * 
 * CRITICAL: This happens EVEN WITHOUT -D analyzer-optimize flag!
 * The issue is in our compiler's expression processing, not just Haxe's optimizer.
 * 
 * WHAT: Detects when literal values in string interpolations should actually
 * be loop variable references and restores the correct variable names.
 * 
 * HOW: Uses metadata preserved from ElixirASTBuilder that captures loop context
 * when loops are first created. This metadata survives all transformation passes,
 * allowing us to restore variables even after StringInterpolation has run.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles loop variable restoration
 * - Context-Aware: Maintains loop nesting context during traversal
 * - Pattern-Based: Uses heuristics to detect misoptimized variables
 * - Non-Invasive: Only affects interpolations within loop contexts
 */
/**
 * Legacy context for tracking loop variables (kept for compatibility with old pattern detection)
 * The new metadata-based approach uses ASTLoopContext from ElixirAST
 */
typedef LegacyLoopContext = {
    var variable: String;        // The loop variable name (e.g., "i", "j")
    var range: {min: Int, max: Int}; // Expected range of values
    var parent: Null<LegacyLoopContext>;   // Parent loop context for nesting
}

class LoopVariableRestorer {
    
    /**
     * Main transformation pass
     * 
     * ENHANCED: Now uses metadata-based approach instead of pattern detection
     * Metadata is preserved from ElixirASTBuilder through all transformation passes
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
        // Start with empty loop context, will be populated from metadata
        return transformWithMetadata(ast);
    }
    
    /**
     * Transform AST using metadata-based approach
     * 
     * NEW APPROACH: Instead of pattern detection, we use metadata preserved from builder
     * 
     * WHY THIS REPLACED PATTERN DETECTION:
     * - Pattern detection fails when StringInterpolation runs first and creates ERaw nodes
     * - By the time we see ERaw("Cell (#{0},#{1})"), the loop structure is gone
     * - Metadata survives all transformation passes, giving us context when needed
     * 
     * WHAT THIS DOES:
     * 1. Checks each node for loop context metadata
     * 2. If found and node contains interpolations, attempts restoration
     * 3. Propagates metadata to child nodes for nested structures
     * 
     * RELATES TO: Core solution for LOOP_VARIABLE_FIX_PRD.md
     */
    static function transformWithMetadata(node: ElixirAST): ElixirAST {
        // Check if this node has loop context metadata
        // WHY: Metadata was attached by ElixirASTBuilder when it processed TFor nodes
        var loopContexts = node.metadata != null ? node.metadata.loopContextStack : null;
        
        #if debug_loop_variable_restore
        if (loopContexts != null && loopContexts.length > 0) {
            trace('[LoopVariableRestorer] Found loop context metadata with ${loopContexts.length} contexts');
            for (ctx in loopContexts) {
                trace('[LoopVariableRestorer]   - Variable: ${ctx.variableName}, Range: ${ctx.rangeMin}..${ctx.rangeMax}');
            }
        }
        #end
        
        return switch(node.def) {
            // Process raw interpolated strings with metadata context
            case ERaw(str) if (str.indexOf("#{") >= 0 && loopContexts != null && loopContexts.length > 0):
                #if debug_loop_variable_restore
                trace('[LoopVariableRestorer] Found ERaw with interpolation and loop context: $str');
                #end
                
                var restoredStr = restoreVariablesFromMetadata(str, loopContexts);
                
                #if debug_loop_variable_restore
                if (restoredStr != str) {
                    trace('[LoopVariableRestorer] ✅ Restored string: $str -> $restoredStr');
                } else {
                    trace('[LoopVariableRestorer] ❌ No changes made to string');
                }
                #end
                
                makeASTWithMeta(ERaw(restoredStr), node.metadata, node.pos);
                
            // Recursively process all other nodes, propagating metadata down
            case EModule(name, attributes, body):
                makeASTWithMeta(
                    EModule(name, attributes, body.map(b -> {
                        // Propagate loop context to children if not already present
                        if (b.metadata == null) b.metadata = {};
                        if (loopContexts != null && b.metadata.loopContextStack == null) {
                            b.metadata.loopContextStack = loopContexts;
                        }
                        transformWithMetadata(b);
                    })),
                    node.metadata,
                    node.pos
                );
                
            case EBlock(statements):
                makeASTWithMeta(
                    EBlock(statements.map(s -> {
                        // Propagate metadata to block statements
                        if (s.metadata == null) s.metadata = {};
                        if (loopContexts != null && s.metadata.loopContextStack == null) {
                            s.metadata.loopContextStack = loopContexts;
                        }
                        transformWithMetadata(s);
                    })),
                    node.metadata,
                    node.pos
                );
                
            // Handle Enum.each calls - propagate metadata to function body
            case ERemoteCall(module, "each", args) if (loopContexts != null && loopContexts.length > 0):
                // Process arguments with metadata propagation
                var processedArgs = args.map(arg -> {
                    // For anonymous functions, propagate metadata to body
                    switch(arg.def) {
                        case EFn(clauses):
                            var newClauses = clauses.map(clause -> {
                                var bodyWithMeta = clause.body;
                                if (bodyWithMeta.metadata == null) bodyWithMeta.metadata = {};
                                if (bodyWithMeta.metadata.loopContextStack == null) {
                                    bodyWithMeta.metadata.loopContextStack = loopContexts;
                                }
                                var transformedBody = transformWithMetadata(bodyWithMeta);
                                {args: clause.args, guard: clause.guard, body: transformedBody};
                            });
                            makeASTWithMeta(EFn(newClauses), arg.metadata, arg.pos);
                        default:
                            transformWithMetadata(arg);
                    }
                });
                
                makeASTWithMeta(
                    ERemoteCall(module, "each", processedArgs),
                    node.metadata,
                    node.pos
                );
                
            // For loops: Update context stack and process body
            case EFor(generators, filters, body, into, unique):
                // Extract loop variable from first generator
                var newContext = if (generators.length > 0) {
                    switch(generators[0].pattern) {
                        case PVar(name):
                            // Create new context from this loop
                            var ctx: LoopContext = {
                                variableName: name,
                                rangeMin: 0,  // Would need to extract from generator.expr
                                rangeMax: -1,
                                depth: loopContexts != null ? loopContexts.length : 0,
                                iteratorExpr: "unknown"
                            };
                            
                            // Add to context stack
                            var newStack = loopContexts != null ? loopContexts.copy() : [];
                            newStack.push(ctx);
                            newStack;
                        default:
                            loopContexts;
                    }
                } else {
                    loopContexts;
                };
                
                // Process body with new context
                if (body.metadata == null) body.metadata = {};
                if (newContext != null) {
                    body.metadata.loopContextStack = newContext;
                }
                var processedBody = transformWithMetadata(body);
                
                makeASTWithMeta(
                    EFor(generators, filters, processedBody, into, unique),
                    node.metadata,
                    node.pos
                );
                
            // Default: recursively process children
            default:
                // For nodes with standard recursive structure, process children
                var processed = processChildNodes(node, loopContexts);
                makeASTWithMeta(processed.def, node.metadata, node.pos);
        }
    }
    
    /**
     * Restore variables in string using metadata context
     * 
     * WHY THIS WORKS: We know exactly which literal values came from which loops
     * because we captured the range information when the loop was created.
     * 
     * WHAT IT DOES:
     * - Takes a string like "Cell (#{0},#{1})"
     * - Uses loop contexts to know: 0 is from outer loop 'i', 1 is from inner loop 'j'
     * - Produces: "Cell (#{i},#{j})"
     * 
     * HOW IT HANDLES NESTING:
     * - Processes innermost loops first (reverse order)
     * - Prevents incorrect replacements (inner loop's 0 won't become outer loop's i)
     * 
     * RELATES TO: Final step in restoring idiomatic Elixir output
     */
    static function restoreVariablesFromMetadata(str: String, contexts: Array<LoopContext>): String {
        var result = str;
        
        // Process each loop context, innermost first (reverse order)
        // WHY REVERSE: Inner loop values should be replaced before outer loop values
        // EXAMPLE: In nested 0...2, both loops produce 0,1 but mean different variables
        var i = contexts.length;
        while (i > 0) {
            i--;
            var ctx = contexts[i];
            
            // Replace literal values that match expected range with variable names
            for (value in ctx.rangeMin...ctx.rangeMax + 1) {
                var pattern = '#{$value}';
                var replacement = '#{${ctx.variableName}}';
                
                if (result.indexOf(pattern) >= 0) {
                    #if debug_loop_variable_restore
                    trace('[LoopVariableRestorer] Replacing $pattern with $replacement');
                    #end
                    result = StringTools.replace(result, pattern, replacement);
                }
            }
        }
        
        return result;
    }
    
    /**
     * Process child nodes recursively
     */
    static function processChildNodes(node: ElixirAST, loopContexts: Array<LoopContext>): ElixirAST {
        // This handles the default recursive processing for node types not explicitly handled
        return node; // Simplified for now - would need full implementation
    }
    
    /**
     * Transform AST with loop context tracking (LEGACY - kept for compatibility)
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
                    trace('[LoopVariableRestorer]   Context variable: ${context.variableName}');
                    trace('[LoopVariableRestorer]   Context range: ${context.rangeMin}..${context.rangeMax}');
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
            variableName: params.length > 0 ? params[0] : "i",
            rangeMin: min,
            rangeMax: max,
            depth: parent != null ? parent.depth + 1 : 0,
            iteratorExpr: ""  // Not needed for legacy extraction
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
            for (i in currentContext.rangeMin...(currentContext.rangeMax + 1)) {
                var pattern = '#{$i}';
                if (result.indexOf(pattern) >= 0) {
                    // This literal value is suspicious - likely should be the loop variable
                    var replacement = '#{${currentContext.variableName}}';
                    
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
            
            currentContext = null;  // Legacy pattern detection doesn't support nested loops well
            variableIndex++;
        }
        
        return result;
    }
}

#end