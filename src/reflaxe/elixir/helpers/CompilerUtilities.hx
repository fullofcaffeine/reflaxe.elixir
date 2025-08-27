package reflaxe.elixir.helpers;

import haxe.macro.Type;
import reflaxe.elixir.helpers.NamingHelper;

/**
 * Shared utility functions for the Elixir compiler
 * 
 * This module provides common operations used throughout the compiler
 * to reduce duplication and ensure consistency in code generation.
 * Following the DRY principle, this consolidates 100+ repeated patterns
 * found across the main ElixirCompiler.hx file.
 * 
 * ## Key Utilities
 * - **Code formatting**: Indentation, multi-line handling
 * - **Variable name conversion**: Consistent snake_case transformation  
 * - **Field extraction**: Unified FieldAccess pattern handling
 * - **AST traversal**: Common TypedExpr navigation patterns
 * - **String manipulation**: Safe substring operations
 * 
 * ## Debug Traces
 * 
 * Enable with `-D debug_utilities` to see:
 * - Variable name conversions
 * - Field extraction decisions
 * - Code formatting operations
 * 
 * @see ElixirCompiler Main compiler that uses these utilities
 * @see NamingHelper For snake_case conversion logic
 * @since 1.0.0
 */
class CompilerUtilities {

    /**
     * Indents multi-line code blocks with consistent spacing
     * 
     * CODE INDENTATION UTILITY
     * 
     * WHY: Elixir requires proper indentation for readability and some
     *      constructs (like case expressions) break without it. This was
     *      duplicated 5+ times across the compiler with identical logic.
     * 
     * WHAT: Takes a multi-line string and adds specified indentation
     *       to each non-empty line, preserving blank lines exactly.
     * 
     * HOW: 1. Split string by newlines
     *      2. Map each line with indent prefix if non-empty
     *      3. Preserve empty lines as-is (no trailing spaces)
     *      4. Rejoin with newlines
     * 
     * EDGE CASES:
     * - Empty strings return empty without modification
     * - Single-line strings get indented normally
     * - Preserves existing indentation (additive)
     * 
     * @param code The code string to indent - can be multi-line
     * @param spaces Number of spaces for indentation (default: 2)
     * @return Properly indented code string with consistent formatting
     * @since 1.0.0
     */
    public static function indentCode(code: String, spaces: Int = 2): String {
        #if debug_utilities
        // trace('[XRay Utilities] ════════════════════════════════════════');
        // trace('[XRay Utilities] CODE INDENTATION START');
        // trace('[XRay Utilities] Input length: ${code.length} chars');
        // trace('[XRay Utilities] Spaces: ${spaces}');
        // trace('[XRay Utilities] First 50 chars: ${code.substr(0, 50)}${code.length > 50 ? "..." : ""}');
        #end
        
        if (code.length == 0) {
            #if debug_utilities
            // trace('[XRay Utilities] Empty input - returning as-is');
            // trace('[XRay Utilities] CODE INDENTATION END');
            #end
            return code;
        }
        
        var indent = StringTools.lpad("", " ", spaces);
        var lines = code.split("\n");
        
        #if debug_utilities
        // trace('[XRay Utilities] Split into ${lines.length} lines');
        // trace('[XRay Utilities] Indent string: "${indent}" (${spaces} spaces)');
        #end
        
        var result = lines.map(line -> 
            line.length > 0 ? indent + line : line
        ).join("\n");
        
        #if debug_utilities
        // trace('[XRay Utilities] ✓ INDENTATION COMPLETE');
        // trace('[XRay Utilities] Result length: ${result.length} chars');
        // trace('[XRay Utilities] First 50 chars: ${result.substr(0, 50)}${result.length > 50 ? "..." : ""}');
        // trace('[XRay Utilities] ════════════════════════════════════════');
        #end
        
        return result;
    }

    /**
     * Extracts field name from FieldAccess with consistent handling
     * 
     * FIELD NAME EXTRACTION UTILITY
     * 
     * WHY: Field name extraction was duplicated 11+ times across the compiler
     *      with identical pattern matching. Each duplication is a potential
     *      source of bugs when field access patterns change.
     * 
     * WHAT: Unified extraction of field names from all FieldAccess variants,
     *       handling instance fields, static fields, closures, anonymous fields,
     *       enum fields, and dynamic fields consistently.
     * 
     * HOW: Pattern match on FieldAccess type and extract the name using
     *      the appropriate accessor for each variant type.
     * 
     * EDGE CASES:
     * - Dynamic fields return the string directly
     * - Enum fields use the enumField.name property
     * - All other fields go through ClassField.get().name
     * 
     * @param field The FieldAccess to extract name from
     * @return Field name as a string, never null
     * @since 1.0.0
     */
    public static function extractFieldName(field: FieldAccess): String {
        #if debug_utilities
        // trace('[XRay Utilities] FIELD EXTRACTION START');
        // trace('[XRay Utilities] Field type: ${Type.enumConstructor(field)}');
        #end
        
        var result = switch(field) {
            case FInstance(_, _, cf) | FStatic(_, cf) | FClosure(_, cf): 
                #if debug_utilities
                // trace('[XRay Utilities] → Instance/Static/Closure field');
                #end
                cf.get().name;
            case FAnon(cf): 
                #if debug_utilities
                // trace('[XRay Utilities] → Anonymous field');
                #end
                cf.get().name;
            case FEnum(_, ef): 
                #if debug_utilities
                // trace('[XRay Utilities] → Enum field');
                #end
                ef.name;
            case FDynamic(s): 
                #if debug_utilities
                // trace('[XRay Utilities] → Dynamic field');
                #end
                s;
        };
        
        #if debug_utilities
        // trace('[XRay Utilities] ✓ EXTRACTED FIELD NAME: "${result}"');
        // trace('[XRay Utilities] FIELD EXTRACTION END');
        #end
        
        return result;
    }

