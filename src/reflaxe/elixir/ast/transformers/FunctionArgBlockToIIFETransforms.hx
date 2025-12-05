package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FunctionArgBlockToIIFETransforms
 *
 * WHAT
 * - Ensures any multi-statement block in expression positions requiring single
 *   expressions is converted to an immediately-invoked anonymous function (IIFE).
 *
 * WHY
 * - Elixir requires single expressions in many contexts: function arguments,
 *   list elements, map/struct values, keyword list values, string interpolations.
 * - Raw multi-statement blocks in these positions lead to syntax errors.
 * - Wrapping as an IIFE is idiomatic and preserves semantics.
 * - CRITICAL: Creating IIFEs at AST level (not string level in printer) allows
 *   cleanup passes (removeRedundantNilInitPass, DropTempNilAssignTransforms,
 *   EFnTempChainSimplifyTransforms) to see and optimize the IIFE bodies.
 *
 * HOW
 * - Walk all relevant nodes and wrap multi-statement blocks:
 *   - ECall/ERemoteCall arguments
 *   - EList elements
 *   - EMap values
 *   - EStruct field values
 *   - EStructUpdate field values
 *   - EKeywordList values
 * - Creates: (fn -> <block> end).() as ECall(EFn([{body: block}]), "", [])
 */
class FunctionArgBlockToIIFETransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECall(target, name, args):
                    var newArgs = [];
                    for (a in args) if (shouldWrap(a)) {
                        #if debug_iife
                        trace('[FunctionArgBlockToIIFE] wrapping arg for ' + (name == null ? '<anon>' : name));
                        #end
                        newArgs.push(makeIIFE(unwrapParens(a)));
                    } else newArgs.push(a);
                    if (newArgs != args) makeAST(ECall(target, name, newArgs)) else n;
                case ERemoteCall(mod, fnName, argsList):
                    var rewrittenArgs = [];
                    for (argNode in argsList) if (shouldWrap(argNode)) {
                        #if debug_iife
                        trace('[FunctionArgBlockToIIFE] wrapping arg for remote ' + fnName);
                        #end
                        rewrittenArgs.push(makeIIFE(unwrapParens(argNode)));
                    } else rewrittenArgs.push(argNode);
                    if (rewrittenArgs != argsList) makeAST(ERemoteCall(mod, fnName, rewrittenArgs)) else n;

                // EList - wrap multi-statement elements
                case EList(elements):
                    var changed = false;
                    var newElements = [];
                    for (el in elements) {
                        if (shouldWrap(el)) {
                            #if debug_iife
                            trace('[FunctionArgBlockToIIFE] wrapping list element');
                            #end
                            newElements.push(makeIIFE(unwrapParens(el)));
                            changed = true;
                        } else {
                            newElements.push(el);
                        }
                    }
                    if (changed) makeAST(EList(newElements)) else n;

                // EMap - wrap multi-statement values
                case EMap(pairs):
                    var changed = false;
                    var newPairs = [];
                    for (p in pairs) {
                        if (shouldWrap(p.value)) {
                            #if debug_iife
                            trace('[FunctionArgBlockToIIFE] wrapping map value');
                            #end
                            newPairs.push({key: p.key, value: makeIIFE(unwrapParens(p.value))});
                            changed = true;
                        } else {
                            newPairs.push(p);
                        }
                    }
                    if (changed) makeAST(EMap(newPairs)) else n;

                // EStruct - wrap multi-statement field values
                case EStruct(module, fields):
                    var changed = false;
                    var newFields = [];
                    for (f in fields) {
                        if (shouldWrap(f.value)) {
                            #if debug_iife
                            trace('[FunctionArgBlockToIIFE] wrapping struct field value');
                            #end
                            newFields.push({key: f.key, value: makeIIFE(unwrapParens(f.value))});
                            changed = true;
                        } else {
                            newFields.push(f);
                        }
                    }
                    if (changed) makeAST(EStruct(module, newFields)) else n;

                // EStructUpdate - wrap multi-statement field values
                case EStructUpdate(struct, fields):
                    var changed = false;
                    var newFields = [];
                    for (f in fields) {
                        if (shouldWrap(f.value)) {
                            #if debug_iife
                            trace('[FunctionArgBlockToIIFE] wrapping struct update field value');
                            #end
                            newFields.push({key: f.key, value: makeIIFE(unwrapParens(f.value))});
                            changed = true;
                        } else {
                            newFields.push(f);
                        }
                    }
                    if (changed) makeAST(EStructUpdate(struct, newFields)) else n;

                // EKeywordList - wrap multi-statement values
                case EKeywordList(pairs):
                    var changed = false;
                    var newPairs = [];
                    for (p in pairs) {
                        if (shouldWrap(p.value)) {
                            #if debug_iife
                            trace('[FunctionArgBlockToIIFE] wrapping keyword list value');
                            #end
                            newPairs.push({key: p.key, value: makeIIFE(unwrapParens(p.value))});
                            changed = true;
                        } else {
                            newPairs.push(p);
                        }
                    }
                    if (changed) makeAST(EKeywordList(newPairs)) else n;

                default:
                    n;
            }
        });
    }

    static inline function unwrapParens(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case EParen(inner): inner;
            default: e;
        }
    }

    static inline function isNumericSentinel(e: ElixirAST): Bool {
        return switch (e.def) {
            case EInteger(v) if (v == 0 || v == 1): true;
            case EFloat(f) if (f == 0.0): true;
            default: false;
        }
    }

    static inline function shouldWrap(a: ElixirAST): Bool {
        function needsWrapFor(sts:Array<ElixirAST>):Bool {
            if (sts == null) return false;
            // Ignore bare numeric sentinels often emitted by earlier passes
            var filtered = [];
            for (s in sts) if (!isNumericSentinel(s)) filtered.push(s);
            // If any top-level element is already an anonymous function, don't wrap
            for (s in filtered) switch (s.def) { case EFn(_): return false; default: }
            // Otherwise, wrap only if there are multiple meaningful statements
            return filtered.length > 1;
        }

        return switch (a.def) {
            case EBlock(sts): needsWrapFor(sts);
            case EDo(statements): needsWrapFor(statements);
            case EParen(inner):
                switch (inner.def) {
                    case EBlock(es): needsWrapFor(es);
                    case EDo(exprs): needsWrapFor(exprs);
                    default: false;
                }
            default: false;
        }
    }

    static inline function makeIIFE(block: ElixirAST): ElixirAST {
        return makeAST(ECall(makeAST(EFn([{ args: [], guard: null, body: block }])), "", []));
    }
}

#end
