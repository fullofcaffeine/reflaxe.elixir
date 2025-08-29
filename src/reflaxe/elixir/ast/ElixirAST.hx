package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr.Position;

/**
 * ElixirAST: Strongly-Typed Intermediate AST for Reflaxe.Elixir
 * 
 * WHY: Replace string manipulation with type-safe AST operations to enable:
 * - Semantic understanding of code structure
 * - Independent transformation passes
 * - Better debugging and inspection
 * - Context preservation through metadata
 * 
 * WHAT: Complete representation of Elixir language constructs with:
 * - All syntax nodes (modules, functions, expressions, patterns)
 * - Rich metadata for each node
 * - Zero Dynamic types - everything strongly typed
 * - Support for all Elixir idioms and Phoenix patterns
 * 
 * HOW: Three-phase compilation pipeline uses this AST:
 * 1. ElixirASTBuilder converts TypedExpr → ElixirAST
 * 2. ElixirASTTransformer applies idiom/framework transformations
 * 3. ElixirPrinter generates string output
 * 
 * @see docs/03-compiler-development/INTERMEDIATE_AST_REFACTORING_PRD.md
 */

// ============================================================================
// Core AST Definition
// ============================================================================

/**
 * Main AST node enum containing all Elixir language constructs
 */
enum ElixirASTDef {
    // ========================================================================
    // Modules and Structure
    // ========================================================================
    
    /** Elixir module definition with attributes and body */
    EModule(name: String, attributes: Array<EAttribute>, body: Array<ElixirAST>);
    
    /** Defmodule block */
    EDefmodule(name: String, doBlock: ElixirAST);
    
    // ========================================================================
    // Functions
    // ========================================================================
    
    /** Public function definition */
    EDef(name: String, args: Array<EPattern>, guards: Null<ElixirAST>, body: ElixirAST);
    
    /** Private function definition */
    EDefp(name: String, args: Array<EPattern>, guards: Null<ElixirAST>, body: ElixirAST);
    
    /** Macro definition */
    EDefmacro(name: String, args: Array<EPattern>, guards: Null<ElixirAST>, body: ElixirAST);
    
    /** Private macro definition */
    EDefmacrop(name: String, args: Array<EPattern>, guards: Null<ElixirAST>, body: ElixirAST);
    
    // ========================================================================
    // Pattern Matching
    // ========================================================================
    
    /** Case expression with pattern matching */
    ECase(expr: ElixirAST, clauses: Array<ECaseClause>);
    
    /** Cond expression for condition chains */
    ECond(clauses: Array<ECondClause>);
    
    /** Pattern match (=) operator */
    EMatch(pattern: EPattern, expr: ElixirAST);
    
    /** With expression for chained pattern matching */
    EWith(clauses: Array<EWithClause>, doBlock: ElixirAST, elseBlock: Null<ElixirAST>);
    
    // ========================================================================
    // Control Flow
    // ========================================================================
    
    /** If expression */
    EIf(condition: ElixirAST, thenBranch: ElixirAST, elseBranch: Null<ElixirAST>);
    
    /** Unless expression (negative if) */
    EUnless(condition: ElixirAST, body: ElixirAST, elseBranch: Null<ElixirAST>);
    
    /** Try-rescue-catch-after expression */
    ETry(body: ElixirAST, rescue: Array<ERescueClause>, catchClauses: Array<ECatchClause>, 
         afterBlock: Null<ElixirAST>, elseBlock: Null<ElixirAST>);
    
    /** Raise exception */
    ERaise(exception: ElixirAST, attributes: Null<ElixirAST>);
    
    /** Throw expression */
    EThrow(value: ElixirAST);
    
    // ========================================================================
    // Data Structures
    // ========================================================================
    
    /** List literal [] */
    EList(elements: Array<ElixirAST>);
    
    /** Tuple literal {} */
    ETuple(elements: Array<ElixirAST>);
    
    /** Map literal %{} */
    EMap(pairs: Array<EMapPair>);
    
    /** Struct literal %Module{} */
    EStruct(module: String, fields: Array<EStructField>);
    
    /** Keyword list [key: value] */
    EKeywordList(pairs: Array<EKeywordPair>);
    
