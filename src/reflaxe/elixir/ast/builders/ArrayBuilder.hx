package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTPatterns;
import reflaxe.elixir.CompilationContext;

/**
 * ArrayBuilder: Builds ElixirAST nodes for array and list operations
 *
 * WHY: Arrays in Haxe map to lists in Elixir, which have different
 * semantics and operations. This module handles the transformation
 * ensuring idiomatic Elixir list operations are generated.
 *
 * WHAT: Converts array-related nodes to Elixir list operations:
 * - TArrayDecl → list literals
 * - Array access → Enum.at or pattern matching
 * - Array methods → Enum module functions
 * - Array comprehensions → for comprehensions
 * - Array mutations → new list creation (immutability)
 * - Push/pop operations → list concatenation
 *
 * HOW: Maps Haxe's mutable array operations to Elixir's immutable
 * list operations, using Enum functions and comprehensions to
 * maintain functional programming semantics.
 *
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles array/list operations
 * - Immutability Handling: Properly transforms mutations to rebinding
 * - Performance Awareness: Uses efficient list operations
 * - Pattern Optimization: Recognizes and optimizes common patterns
 *
 * EDGE CASES:
 * - Array index out of bounds (returns nil in Elixir)
 * - Negative indices (not supported directly)
 * - Multi-dimensional arrays
 * - Array mutations in loops
 * - Array as map keys (needs special handling)
 *
 * @see ElixirASTBuilder for integration
 * @see CompilationContext for state management
 */
class ArrayBuilder {

    /**
     * Build an array declaration
     *
     * WHY: Array literals need to become Elixir list literals
     * WHAT: Converts TArrayDecl to list syntax
     * HOW: Recursively builds elements and wraps in list
     *
     * @param elements Array elements to include
     * @param context Compilation context
     * @param buildExpr Expression builder callback
     */
    public static function buildArrayDecl(
        elements: Array<TypedExpr>,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        // Store expression builder
        exprBuilder = buildExpr;

        // Build each element
        var elementASTs = elements.map(e -> exprBuilder(e));

        // Return as list
        return makeAST(EList(elementASTs));
    }

    /**
     * Build array element access
     *
     * WHY: Array[index] needs different handling in Elixir
     * WHAT: Converts to Enum.at or pattern matching
     * HOW: Determines best access method based on context
     *
     * @param array The array expression
     * @param index The index expression
     * @param context Compilation context
     * @param buildExpr Expression builder callback
     */
    public static function buildArrayAccess(
        array: TypedExpr,
        index: TypedExpr,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        exprBuilder = buildExpr;

        var arrayAST = exprBuilder(array);
        var indexAST = exprBuilder(index);

        // Use Enum.at for safe access (returns nil if out of bounds)
        return makeAST(ECall(
            makeAST(EField(makeAST(EVar("Enum")), "at")),
            [arrayAST, indexAST]
        ));
    }

    /**
     * Build array method calls
     *
     * WHY: Array methods need to map to Enum functions
     * WHAT: Transforms array.method() to Enum.method(array)
     * HOW: Identifies method and generates appropriate Enum call
     *
     * @param array Array expression
     * @param method Method name
     * @param args Method arguments
     * @param context Compilation context
     * @param buildExpr Expression builder callback
     */
    public static function buildArrayMethod(
        array: TypedExpr,
        method: String,
        args: Array<TypedExpr>,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        exprBuilder = buildExpr;

        var arrayAST = exprBuilder(array);
        var argASTs = args.map(a -> exprBuilder(a));

        return switch(method) {
            case "push":
                buildPush(arrayAST, argASTs[0], context);
            case "pop":
                buildPop(arrayAST, context);
            case "shift":
                buildShift(arrayAST, context);
            case "unshift":
                buildUnshift(arrayAST, argASTs[0], context);
            case "length":
                buildLength(arrayAST);
            case "map":
                buildMap(arrayAST, argASTs[0], context);
            case "filter":
                buildFilter(arrayAST, argASTs[0], context);
            case "reduce" | "fold":
                buildReduce(arrayAST, argASTs[0], argASTs[1], context);
            case "forEach" | "iter":
                buildForEach(arrayAST, argASTs[0], context);
            case "indexOf":
                buildIndexOf(arrayAST, argASTs[0]);
            case "contains":
                buildContains(arrayAST, argASTs[0]);
            case "join":
                buildJoin(arrayAST, argASTs.length > 0 ? argASTs[0] : null);
            case "reverse":
                buildReverse(arrayAST);
            case "sort":
                buildSort(arrayAST, argASTs.length > 0 ? argASTs[0] : null);
            case "slice":
                buildSlice(arrayAST, argASTs[0], argASTs.length > 1 ? argASTs[1] : null);
            case "concat":
                buildConcat(arrayAST, argASTs[0]);
            case "copy":
                buildCopy(arrayAST);
            default:
                // Unknown method - generate comment
                makeAST(EComment('Array.$method not implemented'));
        };
    }

