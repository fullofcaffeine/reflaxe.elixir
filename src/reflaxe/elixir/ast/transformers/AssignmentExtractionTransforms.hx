package reflaxe.elixir.ast.transformers;

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;

using reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AssignmentExtractionTransforms: Handles extraction of assignments from expressions
 * 
 * WHY: Elixir doesn't allow assignments within arithmetic/binary expressions.
 * When Haxe's inline expansion creates patterns like `expr1 ||| index = call() &&& expr2`,
 * this causes compilation errors: "cannot invoke remote function :erlang.-/2 inside a match"
 * 
 * WHAT: Detects and extracts assignments (EMatch nodes) from within binary operations
 * and other expression contexts where they're not allowed. Hoists assignments before
 * the expression that uses them while preserving evaluation order.
 * 
 * HOW: 
 * - Recursively traverses expressions to find embedded EMatch nodes
 * - Collects assignments in evaluation order (left-to-right)
 * - Returns extracted assignments and cleaned expression
 * - Transforms blocks to include hoisted assignments before expressions
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles assignment extraction
 * - Preserves Evaluation Order: Critical for inline expansion correctness
 * - Recursive Design: Handles deeply nested assignments
 * - Clean Separation: Doesn't modify other AST transformations
 * 
 * EDGE CASES:
 * - Nested assignments (index = i = i + 1)
 * - Multiple assignments in one expression
 * - Assignments in function arguments
 * - Assignments in both operands of binary operations
 */
@:nullSafety(Off)
class AssignmentExtractionTransforms {
    
    /**
     * Main transformation pass for extracting assignments from expressions
     * 
     * WHY: Entry point for the assignment extraction transformation
     * WHAT: Traverses the AST and extracts assignments from expression contexts
     * HOW: Uses transformNode to visit each node and apply extraction logic
     */
    public static function assignmentExtractionPass(ast: ElixirAST): ElixirAST {
        #if debug_assignment_extraction
        trace("[XRay AssignmentExtraction] Starting assignment extraction pass");
        #end
        
        return transformAssignments(ast);
    }
    
    static function transformAssignments(node: ElixirAST): ElixirAST {
        #if debug_assignment_extraction
        var nodeType = Type.enumConstructor(node.def);
        if (nodeType == "EMatch" || nodeType == "EBinary") {
            trace('[XRay AssignmentExtraction] ⚡ Visiting ${nodeType} node');
        }
        #end
        
        // First, recursively transform children
        var transformedNode = ElixirASTTransformer.transformAST(node, transformAssignments);
        
        // Then check if this node itself needs transformation
        switch(transformedNode.def) {
            // Look for assignments that are direct statements
            case EMatch(pattern, value):
                #if debug_assignment_extraction
                trace("[XRay AssignmentExtraction] Found top-level EMatch");
                trace('[XRay AssignmentExtraction] Pattern: $pattern');
                trace('[XRay AssignmentExtraction] Value type: ${Type.enumConstructor(value.def)}');
                if (value.metadata?.sourceFile != null) {
                    trace('[XRay AssignmentExtraction] Source: ${value.metadata.sourceFile}:${value.metadata.sourceLine}');
                }
                // Special check for chained assignments like c = index = s.cca(...)
                switch(value.def) {
                    case EMatch(innerPattern, innerValue):
                        trace('[XRay AssignmentExtraction] Found chained assignment!');
                        trace('[XRay AssignmentExtraction] Inner pattern: $innerPattern');
                        trace('[XRay AssignmentExtraction] Inner value type: ${Type.enumConstructor(innerValue.def)}');
                    default:
                }
                #end
                // Check if the value contains assignments in binary expressions
                var result = extractAndTransformExpression(value);
                if (result.hasExtracted) {
                    #if debug_assignment_extraction
                    trace("[XRay AssignmentExtraction] Transforming top-level assignment");
                    trace('[XRay AssignmentExtraction] Extracted ${result.extracted.length} assignments');
                    #end
                    // Create a block with extracted assignments followed by the main assignment
                    var statements = result.extracted.copy();
                    statements.push(makeASTWithMeta(
                        EMatch(pattern, result.expression),
                        transformedNode.metadata,
                        transformedNode.pos
                    ));
                    return makeAST(EBlock(statements));
                }
                return transformedNode;
                
            // Binary operations should not create blocks themselves
            // The extraction happens when we process the parent assignment
            case EBinary(op, left, right):
                // Just return the already-transformed node
                return transformedNode;
                
            default:
                // Return the already-transformed node
                return transformedNode;
        }
    }
    