    /** Binary/Bitstring <<>> */
    EBinary(segments: Array<EBinarySegment>);
    
    // ========================================================================
    // Expressions
    // ========================================================================
    
    /** Function call */
    ECall(target: Null<ElixirAST>, function: String, args: Array<ElixirAST>);
    
    /** Remote call Module.function() */
    ERemoteCall(module: ElixirAST, function: String, args: Array<ElixirAST>);
    
    /** Pipe operator |> */
    EPipe(left: ElixirAST, right: ElixirAST);
    
    /** Binary operator */
    EBinary(op: EBinaryOp, left: ElixirAST, right: ElixirAST);
    
    /** Unary operator */
    EUnary(op: EUnaryOp, expr: ElixirAST);
    
    /** Dot access for maps/structs */
    EField(target: ElixirAST, field: String);
    
    /** Bracket access [] */
    EAccess(target: ElixirAST, key: ElixirAST);
    
    /** Range operator .. or ... */
    ERange(start: ElixirAST, end: ElixirAST, exclusive: Bool);
    
    // ========================================================================
    // Literals
    // ========================================================================
    
    /** Atom literal */
    EAtom(value: String);
    
    /** String literal */
    EString(value: String);
    
    /** Integer literal */
    EInteger(value: Int);
    
    /** Float literal */
    EFloat(value: Float);
    
    /** Boolean literal */
    EBoolean(value: Bool);
    
    /** Nil literal */
    ENil;
    
    /** Charlist literal */
    ECharlist(value: String);
    
    // ========================================================================
    // Variables and Binding
    // ========================================================================
    
    /** Variable reference */
    EVar(name: String);
    
    /** Pin operator ^ */
    EPin(expr: ElixirAST);
    
    /** Underscore pattern _ */
    EUnderscore;
    
    // ========================================================================
    // Comprehensions
    // ========================================================================
    
    /** For comprehension */
    EFor(generators: Array<EGenerator>, filters: Array<ElixirAST>, 
         body: ElixirAST, into: Null<ElixirAST>, uniq: Bool);
    
    // ========================================================================
    // Anonymous Functions
    // ========================================================================
    
    /** Anonymous function fn -> end */
    EFn(clauses: Array<EFnClause>);
    
    /** Capture operator & */
    ECapture(expr: ElixirAST);
    
    // ========================================================================
    // Module Directives
    // ========================================================================
    
    /** Alias directive */
    EAlias(module: String, as: Null<String>);
    
    /** Import directive */
    EImport(module: String, only: Null<Array<EImportOption>>, except: Null<Array<EImportOption>>);
    
    /** Use macro */
    EUse(module: String, options: Array<ElixirAST>);
    
    /** Require directive */
    ERequire(module: String, as: Null<String>);
    
    // ========================================================================
    // Special Forms
    // ========================================================================
    
    /** Quote expression */
    EQuote(options: Array<ElixirAST>, expr: ElixirAST);
    
    /** Unquote expression */
    EUnquote(expr: ElixirAST);
    
    /** Unquote splicing */
    EUnquoteSplicing(expr: ElixirAST);
    
    /** Receive block for message passing */
    EReceive(clauses: Array<ECaseClause>, after: Null<EAfterClause>);
    
    /** Send message */
    ESend(target: ElixirAST, message: ElixirAST);
    
    // ========================================================================
    // Blocks and Grouping
    // ========================================================================
    
    /** Block of expressions */
    EBlock(expressions: Array<ElixirAST>);
    
    /** Parenthesized expression */
    EParen(expr: ElixirAST);
    
    /** Do-end block */
    EDo(body: Array<ElixirAST>);
    
    // ========================================================================
    // Documentation
    // ========================================================================
    
    /** @moduledoc documentation */
    EModuledoc(content: String);
    
    /** @doc documentation */
    EDoc(content: String);
    
    /** @spec type specification */
    ESpec(signature: String);
    
    /** @type type definition */
    ETypeDef(name: String, definition: String);
    
    // ========================================================================
    // Phoenix/Framework Specific (for transformation phase)
    // ========================================================================
    
    /** Sigil (like ~H for HEEx templates) */
    ESigil(type: String, content: String, modifiers: String);
    
