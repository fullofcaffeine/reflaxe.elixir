package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexAssignsBindRepairTransforms
 *
 * WHAT
 * - In render/1, repair wildcard assignments of Phoenix.Component.assign/2 to
 *   bind to the "assigns" variable so that ~H can use @content (or other assigns).
 *
 * WHY
 * - Late hygiene may convert `assigns = Phoenix.Component.assign(assigns, map)`
 *   into `_ = Phoenix.Component.assign(assigns, map)` when the local "assigns"
 *   variable is not referenced textually after injection. HEEx relies on assigns
 *   being updated; wildcard discards the new map, leading to KeyError at runtime.
 *
 * HOW
 * - Part A (bind repair): Targets only functions named "render". Looks for assignments
 *   where LHS is a wildcard (`_`) and RHS is Phoenix.Component.assign(first, second).
 *   Rewrites LHS to bind the first argument variable name when it is a simple variable.
 *   Supports both EMatch(PWildcard, ...) and EBinary(Match, EVar("_"), ...).
 * - Part B (inline captured content): If the function constructs a string literal
 *   `content`, assigns it into assigns, then renders `~H` with
 *   `Phoenix.HTML.raw(@content)`, replace the ~H body with the literal HTML and
 *   drop the scaffolding lines. This produces a proper ~H template tree.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HeexAssignsBindRepairTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "render"):
                    var fixed = fixBody(body);
                    var inlined = inlineCapturedContent(fixed);
                    makeASTWithMeta(EDef(name, args, guards, inlined), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function fixBody(body: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                // _ = Phoenix.Component.assign(first, second)
                case EBinary(Match, {def: EVar(lv)} , { def: ERemoteCall({def: EVar(mod)}, "assign", [firstArg, secondArg]) }) if (lv == "_" && mod == "Phoenix.Component"):
                    switch (firstArg.def) {
                        case EVar(firstName):
                            makeASTWithMeta(EBinary(Match, makeAST(EVar(firstName)), makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [firstArg, secondArg]))), x.metadata, x.pos);
                        default:
                            x;
                    }
                // _ = ... (pattern form)
                case EMatch(PWildcard, { def: ERemoteCall({def: EVar(mod2)}, "assign", [fa2, sa2]) }) if (mod2 == "Phoenix.Component"):
                    switch (fa2.def) {
                        case EVar(firstName2):
                            makeASTWithMeta(EMatch(PVar(firstName2), makeAST(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", [fa2, sa2]))), x.metadata, x.pos);
                        default:
                            x;
                    }
                default:
                    x;
            }
        });
    }

    static function inlineCapturedContent(body: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts):
                    var html: Null<String> = null;
                    var contentIdx = -1;
                    var assignsIdx = -1;
                    var sigilIdx = -1;
                    // Locate content = "..."
                    for (i in 0...stmts.length) {
                        switch (stmts[i].def) {
                            case EMatch(PVar(varName), rhs) if (varName == "content"):
                                switch (rhs.def) {
                                    case EString(s): html = s; contentIdx = i;
                                    case EParen(inner):
                                        switch (inner.def) {
                                            case EString(s2): html = s2; contentIdx = i;
                                            default:
                                        }
                                    default:
                                }
                            case EBinary(Match, _l, rhs2):
                                switch (rhs2.def) {
                                    case EString(s3): html = s3; contentIdx = i;
                                    case EParen(inner2):
                                        switch (inner2.def) {
                                            case EString(s4): html = s4; contentIdx = i;
                                            default:
                                        }
                                    default:
                                }
                            default:
                        }
                    }
                    if (html == null) return node;
                    // Optional assigns capture line
                    for (i in 0...stmts.length) {
                        switch (stmts[i].def) {
                            case EMatch(PVar(lhs), { def: ERemoteCall({def: EVar(mod)}, "assign", [_fa, _sa]) }) if (lhs == "assigns" && mod == "Phoenix.Component"):
                                assignsIdx = i;
                            case EBinary(Match, {def:EVar(lhs2)}, { def: ERemoteCall({def: EVar(mod2)}, "assign", [_fa2, _sa2]) }) if (lhs2 == "assigns" && mod2 == "Phoenix.Component"):
                                assignsIdx = i;
                            default:
                        }
                    }
                    // Find ~H containing Phoenix.HTML.raw(@content) or raw(content)
                    var parens = 0;
                    for (i in 0...stmts.length) {
                        var cur = stmts[i];
                        parens = 0;
                        for (k in 0...3) {
                            switch (cur.def) {
                                case EParen(inner): cur = inner; parens++;
                                default:
                            }
                        }
                        switch (cur.def) {
                            case ESigil(type, content, _m) if (type == "H"):
                                if (content.indexOf("Phoenix.HTML.raw(@content)") != -1 || content.indexOf("Phoenix.HTML.raw(content)") != -1) {
                                    sigilIdx = i; break;
                                }
                            default:
                        }
                    }
                    if (sigilIdx == -1) return node;
                    var out: Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        if (i == contentIdx) continue;
                        if (i == assignsIdx) continue;
                        if (i == sigilIdx) {
                            var rebuilt = makeAST(ESigil("H", html, ""));
                            switch (stmts[i].def) {
                                case EParen(_): rebuilt = makeAST(EParen(rebuilt));
                                default:
                            }
                            out.push(makeASTWithMeta(rebuilt.def, stmts[i].metadata, stmts[i].pos));
                        } else {
                            out.push(stmts[i]);
                        }
                    }
                    makeASTWithMeta(EBlock(out), node.metadata, node.pos);
                case EDo(stmts):
                    var html: Null<String> = null;
                    var contentIdx = -1;
                    var assignsIdx = -1;
                    var sigilIdx = -1;

                    // Locate content = "..."
                    for (i in 0...stmts.length) {
                        switch (stmts[i].def) {
                            case EMatch(PVar(varName), rhs) if (varName == "content"):
                                switch (rhs.def) {
                                    case EString(s): html = s; contentIdx = i;
                                    case EParen(inner):
                                        switch (inner.def) {
                                            case EString(s2): html = s2; contentIdx = i;
                                            default:
                                        }
                                    default:
                                }
                            case EBinary(Match, _l, rhs2):
                                switch (rhs2.def) {
                                    case EString(s3): html = s3; contentIdx = i;
                                    case EParen(inner2):
                                        switch (inner2.def) {
                                            case EString(s4): html = s4; contentIdx = i;
                                            default:
                                        }
                                    default:
                                }
                            default:
                        }
                    }
                    if (html == null) return node;

                    // Optional assigns capture line
                    for (i in 0...stmts.length) {
                        switch (stmts[i].def) {
                            case EMatch(PVar(lhs), { def: ERemoteCall({def: EVar(mod)}, "assign", [_fa, _sa]) }) if (lhs == "assigns" && mod == "Phoenix.Component"):
                                assignsIdx = i;
                            case EBinary(Match, {def:EVar(lhs2)}, { def: ERemoteCall({def: EVar(mod2)}, "assign", [_fa2, _sa2]) }) if (lhs2 == "assigns" && mod2 == "Phoenix.Component"):
                                assignsIdx = i;
                            default:
                        }
                    }

                    // Find ~H containing Phoenix.HTML.raw(@content) or raw(content)
                    var parens = 0;
                    for (i in 0...stmts.length) {
                        var cur = stmts[i];
                        parens = 0;
                        for (k in 0...2) {
                            switch (cur.def) {
                                case EParen(inner): cur = inner; parens++;
                                default:
                            }
                        }
                        switch (cur.def) {
                            case ESigil(type, content, _m) if (type == "H"):
                                if (content.indexOf("Phoenix.HTML.raw(@content)") != -1 || content.indexOf("Phoenix.HTML.raw(content)") != -1) {
                                    sigilIdx = i; break;
                                }
                            default:
                        }
                    }
                    if (sigilIdx == -1) return node;

                    var out: Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        if (i == contentIdx) continue;
                        if (i == assignsIdx) continue;
                        if (i == sigilIdx) {
                            var rebuilt = makeAST(ESigil("H", html, ""));
                            switch (stmts[i].def) {
                                case EParen(_): rebuilt = makeAST(EParen(rebuilt));
                                default:
                            }
                            out.push(makeASTWithMeta(rebuilt.def, stmts[i].metadata, stmts[i].pos));
                        } else {
                            out.push(stmts[i]);
                        }
                    }
                    makeASTWithMeta(EDo(out), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }
}

#end