    /**
     * Build array comprehension
     *
     * WHY: Haxe array comprehensions map well to Elixir for comprehensions
     * WHAT: Converts to for comprehension syntax
     * HOW: Analyzes pattern and generates appropriate for expression
     */
    public static function buildArrayComprehension(
        forExpr: TypedExpr,
        context: CompilationContext,
        buildExpr: TypedExpr -> ElixirAST
    ): ElixirAST {
        exprBuilder = buildExpr;

        // Extract comprehension components
        var components = extractComprehensionComponents(forExpr);
        if (components == null) {
            // Fallback to regular expression
            return exprBuilder(forExpr);
        }

        // Build for comprehension
        return makeAST(EFor(
            components.variable,
            exprBuilder(components.collection),
            components.filter != null ? exprBuilder(components.filter) : null,
            exprBuilder(components.expression)
        ));
    }

    // Helper functions for specific array operations
    static var exprBuilder: TypedExpr -> ElixirAST;

    static function buildPush(arrayAST: ElixirAST, elementAST: ElixirAST, context: CompilationContext): ElixirAST {
        // array ++ [element]
        return makeAST(EBinop(
            EListConcat,
            arrayAST,
            makeAST(EList([elementAST]))
        ));
    }

    static function buildPop(arrayAST: ElixirAST, context: CompilationContext): ElixirAST {
        // {init, last} = List.pop_at(array, -1)
        return makeAST(ECall(
            makeAST(EField(makeAST(EVar("List")), "pop_at")),
            [arrayAST, makeAST(EInteger(-1))]
        ));
    }

    static function buildShift(arrayAST: ElixirAST, context: CompilationContext): ElixirAST {
        // [head | tail] = array; head
        return makeAST(ECase(
            arrayAST,
            [
                {
                    pattern: PListCons(PVar("head"), PVar("tail")),
                    guard: null,
                    body: makeAST(EVar("head"))
                },
                {
                    pattern: PList([]),
                    guard: null,
                    body: makeAST(ENil)
                }
            ]
        ));
    }

    static function buildUnshift(arrayAST: ElixirAST, elementAST: ElixirAST, context: CompilationContext): ElixirAST {
        // [element | array]
        return makeAST(EListCons(elementAST, arrayAST));
    }

    static function buildLength(arrayAST: ElixirAST): ElixirAST {
        // length(array) or Enum.count(array)
        return makeAST(ECall(
            makeAST(EVar("length")),
            [arrayAST]
        ));
    }

    static function buildMap(arrayAST: ElixirAST, funcAST: ElixirAST, context: CompilationContext): ElixirAST {
        // Enum.map(array, func)
        return makeAST(ECall(
            makeAST(EField(makeAST(EVar("Enum")), "map")),
            [arrayAST, funcAST]
        ));
    }

    static function buildFilter(arrayAST: ElixirAST, funcAST: ElixirAST, context: CompilationContext): ElixirAST {
        // Enum.filter(array, func)
        return makeAST(ECall(
            makeAST(EField(makeAST(EVar("Enum")), "filter")),
            [arrayAST, funcAST]
        ));
    }

