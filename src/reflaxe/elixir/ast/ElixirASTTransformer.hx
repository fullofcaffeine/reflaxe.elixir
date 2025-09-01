package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
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
        trace('[XRay AST Transformer] AST type: ${ast.def}');
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
        
        // Inline expansion fixes (should run very early to fix AST structure)
        passes.push({
            name: "InlineMethodCallCombiner",
            description: "Combine split inline expansion patterns from stdlib",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.InlineExpansionTransforms.inlineMethodCallCombinerPass
        });
        
        // Bitwise import pass (should run early to add imports)
        passes.push({
            name: "BitwiseImport",
            description: "Add Bitwise import when bitwise operators are used",
            enabled: true,
            pass: bitwiseImportPass
        });
        
        // Phoenix Component import pass (should run early to add imports)
        passes.push({
            name: "PhoenixComponentImport",
            description: "Add Phoenix.Component import when ~H sigil is used",
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
        
        // Annotation-based transformation passes (should run early to set up module structure)
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
            name: "ApplicationTransform",
            description: "Transform @:application modules into OTP Application structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.applicationTransformPass
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
        
        // Return only enabled passes
        return passes.filter(p -> p.enabled);
    }
    
    // ========================================================================
    // Transformation Passes
    // ========================================================================
    
    /**
     * Identity pass - returns AST unchanged
     * Base pass that ensures transformer works even with no transformations
     */
    static function identityPass(ast: ElixirAST): ElixirAST {
        return ast;
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
                            
                            // Check if Phoenix.Component is already imported
                            var hasImport = false;
                            for (stmt in statements) {
                                switch(stmt.def) {
                                    case EImport(module, _, _):
                                        // module is a string in EImport
                                        if (module == "Phoenix.Component") {
                                            hasImport = true;
                                            break;
                                        }
                                    case EUse(module, _):
                                        // module is a string in EUse
                                        if (module == "Phoenix.Component") {
                                            hasImport = true;
                                            break;
                                        }
                                    default:
                                }
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
     * LiveView CoreComponents Import Pass: Add app's CoreComponents import for LiveView modules
     * 
     * WHY: LiveView modules that use component functions need to import their app's CoreComponents
     * WHAT: Detects component usage (<.button, <.input, etc.) and adds CoreComponents import
     * HOW: Looks for ~H sigils with component calls and adds appropriate import
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
                                
                                // Create the import statement
                                var importStmt = makeAST(EImport(coreComponentsModule, null, null));
                                
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
                                makeAST(EAtom("ok"))
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
                                case PVar(paramName) if (paramName.indexOf("this") == 0):
                                    #if debug_abstract_this
                                    trace('[XRay AbstractThis] Found function with this parameter: $paramName');
                                    trace('[XRay AbstractThis] Body before fix: ${ElixirASTPrinter.print(clause.body, 0)}');
                                    #end
                                    
                                    // Found a "this" or "this_1" parameter
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
                                case EAtom("Bitwise") | EVar("Bitwise"):
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
                            value: makeAST(EAtom("Bitwise"))
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
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EMatch(pattern, value):
                    // Pattern matching for struct field assignment not implemented yet
                    // EPattern is a different type from ElixirAST, would need separate handling
                    return node;
                default:
                    // Not a match, continue traversal
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
                case EBlock(expressions):
                    // In a block, all but the last expression are in statement context
                    var newExpressions = [];
                    for (i in 0...expressions.length) {
                        var isLast = (i == expressions.length - 1);
                        var childContext = isLast ? isStatementContext : true;
                        newExpressions.push(transformWithContext(expressions[i], childContext));
                    }
                    makeASTWithMeta(EBlock(newExpressions), node.metadata, node.pos);
                    
                case EDef(name, args, guards, body):
                    // Function body is in expression context (returns value)
                    makeASTWithMeta(
                        EDef(name, args, guards, transformWithContext(body, false)),
                        node.metadata, node.pos
                    );
                    
                case EDefp(name, args, guards, body):
                    // Private function body is in expression context
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
                        // Check for Map.put() in statement context
                        switch(module.def) {
                            case EAtom("Map") | EVar("Map"):
                                if (funcName == "put" && args.length >= 1) {
                                    // First arg should be the map variable
                                    switch(args[0].def) {
                                        case EVar(varName):
                                            #if debug_ast_transformer
                                            trace('[XRay StatementContext] Wrapping Map.put with reassignment to: $varName');
                                            #end
                                            // Transform to: varName = Map.put(varName, ...)
                                            return makeASTWithMeta(
                                                EMatch(PVar(varName), transformed),
                                                node.metadata, node.pos
                                            );
                                        default:
                                            // Not a simple variable, can't reassign
                                    }
                                }
                            default:
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
     */
    static function immutabilityTransformPass(ast: ElixirAST): ElixirAST {
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
                    
                // Transform array mutation patterns
                case ECall(target, "push", [item]):
                    // array.push(item) becomes array ++ [item]
                    makeAST(EBinary(Concat, target, makeAST(EList([item]))));
                    
                case ECall(target, "pop", []):
                    // array.pop() becomes List.delete_at(array, -1)
                    makeAST(ERemoteCall(
                        makeAST(EAtom("List")),
                        "delete_at",
                        [target, makeAST(EInteger(-1))]
                    ));
                    
                default:
                    node;
            }
        });
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
            case _:
                // Leaf nodes - nothing to iterate
        }
    }
    
    /**
     * Helper function to transform AST nodes recursively
     */
    public static function transformAST(node: ElixirAST, transformer: ElixirAST -> ElixirAST): ElixirAST {
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
                        trace('[XRay UnderscoreCleanup] Found used underscore variable: $name');
                        #end
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
                    var keyName = switch(pair.key.def) {
                        case EAtom(name): name;
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