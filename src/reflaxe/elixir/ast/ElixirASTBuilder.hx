package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST;
using reflaxe.helpers.TypedExprHelper;
using reflaxe.helpers.TypeHelper;
using StringTools;

/**
 * ElixirASTBuilder: TypedExpr to ElixirAST Converter (Analysis Phase)
 * 
 * WHY: Bridge between Haxe's TypedExpr and our ElixirAST representation
 * - Preserves all semantic information from Haxe's type system
 * - Enriches nodes with metadata for later transformation phases
 * - Separates AST construction from string generation
 * - Enables multiple transformation passes on strongly-typed structure
 * 
 * WHAT: Converts Haxe TypedExpr nodes to corresponding ElixirAST nodes
 * - Handles all expression types (literals, variables, operations, calls)
 * - Captures type information and source positions
 * - Detects patterns that need special handling (e.g., array operations)
 * - Maintains context through metadata enrichment
 * 
 * HOW: Recursive pattern matching on TypedExpr with metadata preservation
 * - Each TypedExpr constructor maps to one or more ElixirAST nodes
 * - Metadata carries context through the entire pipeline
 * - Complex expressions decomposed into simpler AST nodes
 * - Pattern detection integrated into conversion process
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only converts AST formats, no code generation
 * - Open/Closed: Easy to add new node types without modifying existing
 * - Testability: Can test AST conversion independently of generation
 * - Maintainability: Clear separation from transformation and printing
 * 
 * @see docs/03-compiler-development/INTERMEDIATE_AST_REFACTORING_PRD.md
 */
class ElixirASTBuilder {
    
    /**
     * Main entry point: Convert TypedExpr to ElixirAST
     * 
     * WHY: Single entry point for all AST conversion
     * WHAT: Recursively converts TypedExpr tree to ElixirAST tree
     * HOW: Pattern matches on expr type and delegates to specific handlers
     */
    public static function buildFromTypedExpr(expr: TypedExpr): ElixirAST {
        #if debug_ast_builder
        trace('[XRay AST Builder] Converting TypedExpr: ${expr.expr}');
        #end
        
        var metadata = createMetadata(expr);
        var astDef = convertExpression(expr);
        
        var result = makeASTWithMeta(astDef, metadata, expr.pos);
        
        #if debug_ast_builder
        trace('[XRay AST Builder] Generated AST: ${astDef}');
        #end
        
        return result;
    }
    
