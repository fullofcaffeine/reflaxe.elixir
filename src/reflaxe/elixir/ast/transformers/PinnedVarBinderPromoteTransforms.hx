package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PinnedVarBinderPromoteTransforms
 *
 * WHAT
 * - Promote `_ = <literal>` to `name = <literal>` when a unique pinned variable `^(name)`
 *   is referenced later in the same block and `name` is undeclared at that point.
 *
 * WHY
 * - Earlier hygiene passes may aggressively discard a binder even if its value is
 *   used later as a pinned variable in Ecto or similar DSLs. This pass repairs the
 *   binder-to-use path in a shape- and usage-based manner (no app coupling).
 *
 * HOW
 * - For each def/defp body (EBlock/EDo):
 *   1) Collect declared variable names up to each statement.
 *   2) When encountering `_ = <literal>` (EMatch(PWildcard, rhs) or EBinary(Match, EUnderscore/_ , rhs)),
 *      look ahead for pinned variable usages `EPin(EVar(name))` or raw pattern `^(name)`.
 *   3) If exactly one candidate `name` is found and it is not declared before its first
 *      usage and not declared at the assignment site, rewrite the wildcard to `name`.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class PinnedVarBinderPromoteTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, processBody(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, processBody(body)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function processBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts): makeASTWithMeta(EBlock(processStmts(stmts)), body.metadata, body.pos);
            case EDo(stmts): makeASTWithMeta(EDo(processStmts(stmts)), body.metadata, body.pos);
            default: body;
        }
    }

    static inline function snakeCase(s:String):String {
        if (s == null || s.length == 0) return s;
        var out = new StringBuf();
        for (i in 0...s.length) {
            var ch = s.charAt(i);
            var isUpper = (ch.toUpperCase() == ch && ch.toLowerCase() != ch);
            if (isUpper && i > 0) out.add("_");
            out.add(ch.toLowerCase());
        }
        return out.toString();
    }

    static function collectPinnedCandidates(stmts:Array<ElixirAST>, startIdx:Int):Array<String> {
        var names = new Map<String,Bool>();
        function scan(n:ElixirAST):Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EPin(inner):
                    switch (inner.def) {
                        case EVar(v): names.set(v, true);
                        default:
                    }
                case ERaw(code) if (code != null):
                    // Extract simple ^(name) tokens conservatively
                    var i = 0;
                    while (true) {
                        var idx = code.indexOf("^(", i);
                        if (idx == -1) break;
                        var j = code.indexOf(")", idx + 2);
                        if (j == -1) break;
                        var candidate = code.substring(idx + 2, j);
                        // Basic identifier check
                        if (~/^[A-Za-z_][A-Za-z0-9_]*$/.match(candidate)) names.set(candidate, true);
                        i = j + 1;
                    }
                case EBlock(ss): for (s in ss) scan(s);
                case EDo(ss2): for (s in ss2) scan(s);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case EBinary(_, l, r): scan(l); scan(r);
                case EMatch(_, rhs): scan(rhs);
                case ECall(tgt, _, args2): if (tgt != null) scan(tgt); for (a in args2) scan(a);
                case ERemoteCall(tgt2, _, args3): scan(tgt2); for (a in args3) scan(a);
                case ECase(expr, cs): scan(expr); for (c in cs) scan(c.body);
                default:
            }
        }
        for (i in startIdx...stmts.length) scan(stmts[i]);
        return [for (k in names.keys()) k];
    }

    static function isLiteral(e: ElixirAST): Bool {
        return switch (e.def) {
            case EString(_) | EInteger(_) | EFloat(_) | EBoolean(_) | EAtom(_) | EList(_) | EMap(_) | ETuple(_): true;
            default: false;
        };
    }

    static function processStmts(stmts:Array<ElixirAST>):Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        // Track declarations as we go
        var declared = new Map<String,Bool>();
        function markDeclaredIn(n:ElixirAST):Void {
            switch (n.def) {
                case EMatch(PVar(nm), _): declared.set(nm, true);
                case EBinary(Match, left, _): switch (left.def) { case EVar(nm2): declared.set(nm2, true); default: }
                default:
            }
        }
        for (s in stmts) markDeclaredIn(s);
        for (i in 0...stmts.length) {
            var s = stmts[i];
            switch (s.def) {
                case EMatch(PWildcard, rhs) if (isLiteral(rhs)):
                    var candidates = collectPinnedCandidates(stmts, i + 1);
                    // Remove any already-declared names at or before this point
                    var filtered = [];
                    for (c in candidates) if (!declared.exists(c)) filtered.push(c);
                    if (filtered.length == 1) {
                        var nm = filtered[0];
                        out.push(makeASTWithMeta(EMatch(PVar(nm), rhs), s.metadata, s.pos));
                        declared.set(nm, true);
                    } else out.push(s);
                case EBinary(Match, left, rhs2):
                    var isWild = switch (left.def) {
                        case EVar(v) if (v == "_"): true;
                        case EUnderscore: true;
                        default: false;
                    };
                    if (isWild && isLiteral(rhs2)) {
                        var cands = collectPinnedCandidates(stmts, i + 1);
                        var filtered2 = [];
                        for (c in cands) if (!declared.exists(c)) filtered2.push(c);
                        if (filtered2.length == 1) {
                            var nm2 = filtered2[0];
                            out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar(nm2)), rhs2), s.metadata, s.pos));
                            declared.set(nm2, true);
                        } else out.push(s);
                    } else out.push(s);
                default:
                    out.push(s);
            }
        }
        return out;
    }
}

#end

