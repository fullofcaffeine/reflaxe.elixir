package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * TopLevelNilAssignDiscardTransforms
 *
 * WHAT
 * - Discard top-level assignments to nil in function bodies when the variable
 *   is not used later: `var = nil` → `_ = nil` to eliminate unused-variable warnings.
 */
class TopLevelNilAssignDiscardTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(EDefp(name, args, guards, rewriteBody(body)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteBody(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                for (i in 0...stmts.length) {
                    var s = stmts[i];
                    switch (s.def) {
                        case EBinary(Match, left, right) if (isNil(right) && isVar(left)):
                            var name = getVar(left);
                            if (!nameUsedLater(stmts, i+1, name)) out.push(makeASTWithMeta(EMatch(PWildcard, right), s.metadata, s.pos)) else out.push(s);
                        case EMatch(pat, right) if (isNil(right) && isPVar(pat)):
                            var name2 = getPVar(pat);
                            if (!nameUsedLater(stmts, i+1, name2)) out.push(makeASTWithMeta(EMatch(PWildcard, right), s.metadata, s.pos)) else out.push(s);
                        default:
                            out.push(s);
                    }
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            default:
                body;
        }
    }

    static inline function isNil(e: ElixirAST):Bool {
        return switch (e.def) { case ENil: true; default: false; };
    }
    static inline function isVar(e: ElixirAST):Bool {
        return switch (e.def) { case EVar(_): true; default: false; };
    }
    static inline function isPVar(p: EPattern):Bool {
        return switch (p) { case PVar(_): true; default: false; };
    }
    static inline function getVar(e: ElixirAST):String {
        return switch (e.def) { case EVar(n): n; default: null; };
    }
    static inline function getPVar(p: EPattern):String {
        return switch (p) { case PVar(n): n; default: null; };
    }
    static function nameUsedLater(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
        for (j in start...stmts.length) if (statementUsesName(stmts[j], name)) return true;
        return false;
    }
    static function statementUsesName(s:ElixirAST, name:String):Bool {
        var used = false;

        function pinnedPatternUsesName(pattern:EPattern, isPinned:Bool):Bool {
            return switch (pattern) {
                case PVar(varName):
                    isPinned && varName == name;
                case PLiteral(_):
                    false;
                case PTuple(elements):
                    Lambda.exists(elements, p -> pinnedPatternUsesName(p, isPinned));
                case PList(elements):
                    Lambda.exists(elements, p -> pinnedPatternUsesName(p, isPinned));
                case PCons(head, tail):
                    pinnedPatternUsesName(head, isPinned) || pinnedPatternUsesName(tail, isPinned);
                case PMap(pairs):
                    Lambda.exists(pairs, pair -> pinnedPatternUsesName(pair.value, isPinned));
                case PStruct(_, fields):
                    Lambda.exists(fields, field -> pinnedPatternUsesName(field.value, isPinned));
                case PPin(inner):
                    pinnedPatternUsesName(inner, true);
                case PWildcard:
                    false;
                case PAlias(_, inner):
                    pinnedPatternUsesName(inner, isPinned);
                case PBinary(segments):
                    Lambda.exists(segments, seg -> pinnedPatternUsesName(seg.pattern, isPinned));
            }
        }

        function visit(n: ElixirAST): Void {
            if (used || n == null || n.def == null) return;

            switch (n.def) {
                // Direct references
                case EVar(varName) if (varName == name):
                    used = true;

                // Do not treat match binders as "uses"; only RHS is an expression.
                case EBinary(Match, _left, rhs):
                    visit(rhs);
                case EMatch(pattern, rhsExpr):
                    if (pinnedPatternUsesName(pattern, false)) used = true;
                    visit(rhsExpr);

                // Patterns that may include pins
                case ECase(expr, clauses):
                    visit(expr);
                    for (clause in clauses) {
                        if (pinnedPatternUsesName(clause.pattern, false)) { used = true; break; }
                        if (clause.guard != null) visit(clause.guard);
                        visit(clause.body);
                        if (used) break;
                    }
                case EWith(clauses, doBlock, elseBlock):
                    for (clause in clauses) {
                        if (pinnedPatternUsesName(clause.pattern, false)) { used = true; break; }
                        visit(clause.expr);
                        if (used) break;
                    }
                    if (!used) {
                        visit(doBlock);
                        if (elseBlock != null) visit(elseBlock);
                    }
                case EFn(clauses):
                    for (clause in clauses) {
                        // Only pinned vars in binders count as "uses" here.
                        for (arg in clause.args) {
                            if (pinnedPatternUsesName(arg, false)) { used = true; break; }
                        }
                        if (used) break;
                        if (clause.guard != null) visit(clause.guard);
                        visit(clause.body);
                        if (used) break;
                    }
                case EFor(generators, filters, body, into, _uniq):
                    for (gen in generators) {
                        if (pinnedPatternUsesName(gen.pattern, false)) { used = true; break; }
                        visit(gen.expr);
                        if (used) break;
                    }
                    if (!used) for (f in filters) { visit(f); if (used) break; }
                    if (!used) visit(body);
                    if (!used && into != null) visit(into);
                case EReceive(clauses, after):
                    for (clause in clauses) {
                        if (pinnedPatternUsesName(clause.pattern, false)) { used = true; break; }
                        if (clause.guard != null) visit(clause.guard);
                        visit(clause.body);
                        if (used) break;
                    }
                    if (!used && after != null) {
                        visit(after.timeout);
                        visit(after.body);
                    }
                case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
                    visit(body);
                    if (!used) for (r in rescueClauses) {
                        if (pinnedPatternUsesName(r.pattern, false)) { used = true; break; }
                        visit(r.body);
                        if (used) break;
                    }
                    if (!used) for (c in catchClauses) {
                        if (pinnedPatternUsesName(c.pattern, false)) { used = true; break; }
                        visit(c.body);
                        if (used) break;
                    }
                    if (!used && afterBlock != null) visit(afterBlock);
                    if (!used && elseBlock != null) visit(elseBlock);

                // Core expression forms
                case EIf(condition, thenBranch, elseBranch):
                    visit(condition); visit(thenBranch); if (elseBranch != null) visit(elseBranch);
                case EUnless(condition, bodyExpr, elseBranch):
                    visit(condition); visit(bodyExpr); if (elseBranch != null) visit(elseBranch);
                case EUnary(_op, expr):
                    visit(expr);
                case EPin(expr):
                    visit(expr);
                case EParen(expr):
                    visit(expr);
                case EPipe(left, right):
                    visit(left); visit(right);
                case ECall(target, _func, args):
                    if (target != null) visit(target);
                    for (a in args) { visit(a); if (used) break; }
                case ERemoteCall(moduleExpr, _funcName, callArgs):
                    visit(moduleExpr);
                    for (arg in callArgs) { visit(arg); if (used) break; }
                case EMacroCall(_macro, macroArgs, doBlock):
                    for (arg in macroArgs) { visit(arg); if (used) break; }
                    if (!used) visit(doBlock);
                case EField(obj, _field):
                    visit(obj);
                case EAccess(obj, key):
                    visit(obj); visit(key);
                case ERange(start, end, _exclusive):
                    visit(start); visit(end);

                // Data structures
                case EList(elements) | ETuple(elements):
                    for (e in elements) { visit(e); if (used) break; }
                case EMap(pairs):
                    for (p in pairs) { visit(p.key); visit(p.value); if (used) break; }
                case EKeywordList(pairs):
                    for (pair in pairs) { visit(pair.value); if (used) break; }
                case EStruct(_module, fields):
                    for (f in fields) { visit(f.value); if (used) break; }
                case EStructUpdate(base, fields):
                    visit(base);
                    for (field in fields) { visit(field.value); if (used) break; }
                case EBitstring(segments):
                    for (seg in segments) {
                        visit(seg.value);
                        if (used) break;
                        if (seg.size != null) visit(seg.size);
                        if (used) break;
                    }

                // Blocks
                case EBlock(statements):
                    for (st in statements) { visit(st); if (used) break; }
                case EDo(statements2):
                    for (st2 in statements2) { visit(st2); if (used) break; }

                // ERaw / interpolation
                case ERaw(code):
                    if (code != null && code.indexOf('#{' + name) != -1) used = true;
                case EString(value):
                    if (value != null && value.indexOf('#{' + name) != -1) used = true;

                default:
            }
        }

        visit(s);
        return used;
    }
}

#end
