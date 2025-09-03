package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import haxe.macro.Expr.Position;
using StringTools;

/**
 * ElixirASTHelpers: Fluent Builder API and Pattern Recognition
 * 
 * WHY: Simplify AST construction and pattern detection
 * - Reduce boilerplate code in ElixirASTBuilder
 * - Prevent common bugs through consistent API
 * - Make transformation code more readable
 * - Encapsulate common patterns (null coalescing, etc.)
 * 
 * WHAT: High-level abstractions for AST manipulation
 * - Fluent builder API for creating AST nodes
 * - Pattern recognizers for detecting Haxe patterns
 * - Metadata helpers for consistent metadata handling
 * - Common transformation utilities
 * 
 * HOW: Builder pattern with chainable methods
 * - Each method returns the builder for chaining
 * - Build() finalizes and returns the AST node
 * - Pattern matchers return Option types for safety
 */
class ElixirASTHelpers {
    
    // ================================================================
    // Fluent Builder API
    // ================================================================
    
    /**
     * Create a new AST builder
     */
    public static inline function ast(): ASTBuilder {
        return new ASTBuilder();
    }
    
    /**
     * Quick helper for creating simple AST nodes
     */
    public static inline function make(def: ElixirASTDef, ?metadata: ElixirMetadata): ElixirAST {
        return {
            def: def,
            metadata: metadata != null ? metadata : {},
            pos: null
        };
    }
    
    // ================================================================
    // Pattern Recognizers
    // ================================================================
    
    /**
     * Check if a TypedExpr is a null coalescing pattern
     * Returns the components if it matches, null otherwise
     */
    public static function isNullCoalescingPattern(expr: TypedExpr): Null<NullCoalescingPattern> {
        if (expr == null) return null;
        
        // Check for TMeta(:mergeBlock, TBlock([TVar, TIf]))
        switch(expr.expr) {
            case TMeta({name: ":mergeBlock"}, {expr: TBlock([varExpr, ifExpr])}):
                return checkNullCoalescingBlock(varExpr, ifExpr);
            
            // Direct TBlock pattern (without TMeta)
            case TBlock([varExpr, ifExpr]):
                return checkNullCoalescingBlock(varExpr, ifExpr);
                
            default:
                return null;
        }
    }
    
    static function checkNullCoalescingBlock(varExpr: TypedExpr, ifExpr: TypedExpr): Null<NullCoalescingPattern> {
        // Check first expression is TVar with init
        switch(varExpr.expr) {
            case TVar(tmpVar, init) if (init != null):
                // Check second expression is TIf testing the temp var
                switch(ifExpr.expr) {
                    case TIf(condition, thenBranch, elseBranch):
                        // Check condition is (tmp != null)
                        var isNullCheck = switch(condition.expr) {
                            case TParenthesis({expr: TBinop(OpNotEq, {expr: TLocal(v)}, {expr: TConst(TNull)})}):
                                v.id == tmpVar.id;
                            case TBinop(OpNotEq, {expr: TLocal(v)}, {expr: TConst(TNull)}):
                                v.id == tmpVar.id;
                            default: 
                                false;
                        };
                        
                        if (isNullCheck) {
                            return {
                                tempVar: tmpVar,
                                initExpr: init,
                                defaultExpr: elseBranch
                            };
                        }
                    default:
                }
            default:
        }
        return null;
    }
    
    // ================================================================
    // Common Transformations
    // ================================================================
    
    /**
     * Create an inline null coalescing if expression
     * Generates: if (tmp = expr) != nil, do: tmp, else: default
     */
    public static function makeNullCoalescing(tempVarName: String, initExpr: ElixirAST, defaultExpr: ElixirAST): ElixirAST {
        var assignment = make(EMatch(PVar(tempVarName), initExpr));
        var condition = make(EBinary(NotEqual, make(EParen(assignment)), make(ENil)));
        var thenBranch = make(EVar(tempVarName));
        
        var ifExpr = make(EIf(condition, thenBranch, defaultExpr));
        
        // Mark for inline formatting
        if (ifExpr.metadata == null) ifExpr.metadata = {};
        ifExpr.metadata.keepInlineInAssignment = true;
        
        return ifExpr;
    }
    