    /** Attribute @ (for assigns in templates) */
    EAssign(name: String);
    
    /** Fragment for template composition */
    EFragment(tag: String, attributes: Array<EAttribute>, children: Array<ElixirAST>);
}

// ============================================================================
// Supporting Types
// ============================================================================

/**
 * Pattern types for pattern matching contexts
 */
enum EPattern {
    /** Variable pattern */
    PVar(name: String);
    
    /** Literal pattern */
    PLiteral(value: ElixirAST);
    
    /** Tuple pattern */
    PTuple(elements: Array<EPattern>);
    
    /** List pattern */
    PList(elements: Array<EPattern>);
    
    /** Cons pattern [head | tail] */
    PCons(head: EPattern, tail: EPattern);
    
    /** Map pattern */
    PMap(pairs: Array<{key: ElixirAST, value: EPattern}>);
    
    /** Struct pattern */
    PStruct(module: String, fields: Array<{key: String, value: EPattern}>);
    
    /** Pin pattern ^variable */
    PPin(pattern: EPattern);
    
    /** Underscore/wildcard pattern */
    PWildcard;
    
    /** Alias pattern (var = pattern) */
    PAlias(var: String, pattern: EPattern);
    
    /** Binary pattern */
    PBinary(segments: Array<PBinarySegment>);
}

/**
 * Case clause for case/receive expressions
 */
typedef ECaseClause = {
    pattern: EPattern,
    ?guard: ElixirAST,
    body: ElixirAST
}

/**
 * Cond clause for cond expressions
 */
typedef ECondClause = {
    condition: ElixirAST,
    body: ElixirAST
}

/**
 * With clause for with expressions
 */
typedef EWithClause = {
    pattern: EPattern,
    expr: ElixirAST
}

/**
 * Function clause for anonymous functions
 */
typedef EFnClause = {
    args: Array<EPattern>,
    ?guard: ElixirAST,
    body: ElixirAST
}

/**
 * Rescue clause for try expressions
 */
typedef ERescueClause = {
    pattern: EPattern,
    ?var: String,
    body: ElixirAST
}

/**
 * Catch clause for try expressions
 */
typedef ECatchClause = {
    kind: ECatchKind,
    pattern: EPattern,
    body: ElixirAST
}

/**
 * After clause for receive expressions
 */
typedef EAfterClause = {
    timeout: ElixirAST,
    body: ElixirAST
}

/**
 * Generator for comprehensions
 */
typedef EGenerator = {
    pattern: EPattern,
    expr: ElixirAST
}

/**
 * Module attribute
 */
typedef EAttribute = {
    name: String,
    value: ElixirAST
}

/**
 * Map pair
 */
typedef EMapPair = {
    key: ElixirAST,
    value: ElixirAST
}

/**
 * Struct field
 */
typedef EStructField = {
    key: String,
    value: ElixirAST
}

/**
 * Keyword pair
 */
typedef EKeywordPair = {
    key: String,
    value: ElixirAST
}

/**
 * Binary segment for binary patterns
 */
typedef EBinarySegment = {
    value: ElixirAST,
    ?size: ElixirAST,
    ?type: String,
    ?modifiers: Array<String>
}

/**
 * Binary pattern segment
 */
typedef PBinarySegment = {
    pattern: EPattern,
    ?size: ElixirAST,
    ?type: String,
    ?modifiers: Array<String>
}

/**
 * Import option for import directive
 */
typedef EImportOption = {
    name: String,
    arity: Int
}

/**
 * Binary operators
 */
enum EBinaryOp {
    // Arithmetic
    Add;        // +
    Subtract;   // -
    Multiply;   // *
    Divide;     // /
    Remainder;  // rem
    Power;      // **
    
    // Comparison
    Equal;      // ==
    NotEqual;   // !=
    StrictEqual;    // ===
    StrictNotEqual; // !==
    Less;       // <
    Greater;    // >
    LessEqual;  // <=
    GreaterEqual; // >=
    
    // Logical
    And;        // and
    Or;         // or
    AndAlso;    // &&
    OrElse;     // ||
    
    // Binary
    BitwiseAnd; // &&&
    BitwiseOr;  // |||
    BitwiseXor; // ^^^
    ShiftLeft;  // <<<
    ShiftRight; // >>>
    
