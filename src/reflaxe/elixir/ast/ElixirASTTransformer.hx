package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.naming.ElixirAtom;
using StringTools;

/**
 * Transformation pass function type
 * Takes an AST node and returns a transformed node
 */
typedef TransformPass = (ast: ElixirAST) -> ElixirAST;

/**
 * Pass configuration
 */
typedef PassConfig = {
    name: String,
    description: String,
    enabled: Bool,
    pass: TransformPass
};

/**
 * ElixirASTTransformer: AST-to-AST Transformation Engine (Transformation Phase)
 * 
 * WHY: Central transformation phase for converting Haxe patterns to idiomatic Elixir
 * - Separates transformation logic from parsing and generation
 * - Enables multiple optimization and idiom conversion passes
 * - Makes transformations testable and composable
 * - Allows gradual addition of new transformations without breaking existing ones
 * 
 * WHAT: Applies a series of transformation passes to ElixirAST
 * - Each pass focuses on one specific transformation
 * - Passes can be enabled/disabled independently
 * - Transformations preserve semantics while improving idiomaticity
 * - Handles imperative→functional, mutable→immutable, loops→comprehensions
 * 
 * HOW: Pass-based architecture with recursive AST traversal
 * - Identity transformation as base (pass-through unchanged)
 * - Each pass is a separate function that pattern matches on AST nodes
 * - Passes are composed in a specific order for correctness
 * - Metadata preserved and enriched through transformations
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Each pass has one transformation goal
 * - Open/Closed: New passes can be added without modifying existing
 * - Composability: Passes can be combined and reordered
 * - Debuggability: Each pass can be tested in isolation
 * - Performance: Only enabled passes are executed
 * 
 * @see docs/03-compiler-development/INTERMEDIATE_AST_REFACTORING_PRD.md
 */
class ElixirASTTransformer {
    
    /**
     * Main entry point: Apply all transformation passes
     * 
     * WHY: Single interface for all AST transformations
     * WHAT: Applies enabled passes in order to transform AST
     * HOW: Iterates through pass list, applying each to the AST
     */
    public static function transform(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace('[XRay AST Transformer] Starting transformation pipeline');
        trace('[XRay AST Transformer] AST type: ${Type.enumConstructor(ast.def)}');
        trace('[XRay AST Transformer] AST metadata: ${ast.metadata}');
        #end
        #if debug_unrolled_comprehension
        trace('[DEBUG Transform] ElixirASTTransformer.transform() called');
        #end
        
        #if debug_ast_structure
        // Print AST structure for debugging
        switch(ast.def) {
            case EModule(name, _, _):
                trace('[XRay AST Structure] Module: $name');
            default:
                trace('[XRay AST Structure] Root: ${ast.def}');
        }
        #end
        
        var passes = getEnabledPasses();
        var result = ast;
        
        for (passConfig in passes) {
            #if debug_ast_transformer
            trace('[XRay AST Transformer] Applying pass: ${passConfig.name}');
            #end
            
            result = passConfig.pass(result);
        }
        
        #if debug_ast_transformer
        trace('[XRay AST Transformer] Transformation complete');
        #end
        
        return result;
    }
    
    /**
     * Get list of enabled transformation passes
     */
    static function getEnabledPasses(): Array<PassConfig> {
        var passes: Array<PassConfig> = [];
        
        // Identity pass (always first - ensures pass-through functionality)
        passes.push({
            name: "Identity",
            description: "Pass-through transformation (no changes)",
            enabled: true,
            pass: identityPass
        });
        
        // Resolve clause locals pass (must run very early to fix variable references)
        passes.push({
            name: "ResolveClauseLocals",
            description: "Resolve variable references in case clauses using varIdToName metadata",
            enabled: true,
            pass: resolveClauseLocalsPass
        });
        
        // Throw statement transformation (must run early to fix complex expressions)
        passes.push({
            name: "ThrowStatementTransform",
            description: "Transform complex throw expressions to avoid syntax errors",
            enabled: true,
            pass: throwStatementTransformPass
        });
        
        // Inline expansion fixes (should run very early to fix AST structure)
        passes.push({
            name: "InlineMethodCallCombiner",
            description: "Combine split inline expansion patterns from stdlib",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.InlineExpansionTransforms.inlineMethodCallCombinerPass
        });
        
        // Function reference transformation (must run early to add capture operators)
        passes.push({
            name: "FunctionReferenceTransform",
            description: "Transform function references to use capture operator (&Module.func/arity)",
            enabled: true,
            pass: functionReferenceTransformPass
        });
        
        // Bitwise import pass (should run early to add imports)
        passes.push({
            name: "BitwiseImport",
            description: "Add Bitwise import when bitwise operators are used",
            enabled: true,
            pass: bitwiseImportPass
        });

        // Collapse simple temp-binding blocks in expression contexts
        passes.push({
            name: "InlineTempBindingInExpr",
            description: "Collapse EBlock([tmp = exprA, exprB(tmp)]) to exprB(exprA) in expression positions",
            enabled: true,
            pass: inlineTempBindingInExprPass
        });

        // Debug: XRay map field values that contain EBlock
        passes.push({
            name: "XRayMapBlocks",
            description: "Debug pass to log map fields containing EBlock values",
            enabled: #if debug_temp_binding true #else false #end,
            pass: function(ast) {
                return transformNode(ast, function(node) {
                    switch(node.def) {
                        case EMap(pairs):
                            for (p in pairs) {
                                switch(p.value.def) {
                                    case EBlock(exprs):
                                        trace('[XRayMapBlocks] Found EBlock in map value with ' + exprs.length + ' exprs');
                                        for (i in 0...exprs.length) trace('  expr[' + i + ']: ' + ElixirASTPrinter.print(exprs[i], 0));
                                    default:
                                }
                            }
                            return node;
                        default:
                            return node;
                    }
                });
            }
        });
        
        // Module dependency requires pass (for standalone scripts)
        // NOTE: This is now handled directly in ModuleBuilder.generateRequireStatements
        // when building modules with static main() functions
        
        // Annotation-based transformation passes (MUST run first to set up module structure)
        passes.push({
            name: "PhoenixWebTransform",
            description: "Transform @:phoenixWeb modules into Phoenix Web helper module",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.phoenixWebTransformPass
        });
        
        passes.push({
            name: "EndpointTransform",
            description: "Transform @:endpoint modules into Phoenix.Endpoint structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.endpointTransformPass
        });
        
        passes.push({
            name: "LiveViewTransform",
            description: "Transform @:liveview modules into Phoenix.LiveView structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.liveViewTransformPass
        });
        
        passes.push({
            name: "PresenceTransform",
            description: "Transform @:presence modules into Phoenix.Presence structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.presenceTransformPass
        });
        
        // Phoenix Component import pass (MUST run AFTER LiveViewTransform to detect LiveView use statements)
        passes.push({
            name: "PhoenixComponentImport",
            description: "Add Phoenix.Component import when ~H sigil is used (unless LiveView already includes it)",
            enabled: true,
            pass: phoenixComponentImportPass
        });
        
        // LiveView CoreComponents import pass (should run after Phoenix Component)
        passes.push({
            name: "LiveViewCoreComponentsImport",
            description: "Add CoreComponents import for LiveView modules that use components",
            enabled: true,
            pass: liveViewCoreComponentsImportPass
        });
        
        // Phoenix function name mapping pass (transforms assign_multiple to assign, etc.)
        passes.push({
            name: "PhoenixFunctionMapping",
            description: "Map custom function names to Phoenix conventions",
            enabled: true,
            pass: phoenixFunctionMappingPass
        });
        
        passes.push({
            name: "ControllerTransform",
            description: "Transform @:controller modules into Phoenix.Controller structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.controllerTransformPass
        });
        
        passes.push({
            name: "RouterTransform",
            description: "Transform @:router modules into Phoenix.Router structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.routerTransformPass
        });
        
        passes.push({
            name: "SchemaTransform",
            description: "Transform @:schema modules into Ecto.Schema structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.schemaTransformPass
        });
        
        passes.push({
            name: "RepoTransform", 
            description: "Transform @:repo modules into Ecto.Repo structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.repoTransformPass
        });

        passes.push({
            name: "PostgrexTypesTransform",
            description: "Transform @:postgrexTypes modules into Postgrex types definition",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.postgrexTypesTransformPass
        });

        passes.push({
            name: "DbTypesTransform",
            description: "Transform @:dbTypes modules into DB adapter types definition",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.dbTypesTransformPass
        });
        
        passes.push({
            name: "ApplicationTransform",
            description: "Transform @:application modules into OTP Application structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.applicationTransformPass
        });
        
        passes.push({
            name: "ExUnitTransform",
            description: "Transform @:exunit modules into ExUnit.Case test structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.exunitTransformPass
        });
        
        // Constant folding pass
        #if !disable_constant_folding
        passes.push({
            name: "ConstantFolding",
            description: "Fold constant expressions at compile time",
            enabled: true,
            pass: constantFoldingPass
        });
        #end
        
        // Conditional reassignment pass (should run before pipeline optimization)
        passes.push({
            name: "ConditionalReassignment",
            description: "Convert conditional reassignments to functional style",
            enabled: true,
            pass: conditionalReassignmentPass
        });
        
        // Remove redundant nil initialization pass (should run before pipeline optimization)
        passes.push({
            name: "RemoveRedundantNilInit",
            description: "Remove redundant nil initialization when variable is immediately reassigned",
            enabled: true,
            pass: removeRedundantNilInitPass
        });
        
        // String method transformation pass (before pipeline optimization)
        passes.push({
            name: "StringMethodTransform",
            description: "Convert string method calls to String module calls",
            enabled: true,
            pass: stringMethodTransformPass
        });
        
        // Pipeline optimization pass
        #if !disable_pipeline_optimization
        passes.push({
            name: "PipelineOptimization",
            description: "Convert sequential operations to pipeline",
            enabled: true,
            pass: pipelineOptimizationPass
        });
        #end
        
        // Array method transformations are handled in ElixirASTBuilder
        // at the TCall(TField(...)) pattern to generate idiomatic Elixir directly
        
        // Loop to comprehension pass
        #if !disable_comprehension_conversion
        passes.push({
            name: "ComprehensionConversion",
            description: "Convert imperative loops to comprehensions",
            enabled: true,
            pass: comprehensionConversionPass
        });
        #end
        
        // Unrolled comprehension optimization pass (MUST run before effect lifting)
        // TODO: Fix implementation - functions need to be moved before this reference
        /*
        passes.push({
            name: "UnrolledComprehensionOptimization",
            description: "Optimize unrolled array comprehensions with bare concatenations",
            enabled: true,
            pass: unrolledComprehensionOptimizationPass
        });
        */
        
        // Effect lifting for list literals pass
        passes.push({
            name: "ListEffectLifting",
            description: "Lift side-effecting expressions out of list literals",
            enabled: true,
            pass: listEffectLiftingPass
        });
        
        // Immutability transformation pass
        #if !disable_immutability_transform
        passes.push({
            name: "ImmutabilityTransform",
            description: "Convert mutable patterns to immutable",
            enabled: true,
            pass: immutabilityTransformPass
        });
        #end
        
        // Null coalescing inline transformation pass
        passes.push({
            name: "NullCoalescingInline",
            description: "Convert null coalescing blocks to inline expressions",
            enabled: true,
            pass: nullCoalescingInlinePass
        });
        
        // Statement context transformation pass (MUST run after immutability)
        #if !disable_statement_context_transform
        passes.push({
            name: "StatementContextTransform",
            description: "Add reassignments for immutable operations in statement context",
            enabled: true,
            pass: statementContextTransformPass
        });
        #end
        
        // Self reference transformation pass (should run early)
        passes.unshift({
            name: "SelfReferenceTransform",
            description: "Convert self/this references to struct parameter",
            enabled: true,
            pass: selfReferenceTransformPass
        });
        
        // Struct field assignment transformation pass
        passes.push({
            name: "StructFieldAssignmentTransform",
            description: "Convert struct field assignments to struct update syntax",
            enabled: true,
            pass: structFieldAssignmentTransformPass
        });
        
        // Assignment extraction pass (must run before underscore cleanup)
        passes.push({
            name: "AssignmentExtraction",
            description: "Extract assignments from binary operations and other expression contexts",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignmentExtractionTransforms.assignmentExtractionPass
        });
        
        // Reduce while accumulator transformation (must run after assignment extraction)
        passes.push({
            name: "ReduceWhileAccumulator",
            description: "Fix variable shadowing in reduce_while loops by proper accumulator threading",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceWhileAccumulatorTransform.reduceWhileAccumulatorPass
        });
        
        // Struct field update transformation (removes problematic field assignments)
        passes.push({
            name: "StructUpdateTransform",
            description: "Transform instance field assignments to avoid unused variable warnings",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StructUpdateTransform.structUpdateTransformPass
        });
        
        // Array length field to function transformation (must run early to fix field access)
        passes.push({
            name: "ArrayLengthFieldToFunction",
            description: "Transform array.length field access to length(array) function calls",
            enabled: true,
            pass: arrayLengthFieldToFunctionPass
        });
        
        // Tuple element field to function transformation (must run before enum pattern matching)
        passes.push({
            name: "TupleElemFieldToFunction",
            description: "Transform tuple.elem field access to elem(tuple, index) function calls",
            enabled: true,
            pass: tupleElemFieldToFunctionPass
        });
        
        // Idiomatic enum pattern matching transformation (must run before underscore cleanup)
        passes.push({
            name: "IdiomaticEnumPatternMatching",
            description: "Transform enum tuple access patterns to idiomatic pattern matching",
            enabled: true,
            pass: idiomaticEnumPatternMatchingPass
        });
        
        // Underscore variable cleanup pass (should run late to catch all generated vars)
        #if !disable_underscore_cleanup
        passes.push({
            name: "UnderscoreVariableCleanup",
            description: "Remove underscore prefix from used temporary variables",
            enabled: true,
            pass: underscoreVariableCleanupPass
        });
        #end
        
        // Abstract method this reference fix (should run after underscore cleanup)
        passes.push({
            name: "AbstractMethodThis",
            description: "Fix 'this' references in abstract methods",
            enabled: true,
            pass: abstractMethodThisPass
        });
        
        // Supervisor options transformation pass (convert maps to keyword lists)
        #if !disable_supervisor_options_transform
        passes.push({
            name: "SupervisorOptionsTransform",
            description: "Convert supervisor option maps to keyword lists",
            enabled: true,
            pass: supervisorOptionsTransformPass
        });
        #end
        
        // OTP child spec transformation pass (convert tuples to proper child specs)
        #if !disable_otp_child_spec_transform
        passes.push({
            name: "OTPChildSpecTransform",
            description: "Convert enum-based child specs to proper OTP child specifications",
            enabled: true,
            pass: otpChildSpecTransformPass
        });
        #end
        
        // Prefix unused function parameters with underscore
        // DISABLED: Now handled during AST building with more accurate TypedExpr-based detection
        // The transformer approach had issues with mismatched detection logic between TypedExpr and ElixirAST
        // See ElixirASTBuilder line 2064-2070 for the proper implementation
        /*
        passes.push({
            name: "PrefixUnusedParameters", 
            description: "Prefix unused function parameters with underscore to follow Elixir conventions",
            enabled: true,
            pass: prefixUnusedParametersPass
        });
        */
        
        // ===== HYGIENE TRANSFORMATION PASSES =====
        // These passes eliminate compilation warnings and ensure idiomatic Elixir
        // TEMPORARILY DISABLED: Stack overflow issues due to incomplete AST traversal
        // TODO: Fix recursive traversal to handle all AST node types properly
        
        // Hygienic variable naming pass (eliminate shadowing)
        passes.push({
            name: "HygienicNaming",
            description: "Eliminate variable shadowing with scope-aware renaming",
            enabled: false, // TEMP: Disabled due to stack overflow
            pass: reflaxe.elixir.ast.transformers.HygieneTransforms.hygienicNamingPass
        });
        
        // Usage analysis pass (detect unused variables)
        passes.push({
            name: "UsageAnalysis",
            description: "Detect and mark unused variables with underscore prefix",
            enabled: true, // RE-ENABLED: Implementing proper binding-to-renaming connection
            pass: reflaxe.elixir.ast.transformers.HygieneTransforms.usageAnalysisPass
        });
        
        // Atom normalization pass (remove unnecessary quotes)
        passes.push({
            name: "AtomNormalization",
            description: "Remove unnecessary quotes from atoms",
            enabled: false, // TEMP: Disabled - needs more testing
            pass: reflaxe.elixir.ast.transformers.HygieneTransforms.atomNormalizationPass
        });
        
        // Equality to pattern matching pass (idiomatic comparisons)
        passes.push({
            name: "EqualityToPattern",
            description: "Transform == comparisons to pattern matching",
            enabled: false, // TEMP: Disabled - needs more testing
            pass: reflaxe.elixir.ast.transformers.HygieneTransforms.equalityToPatternPass
        });
        
        // Fix bare concatenations in blocks
        passes.push({
            name: "FixBareConcatenations",
            description: "Convert bare concatenations in blocks to assignments",
            enabled: true,
            pass: fixBareConcatenationsPass
        });
        
        // Return only enabled passes
        return passes.filter(p -> p.enabled);
    }

