package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StringTransforms: String-related idiomatic transforms (interpolation and instance/string methods)
 *
 * WHAT
 * - stringInterpolationPass: Converts concatenation chains into idiomatic Elixir interpolation
 * - instanceMethodTransformPass: Rewrites instance method calls (e.g., StringBuf) to module functions
 * - stringMethodTransformPass: Normalizes string instance helpers when needed (currently unused in registry)
 *
 * WHY
 * - Elixir favors interpolation over concatenation for readability and performance semantics.
 * - Instance methods for core types are modeled as module functions in Elixir; aligning shapes
 *   keeps output idiomatic and predictable.
 *
 * HOW
 * - Each pass is a pure ElixirAST -> ElixirAST transform using ElixirASTTransformer.transformNode.
 * - Avoids app-specific names; operates strictly on structural patterns.
 *
 * CONTEXT
 * - Registered from ElixirASTTransformer as part of early/string-shaping passes.
 * - Runs before constant folding and loop variable restore (see registry ordering).
 */
@:nullSafety(Off)
class StringTransforms {
    /**
     * String interpolation pass - convert string concatenation to idiomatic interpolation
     *
     * WHY: Elixir's string interpolation #{} is more idiomatic and readable than concatenation
     * WHAT: Transforms EBinary(StringConcat, ...) chains into interpolated strings
     * HOW: Finds string concatenation chains and replaces them with interpolated strings
     *
     * NOTE: Custom traversal is used inside to avoid premature recursion reshaping the same node.
     */
    public static function stringInterpolationPass(ast: ElixirAST): ElixirAST {
        function transform(node: ElixirAST): ElixirAST {
            if (node == null) return null;

            switch (node.def) {
                case EBinary(StringConcat, l, r):
                    #if debug_string_interpolation
                    var fullNodeStr = ElixirASTPrinter.printAST(node);
                    trace('[StringInterpolation] Found concatenation pattern: ${fullNodeStr.substring(0, 200)}');
                    trace('[StringInterpolation] Left type: ${Type.enumConstructor(l.def)}');
                    trace('[StringInterpolation] Right type: ${Type.enumConstructor(r.def)}');
                    #end

                    var parts = [];
                    function collectParts(expr: ElixirAST) {
                        switch (expr.def) {
                            case EBinary(StringConcat, l, r):
                                collectParts(l);
                                collectParts(r);
                            case EString(s):
                                parts.push({ isString: true, value: s, expr: null });
                            default:
                                parts.push({ isString: false, value: null, expr: expr });
                        }
                    }
                    collectParts(node);

                    var hasNonString = false;
                    for (part in parts) if (!part.isString) { hasNonString = true; break; }

                    if (hasNonString && parts.length > 1) {
                        var result = '"';
                        for (i in 0...parts.length) {
                            var part = parts[i];
                            if (part.isString) {
                                var escaped = part.value;
                                escaped = escaped.split('\\').join('\\\\');
                                escaped = escaped.split('"').join('\\"');
                                escaped = escaped.split('#{').join('\\#{');
                                result += escaped;
                            } else {
                                var transformedExpr = transform(part.expr);
                                var exprToInterpolate = switch (transformedExpr.def) {
                                    case ECall(target, "to_string", []) if (target != null): target;
                                    default: transformedExpr;
                                };
                                result += '#{' + ElixirASTPrinter.printAST(exprToInterpolate) + '}';
                            }
                        }
                        result += '"';
                        return makeASTWithMeta(EString(result.substr(1, result.length - 2)), node.metadata, node.pos);
                    }

                    // No conversion; recurse and rebuild
                    var tl = transform(l);
                    var tr = transform(r);
                    return makeASTWithMeta(EBinary(StringConcat, tl, tr), node.metadata, node.pos);

                case EBlock(expressions):
                    return makeASTWithMeta(EBlock([for (e in expressions) transform(e)]), node.metadata, node.pos);

                case EBinary(op, left, right) if (op != StringConcat):
                    return makeASTWithMeta(EBinary(op, transform(left), transform(right)), node.metadata, node.pos);

                case ECall(target, method, args):
                    return makeASTWithMeta(ECall(target != null ? transform(target) : null, method, args.map(transform)), node.metadata, node.pos);

                case ERemoteCall(module, func, args):
                    return makeASTWithMeta(ERemoteCall(transform(module), func, args.map(transform)), node.metadata, node.pos);

                case EMatch(pattern, expr):
                    return makeASTWithMeta(EMatch(pattern, transform(expr)), node.metadata, node.pos);

                case EIf(condition, then_expr, else_expr):
                    return makeASTWithMeta(EIf(transform(condition), transform(then_expr), else_expr != null ? transform(else_expr) : null), node.metadata, node.pos);

                case EList(items):
                    return makeASTWithMeta(EList(items.map(transform)), node.metadata, node.pos);

                case ECase(expr, clauses):
                    #if debug_string_interpolation
                    trace('[StringInterpolation] Found ECase, transforming ${clauses.length} clauses');
                    #end
                    return makeASTWithMeta(ECase(transform(expr), clauses.map(clause -> {
                        var transformedBody = transform(clause.body);
                        {
                            pattern: clause.pattern,
                            guard: clause.guard != null ? transform(clause.guard) : null,
                            body: transformedBody
                        }
                    })), node.metadata, node.pos);

                case EParen(expr):
                    return makeASTWithMeta(EParen(transform(expr)), node.metadata, node.pos);

                default:
                    return node;
            }
        }
        return transform(ast);
    }