    /**
     * Extract assignments from an expression and return both extracted assignments and cleaned expression
     */
    static function extractAndTransformExpression(expr: ElixirAST): {extracted: Array<ElixirAST>, expression: ElixirAST, hasExtracted: Bool} {
        var extracted = [];
        
        function extractFromExpr(e: ElixirAST): ElixirAST {
            switch(e.def) {
                case EMatch(pattern, value):
                    #if debug_assignment_extraction
                    trace("[XRay AssignmentExtraction] Found embedded assignment");
                    trace('[XRay AssignmentExtraction] Pattern: $pattern');
                    trace('[XRay AssignmentExtraction] Pattern type: ${Type.enumConstructor(pattern)}');
                    trace('[XRay AssignmentExtraction] Value: ${value.def}');
                    #end
                    // Extract this assignment
                    var cleanValue = extractFromExpr(value);
                    extracted.push(makeASTWithMeta(
                        EMatch(pattern, cleanValue),
                        e.metadata,
                        e.pos
                    ));
                    
                    // Return variable reference
                    switch(pattern) {
                        case PVar(name):
                            return makeAST(EVar(name));
                        default:
                            // For complex patterns, keep the match
                            return e;
                    }
                    
                case EBinary(op, left, right):
                    #if debug_assignment_extraction
                    trace("[XRay AssignmentExtraction] Processing binary in expression: " + Type.enumConstructor(op));
                    trace('[XRay AssignmentExtraction] Left: ${left.def}');
                    trace('[XRay AssignmentExtraction] Right: ${right.def}');
                    
                    // Check if left or right contains assignments
                    var hasLeftAssignment = switch(left.def) {
                        case EMatch(_, _): true;
                        default: false;
                    };
                    var hasRightAssignment = switch(right.def) {
                        case EMatch(_, _): true;
                        default: false;
                    };
                    trace('[XRay AssignmentExtraction] Has left assignment: $hasLeftAssignment');
                    trace('[XRay AssignmentExtraction] Has right assignment: $hasRightAssignment');
                    #end
                    var cleanLeft = extractFromExpr(left);
                    var cleanRight = extractFromExpr(right);
                    
                    return makeASTWithMeta(
                        EBinary(op, cleanLeft, cleanRight),
                        e.metadata,
                        e.pos
                    );
                    
                case ECall(target, funcName, args):
                    #if debug_assignment_extraction
                    trace('[XRay AssignmentExtraction] Processing call: $funcName');
                    trace('[XRay AssignmentExtraction] Args: ${args.map(a -> a.def)}');
                    // Check for assignments in args
                    for (i in 0...args.length) {
                        switch(args[i].def) {
                            case EMatch(_, _):
                                trace('[XRay AssignmentExtraction] Found assignment in arg $i');
                            default:
                        }
                    }
                    #end
                    var cleanTarget = target != null ? extractFromExpr(target) : null;
                    var cleanArgs = args.map(extractFromExpr);
                    
                    return makeASTWithMeta(
                        ECall(cleanTarget, funcName, cleanArgs),
                        e.metadata,
                        e.pos
                    );
                    
                case EParen(inner):
                    var cleanInner = extractFromExpr(inner);
                    return makeASTWithMeta(
                        EParen(cleanInner),
                        e.metadata,
                        e.pos
                    );
                    
                default:
                    return e;
            }
        }
        
        var cleanExpr = extractFromExpr(expr);
        
        #if debug_assignment_extraction
        if (extracted.length > 0) {
            trace('[XRay AssignmentExtraction] Extracted ${extracted.length} assignments');
        }
        #end
        
        return {
            extracted: extracted,
            expression: cleanExpr,
            hasExtracted: extracted.length > 0
        };
    }
}