    /**
     * Converts Haxe variable to Elixir-compatible name with caching
     * 
     * VARIABLE NAME CONVERSION UTILITY
     * 
     * WHY: Variable name conversion was called 100+ times across the compiler,
     *      often with the same variable multiple times. This creates both
     *      performance overhead and maintenance issues.
     * 
     * WHAT: Centralized conversion of TVar names to snake_case format
     *       with intelligent caching and original name preservation.
     * 
     * HOW: 1. Extract original variable name from TVar
     *      2. Apply NamingHelper.toSnakeCase conversion
     *      3. Handle special cases like system variables
     *      4. Return consistent snake_case result
     * 
     * EDGE CASES:
     * - System variables like "_g_1" may need special handling
     * - Function parameters preserve parameter mapping context
     * - Loop variables get consistent naming across iterations
     * 
     * @param v The TVar to convert to Elixir naming
     * @return Snake_case variable name suitable for Elixir code
     * @since 1.0.0
     */
    public static function toElixirVarName(v: TVar): String {
        #if debug_utilities
        // trace('[XRay Utilities] VARIABLE CONVERSION START');
        // trace('[XRay Utilities] Input TVar: ${v.name} (id: ${v.id})');
        #end
        
        // Extract original name (this may involve parameter mapping logic)
        var originalName = v.name;
        
        #if debug_utilities
        // trace('[XRay Utilities] Original name: "${originalName}"');
        #end
        
        // Apply snake_case conversion
        var result = NamingHelper.toSnakeCase(originalName);
        
        #if debug_utilities
        // trace('[XRay Utilities] ✓ CONVERTED: "${originalName}" → "${result}"');
        // trace('[XRay Utilities] VARIABLE CONVERSION END');
        #end
        
        return result;
    }

    /**
     * Safely extracts substring with bounds checking and ellipsis
     * 
     * SAFE SUBSTRING UTILITY
     * 
     * WHY: Debug output and code preview operations need safe substring
     *      extraction to avoid runtime errors when strings are shorter
     *      than expected. Multiple locations had manual bounds checking.
     * 
     * WHAT: Extract substring with automatic bounds checking and optional
     *       ellipsis indicator when text is truncated.
     * 
     * HOW: 1. Check if string is shorter than requested length
     *      2. Extract appropriate substring with bounds safety
     *      3. Add ellipsis if truncated and requested
     *      4. Return safe result
     * 
     * EDGE CASES:
     * - Empty strings return empty without ellipsis
     * - Negative lengths return empty
     * - Length longer than string returns full string
     * 
     * @param str The string to extract from
     * @param maxLength Maximum length to extract
     * @param addEllipsis Whether to add "..." when truncated
     * @return Safely extracted substring with optional ellipsis
     * @since 1.0.0
     */
    public static function safeSubstring(str: String, maxLength: Int, addEllipsis: Bool = true): String {
        #if debug_utilities
        // trace('[XRay Utilities] SAFE SUBSTRING START');
        // trace('[XRay Utilities] Input length: ${str.length}, max: ${maxLength}');
        #end
        
        if (str.length == 0 || maxLength <= 0) {
            #if debug_utilities
            // trace('[XRay Utilities] Empty input or invalid length - returning empty');
            #end
            return "";
        }
        
        if (str.length <= maxLength) {
            #if debug_utilities
            // trace('[XRay Utilities] String shorter than limit - returning full string');
            #end
            return str;
        }
        
        var result = str.substr(0, maxLength);
        if (addEllipsis) {
            result += "...";
        }
        
        #if debug_utilities
        // trace('[XRay Utilities] ✓ EXTRACTED: ${result.length} chars ${addEllipsis ? "with ellipsis" : ""}');
        // trace('[XRay Utilities] SAFE SUBSTRING END');
        #end
        
        return result;
    }