    /**
     * InlineTempBindingInExpr: Collapse simple temp-binding EBlock into a single expression
     * 
     * TERMINOLOGY:
     * - "Collapse" means to transform a two-statement block into a single expression by
     *   inlining a temporary variable. For example:
     *   BEFORE: (tmp = Date.now(); DateTime.to_unix(tmp, :millisecond))
     *   AFTER:  DateTime.to_unix(Date.now(), :millisecond)
     *   The temporary variable 'tmp' is eliminated by substituting its value directly.
     * 
     * WHY: Abstract method inlining sometimes produces blocks like:
     *   %{:online_at => (tmp = Date.now(); DateTime.to_unix(tmp, :millisecond))}
     * which is invalid in map field position. We collapse to a single expression:
     *   %{:online_at => DateTime.to_unix(Date.now(), :millisecond)}
     * 
     * WHAT: Detect EBlock([EMatch(PVar(tmp), exprA), exprB]) where exprB contains EVar(tmp)
     * and replace all occurrences of tmp in exprB with exprA, eliminating the temp variable.
     * 
     * HOW: Two-phase approach to avoid infinite recursion:
     * 1. Build a parent map to track expression vs statement contexts
     * 2. Single bottom-up transformation pass that collapses only in expression contexts
     * 
     * EDGE CASES:
     * - Only collapse in expression contexts (map values, function args, etc.)
     * - Skip collapsing in statement contexts (case clause bodies, function bodies)
     * - Only collapse if the temp variable is actually used
     * - Preserve precedence by wrapping substituted expressions in parentheses
     */
    static function inlineTempBindingInExprPass(ast: ElixirAST): ElixirAST {
        // Helper functions for collapsing logic
        function replaceVar(node: ElixirAST, name: String, replacement: ElixirAST): ElixirAST {
            return transformNode(node, function(n) {
                return switch(n.def) {
                    case EVar(v) if (v == name):
                        // Replace with a parenthesized expression to preserve precedence
                        makeAST(EParen(replacement));
                    case _:
                        n;
                };
            });
        }
        
        // Helper to check if a variable is used in an AST
        function containsVar(node: ElixirAST, varName: String): Bool {
            var found = false;
            iterateAST(node, function(n) {
                switch(n.def) {
                    case EVar(v) if (v == varName):
                        found = true;
                    default:
                }
            });
            return found;
        }
        
        // Determine if we're in an expression context where collapsing is safe
        function isInExpressionContext(parent: ElixirAST, child: ElixirAST): Bool {
            if (parent == null) return false;
            return switch(parent.def) {
                // Expression contexts where collapsing is safe
                case EMap(pairs): true; // Map field values
                case EKeywordList(pairs): true; // Keyword list values
                case ECall(_, _, _): true; // Function arguments
                case EBinary(_, _, _): true; // Binary operator operands
                case EUnary(_, _): true; // Unary operator operand
                case EParen(_): true; // Parenthesized expressions
                case EList(_): true; // List elements
                case ETuple(_): true; // Tuple elements
                case EMatch(_, _): true; // Right side of assignment/match
                
                // Statement contexts where we should NOT collapse
                case ECase(_, clauses): false; // Case clause bodies are statements
                case EDef(_, _, _, _): false; // Function bodies are statements
                case EDefp(_, _, _, _): false; // Private function bodies are statements
                case EDefmodule(_, _): false; // Module bodies are statements
                case EBlock(_): false; // Nested blocks are usually statement contexts
                case EIf(_, _, _): false; // If branches are statement contexts
                case ECond(clauses): false; // Cond clause bodies are statements
                
                default: false; // Conservative: don't collapse unless we're sure
            };
        }
        
        // Phase 1: Build parent map by walking the tree
        var parentOf = new haxe.ds.ObjectMap<ElixirAST, ElixirAST>();
        
        function walk(node: ElixirAST, parent: Null<ElixirAST>): Void {
            // Skip null nodes
            if (node == null) {
                return;
            }
            
            if (parent != null) {
                parentOf.set(node, parent);
            }
            
            // Walk all children based on node type
            switch(node.def) {
                case EBlock(exprs):
                    for (e in exprs) walk(e, node);
                    
                case ECall(target, method, args):
                    walk(target, node);
                    for (a in args) walk(a, node);
                    
                case EMap(pairs):
                    for (p in pairs) walk(p.value, node);
                    
                case EKeywordList(pairs):
                    for (p in pairs) walk(p.value, node);
                    
                case ETuple(values):
                    for (v in values) walk(v, node);
                    
                case EList(items):
                    for (i in items) walk(i, node);
                    
                case EBinary(op, left, right):
                    walk(left, node);
                    walk(right, node);
                    
                case EUnary(op, expr):
                    walk(expr, node);
                    
                case ECase(expr, clauses):
                    walk(expr, node);
                    for (c in clauses) {
                        if (c.guard != null) walk(c.guard, node);
                        walk(c.body, node);
                    }
                    
                case EIf(cond, thenB, elseB):
                    walk(cond, node);
                    walk(thenB, node);
                    if (elseB != null) walk(elseB, node);
                    
                case ECond(clauses):
                    for (c in clauses) {
                        walk(c.condition, node);
                        walk(c.body, node);
                    }
                    
                case EDef(name, args, guards, body):
                    if (guards != null) walk(guards, node);
                    walk(body, node);
                    
                case EDefp(name, args, guards, body):
                    if (guards != null) walk(guards, node);
                    walk(body, node);
                    
                case EDefmodule(name, body):
                    walk(body, node);
                    
                case EAssign(name):
                    // EAssign is for template assigns (@variable), no children
                    
                    
                case EParen(expr):
                    walk(expr, node);
                    
                case EMatch(pattern, expr):
                    // Pattern is usually not an expression, but walk the expr
                    walk(expr, node);
                    
                // Add more cases as needed for other node types
                default:
                    // Leaf nodes or nodes without children
            }
        }
        
        // Walk the entire tree to build parent map
        walk(ast, null);
        
        // Phase 2: Transform bottom-up, collapsing only when in expression context
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            var parent = parentOf.exists(node) ? parentOf.get(node) : null;
            var inExpr = parent != null && isInExpressionContext(parent, node);
            
            // Check if this is a collapsible block in an expression context
            var shouldCollapse = switch(node.def) {
                case EBlock(exprs) if (exprs.length == 2):
                    inExpr; // Only collapse in expression contexts
                default:
                    false;
            };
            
            if (!shouldCollapse) return node;
            
            // Try to collapse the block
            switch(node.def) {
                case EBlock(exprs) if (exprs.length == 2):
                    switch(exprs[0].def) {
                        case EMatch(PVar(tmp), bindExpr):
                            var second = exprs[1];
                            // Check if tmp is actually used in the second expression
                            if (containsVar(second, tmp)) {
                                var collapsed = replaceVar(second, tmp, bindExpr);
                                #if debug_temp_binding
                                trace('[InlineTempBindingInExpr] Collapsing temp binding in expression context');
                                trace('[InlineTempBindingInExpr]   tmp      = ' + tmp);
                                trace('[InlineTempBindingInExpr]   bindExpr = ' + ElixirASTPrinter.print(bindExpr, 0));
                                trace('[InlineTempBindingInExpr]   second   = ' + ElixirASTPrinter.print(second, 0));
                                trace('[InlineTempBindingInExpr]   result   = ' + ElixirASTPrinter.print(collapsed, 0));
                                #end
                                return collapsed;
                            }
                        default:
                    }
                default:
            }
            
            return node;
        });
    }
    
    /**
     * Throw statement transformation pass
     * 
     * WHY: Complex expressions in throw statements can generate invalid Elixir syntax
     *      when string concatenation includes conditionals or function calls
     * WHAT: Transforms throw expressions with complex string concatenation
     * HOW: Wraps complex expressions in parentheses to ensure valid syntax
     */
    static function throwStatementTransformPass(ast: ElixirAST): ElixirAST {
        return switch(ast.def) {
            case EThrow(value):
                // Transform the throw value to ensure it's a valid single expression
                var transformedValue = transformThrowValue(value);
                {
                    def: EThrow(transformedValue),
                    metadata: ast.metadata,
                    pos: ast.pos
                };
            default:
                // Recursively transform children using the standard transformer
                transformAST(ast, throwStatementTransformPass);
        };
    }
    
    /**
     * Transform throw value to ensure it generates valid Elixir syntax
     */
    static function transformThrowValue(expr: ElixirAST): ElixirAST {
        return switch(expr.def) {
            case EBinary(StringConcat, left, right):
                // For string concatenation, ensure both sides are properly formatted
                var leftTransformed = transformThrowValue(left);
                var rightTransformed = transformThrowValue(right);
                
                // If right side is complex, wrap it in parentheses
                var rightWrapped = switch(rightTransformed.def) {
                    case EIf(_, _, _):
                        {
                            def: EParen(rightTransformed),
                            metadata: rightTransformed.metadata,
                            pos: rightTransformed.pos
                        };
                    case ECall(_, _, _) if (hasConditionalInCall(rightTransformed)):
                        {
                            def: EParen(rightTransformed),
                            metadata: rightTransformed.metadata,
                            pos: rightTransformed.pos
                        };
                    default:
                        rightTransformed;
                };
                
                {
                    def: EBinary(StringConcat, leftTransformed, rightWrapped),
                    metadata: expr.metadata,
                    pos: expr.pos
                };
                
            case EIf(cond, then, els):
                // Wrap if expressions in parentheses when used in throw
                {
                    def: EParen(expr),
                    metadata: expr.metadata,
                    pos: expr.pos
                };
                
            default:
                expr;
        };
    }
    
    /**
     * Check if a call expression contains conditionals that might cause syntax issues
     */
    static function hasConditionalInCall(expr: ElixirAST): Bool {
        return switch(expr.def) {
            case ECall(_, _, args):
                Lambda.exists(args, function(arg) {
                    return switch(arg.def) {
                        case EIf(_, _, _): true;
                        default: false;
                    };
                });
            default: false;
        };
    }
    
    /**
     * Identity pass - returns AST unchanged
     * Base pass that ensures transformer works even with no transformations
     */
    static function identityPass(ast: ElixirAST): ElixirAST {
        return ast;
    }
    
    /**
     * Resolve Clause Locals Pass
     * 
     * WHY: Variables in case clause bodies need to match the names used in patterns.
     * When Haxe generates temporary variables (_g, g, etc.) for enum parameters,
     * but our patterns use the actual parameter names (value, reason, etc.),
     * we need to resolve these references.
     * 
     * WHAT: Looks for nodes with varIdToName metadata and rewrites EVar nodes
     * within them to use the mapped names based on their sourceVarId.
     * 
     * HOW: When we encounter a node with varIdToName metadata, we walk its
     * subtree and rewrite any EVar that has a sourceVarId matching an entry
     * in the varIdToName map.
     * 
     * EDGE CASES:
     * - Nested case expressions: Each case should have its own varIdToName scope
     * - String interpolation: Variables inside __elixir__() injections need resolution
     * - Anonymous functions: May reference outer scope variables
     */
    static function resolveClauseLocalsPass(ast: ElixirAST): ElixirAST {
        #if debug_clause_locals
        trace('[XRay ResolveClauseLocals] Starting pass');
        #end
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            // Check if this node has varIdToName metadata
            if (node.metadata != null && node.metadata.varIdToName != null) {
                var varIdToName = node.metadata.varIdToName;
                
                #if debug_clause_locals
                trace('[XRay ResolveClauseLocals] Found varIdToName metadata with ${Lambda.count(varIdToName)} mappings');
                for (id => name in varIdToName) {
                    trace('  $id -> $name');
                }
                #end
                
                // Transform all EVar nodes within this subtree
                return transformNode(node, function(inner: ElixirAST): ElixirAST {
                    switch(inner.def) {
                        case EVar(currentName):
                            // Check if this variable has a sourceVarId that needs remapping
                            if (inner.metadata != null && inner.metadata.sourceVarId != null) {
                                var sourceId = inner.metadata.sourceVarId;
                                if (varIdToName.exists(sourceId)) {
                                    var newName = varIdToName.get(sourceId);
                                    
                                    #if debug_clause_locals
                                    trace('[XRay ResolveClauseLocals] Remapping variable: $currentName (id:$sourceId) -> $newName');
                                    #end
                                    
                                    // Create new EVar with the mapped name
                                    return makeASTWithMeta(EVar(newName), inner.metadata, inner.pos);
                                }
                            }
                            return inner;
                            
                        default:
                            return inner;
                    }
                });
            }
            
            return node;
        });
    }
    
    /**
     * Function Reference Transform Pass
     * 
     * WHY: When passing functions as references in Elixir, they need the capture operator
     * WHAT: Transforms Module.function__FUNC_REF__N to &Module.function/N
     * HOW: Looks for EField nodes with __FUNC_REF__ marker and converts to capture syntax
     */
    static function functionReferenceTransformPass(ast: ElixirAST): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EField(target, field):
                    // Check if this has the function reference marker
                    if (field.indexOf("__FUNC_REF__") != -1) {
                        #if debug_function_reference
                        trace('[FunctionRef] Found marked field: $field');
                        #end
                        
                        // Extract the actual field name and arity
                        var parts = field.split("__FUNC_REF__");
                        var actualField = parts[0];
                        var arity = parts.length > 1 ? Std.parseInt(parts[1]) : 0;
                        if (arity == null) arity = 0;
                        
                        #if debug_function_reference
                        trace('[FunctionRef] Transforming to capture: &Module.$actualField/$arity');
                        #end
                        
                        // Create the clean field access without the marker
                        var cleanField = makeAST(EField(target, actualField));
                        
                        // Transform to capture syntax: &Module.function/arity
                        return makeAST(ECapture(cleanField, arity));
                    }
                    return node;
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * Null Coalescing Inline Pass
     * 
     * Transforms null coalescing blocks into inline if expressions.
     * Detects pattern: var x = {tmp = expr; if (tmp != nil) tmp else default}
     * Transforms to: var x = if (tmp = expr) != nil, do: tmp, else: default
     */
    static function nullCoalescingInlinePass(ast: ElixirAST): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            #if debug_null_coalescing
            switch(node.def) {
                case EMatch(PVar(name), value):
                    trace('[NullCoalescing] Found EMatch with name: $name');
                    if (value != null) {
                        switch(value.def) {
                            case EBlock(exprs):
                                trace('[NullCoalescing] Found block with ${exprs.length} expressions');
                            default:
                                trace('[NullCoalescing] Value is not a block: ${value.def}');
                        }
                    }
                default:
            }
            #end
            
            return switch(node.def) {
                case EMatch(PVar(name), value) if (value != null):
                    // Check if value is a block with null coalescing pattern
                    switch(value.def) {
                        case EBlock([assign, ifExpr]) if (assign != null && ifExpr != null):
                            // Check if this matches the null coalescing pattern
                            switch(assign.def) {
                                case EMatch(PVar(tmpName), expr) if (tmpName != null && tmpName.indexOf("tmp") >= 0):
                                    // Check if the if expression uses the same tmp variable
                                    switch(ifExpr.def) {
                                        case EIf(condition, thenBranch, elseBranch):
                                            // Check if condition is comparing tmp to nil
                                            switch(condition.def) {
                                                case EBinary(NotEqual, tmpVar, nilExpr):
                                                    switch(tmpVar.def) {
                                                        case EVar(checkName) if (checkName == tmpName):
                                                            // This is the null coalescing pattern!
                                                            // Transform to inline if with assignment in condition
                                                            // Create: name = if (tmp = expr) != nil, do: tmp, else: default
                                                            var assignExpr = makeAST(EMatch(PVar(tmpName), expr));
                                                            var inlineCondition = makeAST(EBinary(
                                                                NotEqual,
                                                                makeAST(EParen(assignExpr)),
                                                                makeAST(ENil)
                                                            ));
                                                            makeAST(EMatch(PVar(name), makeAST(EIf(inlineCondition, thenBranch, elseBranch))));
                                                        default:
                                                            node; // Not using the same tmp variable
                                                    }
                                                default:
                                                    node; // Not a nil comparison
                                            }
                                        default:
                                            node; // Not an if expression
                                    }
                                default:
                                    node; // Not a temp variable assignment
                            }
                        default:
                            node; // Not a null coalescing block
                    }
                default:
                    node; // Not a variable declaration or no transformation needed
            };
        });
    }
    
    /**
     * Self reference transformation pass - converts self/this references to struct parameter
     * In Elixir, instance methods receive the struct as their first parameter
     * 
     * For inheritance: Haxe's super.method() becomes delegation to parent module
     * Example: super.toString() -> ParentModule.to_string(struct)
     */
    static function selfReferenceTransformPass(ast: ElixirAST): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                // Transform self.field and super.field  
                case EField(target, fieldName):
                    switch(target.def) {
                        case EVar("self"):
                            // Replace 'self' with 'struct' (the conventional first parameter)
                            makeAST(EField(makeAST(EVar("struct")), fieldName));
                        case EVar("super"):
                            // Transform super.method() to Elixir delegation pattern
                            // Extract parent module from metadata if available
                            var parentModule = extractParentModule(node);
                            if (parentModule != null) {
                                // Generate: ParentModule.method_name(struct, ...args)
                                var elixirMethodName = toSnakeCase(fieldName);
                                makeAST(ECall(
                                    makeAST(EVar(parentModule)),
                                    elixirMethodName,
                                    [makeAST(EVar("struct"))]
                                ));
                            } else {
                                // Fallback: generate a placeholder that indicates inheritance is needed
                                // The compiler should handle this at a higher level
                                // For now, just call the method on struct directly
                                makeAST(ECall(
                                    null,
                                    toSnakeCase(fieldName),
                                    [makeAST(EVar("struct"))]
                                ));
                            }
                        default:
                            node;
                    }
                    
                // Transform standalone 'self' references
                case EVar("self"):
                    makeAST(EVar("struct"));
                    
                // Transform standalone 'super' references
                case EVar("super"):
                    makeAST(ENil);
                    
                // Handle super calls - Elixir doesn't have super
                case ECall(target, funcName, args):
                    if (funcName == "__super__") {
                        // Generate error or warning - super is not supported in Elixir
                        // For now, just return nil
                        makeAST(ENil);
                    } else {
                        node;
                    }
                    
                default:
                    node;
            }
        });
    }
    
    /**
     * Phoenix Component Import Pass: Add Phoenix.Component import when ~H sigil is used
     * 
     * WHY: The ~H sigil for HEEx templates requires Phoenix.Component to be imported
     * WHAT: Detects any ESigil with type "H" and adds the necessary import
     * HOW: Traverses AST looking for ~H sigils, then adds import if found
     * 
     * IMPORTANT: Skip if module already has LiveView use statement (includes Phoenix.Component)
     */
    static function phoenixComponentImportPass(ast: ElixirAST): ElixirAST {
        // Phase 1: Detect if ~H sigil is used
        var needsPhoenixComponent = false;
        
        #if debug_phoenix_component_import
        trace('[XRay PhoenixComponentImport] Starting scan for ~H sigils');
        #end
        
        // Recursive function to deeply traverse the AST
        function checkForHSigil(node: ElixirAST): Void {
            switch(node.def) {
                case ESigil(type, _, _):
                    #if debug_phoenix_component_import
                    trace('[XRay PhoenixComponentImport] Found sigil type: $type');
                    #end
                    if (type == "H") {
                        needsPhoenixComponent = true;
                    }
                default:
                    // For all other node types, recursively visit children
                    iterateAST(node, checkForHSigil);
            }
        }
        
        checkForHSigil(ast);
        
        #if debug_phoenix_component_import
        trace('[XRay PhoenixComponentImport] Needs Phoenix.Component: $needsPhoenixComponent');
        #end
        
        // Phase 2: Add import if needed
        if (!needsPhoenixComponent) return ast;
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EDefmodule(name, doBlock):
                    #if debug_phoenix_component_import
                    trace('[XRay PhoenixComponentImport] Processing defmodule: $name');
                    #end
                    
                    // For defmodule, we need to inject the import into the do block
                    switch(doBlock.def) {
                        case EBlock(statements):
                            #if debug_phoenix_component_import
                            trace('[XRay PhoenixComponentImport] Defmodule has ${statements.length} statements');
                            #end
                            
                            // Check if Phoenix.Component is already imported or if LiveView is used
                            var hasImport = false;
                            var hasLiveViewUse = false;
                            for (stmt in statements) {
                                switch(stmt.def) {
                                    case EImport(module, _, _):
                                        // module is a string in EImport
                                        if (module == "Phoenix.Component") {
                                            hasImport = true;
                                            break;
                                        }
                                    case EUse(module, opts):
                                        // module is a string in EUse
                                        #if debug_phoenix_component_import
                                        trace('[XRay PhoenixComponentImport] Found EUse: module=$module, opts=$opts');
                                        #end
                                        if (module == "Phoenix.Component") {
                                            hasImport = true;
                                            break;
                                        }
                                        // Check if it's a LiveView use statement (e.g., use TodoAppWeb, :live_view)
                                        if (module.indexOf("Web") != -1 && opts != null && opts.length > 0) {
                                            // Check if it has :live_view option
                                            for (opt in opts) {
                                                #if debug_phoenix_component_import
                                                trace('[XRay PhoenixComponentImport] Checking option: $opt');
                                                #end
                                                switch(opt.def) {
                                                    // Pattern matching with abstract types requires guard clause
                                                case EAtom(atom) if (atom == "live_view"):
                                                        #if debug_phoenix_component_import
                                                        trace('[XRay PhoenixComponentImport] Found :live_view option - will skip Phoenix.Component');
                                                        #end
                                                        hasLiveViewUse = true;
                                                        hasImport = true; // LiveView includes Phoenix.Component
                                                        break;
                                                    default:
                                                }
                                            }
                                        }
                                    default:
                                }
                            }
                            
                            // Don't add Phoenix.Component if LiveView is already used
                            if (hasLiveViewUse) {
                                #if debug_phoenix_component_import
                                trace('[XRay PhoenixComponentImport] Module already has LiveView use statement, skipping Phoenix.Component');
                                #end
                                return node;
                            }
                            
                            if (!hasImport) {
                                #if debug_phoenix_component_import
                                trace('[XRay PhoenixComponentImport] Adding Phoenix.Component import');
                                #end
                                
                                // Create the import statement using EUse which takes a string
                                var importStmt = makeAST(EUse("Phoenix.Component", []));
                                
                                // Add import at the beginning of the module body
                                var newStatements = [importStmt].concat(statements);
                                var newDoBlock = makeASTWithMeta(EBlock(newStatements), doBlock.metadata, doBlock.pos);
                                
                                return makeASTWithMeta(EDefmodule(name, newDoBlock), node.metadata, node.pos);
                            }
                            
                            return node; // Return unchanged if already has import
                            
                        default:
                            // Single expression body, wrap in block with import
                            var importStmt = makeAST(EUse("Phoenix.Component", []));
                            var newDoBlock = makeAST(EBlock([importStmt, doBlock]));
                            return makeASTWithMeta(EDefmodule(name, newDoBlock), node.metadata, node.pos);
                    }
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * Phoenix function name mapping pass
     * 
     * WHY: Some Haxe helper functions need to be mapped to proper Phoenix functions
     * WHAT: Transforms assign_multiple to assign, and other custom names to Phoenix conventions
     * HOW: Detects function calls and remaps their names
     */
    static function phoenixFunctionMappingPass(node: ElixirAST): ElixirAST {
        return transformNode(node, function(n: ElixirAST): ElixirAST {
            switch(n.def) {
                // Transform assign_multiple(socket, map) to assign(socket, map)
                case ECall(null, "assign_multiple", args):
                    #if debug_ast_transformer
                    trace('[PhoenixFunctionMapping] Transforming assign_multiple to assign');
                    #end
                    return makeASTWithMeta(ECall(null, "assign", args), n.metadata, n.pos);
                    
                default:
                    return n;
            }
        });
    }
    
    /**
     * LiveView CoreComponents Import Pass: Add app's CoreComponents import for LiveView modules
     * 
     * WHY: LiveView modules that use component functions need to import their app's CoreComponents
     * WHAT: Detects component usage (<.button, <.input, etc.) and adds CoreComponents import
     * HOW: Looks for ~H sigils with component calls and adds appropriate import
     * 
     * NOTE: This can conflict with Phoenix.HTML.Form functions. In Phoenix apps, the CoreComponents
     * version takes precedence for dot-notation components (<.label> uses CoreComponents.label/1)
     */
    static function liveViewCoreComponentsImportPass(ast: ElixirAST): ElixirAST {
        // Phase 1: Detect if component functions are used
        var needsCoreComponents = false;
        var moduleName = "";
        
        #if debug_liveview_components
        trace('[XRay LiveViewComponents] Starting scan for component usage');
        #end
        
        // First, find the module name to determine the app name
        function findModuleName(node: ElixirAST): Void {
            switch(node.def) {
                case EDefmodule(name, _):
                    moduleName = name;
                    return;
                default:
                    iterateAST(node, findModuleName);
            }
        }
        
        findModuleName(ast);
        
        // Check if this is a LiveView module (has "Live" in name)
        if (moduleName == "" || moduleName.indexOf("Live") == -1) {
            return ast; // Not a LiveView module
        }
        
        // Recursive function to check for component usage in ~H sigils
        function checkForComponents(node: ElixirAST): Void {
            switch(node.def) {
                case ESigil(type, content, _):
                    if (type == "H") {
                        // Check if content contains component calls like <.button, <.input, etc.
                        if (content.indexOf("<.") != -1) {
                            #if debug_liveview_components
                            trace('[XRay LiveViewComponents] Found component usage in ~H sigil');
                            #end
                            needsCoreComponents = true;
                        }
                    }
                default:
                    iterateAST(node, checkForComponents);
            }
        }
        
        checkForComponents(ast);
        
        #if debug_liveview_components
        trace('[XRay LiveViewComponents] Needs CoreComponents: $needsCoreComponents');
        #end
        
        // Phase 2: Add import if needed
        if (!needsCoreComponents) return ast;
        
        // Extract app name from module name (e.g., TodoAppWeb.UserLive -> TodoAppWeb)
        var appWebName = "";
        if (moduleName.indexOf(".") != -1) {
            var parts = moduleName.split(".");
            if (parts.length > 0) {
                appWebName = parts[0]; // Get the first part (e.g., TodoAppWeb)
            }
        }
        
        if (appWebName == "") return ast; // Can't determine app name
        
        var coreComponentsModule = appWebName + ".CoreComponents";
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EDefmodule(name, doBlock):
                    #if debug_liveview_components
                    trace('[XRay LiveViewComponents] Processing defmodule: $name');
                    #end
                    
                    // For defmodule, we need to inject the import into the do block
                    switch(doBlock.def) {
                        case EBlock(statements):
                            // Check if CoreComponents is already imported
                            var hasImport = false;
                            for (stmt in statements) {
                                switch(stmt.def) {
                                    case EImport(module, _, _):
                                        if (module == coreComponentsModule) {
                                            hasImport = true;
                                            break;
                                        }
                                    default:
                                }
                            }
                            
                            if (!hasImport) {
                                #if debug_liveview_components
                                trace('[XRay LiveViewComponents] Adding CoreComponents import: $coreComponentsModule');
                                #end
                                
                                // Create the import statement with specific functions to avoid conflicts
                                // Import CoreComponents but exclude label to avoid conflict with Phoenix.HTML.Form.label/1
                                // The dot-notation <.label> will still work via Phoenix.Component's component system
                                var exceptOptions: Array<EImportOption> = [{name: "label", arity: 1}];
                                var importStmt = makeAST(EImport(coreComponentsModule, null, exceptOptions));
                                
                                // Add import after use statements but before function definitions
                                var newStatements = [];
                                var importAdded = false;
                                
                                for (stmt in statements) {
                                    newStatements.push(stmt);
                                    // Add import after use statements
                                    if (!importAdded) {
                                        switch(stmt.def) {
                                            case EUse(_, _):
                                                newStatements.push(importStmt);
                                                importAdded = true;
                                            default:
                                        }
                                    }
                                }
                                
                                // If no use statements, add at the beginning
                                if (!importAdded) {
                                    newStatements = [importStmt].concat(statements);
                                }
                                
                                var newDoBlock = makeASTWithMeta(EBlock(newStatements), doBlock.metadata, doBlock.pos);
                                return makeASTWithMeta(EDefmodule(name, newDoBlock), node.metadata, node.pos);
                            }
                            
                            return node;
                            
                        default:
                            // Single expression body, unlikely for LiveView
                            return node;
                    }
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * String method transformation pass
     * 
     * WHY: Strings in Elixir don't have methods - they use the String module
     * WHAT: Transforms method calls on strings to String module calls
     * HOW: Detects ECall with string targets and converts to ERemoteCall
     * 
     * Examples:
     * - hex_chars.charAt(0) → String.at(hex_chars, 0)
     * - str.toLowerCase() → String.downcase(str)
     * - str.toUpperCase() → String.upcase(str)
     */
    static function stringMethodTransformPass(ast: ElixirAST): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                // Handle method calls that look like string.method(args)
                case ECall(target, methodName, args) if (target != null):
                    // Check if this looks like a string method call
                    var stringMethod = switch(methodName) {
                        case "charAt": "at";
                        case "charCodeAt": "to_charlist"; 
                        case "toLowerCase": "downcase";
                        case "toUpperCase": "upcase";
                        case "indexOf": "index";
                        case "substring" | "substr": "slice";
                        case "split": "split";
                        case _: null;
                    };
                    
                    if (stringMethod != null) {
                        // Transform to String module call
                        #if debug_string_methods
                        trace('[StringMethodTransform] Converting ${methodName} to String.${stringMethod}');
                        if (target != null) {
                            trace('[StringMethodTransform] Target exists');
                        }
                        trace('[StringMethodTransform] Args count: ${args.length}');
                        #end
                        
                        // Special handling for charCodeAt - needs different function
                        if (methodName == "charCodeAt") {
                            // s.charCodeAt(pos) -> :binary.at(s, pos)
                            makeASTWithMeta(
                                ERemoteCall(
                                    makeAST(EAtom(ElixirAtom.raw("binary"))),
                                    "at",
                                    [target].concat(args)
                                ),
                                node.metadata,
                                node.pos
                            );
                        } else {
                            // Prepend the target as the first argument
                            var newArgs = [target].concat(args);
                            makeASTWithMeta(
                                ERemoteCall(
                                    makeAST(EVar("String")),
                                    stringMethod,
                                    newArgs
                                ),
                                node.metadata,
                                node.pos
                            );
                        }
                    } else {
                        node;
                    }
                    
                default:
                    node;
            };
        });
    }
    
    /**
     * Constant folding pass - evaluate constant expressions at compile time
     */
    static function constantFoldingPass(ast: ElixirAST): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                // Fold binary operations on constants
                case EBinary(op, left, right):
                    switch([left.def, right.def]) {
                        case [EInteger(l), EInteger(r)]:
                            var result = switch(op) {
                                case Add: l + r;
                                case Subtract: l - r;
                                case Multiply: l * r;
                                case Divide: Math.floor(l / r);
                                case Remainder: l % r;
                                case Less: l < r ? 1 : 0;
                                case Greater: l > r ? 1 : 0;
                                case LessEqual: l <= r ? 1 : 0;
                                case GreaterEqual: l >= r ? 1 : 0;
                                case Equal: l == r ? 1 : 0;
                                case NotEqual: l != r ? 1 : 0;
                                default: null;
                            };
                            
                            if (result != null) {
                                // For boolean results, convert to EBoolean
                                if (op == Less || op == Greater || op == LessEqual || 
                                    op == GreaterEqual || op == Equal || op == NotEqual) {
                                    makeASTWithMeta(EBoolean(result == 1), node.metadata, node.pos);
                                } else {
                                    makeASTWithMeta(EInteger(result), node.metadata, node.pos);
                                }
                            } else {
                                node; // Can't fold, return unchanged
                            }
                            
                        case [EString(l), EString(r)] if (op == StringConcat):
                            makeASTWithMeta(EString(l + r), node.metadata, node.pos);
                            
                        case [EList(l), EList(r)] if (op == Concat):
                            makeASTWithMeta(EList(l.concat(r)), node.metadata, node.pos);
                            
                        default:
                            node; // Not constant, return unchanged
                    }
                    
                // Fold unary operations on constants
                case EUnary(op, expr):
                    switch(expr.def) {
                        case EInteger(i) if (op == Negate):
                            makeASTWithMeta(EInteger(-i), node.metadata, node.pos);
                        case EBoolean(b) if (op == Not):
                            makeASTWithMeta(EBoolean(!b), node.metadata, node.pos);
                        default:
                            node;
                    }
                    
                default:
                    node; // Not a foldable expression
            }
        });
    }
    
    /**
     * Pipeline optimization pass - convert sequential operations to pipeline
     */
    static function pipelineOptimizationPass(ast: ElixirAST): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EBlock(expressions):
                    // Look for pipeline patterns in blocks
                    var optimized = detectAndOptimizePipeline(expressions);
                    if (optimized != null) {
                        optimized;
                    } else {
                        node;
                    }
                    
                default:
                    node;
            }
        });
    }
    
    /**
     * Comprehension conversion pass - convert loops to comprehensions
     * This pass needs to handle module-level transformation to add generated functions
     */
    static function comprehensionConversionPass(ast: ElixirAST): ElixirAST {
        // Collection for generated loop functions
        var generatedFunctions: Array<ElixirAST> = [];
        var loopCounter = 0;
        
        // First pass: transform loops and collect generated functions
        function transformLoops(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                // Convert for loops that build lists
                case EFor(generators, filters, body, into, uniq):
                    // Already a comprehension, keep as-is
                    node;
                    
                // Convert while loops to recursive functions
                case ECall(null, "while_loop", [condition, body]):
                    // Generate unique function name
                    var funcName = "loop_" + (loopCounter++);
                    
                    // Transform condition and body recursively
                    var transformedCondition = transformNode(condition, transformLoops);
                    var transformedBody = transformNode(body, transformLoops);
                    
                    // Create recursive function definition
                    var recursiveFunc = makeAST(
                        EDefp(funcName, [], null, 
                            makeAST(EIf(
                                transformedCondition,
                                makeAST(EBlock([
                                    transformedBody,
                                    makeAST(ECall(null, funcName, []))
                                ])),
                                makeAST(EAtom(ElixirAtom.ok()))
                            ))
                        )
                    );
                    
                    // Add to generated functions collection
                    generatedFunctions.push(recursiveFunc);
                    
                    // Replace with function call
                    makeAST(ECall(null, funcName, []));
                    
                default:
                    // Return node unchanged - base case to prevent infinite recursion
                    node;
            }
        }
        
        // Apply transformation
        var transformed = transformLoops(ast);
        
        // If we're at module level and have generated functions, insert them
        if (generatedFunctions.length > 0) {
            switch(transformed.def) {
                case EModule(name, attributes, body):
                    // Insert generated functions at the end of the module body
                    var newBody = body.concat(generatedFunctions);
                    return makeAST(EModule(name, attributes, newBody));
                default:
                    // For non-module nodes, we need to wrap or handle differently
                    // This shouldn't happen in normal compilation
                    return transformed;
            }
        }
        
        return transformed;
    }
    
    /**
     * Abstract Method This Reference Fix Pass
     * 
     * WHY: In abstract methods like toDynamic(), Haxe generates parameters like "this_1"
     * but the AST builder incorrectly uses "struct" for TConst(TThis), causing reference mismatches.
     * 
     * WHAT: Fixes "struct" references in anonymous functions to match the actual parameter name.
     * - Detects anonymous functions with parameters like "this", "this_1", etc.
     * - Replaces "struct" references in the body with the actual parameter name
     * 
     * HOW: Tracks the first parameter of anonymous functions and ensures body references match
     */
    static function abstractMethodThisPass(ast: ElixirAST): ElixirAST {
        #if debug_abstract_this
        trace('[XRay AbstractThis] Starting pass');
        #end
        
        // Add debug to see what nodes we're actually getting
        #if debug_abstract_this
        function debugNode(node: ElixirAST, depth: Int = 0) {
            var indent = [for (i in 0...depth) "  "].join("");
            switch(node.def) {
                case EModule(name, _, body):
                    trace('$indent[XRay AbstractThis] Module: $name with ${body.length} definitions');
                    for (def in body) debugNode(def, depth + 1);
                case EDef(name, _, _, body):
                    trace('$indent[XRay AbstractThis] Def: $name');
                    debugNode(body, depth + 1);
                case EFn(clauses):
                    trace('$indent[XRay AbstractThis] !! Found EFn with ${clauses.length} clauses !!');
                default:
                    // Don't trace every node type, just the ones we care about
            }
        }
        debugNode(ast, 0);
        #end
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EFn(clauses):
                    #if debug_abstract_this
                    trace('[XRay AbstractThis] Processing EFn with ${clauses.length} clauses');
                    #end
                    // Check if this is an abstract method with "this" parameter
                    var fixedClauses = [];
                    var hasChanges = false;
                    
                    for (clause in clauses) {
                        if (clause.args.length > 0) {
                            switch(clause.args[0]) {
                                case PVar(paramName) if (paramName.indexOf("this") == 0 || paramName == "_struct" || paramName == "struct"):
                                    #if debug_abstract_this
                                    trace('[XRay AbstractThis] Found function with this/struct parameter: $paramName');
                                    trace('[XRay AbstractThis] Body before fix: ${ElixirASTPrinter.print(clause.body, 0)}');
                                    #end
                                    
                                    // Found a "this", "this_1", "struct", or "_struct" parameter
                                    // Replace "struct" or "this" with the actual parameter name in body
                                    var fixedBody = replaceStructWithParam(clause.body, paramName);
                                    
                                    #if debug_abstract_this
                                    trace('[XRay AbstractThis] Body after fix: ${ElixirASTPrinter.print(fixedBody, 0)}');
                                    #end
                                    
                                    hasChanges = true;
                                    fixedClauses.push({
                                        args: clause.args,
                                        guard: clause.guard,
                                        body: fixedBody
                                    });
                                default:
                                    fixedClauses.push(clause);
                            }
                        } else {
                            fixedClauses.push(clause);
                        }
                    }
                    
                    if (hasChanges) {
                        #if debug_abstract_this
                        trace('[XRay AbstractThis] Applied fix to function');
                        #end
                        return makeASTWithMeta(EFn(fixedClauses), node.metadata, node.pos);
                    }
                    return node;
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * Helper: Replace "struct" or "this" variables with the actual parameter name
     * 
     * PROBLEM: In abstract methods, the AST builder sometimes generates incorrect variable
     * references. The parameter might be named "this_1" but the body references "this" or
     * "struct", causing compilation errors like "undefined variable this".
     * 
     * EXAMPLES:
     * - Input:  fn this_1 -> this end       // Wrong: "this" doesn't exist
     * - Output: fn this_1 -> this_1 end     // Fixed: matches parameter name
     * 
     * - Input:  fn this -> struct end       // Wrong: "struct" is internal compiler name
     * - Output: fn this -> this end         // Fixed: uses actual parameter
     * 
     * - Input:  fn this_2 -> struct.field end    // Wrong: struct not in scope
     * - Output: fn this_2 -> this_2.field end    // Fixed: correct reference
     * 
     * @param ast The AST to transform
     * @param paramName The actual parameter name to use (e.g., "this", "this_1", "this_2")
     * @return AST with all "struct" and "this" references replaced with paramName
     */
    static function replaceStructWithParam(ast: ElixirAST, paramName: String): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EVar("struct") | EVar("this"):
                    // Replace "struct" or "this" with the actual parameter name
                    return makeASTWithMeta(EVar(paramName), node.metadata, node.pos);
                default:
                    return node;
            }
        });
    }
    
    /**
     * Bitwise Import Pass
     * 
     * WHY: Elixir requires "import Bitwise" to use bitwise operators like &&&, |||, ^^^
     * but the generated code doesn't include this import automatically.
     * 
     * WHAT: Detects usage of bitwise operators and adds "import Bitwise" to the module.
     * - Scans the entire AST for bitwise operators
     * - Adds the import statement if any are found
     * 
     * HOW: Two-phase approach:
     * 1. Detection: Walk the AST to find bitwise operators
     * 2. Injection: Add import to module (handles both EModule and EDefmodule formats)
     * 
     * IMPORTANT AST STRUCTURE: Modules can be represented in two ways:
     * 
     * EDefmodule(name, doBlock): Standard Elixir "defmodule Name do ... end" format
     *   This is the most common format. The import must be added as the first 
     *   statement in the do block.
     *   
     *   Original Haxe code:
     *     class StringTools {
     *         public static function ltrim(s: String): String {
     *             // Uses bitwise operators &&&
     *         }
     *     }
     *   
     *   Example AST:
     *     EDefmodule("StringTools", 
     *       EBlock([
     *         EImport("Bitwise", null, null),  // <-- Insert here
     *         EFunction(...),
     *         EFunction(...)
     *       ])
     *     )
     * 
     * EModule(name, attributes, body): Alternative format with attributes array
     *   Less common format. The import is added to the attributes array.
     *   
     *   This format may be used internally by the compiler for certain constructs
     *   or intermediate representations. Most user-defined Haxe classes generate
     *   EDefmodule, not EModule. The exact conditions that produce EModule vs
     *   EDefmodule depend on the AST builder's internal logic.
     *   
     *   Example AST:
     *     EModule("StringTools",
     *       [
     *         EImport("Bitwise", null, null),  // <-- Insert here
     *         EAttribute(...)
     *       ],
     *       [EFunction(...), EFunction(...)]
     *     )
     * 
     * The original pass only handled EModule, which is why it wasn't working for
     * most generated code that uses EDefmodule format.
     */
    static function bitwiseImportPass(ast: ElixirAST): ElixirAST {
        // Phase 1: Detect if bitwise operators are used
        var needsBitwise = false;
        
        #if debug_bitwise_import
        trace('[XRay BitwiseImport] Starting scan for bitwise operators');
        #end
        
        // Recursive function to deeply traverse the AST
        function checkForBitwise(node: ElixirAST): Void {
            #if debug_bitwise_import
            var nodeType = Type.enumConstructor(node.def);
            if (nodeType == "EBinary") {
                trace('[XRay BitwiseImport] Checking EBinary node');
            }
            #end
            
            switch(node.def) {
                case EBinary(op, left, right):
                    #if debug_bitwise_import
                    trace('[XRay BitwiseImport] Binary operator: $op');
                    #end
                    switch(op) {
                        case BitwiseAnd | BitwiseOr | BitwiseXor | ShiftLeft | ShiftRight:
                            #if debug_bitwise_import
                            trace('[XRay BitwiseImport] Found bitwise operator: $op');
                            #end
                            needsBitwise = true;
                        default:
                    }
                    // Recursively check child nodes
                    checkForBitwise(left);
                    checkForBitwise(right);
                case EUnary(BitwiseNot, expr):
                    #if debug_bitwise_import
                    trace('[XRay BitwiseImport] Found BitwiseNot operator');
                    #end
                    needsBitwise = true;
                    checkForBitwise(expr);
                default:
                    // For all other node types, recursively visit children
                    iterateAST(node, checkForBitwise);
            }
        }
        
        checkForBitwise(ast);
        
        #if debug_bitwise_import
        trace('[XRay BitwiseImport] Needs bitwise: $needsBitwise');
        #end
        
        // Phase 2: Add import if needed
        if (!needsBitwise) return ast;
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EDefmodule(name, doBlock):
                    #if debug_bitwise_import
                    trace('[XRay BitwiseImport] Processing defmodule: $name');
                    #end
                    
                    // For defmodule, we need to inject the import into the do block
                    switch(doBlock.def) {
                        case EBlock(statements):
                            #if debug_bitwise_import
                            trace('[XRay BitwiseImport] Defmodule has ${statements.length} statements');
                            #end
                            
                            // Check if Bitwise is already imported
                            var hasImport = false;
                            for (stmt in statements) {
                                switch(stmt.def) {
                                    case EImport(module, _, _):  // Match all three parameters
                                        if (module == "Bitwise") {
                                            hasImport = true;
                                            break;
                                        }
                                    default:
                                }
                            }
                            
                            if (!hasImport) {
                                // Add import Bitwise at the beginning
                                var newStatements = statements.copy();
                                newStatements.insert(0, makeAST(EImport("Bitwise", null, null)));  // Provide all three parameters
                                
                                #if debug_bitwise_import
                                trace('[XRay BitwiseImport] Added import Bitwise to defmodule');
                                #end
                                
                                return makeASTWithMeta(
                                    EDefmodule(name, makeAST(EBlock(newStatements))),
                                    node.metadata,
                                    node.pos
                                );
                            }
                        default:
                    }
                    return node;
                    
                case EModule(name, attributes, body):
                    #if debug_bitwise_import
                    trace('[XRay BitwiseImport] Processing module: $name');
                    trace('[XRay BitwiseImport] Current attributes count: ${attributes.length}');
                    #end
                    
                    // Check if Bitwise is already imported (by checking attribute names)
                    var hasImport = false;
                    for (attr in attributes) {
                        if (attr.name == "import" && attr.value != null) {
                            // Check if it's importing Bitwise
                            switch(attr.value.def) {
                                case EAtom(atomVal) if (atomVal == "Bitwise"):
                                    hasImport = true;
                                case EVar("Bitwise"):
                                    hasImport = true;
                                default:
                            }
                        }
                    }
                    
                    #if debug_bitwise_import
                    trace('[XRay BitwiseImport] Has existing import: $hasImport');
                    #end
                    
                    if (!hasImport) {
                        // Add import Bitwise at the beginning of attributes
                        var newAttributes = attributes.copy();
                        newAttributes.insert(0, {
                            name: "import",
                            value: makeAST(EAtom(ElixirAtom.raw("Bitwise")))
                        });
                        
                        #if debug_bitwise_import
                        trace('[XRay BitwiseImport] Added import Bitwise to module');
                        #end
                        
                        return makeASTWithMeta(
                            EModule(name, newAttributes, body),
                            node.metadata,
                            node.pos
                        );
                    }
                    return node;
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * List Effect Lifting Pass
     * 
     * WHY: Elixir doesn't allow assignments or side-effecting expressions inside list literals.
     * The malformed pattern `g = g ++ [g = [] ...]` creates illegal syntax.
     * 
     * WHAT: Detects and lifts side-effecting expressions out of list literals.
     * - Identifies assignments and other side effects within EList elements
     * - Extracts them to statements before the list construction
     * - Replaces them with pure variable references
     * 
     * HOW: Transforms EList nodes by:
     * 1. Scanning elements for side effects (assignments, blocks)
     * 2. Extracting effects to temporary variables
     * 3. Building the list with pure expressions only
     * 
     * Example:
     * Input:  [g = [], g = g ++ [1], g]
     * Output: g = []; g = g ++ [1]; [g]
     */
    static function listEffectLiftingPass(ast: ElixirAST): ElixirAST {
        #if debug_effect_lifting
        trace('[XRay ListEffectLifting] Starting pass');
        #end
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EList(elements):
                    #if debug_effect_lifting
                    trace('[XRay ListEffectLifting] Processing list with ${elements.length} elements');
                    #end
                    
                    // Check if any element has side effects
                    var hasEffects = false;
                    var liftedStatements: Array<ElixirAST> = [];
                    var pureElements: Array<ElixirAST> = [];
                    
                    for (i in 0...elements.length) {
                        var elem = elements[i];
                        #if debug_effect_lifting
                        trace('[XRay ListEffectLifting] Checking element $i: ${ElixirASTPrinter.print(elem, 0).substring(0, 50)}');
                        #end
                        
                        switch(elem.def) {
                            case EMatch(left, right):
                                // Assignment inside list - needs lifting
                                #if debug_effect_lifting
                                trace('[XRay ListEffectLifting] Found assignment in element $i');
                                #end
                                hasEffects = true;
                                liftedStatements.push(elem);
                                // Replace with just the variable reference
                                switch(left) {
                                    case PVar(name):
                                        pureElements.push(makeAST(EVar(name)));
                                    default:
                                        // For other patterns, convert to a simple variable
                                        pureElements.push(makeAST(EVar("_lifted_var")));
                                }
                                
                            case EBlock(exprs) if (exprs.length > 0):
                                // Block inside list - extract statements, keep last expression
                                #if debug_effect_lifting
                                trace('[XRay ListEffectLifting] Found block in element $i with ${exprs.length} expressions');
                                #end
                                hasEffects = true;
                                for (j in 0...exprs.length - 1) {
                                    liftedStatements.push(exprs[j]);
                                }
                                pureElements.push(exprs[exprs.length - 1]);
                                
                            case EBinary(Concat, left, right):
                                // Check if this is a nested problematic pattern
                                switch(right.def) {
                                    case EList(innerElements) if (innerElements.length > 0):
                                        // Check if inner list has assignments
                                        var innerHasEffects = false;
                                        for (innerElem in innerElements) {
                                            switch(innerElem.def) {
                                                case EMatch(_, _) | EBlock(_):
                                                    innerHasEffects = true;
                                                    break;
                                                default:
                                            }
                                        }
                                        if (innerHasEffects) {
                                            #if debug_effect_lifting
                                            trace('[XRay ListEffectLifting] Found nested list with effects');
                                            #end
                                            // Process the inner list recursively
                                            var processedInner = listEffectLiftingPass(makeAST(right.def));
                                            switch(processedInner.def) {
                                                case EBlock(stmts) if (stmts.length > 0):
                                                    hasEffects = true;
                                                    // Add all but last statement to lifted
                                                    for (k in 0...stmts.length - 1) {
                                                        liftedStatements.push(stmts[k]);
                                                    }
                                                    // Keep the concatenation with cleaned list
                                                    pureElements.push(makeAST(EBinary(Concat, left, stmts[stmts.length - 1])));
                                                default:
                                                    pureElements.push(elem);
                                            }
                                        } else {
                                            pureElements.push(elem);
                                        }
                                    default:
                                        pureElements.push(elem);
                                }
                                
                            default:
                                // Pure expression, keep as-is
                                pureElements.push(elem);
                        }
                    }
                    
                    if (hasEffects) {
                        #if debug_effect_lifting
                        trace('[XRay ListEffectLifting] Lifting ${liftedStatements.length} statements');
                        #end
                        
                        // Return a block with lifted statements followed by pure list
                        var allStatements = liftedStatements.copy();
                        allStatements.push(makeAST(EList(pureElements)));
                        return makeAST(EBlock(allStatements));
                    }
                    
                    return node;
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * Struct field assignment transformation pass
     * 
     * WHY: Haxe's mutable field assignments (this.field = value) need to be transformed
     *      to Elixir's immutable struct update syntax (%{struct | field: value})
     * 
     * WHAT: Detects patterns like EMatch(EField(struct_var, field), value) where struct_var
     *       is a struct parameter (like "struct" or "self"), and transforms them to return
     *       a new struct with the updated field
     * 
     * HOW: - Identifies field assignments on struct parameters
     *      - Converts them to struct update syntax
     *      - Returns the updated struct for proper threading
     * 
     * Example: struct.count = 5 → %{struct | count: 5}
     */
    static function structFieldAssignmentTransformPass(ast: ElixirAST): ElixirAST {
        // Need to track the original struct variable for field assignments
        var structVarTracking: Map<String, String> = new Map();
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EBlock(expressions):
                    // Process block expressions looking for field assignment patterns
                    var transformed = [];
                    var i = 0;
                    
                    while (i < expressions.length) {
                        var expr = expressions[i];
                        
                        // Look for pattern: spec = worker(...) followed by fieldName = value
                        switch(expr.def) {
                            case EMatch(PVar(varName), rhs):
                                // Track struct variable assignments from known constructors
                                switch(rhs.def) {
                                    case ECall(_, funcName, _) if (funcName == "worker" || funcName == "supervisor" || funcName == "temp_worker"):
                                        structVarTracking.set(varName, varName);
                                    case ERemoteCall(_, funcName, _) if (funcName == "worker" || funcName == "supervisor" || funcName == "temp_worker"):
                                        structVarTracking.set(varName, varName);
                                    default:
                                }
                                
                                // Check if this is a field assignment pattern
                                // Look ahead for the next expression to see if it's a field assignment
                                if (i + 1 < expressions.length) {
                                    var nextExpr = expressions[i + 1];
                                    switch(nextExpr.def) {
                                        case EMatch(PVar(fieldName), fieldValue):
                                            // Check if previous expression was a struct assignment we're tracking
                                            // and the field name matches common struct field patterns
                                            if (structVarTracking.exists(varName) && 
                                                (fieldName == "restart" || fieldName == "shutdown" || fieldName == "type" || 
                                                 fieldName == "strategy" || fieldName == "max_restarts" || fieldName == "max_seconds")) {
                                                // This looks like a struct field assignment pattern
                                                // Transform: fieldName = value → spec = Map.put(spec, :fieldName, value)
                                                #if debug_ast_transformer
                                                trace('[XRay StructFieldAssignment] Found field assignment pattern: $fieldName = ...');
                                                trace('[XRay StructFieldAssignment] Transforming to Map.put($varName, :$fieldName, ...)');
                                                #end
                                                
                                                // Add the original struct assignment
                                                transformed.push(expr);
                                                
                                                // Transform the field assignment to Map.put
                                                var mapPut = makeAST(EMatch(
                                                    PVar(varName),
                                                    makeAST(ERemoteCall(
                                                        makeAST(EVar("Map")),
                                                        "put",
                                                        [
                                                            makeAST(EVar(varName)),
                                                            makeAST(EAtom(fieldName)),
                                                            fieldValue
                                                        ]
                                                    ))
                                                ));
                                                transformed.push(mapPut);
                                                
                                                // Skip the original field assignment
                                                i += 2;
                                                continue;
                                            }
                                        default:
                                    }
                                }
                                
                                // Not a field assignment pattern, keep as-is
                                transformed.push(expr);
                            default:
                                transformed.push(expr);
                        }
                        i++;
                    }
                    
                    // Return transformed block if we made changes
                    if (transformed.length > 0) {
                        return makeASTWithMeta(EBlock(transformed), node.metadata, node.pos);
                    }
                    return node;
                    
                default:
                    // Not a block, continue traversal
                    return node;
            }
        });
    }
    
    /**
     * Statement context transformation pass - add reassignments for immutable operations
     * 
     * WHY: Elixir is immutable, so operations like Map.put() return new values
     * WHAT: Detects when these operations are used as statements (value discarded)
     * HOW: Wraps them in reassignment to the original variable
     * 
     * Example transformation:
     * Map.put(params, "key", value) → params = Map.put(params, "key", value)
     */
    static function statementContextTransformPass(ast: ElixirAST): ElixirAST {
        // Transform with context tracking
        function transformWithContext(node: ElixirAST, isStatementContext: Bool): ElixirAST {
            #if debug_ast_transformer
            trace('[XRay StatementContext] Processing node: ${node.def}, context: ${isStatementContext ? "statement" : "expression"}');
            #end
            
            // First, recursively transform children with appropriate context
            var transformed = switch(node.def) {
                case EDefmodule(name, doBlock):
                    // Process the module's do block in statement context
                    #if debug_ast_transformer
                    trace('[XRay StatementContext] Processing EDefmodule: $name');
                    #end
                    makeASTWithMeta(
                        EDefmodule(name, transformWithContext(doBlock, true)),
                        node.metadata, node.pos
                    );
                    
                case EBlock(expressions):
                    // In a block, all but the last expression are in statement context
                    #if debug_ast_transformer
                    trace('[XRay StatementContext] Processing EBlock with ${expressions.length} expressions');
                    #end
                    var newExpressions = [];
                    for (i in 0...expressions.length) {
                        var isLast = (i == expressions.length - 1);
                        var childContext = isLast ? isStatementContext : true;
                        #if debug_ast_transformer
                        if (expressions[i] != null && expressions[i].def != null) {
                            var exprType = Type.enumConstructor(expressions[i].def);
                            trace('[XRay StatementContext] Block expr $i/${expressions.length}: $exprType, context: ${childContext ? "statement" : "expression"}');
                        }
                        #end
                        newExpressions.push(transformWithContext(expressions[i], childContext));
                    }
                    makeASTWithMeta(EBlock(newExpressions), node.metadata, node.pos);
                    
                case EDef(name, args, guards, body):
                    // Function body is a block - let it handle its own statement/expression context
                    // The block will mark all but the last expression as statement context
                    #if debug_ast_transformer
                    trace('[XRay StatementContext] Processing EDef: $name, body type: ${body.def}');
                    #end
                    makeASTWithMeta(
                        EDef(name, args, guards, transformWithContext(body, false)),
                        node.metadata, node.pos
                    );
                    
                case EDefp(name, args, guards, body):
                    // Function body is a block - let it handle its own statement/expression context  
                    // The block will mark all but the last expression as statement context
                    #if debug_ast_transformer
                    trace('[XRay StatementContext] Processing EDefp: $name, body type: ${body.def}');
                    #end
                    makeASTWithMeta(
                        EDefp(name, args, guards, transformWithContext(body, false)),
                        node.metadata, node.pos
                    );
                    
                case EIf(condition, thenBranch, elseBranch):
                    // Both branches inherit parent context
                    makeASTWithMeta(
                        EIf(transformWithContext(condition, false),
                            transformWithContext(thenBranch, isStatementContext),
                            elseBranch != null ? transformWithContext(elseBranch, isStatementContext) : null),
                        node.metadata, node.pos
                    );
                    
                case ECase(expr, clauses):
                    // All clauses inherit parent context
                    makeASTWithMeta(
                        ECase(transformWithContext(expr, false),
                              clauses.map(c -> {
                                  pattern: c.pattern,
                                  guard: c.guard != null ? transformWithContext(c.guard, false) : null,
                                  body: transformWithContext(c.body, isStatementContext)
                              })),
                        node.metadata, node.pos
                    );
                    
                // For other nodes, recursively transform children based on node type
                default:
                    // Manually handle child transformation for other node types
                    switch(node.def) {
                        case EModule(name, attributes, body):
                            makeASTWithMeta(
                                EModule(name, attributes, body.map(e -> transformWithContext(e, true))),
                                node.metadata, node.pos
                            );
                            
                        case ECall(target, funcName, args):
                            makeASTWithMeta(
                                ECall(target != null ? transformWithContext(target, false) : null,
                                      funcName,
                                      args.map(a -> transformWithContext(a, false))),
                                node.metadata, node.pos
                            );
                            
                        case ERemoteCall(module, funcName, args):
                            makeASTWithMeta(
                                ERemoteCall(transformWithContext(module, false),
                                           funcName,
                                           args.map(a -> transformWithContext(a, false))),
                                node.metadata, node.pos
                            );
                            
                        case EBinary(op, left, right):
                            makeASTWithMeta(
                                EBinary(op,
                                       transformWithContext(left, false),
                                       transformWithContext(right, false)),
                                node.metadata, node.pos
                            );
                            
                        case EMatch(pattern, expr):
                            makeASTWithMeta(
                                EMatch(pattern, transformWithContext(expr, false)),
                                node.metadata, node.pos
                            );
                            
                        // For literals and simple nodes, return unchanged
                        default:
                            node;
                    }
            };
            
            // Now check if this node needs reassignment wrapping
            if (isStatementContext) {
                switch(transformed.def) {
                    case ERemoteCall(module, funcName, args):
                        #if debug_ast_transformer
                        trace('[XRay StatementContext] Checking ERemoteCall: module=${module.def}, func=$funcName, args=${args.length}');
                        #end
                        // Check for immutable operations that need reassignment in statement context
                        var moduleName: Null<String> = switch(module.def) {
                            case EAtom(atom): atom; // ElixirAtom implicitly converts to String
                            case EVar(name): name;  // name is already String
                            default: null;
                        };
                        
                        if (moduleName != null) {
                            #if debug_ast_transformer
                            trace('[XRay StatementContext] Found module $moduleName, checking function: $funcName');
                            #end
                            
                            // Define immutable operations for each Elixir module
                            // TODO: Future improvement - Move this metadata to Haxe source files
                            // Instead of hardcoding here, each module (Map.hx, List.hx, etc.) could
                            // use metadata annotations like @:immutable or @:reassignsVar on methods
                            // that return new instances. This would make the system more maintainable
                            // and allow custom types to opt into this behavior.
                            // Example: @:immutable function put(key: K, value: V): Map<K,V> { ... }
                            var needsReassignment = switch(moduleName) {
                                case "Map":
                                    ["put", "delete", "merge", "update", "drop", "put_new", "put_new_lazy", "replace"].indexOf(funcName) >= 0;
                                case "List":
                                    ["delete", "delete_at", "insert_at", "replace_at", "update_at", "pop_at", "flatten", "wrap"].indexOf(funcName) >= 0;
                                case "MapSet":
                                    ["put", "delete", "union", "intersection", "difference"].indexOf(funcName) >= 0;
                                case "Keyword":
                                    ["put", "delete", "merge", "update", "drop", "put_new", "put_new_lazy", "replace"].indexOf(funcName) >= 0;
                                case "String":
                                    ["replace", "trim", "upcase", "downcase", "capitalize", "reverse", "slice"].indexOf(funcName) >= 0;
                                default:
                                    false;
                            };
                            
                            if (needsReassignment && args.length >= 1) {
                                // First arg should be the variable being modified
                                switch(args[0].def) {
                                    case EVar(varName):
                                        #if debug_ast_transformer
                                        trace('[XRay StatementContext] Wrapping $moduleName.$funcName with reassignment to: $varName');
                                        #end
                                        // Transform to: varName = Module.operation(varName, ...)
                                        return makeASTWithMeta(
                                            EMatch(PVar(varName), transformed),
                                            node.metadata, node.pos
                                        );
                                    default:
                                        // Not a simple variable, can't reassign
                                }
                            }
                        }
                        
                    case EBinary(Concat, left, right):
                        // Check for list concatenation in statement context
                        switch(left.def) {
                            case EVar(varName):
                                #if debug_ast_transformer
                                trace('[XRay StatementContext] Wrapping ++ with reassignment to: $varName');
                                #end
                                // Transform to: varName = varName ++ right
                                return makeASTWithMeta(
                                    EMatch(PVar(varName), transformed),
                                    node.metadata, node.pos
                                );
                            default:
                        }
                        
                    default:
                }
            }
            
            return transformed;
        }
        
        // Start transformation with top-level as statement context
        return transformWithContext(ast, true);
    }
    
    /**
     * Immutability transformation pass - convert mutable patterns to immutable
     * 
     * ENHANCED: Now handles struct field mutations in BalancedTree and similar patterns
     */
    static function immutabilityTransformPass(ast: ElixirAST): ElixirAST {
        // First pass: Transform method bodies that mutate struct fields
        ast = transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EDef(name, args, guards, body) if ((name == "set" || name == "remove") && 
                                                        args.length > 0 && 
                                                        switch(args[0]) { case PVar("struct"): true; default: false; }):
                    // This is a struct method that might mutate fields
                    #if debug_ast_transformer
                    trace('[XRay ImmutabilityTransform] Found method $name with struct parameter');
                    #end
                    var updatedBody = transformStructFieldAssignments(body, args);
                    if (updatedBody != body) {
                        #if debug_ast_transformer
                        trace('[XRay ImmutabilityTransform] Transformed body for method $name');
                        #end
                        makeASTWithMeta(
                            EDef(name, args, guards, updatedBody),
                            node.metadata,
                            node.pos
                        );
                    } else {
                        #if debug_ast_transformer
                        trace('[XRay ImmutabilityTransform] No transformation needed for method $name');
                        #end
                        node;
                    }
                default:
                    node;
            }
        });
        
        // Second pass: Other immutability transformations
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                // Transform increment/decrement to reassignment
                case ECall(null, "pre_inc", [expr]):
                    // x++ becomes x = x + 1
                    switch(expr.def) {
                        case EVar(name):
                            makeAST(EMatch(
                                PVar(name),
                                makeAST(EBinary(Add, expr, makeAST(EInteger(1))))
                            ));
                        default:
                            node;
                    }
                    
                case ECall(null, "pre_dec", [expr]):
                    // x-- becomes x = x - 1
                    switch(expr.def) {
                        case EVar(name):
                            makeAST(EMatch(
                                PVar(name),
                                makeAST(EBinary(Subtract, expr, makeAST(EInteger(1))))
                            ));
                        default:
                            node;
                    }
                    
                // Transform modulo operator to rem function call
                case EBinary(Remainder, left, right):
                    // x % 2 becomes rem(x, 2) - rem is a function in Elixir, not an operator
                    makeAST(ECall(
                        null,
                        "rem",
                        [left, right]
                    ));
                    
                // Transform array mutation patterns
                case ECall(target, "push", [item]):
                    // Check if this is a push on a field (either direct or via struct)
                    switch(target.def) {
                        case EField(structVar, fieldName):
                            // This is struct.field.push(item) - qualified field access
                            // Check if structVar is "struct" (the conventional instance parameter)
                            switch(structVar.def) {
                                case EVar("struct"):
                                    // Transform to struct update: %{struct | field: struct.field ++ [item]}
                                    #if debug_ast_transformer
                                    trace('[XRay ImmutabilityTransform] Transforming struct.$fieldName.push(item) to struct update');
                                    #end
                                    makeAST(EStructUpdate(
                                        structVar,
                                        [{
                                            key: fieldName,
                                            value: makeAST(EBinary(
                                                Concat,
                                                target,  // struct.field
                                                makeAST(EList([item]))
                                            ))
                                        }]
                                    ));
                                default:
                                    node;
                            }
                        case EVar(fieldName):
                            // This is field.push(item) - direct field access
                            // This happens in instance methods where fields are accessed directly
                            // We need to transform this to a struct update
                            #if debug_ast_transformer
                            trace('[XRay ImmutabilityTransform] Transforming $fieldName.push(item) to struct update');
                            #end
                            // Create the struct variable (assuming "struct" is the instance parameter)
                            var structVar = makeAST(EVar("struct"));
                            makeAST(EStructUpdate(
                                structVar,
                                [{
                                    key: fieldName,
                                    value: makeAST(EBinary(
                                        Concat,
                                        makeAST(EField(structVar, fieldName)),  // struct.field
                                        makeAST(EList([item]))
                                    ))
                                }]
                            ));
                        default:
                            // Regular array.push(item) becomes array ++ [item]
                            makeAST(EBinary(Concat, target, makeAST(EList([item]))));
                    }

                case ECall(target, "pop", []):
                    // array.pop() becomes List.delete_at(array, -1)
                    makeAST(ERemoteCall(
                        makeAST(EAtom(ElixirAtom.raw("List"))),
                        "delete_at",
                        [target, makeAST(EInteger(-1))]
                    ));
                    
                    
                default:
                    node;
            }
        });
    }
    
    /**
     * Transform struct field assignments within a method body to return updated struct
     * 
     * WHY: Methods like BalancedTree.set() modify fields but need to return the updated struct
     * WHAT: Detects field assignments on "struct" parameter and adds struct return
     * HOW: Wraps body in block that returns updated struct
     */
    static function transformStructFieldAssignments(body: ElixirAST, args: Array<EPattern>): ElixirAST {
        // Check if first argument is "struct" (instance method pattern)
        var hasStructParam = args.length > 0 && switch(args[0]) {
            case PVar("struct"): true;
            default: false;
        };
        
        if (!hasStructParam) return body;
        
        #if debug_ast_transformer
        trace('[XRay transformStructFieldAssignments] Analyzing body for field assignments');
        #end
        
        // Look for field assignments in the body
        var hasFieldAssignment = false;
        var fieldUpdates: Map<String, ElixirAST> = new Map();
        
        // Analyze the body for field assignments
        function analyzeNode(node: ElixirAST): Void {
            switch(node.def) {
                case EMatch(PVar("root"), value):
                    // Found field assignment: root = ...
                    #if debug_ast_transformer
                    trace('[XRay transformStructFieldAssignments] Found root assignment');
                    #end
                    hasFieldAssignment = true;
                    fieldUpdates.set("root", value);
                case EBlock(statements):
                    for (stmt in statements) {
                        analyzeNode(stmt);
                    }
                default:
                    // Continue analyzing
            }
        }
        
        analyzeNode(body);
        
        #if debug_ast_transformer
        trace('[XRay transformStructFieldAssignments] hasFieldAssignment: $hasFieldAssignment, has root: ${fieldUpdates.exists("root")}');
        #end
        
        if (hasFieldAssignment && fieldUpdates.exists("root")) {
            // Transform the body to return updated struct
            var statements = [];
            
            // Add the original body logic
            switch(body.def) {
                case EBlock(stmts):
                    statements = stmts.copy();
                default:
                    statements = [body];
            }
            
            // Add struct update at the end
            // %{struct | root: root}
            var structUpdate = makeAST(EStructUpdate(
                makeAST(EVar("struct")),
                [{ key: "root", value: makeAST(EVar("root")) }]
            ));
            
            statements.push(structUpdate);
            
            return makeAST(EBlock(statements));
        }
        
        return body;
    }
    
    // ========================================================================
    // Helper Functions
    // ========================================================================
    
    /**
     * Extract parent module name from AST metadata
     * This should be set during the AST building phase when we know inheritance relationships
     * For now, we return null since metadata doesn't have a parentModule field yet
     * In the future, we should add this field to ElixirMetadata typedef
     */
    static function extractParentModule(node: ElixirAST): Null<String> {
        // TODO: Add parentModule field to ElixirMetadata typedef
        // For now, we can try to extract from sourceExpr if available
        if (node.metadata != null && node.metadata.sourceExpr != null) {
            // Could analyze the TypedExpr to find parent class info
            // For now, return null and use the fallback mechanism
        }
        return null;
    }
    
    /**
     * Array length field to function transformation pass
     * 
     * WHY: Elixir doesn't support .length property access on arrays/lists
     * WHAT: Transforms array.length field access to length(array) function calls
     * HOW: Detects EField(target, "length") and converts to ECall(null, "length", [target])
     * 
     * Example transformation:
     *   array.length -> length(array)
     *   list.length -> length(list) 
     */
    static function arrayLengthFieldToFunctionPass(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace('[XRay ArrayLengthField] Starting array length field to function transformation');
        #end
        
        // Handle null nodes
        if (ast == null) {
            return null;
        }
        
        return switch(ast.def) {
            case EField(target, "length"):
                // This is an array.length field access that needs to become length(array)
                #if debug_ast_transformer
                var targetStr = ElixirASTPrinter.printAST(target);
                trace('[XRay ArrayLengthField] Transforming ${targetStr}.length to length($targetStr)');
                #end
                {
                    def: ECall(null, "length", [
                        transformAST(target, arrayLengthFieldToFunctionPass)
                    ]),
                    metadata: ast.metadata,
                    pos: ast.pos
                };
                
            case ECall(expr, funcName, args):
                // Regular call, transform recursively
                {
                    def: ECall(
                        expr != null ? transformAST(expr, arrayLengthFieldToFunctionPass) : null,
                        funcName,
                        [for (arg in args) transformAST(arg, arrayLengthFieldToFunctionPass)]
                    ),
                    metadata: ast.metadata,
                    pos: ast.pos
                };
                
            default:
                // Recursively transform children
                transformAST(ast, arrayLengthFieldToFunctionPass);
        };
    }
    
    /**
     * Convert camelCase to snake_case for Elixir method names
     */
    static function toSnakeCase(name: String): String {
        var result = "";
        for (i in 0...name.length) {
            var char = name.charAt(i);
            if (i > 0 && char == char.toUpperCase() && char != char.toLowerCase()) {
                result += "_";
            }
            result += char.toLowerCase();
        }
        return result;
    }
    
    /**
     * Recursively transform AST nodes
     */
    public static function transformNode(ast: ElixirAST, transformer: (ElixirAST) -> ElixirAST): ElixirAST {
        // First transform children
        var transformed = switch(ast.def) {
            case EModule(name, attributes, body):
                makeASTWithMeta(
                    EModule(name, attributes, body.map(e -> transformNode(e, transformer))),
                    ast.metadata,
                    ast.pos
                );
                
            case EDef(name, args, guards, body):
                makeASTWithMeta(
                    EDef(name, args, 
                         guards != null ? transformNode(guards, transformer) : null,
                         transformNode(body, transformer)),
                    ast.metadata,
                    ast.pos
                );
                
            case EDefp(name, args, guards, body):
                makeASTWithMeta(
                    EDefp(name, args,
                          guards != null ? transformNode(guards, transformer) : null,
                          transformNode(body, transformer)),
                    ast.metadata,
                    ast.pos
                );
                
            case EBlock(expressions):
                makeASTWithMeta(
                    EBlock(expressions.map(e -> transformNode(e, transformer))),
                    ast.metadata,
                    ast.pos
                );
                
            case EIf(condition, thenBranch, elseBranch):
                makeASTWithMeta(
                    EIf(transformNode(condition, transformer),
                        transformNode(thenBranch, transformer),
                        elseBranch != null ? transformNode(elseBranch, transformer) : null),
                    ast.metadata,
                    ast.pos
                );
                
            case ECase(expr, clauses):
                makeASTWithMeta(
                    ECase(transformNode(expr, transformer),
                          clauses.map(c -> {
                              pattern: c.pattern,
                              guard: c.guard != null ? transformNode(c.guard, transformer) : null,
                              body: transformNode(c.body, transformer)
                          })),
                    ast.metadata,
                    ast.pos
                );
                
            case EBinary(op, left, right):
                makeASTWithMeta(
                    EBinary(op,
                            transformNode(left, transformer),
                            transformNode(right, transformer)),
                    ast.metadata,
                    ast.pos
                );
                
            case EUnary(op, expr):
                makeASTWithMeta(
                    EUnary(op, transformNode(expr, transformer)),
                    ast.metadata,
                    ast.pos
                );
                
            case ECall(target, funcName, args):
                makeASTWithMeta(
                    ECall(target != null ? transformNode(target, transformer) : null,
                          funcName,
                          args.map(a -> transformNode(a, transformer))),
                    ast.metadata,
                    ast.pos
                );
                
            case EList(elements):
                makeASTWithMeta(
                    EList(elements.map(e -> transformNode(e, transformer))),
                    ast.metadata,
                    ast.pos
                );
                
            case ETuple(elements):
                makeASTWithMeta(
                    ETuple(elements.map(e -> transformNode(e, transformer))),
                    ast.metadata,
                    ast.pos
                );
                
            case EMap(pairs):
                makeASTWithMeta(
                    EMap(pairs.map(p -> {
                        key: transformNode(p.key, transformer),
                        value: transformNode(p.value, transformer)
                    })),
                    ast.metadata,
                    ast.pos
                );
                
            case EFor(generators, filters, body, into, uniq):
                makeASTWithMeta(
                    EFor(generators.map(g -> {
                        pattern: g.pattern,
                        expr: transformNode(g.expr, transformer)
                    }),
                         filters.map(f -> transformNode(f, transformer)),
                         transformNode(body, transformer),
                         into != null ? transformNode(into, transformer) : null,
                         uniq),
                    ast.metadata,
                    ast.pos
                );
                
            // Raw Elixir code injection - NEVER transform
            case ERaw(code):
                // ERaw nodes are sacred - they contain direct Elixir code injection
                // from __elixir__() calls and must NEVER be transformed
                // Just return the node as-is, without calling the transformer
                return ast;
                
            case EDefmodule(name, body):
                // Transform the module body recursively
                makeASTWithMeta(
                    EDefmodule(name, transformNode(body, transformer)),
                    ast.metadata,
                    ast.pos
                );
                
            // Literals and simple nodes - no children to transform
            default:
                ast;
        };
        
        // Then apply the transformation to this node
        return transformer(transformed);
    }
    
    /**
     * Detect and optimize pipeline patterns in a block
     */
    static function detectAndOptimizePipeline(expressions: Array<ElixirAST>): Null<ElixirAST> {
        // Look for patterns like:
        // x = f(x, ...)
        // x = g(x, ...)
        // x = h(x, ...)
        // Also handles remote calls like:
        // x = Module.f(x, ...)
        // x = Module.g(x, ...)
        
        if (expressions.length < 2) return null;
        
        var pipelineOps = [];
        var baseVar: String = null;
        var lastExpr: ElixirAST = null;
        
        for (expr in expressions) {
            switch(expr.def) {
                case EMatch(PVar(name), call):
                    switch(call.def) {
                        case ECall(target, func, args):
                            if (args.length > 0) {
                                switch(args[0].def) {
                                    case EVar(argName) if (argName == name):
                                        // Found a pipeline candidate
                                        if (baseVar == null) {
                                            baseVar = name;
                                        }
                                        if (baseVar == name) {
                                            pipelineOps.push({
                                                func: func,
                                                args: args.slice(1),
                                                target: target
                                            });
                                            lastExpr = expr;
                                            continue;
                                        }
                                    default:
                                }
                            }
                        case ERemoteCall(module, func, args):
                            // Handle remote calls like EctoQuery_Impl_.where(query, ...)
                            if (args.length > 0) {
                                switch(args[0].def) {
                                    case EVar(argName) if (argName == name):
                                        // Found a pipeline candidate for remote call
                                        if (baseVar == null) {
                                            baseVar = name;
                                        }
                                        if (baseVar == name) {
                                            pipelineOps.push({
                                                func: func,
                                                args: args.slice(1),
                                                target: module  // Use module as target
                                            });
                                            lastExpr = expr;
                                            continue;
                                        }
                                    default:
                                }
                            }
                        default:
                    }
                default:
            }
            
            // Pattern broken, check if we have enough for a pipeline
            if (pipelineOps.length >= 2) {
                break;
            } else {
                // Reset and continue looking
                pipelineOps = [];
                baseVar = null;
            }
        }
        
        // Create pipeline if we found a pattern
        if (pipelineOps.length >= 2) {
            var pipeline = makeAST(EVar(baseVar));
            
            for (op in pipelineOps) {
                if (op.target != null) {
                    pipeline = makeAST(EPipe(
                        pipeline,
                        makeAST(ERemoteCall(op.target, op.func, op.args))
                    ));
                } else {
                    pipeline = makeAST(EPipe(
                        pipeline,
                        makeAST(ECall(null, op.func, op.args))
                    ));
                }
            }
            
            // Create final assignment
            return makeAST(EMatch(PVar(baseVar), pipeline));
        }
        
        return null;
    }
    
    /**
     * Conditional reassignment transformation pass
     * 
     * WHY: Elixir warns when variables are reassigned (shadowing)
     * WHAT: Transform conditional reassignments to functional style
     * HOW: Make if blocks return the new value instead of reassigning
     * 
     * Example transformation:
     * ```
     * if (condition) {
     *   query = query.where(...);
     * }
     * ```
     * Becomes:
     * ```
     * query = if (condition) do
     *   query.where(...)
     * else
     *   query
     * end
     * ```
     */
    static function conditionalReassignmentPass(ast: ElixirAST): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EBlock(expressions):
                    // Transform each if statement in the block
                    var transformed = [];
                    for (expr in expressions) {
                        switch(expr.def) {
                            case EIf(cond, thenBranch, null):  // If without else
                                // Check if the then branch is a single reassignment
                                switch(thenBranch.def) {
                                    case EMatch(PVar(varName), value):
                                        // Check if this is reassigning to an existing variable
                                        // by looking if the value references the same variable
                                        if (referencesVariable(value, varName)) {
                                            // Transform to functional style: var = if cond do new_value else var end
                                            var newIf = makeAST(EIf(
                                                cond,
                                                value,  // Return the new value
                                                makeAST(EVar(varName))  // Return original variable
                                            ));
                                            transformed.push(makeAST(EMatch(PVar(varName), newIf)));
                                        } else {
                                            transformed.push(expr);
                                        }
                                    default:
                                        transformed.push(expr);
                                }
                            default:
                                transformed.push(expr);
                        }
                    }
                    return makeASTWithMeta(EBlock(transformed), node.metadata, node.pos);
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * Check if an AST node references a specific variable
     */
    static function referencesVariable(ast: ElixirAST, varName: String): Bool {
        var found = false;
        
        function visitor(node: ElixirAST): Void {
            if (found) return;
            
            switch(node.def) {
                case EVar(name) if (name == varName):
                    found = true;
                case ERemoteCall(_, _, args):
                    // Check if first argument is the variable
                    if (args.length > 0) {
                        switch(args[0].def) {
                            case EVar(name) if (name == varName):
                                found = true;
                            default:
                                for (arg in args) {
                                    visitor(arg);
                                }
                        }
                    }
                default:
                    // Recursively visit child nodes
                    transformAST(node, function(n) { 
                        visitor(n); 
                        return n; 
                    });
            }
        }
        
        visitor(ast);
        return found;
    }
    
    /**
     * Remove redundant nil initialization pass
     * 
     * WHY: Abstract type constructors generate redundant `var = nil` followed by `var = value`
     * WHAT: Removes nil initialization when variable is immediately reassigned  
     * HOW: Detects pattern of consecutive assignments to same variable and removes first
     * 
     * Pattern detected:
     * ```elixir
     * this1 = nil
     * this1 = %{data: data, params: params}
     * ```
     * 
     * Transformed to:
     * ```elixir
     * this1 = %{data: data, params: params}
     * ```
     */
    static function removeRedundantNilInitPass(ast: ElixirAST): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EDef(name, args, guards, body) if (name == "_new"):
                    #if debug_ast_transformer
                    trace('[XRay RemoveRedundantNilInit] Processing _new function');
                    #end
                    // Special handling for abstract constructor _new functions
                    var transformedBody = switch(body.def) {
                        case EBlock(expressions) if (expressions.length >= 2):
                            // Look for pattern: this1 = nil; this1 = <value>; this1
                            var filteredExprs = [];
                            var i = 0;
                            while (i < expressions.length) {
                                var expr = expressions[i];
                                var shouldSkip = false;
                                
                                // Check for this1 = nil
                                switch(expr.def) {
                                    case EMatch(PVar("this1"), nilValue):
                                        switch(nilValue.def) {
                                            case ENil:
                                                // Check next expression
                                                if (i + 1 < expressions.length) {
                                                    switch(expressions[i + 1].def) {
                                                        case EMatch(PVar("this1"), value):
                                                            switch(value.def) {
                                                                case ENil:
                                                                    // Don't skip if reassigning to nil
                                                                default:
                                                                    // Skip the nil assignment
                                                                    #if debug_ast_transformer
                                                                    trace('[XRay RemoveRedundantNilInit] Removing this1 = nil in _new function');
                                                                    #end
                                                                    shouldSkip = true;
                                                            }
                                                        default:
                                                    }
                                                }
                                            default:
                                        }
                                    default:
                                }
                                
                                if (!shouldSkip) {
                                    filteredExprs.push(expr);
                                }
                                i++;
                            }
                            
                            if (filteredExprs.length != expressions.length) {
                                makeASTWithMeta(EBlock(filteredExprs), body.metadata, body.pos);
                            } else {
                                body;
                            }
                        default:
                            body;
                    };
                    
                    return makeASTWithMeta(EDef(name, args, guards, transformedBody), node.metadata, node.pos);
                    
                case EBlock(expressions):
                    #if debug_ast_transformer
                    trace('[XRay RemoveRedundantNilInit] Processing EBlock with ${expressions.length} expressions');
                    #end
                    var filtered = [];
                    var nilAssignments = new Map<String, Int>(); // Track nil assignments by variable name
                    var i = 0;
                    
                    // First pass: identify all nil assignments
                    while (i < expressions.length) {
                        var expr = expressions[i];
                        switch(expr.def) {
                            case EMatch(PVar(varName), nilValue):
                                switch(nilValue.def) {
                                    case ENil:
                                        nilAssignments.set(varName, i);
                                    default:
                                }
                            default:
                        }
                        i++;
                    }
                    
                    // Second pass: filter out redundant nil assignments
                    i = 0;
                    while (i < expressions.length) {
                        var expr = expressions[i];
                        var shouldSkip = false;
                        
                        // Check if this is a nil assignment that should be removed
                        switch(expr.def) {
                            case EMatch(PVar(varName), nilValue):
                                switch(nilValue.def) {
                                    case ENil:
                                        // Special handling for 'this1' and similar abstract constructor variables
                                        // These are ALWAYS immediately reassigned in abstract constructors
                                        if (varName == "this1" || varName == "this" || varName.startsWith("this")) {
                                            #if debug_ast_transformer
                                            trace('[XRay RemoveRedundantNilInit] Found "this1" nil assignment at index $i');
                                            #end
                                            // Check immediate next expression for reassignment
                                            if (i + 1 < expressions.length) {
                                                #if debug_ast_transformer
                                                trace('[XRay RemoveRedundantNilInit] Next expr at ${i+1}: ${expressions[i + 1].def}');
                                                #end
                                                switch(expressions[i + 1].def) {
                                                    case EMatch(PVar(nextVarName), value) if (nextVarName == varName):
                                                        switch(value.def) {
                                                            case ENil:
                                                                // Don't skip if it's another nil
                                                                #if debug_ast_transformer
                                                                trace('[XRay RemoveRedundantNilInit] Next assignment is also nil, not skipping');
                                                                #end
                                                            default:
                                                                // Non-nil reassignment - skip the initial nil
                                                                #if debug_ast_transformer
                                                                trace('[XRay RemoveRedundantNilInit] REMOVING redundant nil init for abstract constructor var: $varName');
                                                                #end
                                                                shouldSkip = true;
                                                        }
                                                    default:
                                                        #if debug_ast_transformer
                                                        trace('[XRay RemoveRedundantNilInit] Next expr is not a match for $varName');
                                                        #end
                                                }
                                            }
                                        }
                                        
                                        // If not skipped yet, check if this variable is assigned again later
                                        if (!shouldSkip) {
                                            var j = i + 1;
                                            while (j < expressions.length) {
                                                switch(expressions[j].def) {
                                                    case EMatch(PVar(nextVarName), value) if (nextVarName == varName):
                                                        // Found reassignment - check if the value is not nil
                                                        switch(value.def) {
                                                            case ENil:
                                                                // Another nil assignment, keep looking
                                                            default:
                                                                // Non-nil reassignment found - skip the initial nil
                                                                #if debug_ast_transformer
                                                                trace('[XRay RemoveRedundantNilInit] Removing redundant nil init for: $varName (reassigned at index $j)');
                                                                #end
                                                                shouldSkip = true;
                                                                break;
                                                        }
                                                    default:
                                                }
                                                j++;
                                            }
                                        }
                                    default:
                                        // Not a nil assignment
                                }
                            default:
                                // Not a match expression
                        }
                        
                        if (!shouldSkip) {
                            filtered.push(expr);
                        }
                        i++;
                    }
                    
                    // Only create new block if we removed something
                    if (filtered.length != expressions.length) {
                        return makeASTWithMeta(EBlock(filtered), node.metadata, node.pos);
                    } else {
                        return node;
                    }
                    
                case EFn(clauses):
                    // Also handle anonymous function bodies
                    var transformedClauses = [for (clause in clauses) {
                        args: clause.args,
                        guard: clause.guard,
                        body: removeRedundantNilInitPass(clause.body)
                    }];
                    return makeASTWithMeta(EFn(transformedClauses), node.metadata, node.pos);
                    
                case EDef(name, args, guards, body):
                    // Handle public function definitions
                    var transformedBody = removeRedundantNilInitPass(body);
                    return makeASTWithMeta(EDef(name, args, guards, transformedBody), node.metadata, node.pos);
                    
                case EDefp(name, args, guards, body):
                    // Handle private function definitions
                    var transformedBody = removeRedundantNilInitPass(body);
                    return makeASTWithMeta(EDefp(name, args, guards, transformedBody), node.metadata, node.pos);
                    
                case EParen(inner):
                    // Handle parenthesized expressions (often contains this1 = nil pattern)
                    #if debug_ast_transformer
                    trace('[XRay RemoveRedundantNilInit] Processing EParen');
                    #end
                    
                    // Check if the inner expression is a sequence with redundant nil init
                    var transformedInner = switch(inner.def) {
                        case EBlock(expressions) if (expressions.length == 3):
                            // Pattern: (this1 = nil; this1 = value; this1)
                            var hasRedundantNil = false;
                            
                            // Check for this1 = nil as first expression
                            switch(expressions[0].def) {
                                case EMatch(PVar("this1"), nilValue):
                                    switch(nilValue.def) {
                                        case ENil:
                                            // Check second expression is also assignment to this1
                                            switch(expressions[1].def) {
                                                case EMatch(PVar("this1"), _):
                                                    // Check third expression is just this1
                                                    switch(expressions[2].def) {
                                                        case EVar("this1"):
                                                            hasRedundantNil = true;
                                                        default:
                                                    }
                                                default:
                                            }
                                        default:
                                    }
                                default:
                            }
                            
                            if (hasRedundantNil) {
                                #if debug_ast_transformer
                                trace('[XRay RemoveRedundantNilInit] Removing redundant nil from EParen block');
                                #end
                                // Remove the first expression (this1 = nil)
                                makeASTWithMeta(
                                    EBlock([expressions[1], expressions[2]]),
                                    inner.metadata,
                                    inner.pos
                                );
                            } else {
                                // Recursively process the block
                                removeRedundantNilInitPass(inner);
                            }
                        default:
                            // For other patterns, process recursively
                            removeRedundantNilInitPass(inner);
                    };
                    
                    return makeASTWithMeta(EParen(transformedInner), node.metadata, node.pos);
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * PREFIX UNUSED PARAMETERS PASS
     * 
     * WHY: Elixir convention requires unused function parameters to be prefixed with underscore
     *      to indicate they're intentionally unused. This prevents compiler warnings.
     * 
     * WHAT: Detects unused parameters in function definitions and prefixes them with underscore.
     *       Handles EDef, EDefp, EDefmacro, EDefmacrop, and EFn (anonymous functions).
     * 
     * HOW: 1. For each function definition, collect all parameter names
     *      2. Scan the function body to find which parameters are actually used
     *      3. Prefix unused parameters with underscore
     *      4. Update all references to maintain consistency
     * 
     * EDGE CASES:
     * - Parameters already prefixed with underscore are left as-is
     * - Parameters named "_" are not modified
     * - Nested functions are handled recursively
     */
    static function prefixUnusedParametersPass(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace('[XRay PrefixUnusedParams] PASS START');
        #end
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                // Handle regular function definitions
                case EDef(name, args, guards, body):
                    #if debug_ast_transformer
                    trace('[XRay PrefixUnusedParams] Found EDef: $name with ${args.length} args');
                    #end
                    var result = handleFunctionParameters(args, guards, body);
                    if (result.hasChanges) {
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Updated EDef: $name');
                        #end
                        return makeASTWithMeta(EDef(name, result.args, guards, result.body), node.metadata, node.pos);
                    }
                    return node;
                    
                case EDefp(name, args, guards, body):
                    var result = handleFunctionParameters(args, guards, body);
                    if (result.hasChanges) {
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Updated EDefp: $name');
                        #end
                        return makeASTWithMeta(EDefp(name, result.args, guards, result.body), node.metadata, node.pos);
                    }
                    return node;
                    
                case EDefmacro(name, args, guards, body):
                    var result = handleFunctionParameters(args, guards, body);
                    if (result.hasChanges) {
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Updated EDefmacro: $name');
                        #end
                        return makeASTWithMeta(EDefmacro(name, result.args, guards, result.body), node.metadata, node.pos);
                    }
                    return node;
                    
                case EDefmacrop(name, args, guards, body):
                    var result = handleFunctionParameters(args, guards, body);
                    if (result.hasChanges) {
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Updated EDefmacrop: $name');
                        #end
                        return makeASTWithMeta(EDefmacrop(name, result.args, guards, result.body), node.metadata, node.pos);
                    }
                    return node;
                    
                // Handle anonymous functions
                case EFn(clauses):
                    var hasAnyChange = false;
                    var newClauses = [];
                    
                    for (clause in clauses) {
                        var result = handleFunctionParameters(clause.args, clause.guard, clause.body);
                        if (result.hasChanges) {
                            hasAnyChange = true;
                            newClauses.push({
                                args: result.args,
                                guard: clause.guard,
                                body: result.body
                            });
                        } else {
                            newClauses.push(clause);
                        }
                    }
                    
                    if (hasAnyChange) {
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Updated EFn with ${clauses.length} clauses');
                        #end
                        return makeASTWithMeta(EFn(newClauses), node.metadata, node.pos);
                    }
                    return node;
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * Handle parameter detection and renaming for a function
     * Returns updated args and body if changes were made
     */
    static function handleFunctionParameters(args: Array<EPattern>, guards: Null<ElixirAST>, body: ElixirAST): {args: Array<EPattern>, body: ElixirAST, hasChanges: Bool} {
        // Extract parameter names from patterns
        var paramNames: Map<String, Bool> = new Map();
        var paramRenames: Map<String, String> = new Map();
        
        function extractParamNames(pattern: EPattern) {
            switch(pattern) {
                case PVar(name):
                    if (!name.startsWith("_")) { // Don't track already underscored params
                        paramNames.set(name, false); // false = not yet seen as used
                    }
                case PTuple(patterns):
                    for (p in patterns) extractParamNames(p);
                case PList(patterns):
                    for (p in patterns) extractParamNames(p);
                case PMap(pairs):
                    for (pair in pairs) extractParamNames(pair.value);
                case PCons(head, tail):
                    extractParamNames(head);
                    extractParamNames(tail);
                case PPin(pattern):
                    extractParamNames(pattern);
                default:
                    // Other patterns don't introduce variables
            }
        }
        
        for (arg in args) {
            extractParamNames(arg);
        }
        
        #if debug_ast_transformer
        trace('[XRay PrefixUnusedParams] Found parameters: ' + [for (name => _ in paramNames) name].join(", "));
        #end
        
        // If no parameters to check, return early
        if (Lambda.count(paramNames) == 0) {
            return {args: args, body: body, hasChanges: false};
        }
        
        // Check which parameters are used in the body (and guards if present)
        function markUsedVars(ast: ElixirAST) {
            switch(ast.def) {
                case EVar(name):
                    if (paramNames.exists(name)) {
                        paramNames.set(name, true); // Mark as used
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Found usage of param: $name');
                        #end
                    }
                case EField(target, _):
                    // Check if the target is a parameter being accessed
                    switch(target.def) {
                        case EVar(name):
                            if (paramNames.exists(name)) {
                                paramNames.set(name, true); // Mark as used
                                #if debug_ast_transformer
                                trace('[XRay PrefixUnusedParams] Found field access on param: $name');
                                #end
                            }
                        default:
                            markUsedVars(target); // Continue checking nested expressions
                    }
                case EAccess(target, key):
                    // Check if the target is a parameter being accessed
                    switch(target.def) {
                        case EVar(name):
                            if (paramNames.exists(name)) {
                                paramNames.set(name, true); // Mark as used
                                #if debug_ast_transformer
                                trace('[XRay PrefixUnusedParams] Found bracket access on param: $name');
                                #end
                            }
                        default:
                            markUsedVars(target); // Continue checking nested expressions
                    }
                    markUsedVars(key); // Also check the key expression
                case EStructUpdate(struct, fields):
                    // Check if struct being updated is a parameter
                    switch(struct.def) {
                        case EVar(name):
                            if (paramNames.exists(name)) {
                                paramNames.set(name, true); // Mark as used
                                #if debug_ast_transformer
                                trace('[XRay PrefixUnusedParams] Found struct update on param: $name');
                                #end
                            }
                        default:
                            markUsedVars(struct); // Continue checking nested expressions
                    }
                    // Also check the field values
                    for (field in fields) {
                        markUsedVars(field.value);
                    }
                case ERaw(code):
                    // Check if parameter names appear in raw Elixir code
                    // This handles __elixir__() injection where parameters are referenced
                    for (name => _ in paramNames) {
                        // Check if the parameter name appears as a word boundary in the raw code
                        // This handles cases like "Ecto.Changeset.change(data, params)"
                        var pattern = '\\b${name}\\b';
                        if (new EReg(pattern, "").match(code)) {
                            paramNames.set(name, true); // Mark as used
                            #if debug_ast_transformer
                            trace('[XRay PrefixUnusedParams] Found param usage in ERaw: $name in code: ${code.substring(0, 100)}...');
                            #end
                        }
                    }
                case EKeywordList(pairs):
                    // Check values in keyword list for parameter usage
                    for (pair in pairs) {
                        markUsedVars(pair.value);
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Checking keyword list value for parameter usage');
                        #end
                    }
                default:
                    iterateAST(ast, markUsedVars);
            }
        }
        
        // Check guards for parameter usage
        if (guards != null) {
            markUsedVars(guards);
        }
        
        // Check body for parameter usage
        markUsedVars(body);
        
        // Build rename map for unused parameters
        var hasChanges = false;
        for (name => used in paramNames) {
            if (!used && !name.startsWith("_")) {
                var newName = "_" + name;
                paramRenames.set(name, newName);
                hasChanges = true;
                #if debug_ast_transformer
                trace('[XRay PrefixUnusedParams] Will rename unused param: $name -> $newName');
                #end
            }
        }
        
        // If no changes needed, return original
        if (!hasChanges) {
            return {args: args, body: body, hasChanges: false};
        }
        
        // Apply renames to argument patterns
        function renameInPattern(pattern: EPattern): EPattern {
            switch(pattern) {
                case PVar(name):
                    if (paramRenames.exists(name)) {
                        return PVar(paramRenames.get(name));
                    }
                    return pattern;
                case PTuple(patterns):
                    return PTuple(patterns.map(renameInPattern));
                case PList(patterns):
                    return PList(patterns.map(renameInPattern));
                case PMap(pairs):
                    return PMap([for (pair in pairs) {key: pair.key, value: renameInPattern(pair.value)}]);
                case PCons(head, tail):
                    return PCons(renameInPattern(head), renameInPattern(tail));
                case PPin(p):
                    return PPin(renameInPattern(p));
                default:
                    return pattern;
            }
        }
        
        var newArgs = args.map(renameInPattern);
        
        // Apply renames to the body as well to handle cases where usage detection
        // might be incomplete (e.g., field access patterns that weren't detected)
        function renameInAST(ast: ElixirAST): ElixirAST {
            switch(ast.def) {
                case EVar(name):
                    if (paramRenames.exists(name)) {
                        return {def: EVar(paramRenames.get(name)), metadata: ast.metadata};
                    }
                    return ast;
                default:
                    return transformAST(ast, renameInAST);
            }
        }
        
        var newBody = renameInAST(body);
        
        return {args: newArgs, body: newBody, hasChanges: true};
    }
    
    /**
     * Generate unique identifier for generated code
     */
    static var uniqueCounter = 0;
    static function generateUniqueId(): String {
        return Std.string(uniqueCounter++);
    }
    
    /**
     * Helper function to iterate over AST nodes without transformation
     */
    static function iterateAST(node: ElixirAST, visitor: ElixirAST -> Void): Void {
        switch(node.def) {
            case EBlock(expressions):
                for (expr in expressions) visitor(expr);
            case EModule(name, attributes, body):
                for (b in body) visitor(b);
            case EDefmodule(name, doBlock):
                visitor(doBlock);
            case EDef(name, args, guards, body):
                visitor(body);
            case EDefp(name, args, guards, body):
                visitor(body);
            case EIf(condition, thenBranch, elseBranch):
                visitor(condition);
                visitor(thenBranch);
                if (elseBranch != null) visitor(elseBranch);
            case ECase(expr, clauses):
                visitor(expr);
                for (clause in clauses) {
                    if (clause.guard != null) visitor(clause.guard);
                    visitor(clause.body);
                }
            case EMatch(pattern, expr):
                visitor(expr);
            case EBinary(op, left, right):
                visitor(left);
                visitor(right);
            case EUnary(op, expr):
                visitor(expr);
            case ECall(target, funcName, args):
                if (target != null) visitor(target);
                for (arg in args) visitor(arg);
            case EMacroCall(macroName, args, doBlock):
                for (arg in args) visitor(arg);
                visitor(doBlock);
            case ETuple(elements):
                for (elem in elements) visitor(elem);
            case EList(elements):
                for (elem in elements) visitor(elem);
            case EMap(pairs):
                for (pair in pairs) {
                    visitor(pair.key);
                    visitor(pair.value);
                }
            case EStruct(name, fields):
                for (field in fields) visitor(field.value);
            case EFor(generators, filters, body, into, uniq):
                for (gen in generators) {
                    visitor(gen.expr);
                }
                for (filter in filters) visitor(filter);
                visitor(body);
                if (into != null) visitor(into);
            case EFn(clauses):
                for (clause in clauses) {
                    if (clause.guard != null) visitor(clause.guard);
                    visitor(clause.body);
                }
            case EReceive(clauses, after):
                for (clause in clauses) {
                    if (clause.guard != null) visitor(clause.guard);
                    visitor(clause.body);
                }
                if (after != null) {
                    visitor(after.timeout);
                    visitor(after.body);
                }
            case ERemoteCall(module, funcName, args):
                if (module != null) visitor(module);
                for (arg in args) visitor(arg);
            case EParen(expr):
                visitor(expr);
            case EDo(body):
                for (stmt in body) visitor(stmt);
            case ETry(body, rescue, catchClauses, afterBlock, elseBlock):
                visitor(body);
                if (rescue != null) {
                    for (clause in rescue) {
                        // ERescueClause structure would need checking
                        visitor(clause.body);
                    }
                }
                if (catchClauses != null) {
                    for (clause in catchClauses) {
                        visitor(clause.body);
                    }
                }
                if (afterBlock != null) visitor(afterBlock);
                if (elseBlock != null) visitor(elseBlock);
            case EWith(clauses, doBlock, elseBlock):
                for (clause in clauses) {
                    // Pattern is not an ElixirAST, only visit the expression
                    visitor(clause.expr);
                }
                visitor(doBlock);
                if (elseBlock != null) visitor(elseBlock);
            case ECond(clauses):
                for (clause in clauses) {
                    visitor(clause.condition);
                    visitor(clause.body);
                }
            case EField(object, field):
                visitor(object);
            case EModuleAttribute(name, value):
                visitor(value);
            case EKeywordList(pairs):
                // Visit values in keyword list
                for (pair in pairs) {
                    visitor(pair.value);
                }
            case _:
                // Leaf nodes - nothing to iterate
        }
    }
    
    /**
     * Helper function to transform AST nodes recursively
     */
    public static function transformAST(node: ElixirAST, transformer: ElixirAST -> ElixirAST): ElixirAST {
        if (node == null) {
            return null;
        }
        var transformed = switch(node.def) {
            case EBlock(expressions):
                makeASTWithMeta(EBlock(expressions.map(transformer)), node.metadata, node.pos);
            case EModule(name, attributes, body):
                makeASTWithMeta(EModule(name, attributes, body.map(transformer)), node.metadata, node.pos);
            case EDefmodule(name, doBlock):
                makeASTWithMeta(EDefmodule(name, transformer(doBlock)), node.metadata, node.pos);
            case EDef(name, args, guards, body):
                makeASTWithMeta(EDef(name, args, guards, transformer(body)), node.metadata, node.pos);
            case EDefp(name, args, guards, body):
                makeASTWithMeta(EDefp(name, args, guards, transformer(body)), node.metadata, node.pos);
            case EIf(condition, thenBranch, elseBranch):
                makeASTWithMeta(
                    EIf(transformer(condition), transformer(thenBranch),
                        elseBranch != null ? transformer(elseBranch) : null),
                    node.metadata, node.pos
                );
            case ECase(expr, clauses):
                makeASTWithMeta(
                    ECase(transformer(expr),
                          clauses.map(c -> {
                              pattern: c.pattern,
                              guard: c.guard != null ? transformer(c.guard) : null,
                              body: transformer(c.body)
                          })),
                    node.metadata, node.pos
                );
            case EMatch(pattern, expr):
                makeASTWithMeta(EMatch(pattern, transformer(expr)), node.metadata, node.pos);
            case EBinary(op, left, right):
                makeASTWithMeta(EBinary(op, transformer(left), transformer(right)), node.metadata, node.pos);
            case EUnary(op, expr):
                makeASTWithMeta(EUnary(op, transformer(expr)), node.metadata, node.pos);
            case ECall(target, funcName, args):
                makeASTWithMeta(ECall(target != null ? transformer(target) : null, funcName, args.map(transformer)), node.metadata, node.pos);
            case EMacroCall(macroName, args, doBlock):
                makeASTWithMeta(EMacroCall(macroName, args.map(transformer), transformer(doBlock)), node.metadata, node.pos);
            case ETuple(elements):
                makeASTWithMeta(ETuple(elements.map(transformer)), node.metadata, node.pos);
            case EList(elements):
                #if (debug_otp_child_spec && debug_otp_child_spec_verbose)
                if (elements.length > 0) {
                    trace('[XRay OTPChildSpec] Processing EList with ${elements.length} elements');
                    for (i in 0...elements.length) {
                        var elem = elements[i];
                        if (elem.metadata != null && elem.metadata.requiresIdiomaticTransform == true) {
                            trace('[XRay OTPChildSpec] Element $i has requiresIdiomaticTransform flag!');
                        }
                    }
                }
                #end
                makeASTWithMeta(EList(elements.map(transformer)), node.metadata, node.pos);
            case EMap(pairs):
                makeASTWithMeta(
                    EMap(pairs.map(p -> {key: transformer(p.key), value: transformer(p.value)})),
                    node.metadata, node.pos
                );
            case EKeywordList(pairs):
                makeASTWithMeta(
                    EKeywordList(pairs.map(p -> {key: p.key, value: transformer(p.value)})),
                    node.metadata, node.pos
                );
            case EStruct(name, fields):
                makeASTWithMeta(
                    EStruct(name, fields.map(f -> {key: f.key, value: transformer(f.value)})),
                    node.metadata, node.pos
                );
            case EFor(generators, filters, body, into, uniq):
                makeASTWithMeta(
                    EFor(generators.map(g -> {pattern: g.pattern, expr: transformer(g.expr)}),
                         filters.map(transformer),
                         transformer(body),
                         into != null ? transformer(into) : null,
                         uniq),
                    node.metadata, node.pos
                );
            case EFn(clauses):
                makeASTWithMeta(
                    EFn(clauses.map(c -> {
                        args: c.args,
                        guard: c.guard != null ? transformer(c.guard) : null,
                        body: transformer(c.body)
                    })),
                    node.metadata, node.pos
                );
            case EReceive(clauses, after):
                makeASTWithMeta(
                    EReceive(clauses.map(c -> {
                                 pattern: c.pattern,
                                 guard: c.guard != null ? transformer(c.guard) : null,
                                 body: transformer(c.body)
                             }),
                             after != null ? {timeout: transformer(after.timeout), body: transformer(after.body)} : null),
                    node.metadata, node.pos
                );
            case EModuleAttribute(name, value):
                makeASTWithMeta(EModuleAttribute(name, transformer(value)), node.metadata, node.pos);
            case ERemoteCall(module, funcName, args):
                makeASTWithMeta(
                    ERemoteCall(module != null ? transformer(module) : null, funcName, args.map(transformer)),
                    node.metadata, node.pos
                );
            case EParen(expr):
                // Transform the inner expression and preserve parentheses
                makeASTWithMeta(EParen(transformer(expr)), node.metadata, node.pos);
            case _:
                // Leaf nodes - return unchanged
                node;
        };
        return transformed;
    }
    
    /**
     * Underscore Variable Cleanup Pass
     * 
     * WHY: Haxe generates temporary variables with underscore prefixes (_g, _g_1, etc.) during
     * desugaring of switches, loops, and other complex expressions. These are actually USED
     * variables, but in Elixir, underscore-prefixed variables should not be referenced after
     * assignment, causing warnings and violating Elixir conventions.
     * 
     * WHAT: Detects and renames underscore-prefixed temporary variables that are actually used
     * - Identifies Haxe-generated temp variables (_g, _g_1, _g1, etc.)
     * - Tracks which ones are referenced after declaration
     * - Renames them consistently throughout the AST
     * - Preserves truly unused underscore variables (single underscore or unused prefixed)
     * 
     * HOW: Two-phase transformation
     * 1. Analysis phase: Collect all underscore variables and track usage
     * 2. Transformation phase: Rename used variables consistently
     */
    /**
     * Supervisor options transformation pass
     * 
     * WHY: Supervisor.start_link expects keyword lists but TObjectDecl generates maps
     * WHAT: Converts supervisor option maps to keyword lists
     * HOW: Delegates to SupervisorOptionsTransformPass
     */
    static function supervisorOptionsTransformPass(ast: ElixirAST): ElixirAST {
        return SupervisorOptionsTransformPass.transform(ast);
    }
    
    /**
     * OTP Child Spec Transformation Pass
     * 
     * WHY: Enum-based child specs generate tuples like {:PubSub, "TodoApp.PubSub"}
     * which are not valid OTP child specifications. Supervisor.start_link expects
     * either module names or proper child spec maps.
     * 
     * WHAT: Detects patterns that look like child specifications and transforms them:
     * - Simple tuples {:Atom, "String"} → proper module references or child spec maps
     * - Lists of such tuples → lists of proper child specs
     * - Works for any enum-based child spec pattern, not just TypeSafeChildSpec
     * 
     * HOW: Pattern matches on common OTP child spec contexts:
     * - Supervisor.start_link calls
     * - Children lists in application modules
     * - Any list containing tuple patterns that match child spec signatures
     * 
     * PATTERNS DETECTED:
     * - {:PubSub, "name"} → {Phoenix.PubSub, name: "name"}
     * - {:Endpoint} → MyAppWeb.Endpoint
     * - {:Telemetry} → MyAppWeb.Telemetry
     * - {:Repo, config} → {MyApp.Repo, config}
     */
    static function otpChildSpecTransformPass(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace("[XRay OTPChildSpec] Starting idiomatic enum transformation pass");
        #end
        
        var transformCount = 0;
        
        function transformIdiomaticNode(node: ElixirAST): ElixirAST {
            #if (debug_otp_child_spec && debug_otp_child_spec_verbose)
            // Very verbose - show every node being checked
            trace('[XRay OTPChildSpec] Checking node type: ${Type.enumConstructor(node.def)}');
            #end
            
            // First, recursively transform children
            var nodeWithTransformedChildren = transformAST(node, transformIdiomaticNode);
            
            // Handle null nodes
            if (nodeWithTransformedChildren == null) {
                return null;
            }
            
            // Then check if this node itself needs transformation
            if (nodeWithTransformedChildren.metadata != null && nodeWithTransformedChildren.metadata.requiresIdiomaticTransform == true) {
                #if debug_otp_child_spec
                trace('[XRay OTPChildSpec] Found node #${++transformCount} with requiresIdiomaticTransform flag');
                trace('[XRay OTPChildSpec] Node def: ${nodeWithTransformedChildren.def}');
                #end
                // Apply transformation using shared utility
                var transformed = reflaxe.elixir.ast.ElixirAST.applyIdiomaticEnumTransformation(nodeWithTransformedChildren);
                #if debug_otp_child_spec
                trace('[XRay OTPChildSpec] Transformed to: ${transformed.def}');
                #end
                return transformed;
            }
            
            return nodeWithTransformedChildren;
        }
        
        var result = transformIdiomaticNode(ast);
        
        #if debug_otp_child_spec
        trace('[XRay OTPChildSpec] Pass complete. Transformed ${transformCount} nodes');
        #end
        
        return result;
    }
    
    /**
     * Transform idiomatic enum constructors using convention-based patterns
     * 
     * WHY: Enums marked with @:elixirIdiomatic need special compilation
     * to match Elixir/OTP conventions. Instead of hardcoding specific patterns,
     * we detect structural conventions that indicate idiomatic Elixir usage.
     * 
     * WHAT: Convention-based transformations based on constructor structure:
     * 
     * 1. ZERO ARGUMENTS → Bare atom
     *    MyConstructor() → :my_constructor
     * 
     * 2. SINGLE ARGUMENT → Unwrap the value
     *    ModuleRef("Phoenix.PubSub") → Phoenix.PubSub
     *    This is common for module references in OTP
     * 
     * 3. TWO ARGUMENTS where second is keyword list → {first, keyword_list}
     *    ModuleWithConfig("Phoenix.PubSub", [name: "MyApp"]) → {Phoenix.PubSub, [name: "MyApp"]}
     *    This is the standard OTP child spec format
     * 
     * 4. TWO ARGUMENTS (general) → Keep as tuple but simplified
     *    SomeConstructor(a, b) → {a, b} (without constructor tag)
     * 
     * 5. THREE+ ARGUMENTS → Keep standard tuple format
     *    Complex(a, b, c) → {:complex, a, b, c}
     * 
     * HOW: Analyzes the AST structure to detect patterns:
     * - Counts arguments
     * - Detects keyword lists (EKeywordList nodes)
     * - Checks for string literals that should become atoms (module names)
     * 
     * CONVENTIONS DETECTED:
     * - Module name patterns (strings that look like Elixir modules)
     * - Keyword list patterns (for configuration)
     * - Arity patterns (zero, one, two, many)
     * 
     * @param elements The tuple elements [constructor_tag, arg1, arg2, ...]
     * @param node The original AST node with metadata
     * @return Transformed AST following Elixir idioms
     */
    /**
     * Tuple Element Field to Function Transformation Pass
     * 
     * WHY: When switch statements are compiled for Result enums, Haxe generates
     * TField expressions like tuple.elem(0) instead of function calls. These
     * become EField nodes which print as invalid Elixir syntax.
     * 
     * WHAT: Transforms EField nodes with "elem" field name into proper ECall nodes
     * for elem(tuple, index) function calls.
     * 
     * HOW: Recursively traverses AST, detects EField with "elem", and converts
     * them to ECall nodes. This enables the enum pattern matching pass to work.
     */
    static function tupleElemFieldToFunctionPass(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace('[XRay TupleElemField] Starting tuple elem field to function transformation');
        #end
        
        // Handle null nodes
        if (ast == null) {
            return null;
        }
        
        return switch(ast.def) {
            case EField(target, "elem"):
                // This is a tuple.elem field access that needs to become elem(tuple, N)
                // However, we don't have the index here - it's usually called as tuple.elem(0)
                // So we need to look for the pattern in context
                #if debug_ast_transformer
                var targetStr = ElixirASTPrinter.printAST(target);
                trace('[XRay TupleElemField] Found .elem field access on: $targetStr');
                #end
                
                // For now, we'll mark it for transformation but can't fully convert
                // without the index. The pattern matching pass will handle it.
                {
                    def: EField(transformAST(target, tupleElemFieldToFunctionPass), "elem"),
                    metadata: ast.metadata,
                    pos: ast.pos
                };
                
            case ECall(expr, funcName, args):
                if (funcName == "elem" && expr != null) {
                    // This is a method call pattern: target.elem(N)
                    // Transform to elem(target, N) for proper Elixir syntax
                    #if debug_ast_transformer
                    var targetStr = ElixirASTPrinter.printAST(expr);
                    trace('[XRay TupleElemField] Transforming ${targetStr}.elem(${args.length} args) to elem($targetStr, ...)');
                    #end
                    {
                        def: ECall(null, "elem", [
                            transformAST(expr, tupleElemFieldToFunctionPass)
                        ].concat([for (arg in args) transformAST(arg, tupleElemFieldToFunctionPass)])),
                        metadata: ast.metadata,
                        pos: ast.pos
                    };
                } else {
                    // Regular call, transform recursively
                    {
                        def: ECall(
                            expr != null ? transformAST(expr, tupleElemFieldToFunctionPass) : null,
                            funcName,
                            [for (arg in args) transformAST(arg, tupleElemFieldToFunctionPass)]
                        ),
                        metadata: ast.metadata,
                        pos: ast.pos
                    };
                }
                
            default:
                // Recursively transform children
                transformAST(ast, tupleElemFieldToFunctionPass);
        };
    }
    
    /**
     * Idiomatic Enum Pattern Matching Transformation Pass
     * 
     * WHY: The compiler generates low-level tuple access patterns for enum matching
     * which results in non-idiomatic Elixir code and variable naming inconsistencies.
     * Instead of case x.elem(0) with x.elem(1) extraction, we want case x with pattern matching.
     * 
     * WHAT: Transforms patterns like:
     *   case result.elem(0) do
     *     0 -> _g = result.elem(1); value = g; {:Some, value}
     *     1 -> _g = result.elem(1); :none
     *   end
     * Into:
     *   case result do
     *     {0, value} -> {:Some, value}
     *     {1, _} -> :none
     *   end
     * 
     * HOW: Detects ECase with ETupleAccess(expr, 0) and transforms the entire structure
     * to use tuple pattern matching instead of manual extraction.
     */
    static function idiomaticEnumPatternMatchingPass(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace('[XRay EnumPatternMatching] Starting idiomatic enum pattern matching pass');
        #end
        
        // Handle null nodes
        if (ast == null) {
            return null;
        }
        
        return switch(ast.def) {
            case ECase(expr, clauses):
                // Check if this is an enum tag check pattern (case x.elem(0))
                var isEnumTagCheck = false;
                var baseExpr = expr;
                
                switch(expr.def) {
                    case ECall(tupleExpr, "elem", [arg]):
                        switch(arg.def) {
                            case EInteger(0):
                                #if debug_ast_transformer
                                trace('[XRay EnumPatternMatching] Found enum tag check pattern on elem(0) as ECall');
                                #end
                                isEnumTagCheck = true;
                                baseExpr = tupleExpr;
                            default:
                        }
                    case EField(tupleExpr, "elem"):
                        // This is the pattern generated by switch on Result enums
                        // We detect it here but can't check for index 0 directly
                        // The transformer will need to analyze the clauses to determine this
                        #if debug_ast_transformer
                        trace('[XRay EnumPatternMatching] Found potential enum tag check pattern with .elem field access');
                        #end
                        isEnumTagCheck = true;
                        baseExpr = tupleExpr;
                    default:
                }
                
                if (isEnumTagCheck) {
                    
                    #if debug_ast_transformer
                    trace('[XRay EnumPatternMatching] Transforming enum case to idiomatic pattern matching');
                    #end
                    
                    // Transform each clause
                    var transformedClauses = [];
                    for (clause in clauses) {
                        var transformedClause = transformEnumClause(clause, baseExpr);
                        transformedClauses.push(transformedClause);
                    }
                    
                    // Return the transformed case using the base expression directly
                    {
                        def: ECase(baseExpr, transformedClauses),
                        metadata: ast.metadata,
                        pos: ast.pos
                    };
                } else {
                    // Not an enum pattern, recursively transform children
                    transformAST(ast, idiomaticEnumPatternMatchingPass);
                }
                
            default:
                // Recursively transform children
                transformAST(ast, idiomaticEnumPatternMatchingPass);
        };
    }
    
    /**
     * Transform an individual enum case clause to use pattern matching
     * 
     * WHY: Each clause needs to be transformed from tag checking to pattern matching
     * WHAT: Converts manual elem() extraction to tuple pattern destructuring  
     * HOW: Analyzes the body for elem(1) calls and creates appropriate patterns
     */
    static function transformEnumClause(clause: ECaseClause, baseExpr: ElixirAST): ECaseClause {
        #if debug_ast_transformer
        trace('[XRay EnumPatternMatching] Transforming clause with pattern: ${clause.pattern}');
        #end
        
        // Extract the tag value from the pattern
        var tagValue = switch(clause.pattern) {
            case PLiteral(ast):
                switch(ast.def) {
                    case EInteger(tag): tag;
                    default:
                        #if debug_ast_transformer
                        trace('[XRay EnumPatternMatching] Non-integer pattern, keeping as-is');
                        #end
                        return clause; // Can't transform non-integer patterns
                }
            default: 
                #if debug_ast_transformer
                trace('[XRay EnumPatternMatching] Non-literal pattern, keeping as-is');
                #end
                return clause; // Can't transform non-literal patterns
        };
        
        // Analyze the body to find parameter extraction patterns
        var extractedParams = analyzeEnumParameterExtraction(clause.body, baseExpr);
        
        #if debug_ast_transformer
        trace('[XRay EnumPatternMatching] Found ${extractedParams.length} extracted parameters');
        #end
        
        // Create tuple pattern based on extracted parameters
        var tuplePattern = if (extractedParams.length > 0) {
            // Create pattern with extracted variable names
            var patterns = [PLiteral(makeAST(EInteger(tagValue)))];
            for (param in extractedParams) {
                patterns.push(PVar(param.finalName));
            }
            PTuple(patterns);
        } else {
            // No parameters, use wildcard
            PTuple([PLiteral(makeAST(EInteger(tagValue))), PWildcard]);
        };
        
        // Clean up the body by removing extraction statements
        var cleanedBody = removeEnumParameterExtractions(clause.body, extractedParams);
        
        #if debug_ast_transformer
        trace('[XRay EnumPatternMatching] Created tuple pattern with ${extractedParams.length + 1} elements');
        #end
        
        return {
            pattern: tuplePattern,
            guard: clause.guard,
            body: cleanedBody
        };
    }
    
    /**
     * Analyze the body to find enum parameter extraction patterns
     */
    static function analyzeEnumParameterExtraction(body: ElixirAST, baseExpr: ElixirAST): Array<{tempName: String, finalName: String}> {
        var params = [];
        
        switch(body.def) {
            case EBlock(exprs):
                for (expr in exprs) {
                    switch(expr.def) {
                        case EMatch(PVar(varName), ast):
                            switch(ast.def) {
                                case ECall(tupleExpr, "elem", [arg]):
                                    switch(arg.def) {
                                        case EInteger(1):
                                            // Found pattern: _g = result.elem(1)
                                            if (astEquals(tupleExpr, baseExpr)) {
                                                // Look for subsequent assignment: value = g
                                                var finalName = findSubsequentAssignment(exprs, varName.replace("_", ""));
                                                if (finalName != null) {
                                                    params.push({tempName: varName, finalName: finalName});
                                                } else {
                                                    // Use the temp name without underscore as final name
                                                    params.push({tempName: varName, finalName: varName.replace("_", "")});
                                                }
                                            }
                                        default:
                                    }
                                default:
                            }
                        default:
                    }
                }
            default:
                // Single expression body, no extraction
        }
        
        return params;
    }
    
    /**
     * Find subsequent assignment of a temp variable
     */
    static function findSubsequentAssignment(exprs: Array<ElixirAST>, tempVarWithoutUnderscore: String): Null<String> {
        for (expr in exprs) {
            switch(expr.def) {
                case EMatch(PVar(finalName), ast):
                    switch(ast.def) {
                        case EVar(srcVar):
                            if (srcVar == tempVarWithoutUnderscore) {
                                return finalName;
                            }
                        default:
                    }
                default:
            }
        }
        return null;
    }
    
    /**
     * Remove enum parameter extraction statements from the body
     */
    static function removeEnumParameterExtractions(body: ElixirAST, extractedParams: Array<{tempName: String, finalName: String}>): ElixirAST {
        switch(body.def) {
            case EBlock(exprs):
                var cleanedExprs = [];
                var skip = false;
                
                for (i in 0...exprs.length) {
                    var expr = exprs[i];
                    var shouldSkip = false;
                    
                    // Check if this is an extraction statement
                    switch(expr.def) {
                        case EMatch(PVar(varName), ast):
                            switch(ast.def) {
                                case ECall(_, "elem", [arg]):
                                    switch(arg.def) {
                                        case EInteger(1):
                                            // Check if this matches any extracted param
                                            for (param in extractedParams) {
                                                if (varName == param.tempName) {
                                                    shouldSkip = true;
                                                    break;
                                                }
                                            }
                                        default:
                                    }
                                case EVar(srcVar):
                                    // Check if this is a reassignment from temp var
                                    for (param in extractedParams) {
                                        if (varName == param.finalName && srcVar == param.tempName.replace("_", "")) {
                                            shouldSkip = true;
                                            break;
                                        }
                                    }
                                default:
                            }
                        default:
                    }
                    
                    if (!shouldSkip) {
                        cleanedExprs.push(expr);
                    }
                }
                
                // If only one expression remains, unwrap the block
                if (cleanedExprs.length == 1) {
                    return cleanedExprs[0];
                } else if (cleanedExprs.length == 0) {
                    // Empty block, return nil
                    return makeAST(EAtom(ElixirAtom.nil()));
                } else {
                    return {
                        def: EBlock(cleanedExprs),
                        metadata: body.metadata,
                        pos: body.pos
                    };
                }
            default:
                // Not a block, return as-is
                return body;
        }
    }
    
    /**
     * Check if two AST nodes are structurally equal
     */
    static function astEquals(a: ElixirAST, b: ElixirAST): Bool {
        // Simple structural equality check for variable references
        return switch([a.def, b.def]) {
            case [EVar(name1), EVar(name2)]: name1 == name2;
            case [EField(obj1, field1), EField(obj2, field2)]: 
                field1 == field2 && astEquals(obj1, obj2);
            default: false;
        };
    }
    
    /**
     * Transform idiomatic enum constructors using shared utility
     * 
     * WHY: This wrapper delegates to the shared transformation utility in ElixirAST.hx
     * to ensure consistent transformation logic across the AST pipeline.
     * 
     * WHAT: Applies convention-based transformations for enums marked with @:elixirIdiomatic.
     * 
     * HOW: Simply delegates to the shared utility function.
     * 
     * @param elements The tuple elements to transform (unused - kept for compatibility)
     * @param node The original AST node for metadata preservation
     * @return Transformed AST following Elixir idioms
     */
    static function transformIdiomaticEnum(elements: Array<ElixirAST>, node: ElixirAST): ElixirAST {
        // Delegate to shared utility function
        return reflaxe.elixir.ast.ElixirAST.applyIdiomaticEnumTransformation(node);
    }
    
    /**
     * Check if a string looks like an Elixir module name
     * 
     * WHY: Module names in strings should be converted to atoms in idiomatic Elixir
     * WHAT: Detects patterns like "Phoenix.PubSub", "MyApp.Repo", "Elixir.MyModule"
     * HOW: Checks for capitalized segments separated by dots
     * 
     * @param s The string to check
     * @return True if it looks like a module name
     */
    static function isModuleName(s: String): Bool {
        if (s == null || s.length == 0) return false;
        
        // Module names start with uppercase or "Elixir."
        var firstChar = s.charAt(0);
        if (firstChar != firstChar.toUpperCase()) return false;
        
        // Check for module path pattern (e.g., "Phoenix.PubSub")
        var segments = s.split(".");
        for (segment in segments) {
            if (segment.length == 0) return false;
            var first = segment.charAt(0);
            // Each segment should start with uppercase
            if (first != first.toUpperCase() || first == first.toLowerCase()) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Convert a constructor name to idiomatic Elixir atom
     * 
     * WHY: Elixir atoms use snake_case, but some patterns need special handling
     * WHAT: Converts CamelCase to snake_case with special cases for common patterns
     * HOW: 
     * - "Ok" → "ok" (common Result pattern)
     * - "Error" → "error" (common Result pattern)  
     * - "Some" → "ok" (Option pattern mapped to Elixir convention)
     * - "None" → "error" (Option pattern mapped to Elixir convention)
     * - Others → snake_case
     * 
     * @param tag The constructor tag name
     * @return Idiomatic atom name
     */
    static function toIdiomaticAtom(tag: String): String {
        // Special cases for common patterns
        switch(tag.toLowerCase()) {
            case "ok": return "ok";
            case "error": return "error";
            case "some": return "ok";  // Option.Some maps to {:ok, _} in Elixir
            case "none": return "error";  // Option.None maps to :error in Elixir
            default:
                // Convert to snake_case
                return toSnakeCase(tag);
        }
    }
    
    
    static function underscoreVariableCleanupPass(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace('[XRay UnderscoreCleanup] Starting underscore variable cleanup pass');
        #end
        
        // Phase 1: Collect underscore variables and track usage
        var underscoreVars = new Map<String, Bool>(); // var name -> is used
        var varDeclarations = new Map<String, Bool>(); // track all declarations
        var allUnderscoreVars = new Map<String, Bool>(); // track ALL underscore vars
        
        function collectPatternVars(pattern: EPattern, vars: Map<String, Bool>): Void {
            switch(pattern) {
                case PVar(name):
                    vars.set(name, true);
                    if (name.charAt(0) == "_" && name.length > 1) {
                        // Track all underscore variables (including _g_1, _g_2, etc.)
                        allUnderscoreVars.set(name, true);
                        // Initialize as unused
                        if (!underscoreVars.exists(name)) {
                            underscoreVars.set(name, false);
                        }
                    }
                case PTuple(patterns):
                    for (p in patterns) collectPatternVars(p, vars);
                case PList(patterns):
                    for (p in patterns) collectPatternVars(p, vars);
                case PCons(head, tail):
                    collectPatternVars(head, vars);
                    collectPatternVars(tail, vars);
                case PMap(pairs):
                    for (pair in pairs) collectPatternVars(pair.value, vars);
                case PStruct(name, fields):
                    for (field in fields) collectPatternVars(field.value, vars);
                case _:
                    // Other patterns don't declare variables
            }
        }
        
        function collectVariables(node: ElixirAST): Void {
            // Handle null nodes
            if (node == null) {
                return;
            }
            
            switch(node.def) {
                case EMatch(pattern, expr):
                    // Track variable declarations in patterns
                    collectPatternVars(pattern, varDeclarations);
                    // Continue collecting in expression
                    collectVariables(expr);
                    
                case EVar(name):
                    // Track variable usage (not in pattern context)
                    if (name.charAt(0) == "_" && name.length > 1) {
                        // Mark this underscore variable as used
                        underscoreVars.set(name, true);
                        allUnderscoreVars.set(name, true);
                        #if debug_ast_transformer
                        trace('[XRay UnderscoreCleanup] Found used underscore variable: $name at ${node.pos}');
                        #end
                    }
                    
                case ERemoteCall(module, funcName, args):
                    #if debug_ast_transformer
                    trace('[XRay UnderscoreCleanup] Found ERemoteCall: $funcName with ${args.length} args');
                    #end
                    // Recursively collect from module and all arguments
                    if (module != null) collectVariables(module);
                    for (arg in args) {
                        collectVariables(arg);
                    }
                    
                case EFn(clauses):
                    #if debug_ast_transformer
                    trace('[XRay UnderscoreCleanup] Found EFn with ${clauses.length} clauses');
                    #end
                    // Recursively collect from lambda/function bodies
                    for (clause in clauses) {
                        if (clause.guard != null) collectVariables(clause.guard);
                        collectVariables(clause.body);
                    }
                    
                case _:
                    // Recursively collect from all children
                    iterateAST(node, collectVariables);
            }
        }
        
        // Run collection phase
        collectVariables(ast);
        
        // Phase 2: Build renaming map for ALL underscore variables that are referenced
        var renameMap = new Map<String, String>();
        
        // Process all underscore variables we found
        for (varName in allUnderscoreVars.keys()) {
            // Check if this variable is actually used (referenced after declaration)
            var isUsed = underscoreVars.exists(varName) && underscoreVars.get(varName);
            
            if (isUsed) {
                // This underscore variable is used, so rename it
                // Check if it's a Haxe-generated temp pattern
                if (~/^_g(_?\d*)?$/.match(varName)) {
                    // _g, _g_1, _g1 -> g, g_1, g1
                    var newName = varName.substr(1);
                    renameMap.set(varName, newName);
                    #if debug_ast_transformer
                    trace('[XRay UnderscoreCleanup] Renaming used variable: $varName -> $newName');
                    #end
                } else if (~/^_\d+$/.match(varName)) {
                    // _1, _2 -> temp_1, temp_2 (avoid pure numeric)
                    var newName = "temp" + varName.substr(1);
                    renameMap.set(varName, newName);
                    #if debug_ast_transformer
                    trace('[XRay UnderscoreCleanup] Renaming used numeric: $varName -> $newName');
                    #end
                }
                // Other underscore variables are left as-is (might be intentional)
            } else {
                #if debug_ast_transformer
                if (varName.charAt(0) == "_" && varName.length > 1) {
                    trace('[XRay UnderscoreCleanup] Keeping unused underscore variable: $varName');
                }
                #end
            }
        }
        
        // Phase 3: Apply renaming throughout the AST
        if (renameMap.keys().hasNext()) {
            #if debug_ast_transformer
            trace('[XRay UnderscoreCleanup] Applying ${Lambda.count(renameMap)} variable renamings');
            #end
            return applyVariableRenaming(ast, renameMap);
        }
        
        #if debug_ast_transformer
        trace('[XRay UnderscoreCleanup] No underscore variables need renaming');
        #end
        return ast;
    }
    
    /**
     * Apply variable renaming throughout the AST
     */
    static function applyVariableRenaming(ast: ElixirAST, renameMap: Map<String, String>): ElixirAST {
        function renameInPattern(pattern: EPattern): EPattern {
            return switch(pattern) {
                case PVar(name):
                    renameMap.exists(name) ? PVar(renameMap.get(name)) : pattern;
                case PTuple(patterns):
                    PTuple(patterns.map(renameInPattern));
                case PList(patterns):
                    PList(patterns.map(renameInPattern));
                case PCons(head, tail):
                    PCons(renameInPattern(head), renameInPattern(tail));
                case PMap(pairs):
                    PMap(pairs.map(p -> {key: p.key, value: renameInPattern(p.value)}));
                case PStruct(name, fields):
                    PStruct(name, fields.map(f -> {key: f.key, value: renameInPattern(f.value)}));
                case _:
                    pattern;
            }
        }
        
        function renameInAST(node: ElixirAST): ElixirAST {
            var transformed = switch(node.def) {
                case EVar(name):
                    if (renameMap.exists(name)) {
                        #if debug_ast_transformer
                        trace('[XRay UnderscoreCleanup] Renaming EVar: $name -> ${renameMap.get(name)}');
                        #end
                        makeASTWithMeta(EVar(renameMap.get(name)), node.metadata, node.pos);
                    } else {
                        node;
                    }
                    
                case EMatch(pattern, expr):
                    makeASTWithMeta(
                        EMatch(renameInPattern(pattern), renameInAST(expr)),
                        node.metadata, node.pos
                    );
                    
                case ECase(expr, clauses):
                    makeASTWithMeta(
                        ECase(renameInAST(expr),
                              clauses.map(c -> {
                                  pattern: renameInPattern(c.pattern),
                                  guard: c.guard != null ? renameInAST(c.guard) : null,
                                  body: renameInAST(c.body)
                              })),
                        node.metadata, node.pos
                    );
                    
                case EReceive(clauses, after):
                    makeASTWithMeta(
                        EReceive(clauses.map(c -> {
                                     pattern: renameInPattern(c.pattern),
                                     guard: c.guard != null ? renameInAST(c.guard) : null,
                                     body: renameInAST(c.body)
                                 }),
                                 after != null ? {timeout: renameInAST(after.timeout), body: renameInAST(after.body)} : null),
                        node.metadata, node.pos
                    );
                    
                case EFn(clauses):
                    makeASTWithMeta(
                        EFn(clauses.map(c -> {
                            args: c.args.map(renameInPattern),
                            guard: c.guard != null ? renameInAST(c.guard) : null,
                            body: renameInAST(c.body)
                        })),
                        node.metadata, node.pos
                    );
                    
                case _:
                    // For all other node types, recursively transform children
                    transformAST(node, renameInAST);
            };
            return transformed;
        }
        
        return renameInAST(ast);
    }
    
    /**
     * Fix Bare Concatenations Pass
     * 
     * WHY: When array.push() is transformed to concatenation, nested blocks can contain
     *      bare concatenations like `g ++ [0]` which are invalid as statements in Elixir.
     * 
     * WHAT: Converts bare concatenation statements to assignments.
     * 
     * HOW: Detects EBinary(Concat, EVar(name), ...) in statement position and wraps
     *      them with EBinary(Match, EVar(name), ...) to create valid assignments.
     */
    static function fixBareConcatenationsPass(ast: ElixirAST): ElixirAST {
        function fixConcatenations(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EBlock(statements):
                    var fixedStatements = [];
                    for (stmt in statements) {
                        var fixed = switch(stmt.def) {
                            // Check for bare concatenation: var ++ [value] or struct.field ++ [value]
                            case EBinary(Concat, left, right):
                                switch(left.def) {
                                    case EVar(name):
                                        // Convert to assignment: var = var ++ [value]
                                        makeAST(EBinary(Match, left, stmt));
                                    case EField(structVar, fieldName):
                                        // This is struct.field ++ [value] - a bare concatenation that should update the struct
                                        // Transform to: struct = %{struct | field: struct.field ++ [value]}
                                        switch(structVar.def) {
                                            case EVar("struct"):
                                                // Create struct update
                                                makeAST(EBinary(
                                                    Match,
                                                    structVar,
                                                    makeAST(EStructUpdate(
                                                        structVar,
                                                        [{
                                                            key: fieldName,
                                                            value: stmt  // The concatenation itself
                                                        }]
                                                    ))
                                                ));
                                            default:
                                                // Not a struct field, keep as-is
                                                stmt;
                                        }
                                    default:
                                        // Keep as-is if not a simple variable or field
                                        stmt;
                                }
                            default:
                                // Recursively fix nested blocks
                                fixConcatenations(stmt);
                        };
                        fixedStatements.push(fixed);
                    }
                    makeAST(EBlock(fixedStatements));
                    
                case EList(elements):
                    // Fix elements inside list literals
                    var fixedElements = [for (e in elements) fixConcatenations(e)];
                    makeAST(EList(fixedElements));
                    
                default:
                    // Recursively apply to all children
                    transformAST(node, fixConcatenations);
            };
        }
        
        return fixConcatenations(ast);
    }
    
    /**
     * Unrolled Comprehension Reconstruction Pass
     * 
     * WHY: Haxe completely unrolls array comprehensions with constant ranges at compile-time,
     *      converting `[for (i in 0...3) i]` into imperative code with temp variables and 
     *      concatenations. This creates invalid Elixir with bare concatenation expressions
     *      like `g ++ [0]` appearing as statements inside list literals.
     * 
     * WHAT: Detects blocks marked with isUnrolledComprehension metadata and reconstructs
     *       them back into idiomatic Elixir `for` comprehensions.
     * 
     * HOW: 1. Looks for Block nodes with isUnrolledComprehension metadata
     *      2. Analyzes the block to extract iteration pattern (range, values)
     *      3. Reconstructs as EFor(iterVar, range, body)
     *      4. Handles nested comprehensions by recursively processing inner blocks
     * 
     * EDGE CASES:
     * - Empty comprehensions (0...0 range)
     * - Single element comprehensions (0...1)
     * - Deeply nested comprehensions (3+ levels)
     * - Mixed constant and variable ranges
     * 
     * @see docs/03-compiler-development/ARRAY_COMPREHENSION_RECONSTRUCTION.md
     */
    static function unrolledComprehensionReconstructionPass(ast: ElixirAST): ElixirAST {
        #if debug_array_comprehension
        trace('[Array Comprehension Transform] Starting reconstruction pass');
        #end
        #if debug_unrolled_comprehension
        trace('[DEBUG Transform] unrolledComprehensionReconstructionPass called');
        #end
        
        function reconstructComprehension(ast: ElixirAST): ElixirAST {
            return switch(ast.def) {
                case EBlock(stmts) if (ast.metadata != null && ast.metadata.isUnrolledComprehension == true):
                    #if debug_array_comprehension
                    trace('[Array Comprehension Transform] ✓ Found marked block with ${stmts.length} statements');
                    trace('[Array Comprehension Transform]   Metadata: ${ast.metadata}');
                    #end
                    
                    // Analyze the block to reconstruct comprehension
                    var comprehension = analyzeAndReconstructComprehension(stmts);
                    if (comprehension != null) {
                        #if debug_array_comprehension
                        trace('[Array Comprehension Transform] ✓ Successfully reconstructed as for comprehension');
                        #end
                        comprehension;
                    } else {
                        #if debug_array_comprehension
                        trace('[Array Comprehension Transform] ✗ Could not reconstruct, keeping as block');
                        #end
                        ast;
                    }
                    
                case _:
                    // Recursively transform children
                    transformAST(ast, reconstructComprehension);
            };
        }
        
        return reconstructComprehension(ast);
    }
    
    /**
     * Analyze an unrolled comprehension block and reconstruct as EFor
     * 
     * Pattern to detect:
     * - g = []                    (initialization)
     * - g = g ++ [...]           (accumulation statements)
     * - g                        (return value)
     * 
     * Reconstructs as: for i <- 0..n, do: expression
     */
    static function analyzeAndReconstructComprehension(stmts: Array<ElixirAST>): Null<ElixirAST> {
        if (stmts.length < 3) return null;
        
        #if debug_array_comprehension
        trace('[Array Comprehension Transform] Analyzing block for reconstruction');
        #end
        
        // Check first statement: should be g = []
        var iterVar = switch(stmts[0].def) {
            case EBinary(Match, {def: EVar(varName)}, {def: EList([])}):
                varName;
            case _:
                return null;
        };
        
        #if debug_array_comprehension
        trace('[Array Comprehension Transform]   Found initialization: $iterVar = []');
        #end
        
        // Extract elements from accumulation statements
        var elements = [];
        for (i in 1...stmts.length - 1) {
            switch(stmts[i].def) {
                case EBinary(Match, {def: EVar(v)}, {def: EBinary(Concat, {def: EVar(v2)}, {def: EList([elem])})}) if (v == iterVar && v2 == iterVar):
                    // g = g ++ [element]
                    elements.push(elem);
                case EBinary(Concat, {def: EVar(v)}, {def: EList([elem])}) if (v == iterVar):
                    // Bare concatenation: g ++ [element] (shouldn't happen after fix, but handle it)
                    elements.push(elem);
                case _:
                    // Unknown pattern
                    #if debug_array_comprehension
                    trace('[Array Comprehension Transform]   Unknown statement pattern: ${stmts[i].def}');
                    #end
            }
        }
        
        #if debug_array_comprehension
        trace('[Array Comprehension Transform]   Extracted ${elements.length} elements');
        #end
        
        // Check last statement: should return the variable
        var returnsVar = switch(stmts[stmts.length - 1].def) {
            case EVar(v) if (v == iterVar): true;
            case _: false;
        };
        
        if (!returnsVar || elements.length == 0) return null;
        
        // Determine the range from element count
        var rangeEnd = elements.length - 1;
        
        // Check if elements are simple integers (0, 1, 2...) or nested comprehensions
        var isSimpleRange = true;
        var hasNestedComprehensions = false;
        
        for (i in 0...elements.length) {
            switch(elements[i].def) {
                case EInteger(val):
                    // Check if it's the expected integer
                    if (val != i) {
                        isSimpleRange = false;
                    }
                case EList(_):
                    // Nested list - likely a nested comprehension
                    hasNestedComprehensions = true;
                    isSimpleRange = false;
                case _:
                    isSimpleRange = false;
            }
        }
        
        #if debug_array_comprehension
        trace('[Array Comprehension Transform]   Simple range: $isSimpleRange, Nested: $hasNestedComprehensions');
        #end
        
        // Generate appropriate comprehension
        if (isSimpleRange) {
            // Simple range comprehension: for i <- 0..n, do: i
            var range = makeAST(ERange(makeAST(EInteger(0)), makeAST(EInteger(rangeEnd)), false));
            var generator: EGenerator = {
                pattern: PVar("i"),
                expr: range
            };
            var body = makeAST(EVar("i")); // Simple case: just return the iterator
            
            return makeAST(EFor([generator], [], body, null, null));
        } else if (hasNestedComprehensions) {
            // Nested comprehension: for i <- 0..n, do: for j <- 0..m, do: expr
            // For now, reconstruct the outer comprehension
            var range = makeAST(ERange(makeAST(EInteger(0)), makeAST(EInteger(rangeEnd)), false));
            var generator: EGenerator = {
                pattern: PVar("i"),
                expr: range
            };
            
            // Use the first element as template for the body (should be consistent)
            var body = elements[0];
            
            // If the body is a list, check if it can be reconstructed as a nested comprehension
            switch(body.def) {
                case EList(innerElements):
                    // Check if inner elements follow a pattern
                    var innerComprehension = tryReconstructInnerComprehension(innerElements);
                    if (innerComprehension != null) {
                        body = innerComprehension;
                    }
                case _:
            }
            
            return makeAST(EFor([generator], [], body, null, null));
        } else {
            // Complex pattern - keep as-is for now
            #if debug_array_comprehension
            trace('[Array Comprehension Transform]   Complex pattern, not reconstructing');
            #end
            return null;
        }
    }
    
    /**
     * Try to reconstruct an inner comprehension from a list of elements
     */
    static function tryReconstructInnerComprehension(elements: Array<ElixirAST>): Null<ElixirAST> {
        if (elements.length == 0) return null;
        
        // Check if elements follow a simple numeric pattern
        var isSimpleRange = true;
        for (i in 0...elements.length) {
            switch(elements[i].def) {
                case EInteger(val):
                    if (val != i) {
                        isSimpleRange = false;
                        break;
                    }
                case _:
                    isSimpleRange = false;
                    break;
            }
        }
        
        if (isSimpleRange) {
            // Reconstruct as: for j <- 0..n, do: j
            var rangeEnd = elements.length - 1;
            var range = makeAST(ERange(makeAST(EInteger(0)), makeAST(EInteger(rangeEnd)), false));
            var generator: EGenerator = {
                pattern: PVar("j"),
                expr: range
            };
            var body = makeAST(EVar("j"));
            
            return makeAST(EFor([generator], [], body, null, null));
        }
        
        return null;
    }
}

/**
 * SupervisorOptionsTransformPass: Convert supervisor options from map to keyword list
 * 
 * WHY: Supervisor.start_link expects options as a keyword list [strategy: :one_for_one, ...]
 *      but TObjectDecl generates EMap %{strategy: :one_for_one, ...}
 * 
 * WHAT: Detects supervisor option patterns and converts EMap to EKeywordList
 * 
 * HOW: Looks for maps with supervisor option keys (strategy, max_restarts, max_seconds)
 *      being passed to Supervisor.start_link and converts them to keyword lists
 */
class SupervisorOptionsTransformPass {
    
    /**
     * Transform supervisor options from maps to keyword lists
     */
    public static function transform(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace("[XRay SupervisorOptions] Starting supervisor options transformation");
        switch(ast.def) {
            case EDefmodule(name, _):
                trace('[XRay SupervisorOptions] Processing module: $name');
            case _:
                trace('[XRay SupervisorOptions] Processing non-module AST');
        }
        #end
        
        return transformSupervisorCalls(ast);
    }
    
    /**
     * Find and transform Supervisor.start_link calls
     */
    static function transformSupervisorCalls(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            #if debug_ast_transformer
            switch(node.def) {
                case EMatch(PVar(name), _):
                    trace('[XRay SupervisorOptions] Found variable assignment in transformSupervisorCalls: $name');
                case EMap(_):
                    trace('[XRay SupervisorOptions] Found map in transformSupervisorCalls');
                case _:
            }
            #end
            
            switch(node.def) {
                case ERemoteCall(module, "start_link", args) if (args.length == 2):
                    // Check if this is Supervisor.start_link(children, opts)
                    var isSupervisor = switch(module.def) {
                        case EVar("Supervisor"): true;
                        case _: false;
                    };
                    
                    if (isSupervisor) {
                        #if debug_ast_transformer
                        trace("[XRay SupervisorOptions] Found Supervisor.start_link call");
                        #end
                        
                        // Transform the second argument (options) if it's a map
                        var children = args[0];
                        var opts = transformSupervisorOptions(args[1]);
                        
                        return makeASTWithMeta(
                            ERemoteCall(module, "start_link", [children, opts]),
                            node.metadata,
                            node.pos
                        );
                    }
                    
                case EMatch(pattern, expr):
                    // Check if we're assigning to a variable named "opts" or similar
                    var varName = switch(pattern) {
                        case PVar(name): name;
                        case _: null;
                    };
                    
                    #if debug_ast_transformer
                    if (varName != null) {
                        trace('[XRay SupervisorOptions] Found variable assignment: $varName');
                    }
                    #end
                    
                    if (varName != null && (varName == "opts" || varName.indexOf("option") != -1 || varName.indexOf("config") != -1)) {
                        // This might be supervisor options
                        #if debug_ast_transformer
                        trace('[XRay SupervisorOptions] Variable $varName looks like options, checking if it\'s a map...');
                        #end
                        
                        var transformedExpr = transformSupervisorOptions(expr);
                        if (transformedExpr != expr) {
                            #if debug_ast_transformer
                            trace('[XRay SupervisorOptions] ✓ Transformed options assignment for variable: $varName');
                            #end
                            return makeASTWithMeta(
                                EMatch(pattern, transformedExpr),
                                node.metadata,
                                node.pos
                            );
                        }
                    }
                    
                case _:
                    // Not a supervisor call
            }
            
            return node;
        });
    }
    
    /**
     * Transform supervisor options from map to keyword list if needed
     */
    static function transformSupervisorOptions(expr: ElixirAST): ElixirAST {
        return switch(expr.def) {
            case EMap(pairs):
                #if debug_ast_transformer
                trace('[XRay SupervisorOptions] Analyzing map with ${pairs.length} pairs');
                #end
                
                // Check if this looks like supervisor options
                var hasStrategy = false;
                var hasMaxRestarts = false;
                var hasMaxSeconds = false;
                var hasName = false;
                
                for (pair in pairs) {
                    var keyName: Null<String> = switch(pair.key.def) {
                        case EAtom(atom): atom; // ElixirAtom implicitly converts to String
                        case _: null;
                    };
                    
                    if (keyName != null) {
                        // Check both snake_case and original field names (before transformation)
                        // since this pass might run at different stages
                        switch(keyName.toLowerCase()) {
                            case "strategy": hasStrategy = true;
                            case "max_restarts" | "maxrestarts": hasMaxRestarts = true;
                            case "max_seconds" | "maxseconds": hasMaxSeconds = true;
                            case "name": hasName = true;
                        }
                        
                        #if debug_ast_transformer
                        trace('[XRay SupervisorOptions] Checking key: $keyName (hasStrategy=$hasStrategy, hasMaxRestarts=$hasMaxRestarts)');
                        #end
                    }
                }
                
                // If it has at least strategy (required) and one other supervisor field, convert it
                if (hasStrategy && (hasMaxRestarts || hasMaxSeconds || hasName)) {
                    #if debug_ast_transformer
                    trace("[XRay SupervisorOptions] Converting map to keyword list for supervisor options");
                    #end
                    
                    // Convert EMapPair to EKeywordPair
                    var keywordPairs: Array<EKeywordPair> = [];
                    for (pair in pairs) {
                        var key = switch(pair.key.def) {
                            case EAtom(name): name;
                            case _: continue; // Skip non-atom keys
                        };
                        
                        // Note: Snake_case conversion for atoms is handled systematically
                        // in ElixirASTBuilder.toElixirAtomName(), not here
                        keywordPairs.push({key: key, value: pair.value});
                    }
                    
                    return makeASTWithMeta(
                        EKeywordList(keywordPairs),
                        expr.metadata,
                        expr.pos
                    );
                }
                
                expr; // Not supervisor options
                
            case _:
                expr; // Not a map
        };
    }
    
    /**
     * Helper to create AST node with metadata
     */
    static function makeASTWithMeta(def: ElixirASTDef, ?metadata: ElixirMetadata, ?pos: haxe.macro.Expr.Position): ElixirAST {
        return {
            def: def,
            metadata: metadata != null ? metadata : {},
            pos: pos
        };
    }
}

#end