    /**
     * Convert TypedExprDef to ElixirASTDef
     */
    static function convertExpression(expr: TypedExpr): ElixirASTDef {
        return switch(expr.expr) {
            // ================================================================
            // Literals and Constants
            // ================================================================
            case TConst(TInt(i)):
                EInteger(i);
                
            case TConst(TFloat(f)):
                EFloat(Std.parseFloat(f));
                
            case TConst(TString(s)):
                EString(s);
                
            case TConst(TBool(b)):
                EBoolean(b);
                
            case TConst(TNull):
                ENil;
                
            case TConst(TThis):
                EVar("self"); // Elixir convention
                
            case TConst(TSuper):
                EVar("super"); // Will be transformed later
                
            // ================================================================
            // Variables and Binding
            // ================================================================
            case TLocal(v):
                EVar(toElixirVarName(v.name));
                
            case TVar(v, init):
                if (init != null) {
                    EMatch(
                        PVar(toElixirVarName(v.name)),
                        buildFromTypedExpr(init)
                    );
                } else {
                    // Uninitialized variable - use nil
                    EMatch(
                        PVar(toElixirVarName(v.name)),
                        makeAST(ENil)
                    );
                }
                
            // ================================================================
            // Binary Operations
            // ================================================================
            case TBinop(op, e1, e2):
                var left = buildFromTypedExpr(e1);
                var right = buildFromTypedExpr(e2);
                
                switch(op) {
                    case OpAdd: EBinary(Add, left, right);
                    case OpSub: EBinary(Subtract, left, right);
                    case OpMult: EBinary(Multiply, left, right);
                    case OpDiv: EBinary(Divide, left, right);
                    case OpMod: EBinary(Remainder, left, right);
                    
                    case OpEq: EBinary(Equal, left, right);
                    case OpNotEq: EBinary(NotEqual, left, right);
                    case OpLt: EBinary(Less, left, right);
                    case OpLte: EBinary(LessEqual, left, right);
                    case OpGt: EBinary(Greater, left, right);
                    case OpGte: EBinary(GreaterEqual, left, right);
                    
                    case OpBoolAnd: EBinary(AndAlso, left, right);
                    case OpBoolOr: EBinary(OrElse, left, right);
                    
                    case OpAssign: EMatch(extractPattern(e1), right);
                    case OpAssignOp(op2): 
                        // a += b becomes a = a + b
                        var innerOp = convertAssignOp(op2);
                        EMatch(extractPattern(e1), makeAST(EBinary(innerOp, left, right)));
                    
                    case OpAnd: EBinary(BitwiseAnd, left, right);
                    case OpOr: EBinary(BitwiseOr, left, right);
                    case OpXor: EBinary(BitwiseXor, left, right);
                    case OpShl: EBinary(ShiftLeft, left, right);
                    case OpShr: EBinary(ShiftRight, left, right);
                    case OpUShr: EBinary(ShiftRight, left, right); // No unsigned in Elixir
                    
                    case OpInterval: ERange(left, right, false);
                    case OpArrow: EFn([{
                        args: [PVar("_arrow")], // Placeholder, will be transformed
                        body: right
                    }]);
                    case OpIn: EBinary(In, left, right);
                    case OpNullCoal: 
                        // a ?? b becomes if a != nil, do: a, else: b
                        EIf(
                            makeAST(EBinary(NotEqual, left, makeAST(ENil))),
                            left,
                            right
                        );
                }
                
            // ================================================================
            // Unary Operations
            // ================================================================
            case TUnop(op, postFix, e):
                var expr = buildFromTypedExpr(e).def;
                
                switch(op) {
                    case OpNot: EUnary(Not, makeAST(expr));
                    case OpNeg: EUnary(Negate, makeAST(expr));
                    case OpNegBits: EUnary(BitwiseNot, makeAST(expr));
                    case OpIncrement, OpDecrement:
                        // Elixir is immutable, these need special handling
                        // Will be transformed in the transformation phase
                        ECall(null, postFix ? "post_" + (op == OpIncrement ? "inc" : "dec") : "pre_" + (op == OpIncrement ? "inc" : "dec"), [makeAST(expr)]);
                    case OpSpread:
                        // Spread operator for destructuring
                        EUnquoteSplicing(makeAST(expr));
                }
                
            // ================================================================
            // Function Calls
            // ================================================================
            case TCall(e, el):
                var target = e != null ? buildFromTypedExpr(e) : null;
                var args = [for (arg in el) buildFromTypedExpr(arg)];
                
                // Detect special call patterns
                switch(e.expr) {
                    case TField(obj, fa):
                        var fieldName = extractFieldName(fa);
                        var objAst = buildFromTypedExpr(obj);
                        
                        // Check for module calls
                        if (isModuleCall(obj)) {
                            ERemoteCall(objAst, fieldName, args);
                        } else {
                            // Instance method call
                            ECall(objAst, fieldName, args);
                        }
                    case TLocal(v):
                        ECall(null, toElixirVarName(v.name), args);
                    default:
                        if (target != null) {
                            // Complex target expression
                            ECall(target, "call", args);
                        } else {
                            // Should not happen
                            ECall(null, "unknown_call", args);
                        }
                }
                
            // ================================================================
            // Field Access
            // ================================================================
            case TField(e, fa):
                var target = buildFromTypedExpr(e);
                var fieldName = extractFieldName(fa);
                
                // Detect map/struct access patterns
                if (isMapAccess(e.t)) {
                    EAccess(target, makeAST(EAtom(fieldName)));
                } else {
                    EField(target, fieldName);
                }
                
            // ================================================================
            // Array Operations
            // ================================================================
            case TArrayDecl(el):
                var elements = [for (e in el) buildFromTypedExpr(e)];
                EList(elements);
                
            case TArray(e, index):
                var target = buildFromTypedExpr(e);
                var key = buildFromTypedExpr(index);
                EAccess(target, key);
                
            // ================================================================
            // Control Flow (Basic)
            // ================================================================
            case TIf(econd, eif, eelse):
                var condition = buildFromTypedExpr(econd);
                var thenBranch = buildFromTypedExpr(eif);
                var elseBranch = eelse != null ? buildFromTypedExpr(eelse) : null;
                EIf(condition, thenBranch, elseBranch);
                
            case TBlock(el):
                var expressions = [for (e in el) buildFromTypedExpr(e)];
                EBlock(expressions);
                
            case TReturn(e):
                if (e != null) {
                    buildFromTypedExpr(e).def; // Return value is implicit in Elixir
                } else {
                    ENil; // Explicit nil return
                }
                
            case TBreak:
                EThrow(makeAST(EAtom("break"))); // Will be transformed
                
            case TContinue:
                EThrow(makeAST(EAtom("continue"))); // Will be transformed
                
            // ================================================================
            // Pattern Matching (Switch/Case)
            // ================================================================
            case TSwitch(e, cases, edef):
                var expr = buildFromTypedExpr(e).def;
                var clauses = [];
                
                // Check if this is a topic_to_string-style temp variable switch
                // These need special handling for return context
                var needsTempVar = false;
                var tempVarName = "temp_result";
                
                // Detect if switch is in return context
                var isReturnContext = false; // TODO: Will be set via metadata
                
                for (c in cases) {
                    var patterns = [for (v in c.values) convertPattern(v)];
                    var body = buildFromTypedExpr(c.expr);
                    
                    // Multiple patterns become multiple clauses
                    for (pattern in patterns) {
                        clauses.push({
                            pattern: pattern,
                            guard: null, // Guards will be added in transformation
                            body: body
                        });
                    }
                }
                
                // Default case
                if (edef != null) {
                    clauses.push({
                        pattern: PWildcard,
                        guard: null,
                        body: buildFromTypedExpr(edef)
                    });
                }
                
                // Create the case expression
                var caseASTDef = ECase(makeAST(expr), clauses);
                
                // If in return context and needs temp var, wrap in assignment
                if (isReturnContext && needsTempVar) {
                    EBlock([
                        makeAST(EMatch(PVar(tempVarName), makeAST(caseASTDef))),
                        makeAST(EVar(tempVarName))
                    ]);
                } else {
                    caseASTDef;
                }
                
            // ================================================================
            // Try/Catch
            // ================================================================
            case TTry(e, catches):
                var body = buildFromTypedExpr(e);
                var rescueClauses = [];
                
                for (c in catches) {
                    var pattern = PVar(toElixirVarName(c.v.name));
                    var catchBody = buildFromTypedExpr(c.expr);
                    
                    rescueClauses.push({
                        pattern: pattern,
                        body: catchBody
                    });
                }
                
                ETry(body, rescueClauses, [], null, null);
                
            // ================================================================
            // Lambda/Anonymous Functions
            // ================================================================
            case TFunction(f):
                var args = [for (arg in f.args) PVar(toElixirVarName(arg.v.name))];
                var body = buildFromTypedExpr(f.expr);
                
                EFn([{
                    args: args,
                    guard: null,
                    body: body
                }]);
                
            // ================================================================
            // Object/Anonymous Structure
            // ================================================================
            case TObjectDecl(fields):
                var pairs = [];
                for (field in fields) {
                    var key = makeAST(EAtom(field.name));
                    var value = buildFromTypedExpr(field.expr);
                    pairs.push({key: key, value: value});
                }
                EMap(pairs);
                
            // ================================================================
            // Type Operations
            // ================================================================
            case TTypeExpr(m):
                // Type reference becomes atom
                EAtom(moduleTypeToString(m));
                
            case TCast(e, m):
                // Casts are mostly compile-time in Haxe
                buildFromTypedExpr(e).def;
                
            case TParenthesis(e):
                EParen(buildFromTypedExpr(e));
                
            case TMeta(m, e):
                // Metadata wrapping - preserve the expression
                buildFromTypedExpr(e).def;
                
            // ================================================================
            // Special Cases
            // ================================================================
            case TNew(c, _, el):
                // Constructor call becomes struct creation
                var className = c.get().name;
                var args = [for (e in el) buildFromTypedExpr(e)];
                
                // Will be transformed to proper struct syntax
                EStruct(className, []);
                
            case TFor(v, e1, e2):
                // For loop becomes comprehension
                var pattern = PVar(toElixirVarName(v.name));
                var expr = buildFromTypedExpr(e1);
                var body = buildFromTypedExpr(e2);
                
                EFor([{pattern: pattern, expr: expr}], [], body, null, false);
                
            case TWhile(econd, e, normalWhile):
                // While loops need special transformation
                var condition = buildFromTypedExpr(econd);
                var body = buildFromTypedExpr(e);
                
                // Placeholder - will be transformed to recursive function
                ECall(null, normalWhile ? "while_loop" : "do_while_loop", [condition, body]);
                
            case TThrow(e):
                EThrow(buildFromTypedExpr(e));
                
            case TEnumParameter(e, ef, index):
                // Enum field access
                var exprAST = buildFromTypedExpr(e);
                var field = ef.name;
                
                // Will be transformed to proper pattern extraction
                ECall(exprAST, "elem", [makeAST(EInteger(index + 1))]); // +1 for tag
                
            case TEnumIndex(e):
                // Get enum tag index
                var exprAST = buildFromTypedExpr(e);
                ECall(exprAST, "elem", [makeAST(EInteger(0))]);
                
            case TIdent(s):
                // Identifier reference
                EVar(toElixirVarName(s));
        }
    }
    