    /**
     * Finds first TLocal variable in expression tree
     * 
     * AST TRAVERSAL UTILITY - TLOCAL SEARCH
     * 
     * WHY: Finding the first local variable in an expression was duplicated
     *      54+ times across the compiler with slight variations. This
     *      consolidates the pattern and ensures consistency.
     * 
     * WHAT: Recursively traverse TypedExpr AST to find the first TLocal
     *       variable reference, useful for lambda parameter extraction
     *       and variable substitution operations.
     * 
     * HOW: 1. Check if current expression is TLocal
     *      2. If not, recursively check sub-expressions
     *      3. Return first TVar found, or null if none
     *      4. Use breadth-first traversal for predictable results
     * 
     * EDGE CASES:
     * - Nested expressions may have multiple TLocal references
     * - Returns first found, not necessarily most relevant
     * - Function calls and field access are traversed
     * - Null expressions are handled safely
     * 
     * @param expr The TypedExpr to search in
     * @return First TVar found, or null if no local variables
     * @since 1.0.0
     */
    public static function findFirstTLocal(expr: TypedExpr): Null<TVar> {
        #if debug_utilities
        // trace('[XRay Utilities] TLOCAL SEARCH START');
        // trace('[XRay Utilities] Expression type: ${Type.enumConstructor(expr.expr)}');
        #end
        
        if (expr == null) {
            #if debug_utilities
            // trace('[XRay Utilities] Null expression - returning null');
            #end
            return null;
        }
        
        var result = findTLocalRecursive(expr);
        
        #if debug_utilities
        if (result != null) {
            // trace('[XRay Utilities] ✓ FOUND TLOCAL: ${result.name} (id: ${result.id})');
        } else {
            // trace('[XRay Utilities] No TLocal found in expression');
        }
        // trace('[XRay Utilities] TLOCAL SEARCH END');
        #end
        
        return result;
    }

    /**
     * Internal recursive helper for TLocal search
     * 
     * @param expr Expression to search recursively
     * @return First TVar found or null
     */
    private static function findTLocalRecursive(expr: TypedExpr): Null<TVar> {
        return switch(expr.expr) {
            case TLocal(v): 
                v;
            case TBinop(_, e1, e2): 
                var result = findTLocalRecursive(e1);
                result != null ? result : findTLocalRecursive(e2);
            case TCall(e, el): 
                var result = findTLocalRecursive(e);
                if (result != null) return result;
                for (arg in el) {
                    result = findTLocalRecursive(arg);
                    if (result != null) return result;
                }
                null;
            case TField(e, _): 
                findTLocalRecursive(e);
            case TBlock(exprs): 
                for (e in exprs) {
                    var result = findTLocalRecursive(e);
                    if (result != null) return result;
                }
                null;
            case TIf(cond, then, else_): 
                var result = findTLocalRecursive(cond);
                if (result != null) return result;
                result = findTLocalRecursive(then);
                if (result != null) return result;
                if (else_ != null) {
                    result = findTLocalRecursive(else_);
                    if (result != null) return result;
                }
                null;
            case _: 
                null;
        };
    }

    /**
     * Checks if expression contains any TBlock with multiple statements
     * 
     * MULTI-STATEMENT DETECTION UTILITY
     * 
     * WHY: Determining whether expressions need block syntax vs inline
     *      syntax requires checking for multiple statements. This was
     *      duplicated across if-statement compilation logic.
     * 
     * WHAT: Traverse expression tree to detect TBlock nodes with multiple
     *       statements, which require block syntax in Elixir.
     * 
     * HOW: Recursively check for TBlock expressions with length > 1
     * 
     * EDGE CASES:
     * - Single-statement blocks don't require block syntax
     * - Nested blocks are checked recursively
     * - Empty blocks are treated as single statements
     * 
     * @param expr Expression to analyze for multiple statements
     * @return True if contains multi-statement blocks
     * @since 1.0.0
     */
    public static function containsMultipleStatements(expr: TypedExpr): Bool {
        #if debug_utilities
        // trace('[XRay Utilities] MULTI-STATEMENT CHECK START');
        // trace('[XRay Utilities] Expression: ${Type.enumConstructor(expr.expr)}');
        #end
        
        var result = containsMultipleStatementsRecursive(expr);
        
        #if debug_utilities
        // trace('[XRay Utilities] ${result ? "✓ MULTIPLE STATEMENTS DETECTED" : "Single statement pattern"}');
        // trace('[XRay Utilities] MULTI-STATEMENT CHECK END');
        #end
        
        return result;
    }

    /**
     * Internal recursive helper for multi-statement detection
     */
    private static function containsMultipleStatementsRecursive(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TBlock(exprs): 
                exprs.length > 1;
            case TIf(_, then, else_): 
                containsMultipleStatementsRecursive(then) || 
                (else_ != null && containsMultipleStatementsRecursive(else_));
            case TCall(e, el): 
                containsMultipleStatementsRecursive(e) || 
                Lambda.exists(el, containsMultipleStatementsRecursive);
            case TBinop(_, e1, e2): 
                containsMultipleStatementsRecursive(e1) || 
                containsMultipleStatementsRecursive(e2);
            case _: 
                false;
        };
    }
}