    /**
     * Instance method transformation: string/struct-like instance calls -> module/local functions
     */
    public static function instanceMethodTransformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case ECall({def: EField(target, field), metadata: fieldMeta, pos: fieldPos}, methodName, args):
                    if (methodName == "add" || methodName == "toString" || methodName == "to_string") {
                        var moduleName = switch (methodName) {
                            case "add": "StringBuf";
                            case "toString" | "to_string": "StringBuf";
                            default: null;
                        };
                        if (moduleName != null) {
                            var moduleRef = makeAST(EVar(moduleName));
                            var targetField = makeASTWithMeta(EField(target, field), fieldMeta, fieldPos);
                            var newArgs = [targetField].concat(args);
                            var functionName = switch (methodName) {
                                case "toString" | "to_string": "to_string";
                                default: methodName;
                            };
                            return makeASTWithMeta(ERemoteCall(moduleRef, functionName, newArgs), node.metadata, node.pos);
                        }
                    }
                    node;

                case ECall(target, methodName, args) if (target != null):
                    switch (target.def) {
                        case EVar(_):
                            if (methodName == "add" || methodName == "toString" || methodName == "to_string") {
                                var moduleRef = makeAST(EVar("StringBuf"));
                                var functionName = switch (methodName) {
                                    case "toString" | "to_string": "to_string";
                                    default: methodName;
                                };
                                return makeASTWithMeta(ERemoteCall(moduleRef, functionName, [target].concat(args)), node.metadata, node.pos);
                            } else if (methodName == "write_value" || methodName == "writeValue") {
                                var functionName = (methodName == "writeValue") ? "write_value" : methodName;
                                return makeASTWithMeta(ECall(null, functionName, [target].concat(args)), node.metadata, node.pos);
                            }
                        case EField(obj, field):
                            if (methodName == "write_value" || methodName == "writeValue") {
                                var functionName = (methodName == "writeValue") ? "write_value" : methodName;
                                var targetExpr = makeAST(EField(obj, field));
                                return makeASTWithMeta(ECall(null, functionName, [targetExpr].concat(args)), node.metadata, node.pos);
                            }
                        default:
                    }
                    node;

                default:
                    node;
            }
        });
    }

    /**
     * String method normalization (kept for completeness; registry disabled by default)
     */
    public static function stringMethodTransformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case ECall(target, methodName, args) if (target != null):
                    var stringMethod = switch (methodName) {
                        case "charAt" | "char_at": "at";
                        case "charCodeAt" | "char_code_at": "to_charlist";
                        case "toLowerCase" | "to_lower_case": "downcase";
                        case "toUpperCase" | "to_upper_case": "upcase";
                        case "startsWith" | "starts_with": "starts_with";
                        case "endsWith" | "ends_with": "ends_with";
                        case "trim": "trim";
                        case _: null;
                    };
                    if (stringMethod != null) {
                        var moduleRef = makeAST(EVar("String"));
                        return makeASTWithMeta(ERemoteCall(moduleRef, stringMethod, [target].concat(args)), node.metadata, node.pos);
                    } else node;
                default:
                    node;
            };
        });
    }
}

#end