    /**
     * Create metadata from TypedExpr
     */
    static function createMetadata(expr: TypedExpr): ElixirMetadata {
        return {
            sourceExpr: expr,
            sourceLine: expr.pos != null ? Context.getPosInfos(expr.pos).min : 0,
            sourceFile: expr.pos != null ? Context.getPosInfos(expr.pos).file : null,
            type: expr.t,
            elixirType: typeToElixir(expr.t),
            purity: isPure(expr),
            tailPosition: false, // Will be set by transformer
            async: false, // Will be detected by transformer
            requiresReturn: false, // Will be set by context
            requiresTempVar: false, // Will be set by transformer
            inPipeline: false, // Will be set by transformer
            inComprehension: false, // Will be set by context
            inGuard: false, // Will be set by context
            canInline: canBeInlined(expr),
            isConstant: isConstant(expr),
            sideEffects: hasSideEffects(expr)
        };
    }
    
    /**
     * Convert Haxe values to patterns
     * 
     * WHY: Switch case values need to be converted to Elixir patterns
     * WHAT: Handles literals, enum constructors, variables, and complex patterns
     * HOW: Analyzes the TypedExpr structure and generates appropriate pattern
     */
    static function convertPattern(value: TypedExpr): EPattern {
        return switch(value.expr) {
            // Literals
            case TConst(TInt(i)): 
                PLiteral(makeAST(EInteger(i)));
            case TConst(TFloat(f)): 
                PLiteral(makeAST(EFloat(Std.parseFloat(f))));
            case TConst(TString(s)): 
                PLiteral(makeAST(EString(s)));
            case TConst(TBool(b)): 
                PLiteral(makeAST(EBoolean(b)));
            case TConst(TNull): 
                PLiteral(makeAST(ENil));
                
            // Variables (for pattern matching)
            case TLocal(v):
                PVar(toElixirVarName(v.name));
                
            // Enum constructors
            case TEnumParameter(e, ef, index):
                // This represents matching against enum constructor arguments
                // We'll need to handle this in the context of the full pattern
                PVar("_enum_param_" + index);
                
            case TEnumIndex(e):
                // Matching against enum index (for switch on elem(tuple, 0))
                PLiteral(makeAST(EInteger(0))); // Will be refined based on actual enum
                
            // Array patterns
            case TArrayDecl(el):
                PList([for (e in el) convertPattern(e)]);
                
            // Tuple patterns (for enum matching)
            case TCall(e, el) if (isEnumConstructor(e)):
                // Enum constructor pattern
                var tag = extractEnumTag(e);
                var args = [for (arg in el) convertPattern(arg)];
                // Create tuple pattern {:tag, arg1, arg2, ...}
                PTuple([PLiteral(makeAST(EAtom(tag)))].concat(args));
                
            // Field access (for enum constructors)
            case TField(e, FEnum(_, ef)):
                // Direct enum constructor reference
                if (ef.params.length == 0) {
                    // No-argument constructor
                    PLiteral(makeAST(EAtom(ef.name)));
                } else {
                    // Constructor with arguments - needs to be a tuple pattern
                    // This will be {:Constructor, _, _, ...} with wildcards for args
                    var wildcards = [for (i in 0...ef.params.length) PWildcard];
                    PTuple([PLiteral(makeAST(EAtom(ef.name)))].concat(wildcards));
                }
                
            // Default/wildcard
            default: 
                PWildcard;
        }
    }
    
