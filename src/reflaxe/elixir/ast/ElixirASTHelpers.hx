package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTBuilder;
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
     * Convert variable name to Elixir snake_case and escape reserved keywords
     *
     * WHY: Elixir has reserved keywords that cannot be used as variable names
     * WHAT: Converts camelCase to snake_case and escapes reserved keywords
     * HOW: Delegates to centralized ElixirNaming module for DRY principle
     *
     * @deprecated Use ElixirNaming.toVarName directly for new code
     */
    public static function toElixirVarName(name: String): String {
        // Delegate to centralized ElixirNaming module to follow DRY principle
        // This eliminates duplicate snake_case conversion logic
        return reflaxe.elixir.ast.naming.ElixirNaming.toVarName(name);
    }
    
    // ================================================================
    // Type Checking Utilities (Extracted from ElixirASTBuilder)
    // ================================================================
    
    /**
     * Check if a Type represents an Array
     */
    public static function isArrayType(t: Type): Bool {
        return switch (t) {
            case TInst(cls, _):
                var clsType = cls.get();
                clsType.name == "Array" || (clsType.pack.length == 0 && clsType.name == "Array");
            case TAbstract(abs, _):
                var absType = abs.get();
                absType.name == "Array" && absType.pack.length == 0;
            default:
                false;
        };
    }
    
    /**
     * Check if a Type represents a Map
     */
    public static function isMapType(t: Type): Bool {
        return switch (t) {
            case TInst(cls, _):
                var clsType = cls.get();
                clsType.name == "Map" || (clsType.module == "haxe.ds.Map");
            case TAbstract(abs, _):
                var absType = abs.get();
                absType.name == "Map" && (absType.module == "haxe.ds.Map" || absType.pack.join(".") == "haxe.ds");
            default:
                false;
        };
    }
    
    /**
     * Check if type supports map access syntax
     */
    public static function isMapAccess(t: Type): Bool {
        return isMapType(t);
    }
    
    // ================================================================
    // Naming and Conversion Utilities
    // ================================================================
    
    /**
     * Convert a name to Elixir atom format
     */
    public static function toElixirAtomName(name: String): String {
        // Apply general snake_case transformation for atoms
        return reflaxe.elixir.ast.naming.ElixirNaming.toVarName(name);
    }
    
    /**
     * Check if a parameter name is in camelCase
     */
    public static function isCamelCaseParameter(name: String): Bool {
        // Check for camelCase pattern (contains uppercase after lowercase)
        if (name.length <= 1) return false;
        
        var hasLowercase = false;
        var hasUppercaseAfterLowercase = false;
        
        for (i in 0...name.length) {
            var char = name.charAt(i);
            if (char == char.toLowerCase() && char != "_" && char != "$") {
                hasLowercase = true;
            } else if (hasLowercase && char == char.toUpperCase() && char != "_" && char != "$") {
                hasUppercaseAfterLowercase = true;
                break;
            }
        }
        
        return hasUppercaseAfterLowercase;
    }
    
    /**
     * Check if a variable name is a temporary pattern variable
     */
    public static function isTempPatternVarName(name: String): Bool {
        // Pattern: starts with g_<word>_ or tmp_<word>_ or match_<number>_ or pattern_<word>_
        if (name == null || name.length == 0) return false;
        
        // Check various temporary variable patterns
        var patterns = [
            ~/^g_\w+_\d+$/,        // g_<word>_<number>
            ~/^tmp_\w+_\d+$/,      // tmp_<word>_<number>
            ~/^match_\d+$/,         // match_<number>
            ~/^pattern_\w+_\d+$/,  // pattern_<word>_<number>
            ~/^_g\d+$/,             // _g<number> (compiler-generated)
            ~/^__temp_\w+$/        // __temp_<word>
        ];
        
        for (pattern in patterns) {
            if (pattern.match(name)) {
                return true;
            }
        }
        
        return false;
    }
    
    // ================================================================
    // AST Manipulation Utilities
    // ================================================================
    
    /**
     * Count occurrences of a variable name in an AST
     */
    public static function countVarOccurrencesInAST(ast: ElixirAST, name: String): Int {
        if (ast == null) return 0;
        
        return switch (ast.def) {
            case EVar(v): v == name ? 1 : 0;
            case EBlock(exprs): Lambda.fold(exprs, (e, acc) -> acc + countVarOccurrencesInAST(e, name), 0);
            case EBinary(_, left, right): countVarOccurrencesInAST(left, name) + countVarOccurrencesInAST(right, name);
            case EIf(cond, thenBranch, elseBranch):
                countVarOccurrencesInAST(cond, name) +
                countVarOccurrencesInAST(thenBranch, name) +
                (elseBranch != null ? countVarOccurrencesInAST(elseBranch, name) : 0);
            case ECall(null, _, args): Lambda.fold(args, (a, acc) -> acc + countVarOccurrencesInAST(a, name), 0);
            case ERemoteCall(_, _, args): Lambda.fold(args, (a, acc) -> acc + countVarOccurrencesInAST(a, name), 0);
            case EField(expr, _): countVarOccurrencesInAST(expr, name);
            case EList(items): Lambda.fold(items, (i, acc) -> acc + countVarOccurrencesInAST(i, name), 0);
            case ETuple(items): Lambda.fold(items, (i, acc) -> acc + countVarOccurrencesInAST(i, name), 0);
            case EMap(fields): Lambda.fold(fields, (f, acc) -> acc + countVarOccurrencesInAST(f.key, name) + countVarOccurrencesInAST(f.value, name), 0);
            case EParen(expr): countVarOccurrencesInAST(expr, name);
            default: 0;
        };
    }
    
    /**
     * Replace all occurrences of a variable name with a replacement AST
     */
    public static function replaceVarInAST(ast: ElixirAST, name: String, replacement: ElixirAST): ElixirAST {
        if (ast == null) return null;
        
        return switch (ast.def) {
            case EVar(v) if (v == name): replacement;
            case EBlock(exprs): make(EBlock(exprs.map(e -> replaceVarInAST(e, name, replacement))));
            case EBinary(op, left, right): make(EBinary(op, replaceVarInAST(left, name, replacement), replaceVarInAST(right, name, replacement)));
            case EIf(cond, thenBranch, elseBranch):
                make(EIf(
                    replaceVarInAST(cond, name, replacement),
                    replaceVarInAST(thenBranch, name, replacement),
                    elseBranch != null ? replaceVarInAST(elseBranch, name, replacement) : null
                ));
            case ECall(null, fn, args): make(ECall(null, fn, args.map(a -> replaceVarInAST(a, name, replacement))));
            case ERemoteCall(mod, fn, args): make(ERemoteCall(mod, fn, args.map(a -> replaceVarInAST(a, name, replacement))));
            case EField(expr, field): make(EField(replaceVarInAST(expr, name, replacement), field));
            case EList(items): make(EList(items.map(i -> replaceVarInAST(i, name, replacement))));
            case ETuple(items): make(ETuple(items.map(i -> replaceVarInAST(i, name, replacement))));
            case EMap(fields): make(EMap(fields.map(f -> {key: replaceVarInAST(f.key, name, replacement), value: replaceVarInAST(f.value, name, replacement)})));
            case EParen(expr): make(EParen(replaceVarInAST(expr, name, replacement)));
            default: ast;
        };
    }
    
    /**
     * Check if a variable name is used anywhere in an AST
     */
    public static function isVariableUsedInAST(varName: String, ast: ElixirAST): Bool {
        return countVarOccurrencesInAST(ast, varName) > 0;
    }
    
    // ================================================================
    // Expression Analysis Utilities
    // ================================================================
    
    /**
     * Check if an expression is pure (no side effects)
     */
    public static function isPure(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TConst(_): true;
            case TLocal(_): true;
            case TTypeExpr(_): true;
            case TBinop(_, e1, e2): isPure(e1) && isPure(e2);
            case TUnop(_, _, e): isPure(e);
            case TParenthesis(e): isPure(e);
            case TArrayDecl(el): Lambda.fold(el, (e, acc) -> acc && isPure(e), true);
            case TObjectDecl(fields): Lambda.fold(fields, (f, acc) -> acc && isPure(f.expr), true);
            default: false;
        };
    }
    
    /**
     * Check if an expression can be safely inlined
     */
    public static function canBeInlined(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TConst(_) | TLocal(_): true;
            case TBinop(_, e1, e2): canBeInlined(e1) && canBeInlined(e2);
            case TUnop(_, _, e): canBeInlined(e);
            case TParenthesis(e): canBeInlined(e);
            default: false;
        };
    }
    
    /**
     * Check if an expression is a constant
     */
    public static function isConstant(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TConst(_): true;
            default: false;
        };
    }
    
    /**
     * Check if an expression has side effects
     */
    public static function hasSideEffects(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TCall(_, _): true;
            case TNew(_, _, _): true;
            case TVar(_, _): true;
            case TBinop(OpAssign | OpAssignOp(_), _, _): true;
            case TUnop(OpIncrement | OpDecrement, _, _): true;
            case TThrow(_): true;
            case TReturn(_): true;
            case TBreak | TContinue: true;
            default: !isPure(expr);
        };
    }
    
    /**
     * Check if an init expression is simple enough to inline
     */
    public static function isSimpleInit(init: TypedExpr): Bool {
        return switch(init.expr) {
            case TConst(_): true;                    // Constants are simple
            case TLocal(_): true;                    // Local variables are simple
            case TField(e, _): isSimpleInit(e);     // Field access is simple if object is simple
            case TParenthesis(e): isSimpleInit(e);  // Parentheses don't add complexity
            case TTypeExpr(_): true;                 // Type references are simple
            case TArrayDecl([]): true;                // Empty arrays are simple
            case TObjectDecl([]): true;               // Empty objects are simple
            case TBinop(op, e1, e2):                  // Binary operations might be simple
                switch(op) {
                    case OpAdd | OpSub | OpMult | OpDiv | OpMod:  // Arithmetic is simple if operands are
                        isSimpleInit(e1) && isSimpleInit(e2);
                    default: false;
                };
            case TUnop(op, _, e):                    // Unary operations might be simple
                switch(op) {
                    case OpNot | OpNeg | OpNegBits:      // These are simple if operand is
                        isSimpleInit(e);
                    default: false;
                };
            default: false;                          // Everything else is not simple
        };
    }
    
    /**
     * Extract field name from a FieldAccess
     */
    public static function extractFieldName(fa: FieldAccess): String {
        return switch(fa) {
            case FAnon(cf) | FInstance(_, _, cf) | FStatic(_, cf) | FClosure(_, cf): 
                cf.get().name;
            case FDynamic(s): 
                s;
            case FEnum(_, ef): 
                ef.name;
        };
    }
    
    // ================================================================
    // Module and Type Utilities
    // ================================================================
    
    /**
     * Get the native module name from a Type using @:native metadata
     */
    public static function getExternNativeModuleNameFromType(t: Type): Null<String> {
        return switch (t) {
            case TInst(cls, _):
                var clsType = cls.get();
                if (clsType.isExtern && clsType.meta.has("native")) {
                    var nativeMeta = clsType.meta.extract("native")[0];
                    if (nativeMeta != null && nativeMeta.params != null && nativeMeta.params.length > 0) {
                        switch (nativeMeta.params[0].expr) {
                            case EConst(CString(s, _)): s;
                            default: null;
                        }
                    } else {
                        null;
                    }
                } else {
                    null;
                }
            default: null;
        };
    }
    
    /**
     * Convert a ModuleType to a string representation
     */
    public static function moduleTypeToString(m: ModuleType): String {
        return switch (m) {
            case TClassDecl(c):
                var cls = c.get();
                if (cls.pack.length > 0) {
                    cls.pack.join(".") + "." + cls.name;
                } else {
                    cls.name;
                }
            case TEnumDecl(e):
                var enm = e.get();
                if (enm.pack.length > 0) {
                    enm.pack.join(".") + "." + enm.name;
                } else {
                    enm.name;
                }
            case TAbstract(a):
                var abs = a.get();
                if (abs.pack.length > 0) {
                    abs.pack.join(".") + "." + abs.name;
                } else {
                    abs.name;
                }
            case TTypeDecl(t):
                var typ = t.get();
                if (typ.pack.length > 0) {
                    typ.pack.join(".") + "." + typ.name;
                } else {
                    typ.name;
                }
        };
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
    
    public function atPos(pos: Position): ASTBuilder {
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
    
    static function getLineNumber(pos: Position): Int {
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