    // List
    Concat;     // ++
    Subtract;   // --
    In;         // in
    
    // String
    StringConcat; // <>
    
    // Other
    Match;      // =
    Pipe;       // |>
    TypeCheck;  // ::
    When;       // when (guards)
}

/**
 * Unary operators
 */
enum EUnaryOp {
    Not;        // not
    Negate;     // -
    Positive;   // +
    BitwiseNot; // ~~~
    Bang;       // !
}

/**
 * Catch kinds for try-catch
 */
enum ECatchKind {
    Error;
    Exit;
    Throw;
    Any;
}

// ============================================================================
// Context Types
// ============================================================================

/**
 * Phoenix-specific context for LiveView, Router, etc.
 */
enum PhoenixContext {
    LiveView;
    LiveComponent;
    Controller;
    Router;
    Channel;
    Endpoint;
    None;
}

/**
 * Ecto-specific context for schemas, queries, etc.
 */
enum EctoContext {
    Schema;
    Query;
    Changeset;
    Repo;
    Migration;
    None;
}

/**
 * Access pattern hints for optimization
 */
enum AccessPattern {
    Sequential;
    Random;
    WriteOnly;
    ReadOnly;
    ReadWrite;
}

// ============================================================================
// Main AST Type with Metadata
// ============================================================================

/**
 * AST node with metadata for context and optimization
 */
typedef ElixirAST = {
    /** The actual AST node */
    def: ElixirASTDef,
    
    /** Rich metadata for transformation and optimization */
    metadata: ElixirMetadata,
    
    /** Source position for error reporting */
    ?pos: Position
}

/**
 * Comprehensive metadata structure for AST nodes
 */
typedef ElixirMetadata = {
    // Source Information
    ?sourceExpr: TypedExpr;        // Original Haxe expression
    ?sourceLine: Int;               // Line number in Haxe source
    ?sourceFile: String;            // Source file path
    
    // Type Information
    ?type: Type;                   // Haxe type information
    ?elixirType: String;           // Inferred Elixir type
    
    // Semantic Information
    ?purity: Bool;                 // Is expression pure?
    ?tailPosition: Bool;           // Is in tail position?
    ?async: Bool;                  // Is async operation?
    
    // Transformation Hints
    ?requiresReturn: Bool;         // Needs explicit return value
    ?requiresTempVar: Bool;        // Needs temporary variable
    ?inPipeline: Bool;            // Part of pipe chain
    ?inComprehension: Bool;       // Inside for comprehension
    ?inGuard: Bool;               // Inside guard clause
    
    // Phoenix/Framework Specific
    ?phoenixContext: PhoenixContext;  // LiveView, Router, etc.
    ?ectoContext: EctoContext;        // Schema, Query, etc.
    
    // Optimization Hints
    ?canInline: Bool;             // Can be inlined
    ?isConstant: Bool;            // Compile-time constant
    ?accessPattern: AccessPattern; // How value is accessed
    ?sideEffects: Bool;           // Has side effects
    
    // User Annotations
    ?annotations: Array<String>;   // @:native, @:inline, etc.
    ?documentation: String;        // Doc comments
    
    // Variable Context
    ?variableScope: String;        // Current scope identifier
    ?capturedVars: Array<String>; // Variables captured by closure
    
    // Error Handling
    ?canRaise: Bool;              // Can raise exceptions
    ?errorContext: String;        // Error handling context
}

// ============================================================================
// Utility Functions (to be implemented by users of this AST)
// ============================================================================

/**
 * Create an empty metadata object
 */
inline function emptyMetadata(): ElixirMetadata {
    return {};
}

/**
 * Create an AST node with empty metadata
 */
inline function makeAST(def: ElixirASTDef, ?pos: Position): ElixirAST {
    return {
        def: def,
        metadata: emptyMetadata(),
        pos: pos
    };
}

/**
 * Create an AST node with specific metadata
 */
inline function makeASTWithMeta(def: ElixirASTDef, meta: ElixirMetadata, ?pos: Position): ElixirAST {
    return {
        def: def,
        metadata: meta,
        pos: pos
    };
}

#end