    /**
     * Check if an expression is an enum constructor call
     */
    static function isEnumConstructor(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TField(_, FEnum(_, _)): true;
            default: false;
        }
    }
    
    /**
     * Extract enum constructor tag name
     */
    static function extractEnumTag(expr: TypedExpr): String {
        return switch(expr.expr) {
            case TField(_, FEnum(_, ef)): ef.name;
            default: "unknown";
        }
    }
    
    /**
     * Extract pattern from left-hand side expression
     */
    static function extractPattern(expr: TypedExpr): EPattern {
        return switch(expr.expr) {
            case TLocal(v): PVar(toElixirVarName(v.name));
            case TField(e, fa): 
                // Map/struct field pattern
                PVar(extractFieldName(fa));
            default: PWildcard;
        }
    }
    
    /**
     * Convert assignment operator to binary operator
     */
    static function convertAssignOp(op: Binop): EBinaryOp {
        return switch(op) {
            case OpAdd: Add;
            case OpSub: Subtract;
            case OpMult: Multiply;
            case OpDiv: Divide;
            case OpMod: Remainder;
            case OpAnd: BitwiseAnd;
            case OpOr: BitwiseOr;
            case OpXor: BitwiseXor;
            case OpShl: ShiftLeft;
            case OpShr: ShiftRight;
            default: Add; // Fallback
        }
    }
    
    /**
     * Convert variable name to Elixir convention
     */
    static function toElixirVarName(name: String): String {
        // Simple snake_case conversion
        var result = "";
        for (i in 0...name.length) {
            var char = name.charAt(i);
            if (i > 0 && char == char.toUpperCase() && char != "_") {
                result += "_" + char.toLowerCase();
            } else {
                result += char.toLowerCase();
            }
        }
        return result;
    }
    
    /**
     * Extract field name from FieldAccess
     */
    static function extractFieldName(fa: FieldAccess): String {
        return switch(fa) {
            case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                cf.get().name;
            case FDynamic(s):
                s;
            case FEnum(_, ef):
                ef.name;
        }
    }
    
    /**
     * Check if expression is a module call
     */
    static function isModuleCall(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TTypeExpr(_): true;
            default: false;
        }
    }
    
    /**
     * Check if type represents a map/struct
     */
    static function isMapAccess(t: Type): Bool {
        return switch(t) {
            case TAnonymous(_): true;
            case TInst(_.get() => ct, _): ct.isInterface || ct.name.endsWith("Map");
            default: false;
        }
    }
    
    /**
     * Convert module type to string
     */
    static function moduleTypeToString(m: ModuleType): String {
        return switch(m) {
            case TClassDecl(c): c.get().name;
            case TEnumDecl(e): e.get().name;
            case TTypeDecl(t): t.get().name;
            case TAbstract(a): a.get().name;
        }
    }
    
    /**
     * Convert Haxe type to Elixir type string
     */
    static function typeToElixir(t: Type): String {
        return switch(t) {
            case TInst(_.get() => {name: "String"}, _): "binary";
            case TInst(_.get() => {name: "Array"}, _): "list";
            case TAbstract(_.get() => {name: "Int"}, _): "integer";
            case TAbstract(_.get() => {name: "Float"}, _): "float";
            case TAbstract(_.get() => {name: "Bool"}, _): "boolean";
            case TDynamic(_): "any";
            default: "term";
        }
    }
    
    /**
     * Check if expression is pure (no side effects)
     */
    static function isPure(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TConst(_) | TLocal(_) | TTypeExpr(_): true;
            case TBinop(_, e1, e2): isPure(e1) && isPure(e2);
            case TUnop(_, _, e): isPure(e);
            case TField(e, _): isPure(e);
            case TParenthesis(e): isPure(e);
            default: false;
        }
    }
    
    /**
     * Check if expression can be inlined
     */
    static function canBeInlined(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TConst(_) | TLocal(_): true;
            case TBinop(_, e1, e2): canBeInlined(e1) && canBeInlined(e2);
            case TUnop(_, _, e): canBeInlined(e);
            default: false;
        }
    }
    
    /**
     * Check if expression is constant
     */
    static function isConstant(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TConst(_): true;
            default: false;
        }
    }
    
    /**
     * Check if expression has side effects
     */
    static function hasSideEffects(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TCall(_, _) | TNew(_, _, _) | TVar(_, _): true;
            case TBinop(OpAssign | OpAssignOp(_), _, _): true;
            case TUnop(OpIncrement | OpDecrement, _, _): true;
            case TThrow(_): true;
            default: false;
        }
    }
}

#end