    /**
     * Convert variable name to Elixir snake_case
     */
    public static function toElixirVarName(name: String): String {
        // Don't modify compiler-generated temporary variables like _g, _g1, etc.
        // These are created by Haxe's desugaring and should be preserved as-is
        if (name.charAt(0) == "_" && name.charAt(1) == "g") {
            return name; // Keep _g variables as-is
        }
        
        // Remove leading underscore if present (for other variables)
        if (name.charAt(0) == "_" && name.length > 1) {
            name = name.substr(1);
        }
        
        // Convert to snake_case
        var result = "";
        for (i in 0...name.length) {
            var char = name.charAt(i);
            if (i > 0 && char == char.toUpperCase() && char != "_" && char != char.toLowerCase()) {
                result += "_" + char.toLowerCase();
            } else {
                result += char.toLowerCase();
            }
        }
        
        return result;
    }
}

/**
 * Fluent builder for creating ElixirAST nodes
 */
class ASTBuilder {
    var def: ElixirASTDef;
    var metadata: ElixirMetadata;
    var pos: Position;
    
    public function new() {
        this.metadata = {};
    }
    
    // ================================================================
    // Node Creation Methods
    // ================================================================
    
    public function nil(): ASTBuilder {
        def = ENil;
        return this;
    }
    
    public function var_(name: String): ASTBuilder {
        def = EVar(name);
        return this;
    }
    
    public function string(value: String): ASTBuilder {
        def = EString(value);
        return this;
    }
    
    public function int(value: Int): ASTBuilder {
        def = EInteger(value);
        return this;
    }
    
    public function float(value: Float): ASTBuilder {
        def = EFloat(value);
        return this;
    }
    
    public function bool(value: Bool): ASTBuilder {
        def = EBoolean(value);
        return this;
    }
    
    public function atom(value: String): ASTBuilder {
        def = EAtom(value);
        return this;
    }
    
    public function match(pattern: EPattern, expr: ElixirAST): ASTBuilder {
        def = EMatch(pattern, expr);
        return this;
    }
    
    public function if_(condition: ElixirAST, thenBranch: ElixirAST, ?elseBranch: ElixirAST): ASTBuilder {
        def = EIf(condition, thenBranch, elseBranch);
        return this;
    }
    
    public function binary(op: EBinaryOp, left: ElixirAST, right: ElixirAST): ASTBuilder {
        def = EBinary(op, left, right);
        return this;
    }
    
    public function call(module: ElixirAST, function_: String, args: Array<ElixirAST>): ASTBuilder {
        def = ERemoteCall(module, function_, args);
        return this;
    }
    
    public function block(exprs: Array<ElixirAST>): ASTBuilder {
        def = EBlock(exprs);
        return this;
    }
    
    public function paren(expr: ElixirAST): ASTBuilder {
        def = EParen(expr);
        return this;
    }
    
    public function list(items: Array<ElixirAST>): ASTBuilder {
        def = EList(items);
        return this;
    }
    
    public function map(fields: Array<{key: ElixirAST, value: ElixirAST}>): ASTBuilder {
        def = EMap(fields);
        return this;
    }
    
    public function tuple(items: Array<ElixirAST>): ASTBuilder {
        def = ETuple(items);
        return this;
    }
    
    // ================================================================
    // Metadata Methods
    // ================================================================
    
    public function setInline(): ASTBuilder {
        metadata.canInline = true;
        metadata.keepInlineInAssignment = true;
        return this;
    }
    
    public function withType(type: Type): ASTBuilder {
        metadata.type = type;
        return this;
    }
    
    public function withSourceExpr(expr: TypedExpr): ASTBuilder {
        metadata.sourceExpr = expr;
        metadata.sourceLine = getLineNumber(expr.pos);
        return this;
    }
    
    public function withMetadata(meta: ElixirMetadata): ASTBuilder {
        // Merge metadata
        for (field in Reflect.fields(meta)) {
            Reflect.setField(metadata, field, Reflect.field(meta, field));
        }
        return this;
    }
    
    public function atPos(pos: haxe.macro.Position): ASTBuilder {
        this.pos = pos;
        return this;
    }
    
    // ================================================================
    // Build Method
    // ================================================================
    
    public function build(): ElixirAST {
        if (def == null) {
            throw "ASTBuilder: No AST definition set";
        }
        
        return {
            def: def,
            metadata: metadata,
            pos: pos
        };
    }
    
    // ================================================================
    // Helper Methods
    // ================================================================
    
    static function getLineNumber(pos: haxe.macro.Position): Int {
        #if macro
        var posInfo = haxe.macro.Context.getPosInfos(pos);
        return posInfo.min; // This is actually the character position, not line number
        #else
        return 0;
        #end
    }
}

/**
 * Pattern match result for null coalescing
 */
typedef NullCoalescingPattern = {
    tempVar: TVar,
    initExpr: TypedExpr,
    defaultExpr: TypedExpr
}

#end