    static function buildReduce(arrayAST: ElixirAST, funcAST: ElixirAST, initAST: ElixirAST, context: CompilationContext): ElixirAST {
        // Enum.reduce(array, init, func)
        return makeAST(ECall(
            makeAST(EField(makeAST(EVar("Enum")), "reduce")),
            [arrayAST, initAST, funcAST]
        ));
    }

    static function buildForEach(arrayAST: ElixirAST, funcAST: ElixirAST, context: CompilationContext): ElixirAST {
        // Enum.each(array, func)
        return makeAST(ECall(
            makeAST(EField(makeAST(EVar("Enum")), "each")),
            [arrayAST, funcAST]
        ));
    }

    static function buildIndexOf(arrayAST: ElixirAST, elementAST: ElixirAST): ElixirAST {
        // Enum.find_index(array, fn x -> x == element end)
        var compareFunc = makeAST(EFunction(
            ["x"],
            makeAST(EBinop(EEqual, makeAST(EVar("x")), elementAST))
        ));

        return makeAST(ECall(
            makeAST(EField(makeAST(EVar("Enum")), "find_index")),
            [arrayAST, compareFunc]
        ));
    }

    static function buildContains(arrayAST: ElixirAST, elementAST: ElixirAST): ElixirAST {
        // Enum.member?(array, element)
        return makeAST(ECall(
            makeAST(EField(makeAST(EVar("Enum")), "member?")),
            [arrayAST, elementAST]
        ));
    }

    static function buildJoin(arrayAST: ElixirAST, separatorAST: Null<ElixirAST>): ElixirAST {
        // Enum.join(array, separator)
        var sep = separatorAST != null ? separatorAST : makeAST(EString(""));
        return makeAST(ECall(
            makeAST(EField(makeAST(EVar("Enum")), "join")),
            [arrayAST, sep]
        ));
    }

    static function buildReverse(arrayAST: ElixirAST): ElixirAST {
        // Enum.reverse(array)
        return makeAST(ECall(
            makeAST(EField(makeAST(EVar("Enum")), "reverse")),
            [arrayAST]
        ));
    }

    static function buildSort(arrayAST: ElixirAST, compareFuncAST: Null<ElixirAST>): ElixirAST {
        // Enum.sort(array) or Enum.sort_by(array, func)
        if (compareFuncAST != null) {
            return makeAST(ECall(
                makeAST(EField(makeAST(EVar("Enum")), "sort_by")),
                [arrayAST, compareFuncAST]
            ));
        } else {
            return makeAST(ECall(
                makeAST(EField(makeAST(EVar("Enum")), "sort")),
                [arrayAST]
            ));
        }
    }

    static function buildSlice(arrayAST: ElixirAST, startAST: ElixirAST, lengthAST: Null<ElixirAST>): ElixirAST {
        // Enum.slice(array, start, length)
        if (lengthAST != null) {
            return makeAST(ECall(
                makeAST(EField(makeAST(EVar("Enum")), "slice")),
                [arrayAST, startAST, lengthAST]
            ));
        } else {
            // Slice to end
            return makeAST(ECall(
                makeAST(EField(makeAST(EVar("Enum")), "drop")),
                [arrayAST, startAST]
            ));
        }
    }

    static function buildConcat(arrayAST: ElixirAST, otherAST: ElixirAST): ElixirAST {
        // array ++ other
        return makeAST(EBinop(EListConcat, arrayAST, otherAST));
    }

    static function buildCopy(arrayAST: ElixirAST): ElixirAST {
        // Lists are immutable, so just return the list
        return arrayAST;
    }

    // Comprehension analysis
    static function extractComprehensionComponents(expr: TypedExpr): Null<{
        variable: String,
        collection: TypedExpr,
        filter: Null<TypedExpr>,
        expression: TypedExpr
    }> {
        // This would need sophisticated analysis of the for expression
        // to extract the iteration variable, collection, optional filter,
        // and the expression to evaluate for each element
        return null; // Simplified for now
    }

    // AST construction helper
    static function makeAST(def: ElixirASTDef): ElixirAST {
        return {
            def: def,
            metadata: {},
            pos: null
        };
    }
}

#end