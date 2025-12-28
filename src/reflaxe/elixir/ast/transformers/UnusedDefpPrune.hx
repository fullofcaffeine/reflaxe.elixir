package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import haxe.ds.StringMap;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * UnusedDefpPrune
 *
 * WHAT
 * - Removes private function definitions (defp) that are never referenced within
 *   the same module.
 *
 * WHY
 * - Keeps generated modules tidy and avoids warnings about unused private
 *   functions when compiling with --warnings-as-errors.
 *
 * HOW
 * - For each module, collect defp names. Walk the module body to find usages:
 *   - Local calls: ECall(null, name, ...)
 *   - Captures: &name/arity represented as ECapture(EVar(name), arity)
 *   - Appearance in ERaw code as "name(" or snake/camel variants
 * - Any defp not referenced is pruned from the module body.
 *
 * EXAMPLES
 * Before:
 *   defp unused_helper(a), do: a
 *   def handle_event(_, _, socket) do
 *     {:noreply, socket}
 *   end
 * After:
 *   def handle_event(_, _, socket) do
 *     {:noreply, socket}
 *   end
 */
class UnusedDefpPrune {
    public static function prunePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    // Skip pruning in Phoenix Web macro modules; macro quoting confuses usage detection
                    var isPhoenixWeb = (n.metadata?.isPhoenixWeb == true) || (name != null && StringTools.endsWith(name, "Web") && name.indexOf(".") == -1);
                    if (isPhoenixWeb) return n;
                    var pruned = pruneModuleBody(name, body, attrs);
                    makeASTWithMeta(EModule(name, attrs, pruned), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var isPhoenixWeb2 = (n.metadata?.isPhoenixWeb == true) || (name != null && StringTools.endsWith(name, "Web") && name.indexOf(".") == -1);
                    if (isPhoenixWeb2) return n;
                    var stmts: Array<ElixirAST> = switch (doBlock.def) {
                        case EBlock(ss): ss;
                        case EDo(ss): ss;
                        default: [doBlock];
                    };
                    var pruned = pruneModuleBody(name, stmts, []);
                    var newDo = makeAST(EBlock(pruned));
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function pruneModuleBody(moduleName: String, stmts: Array<ElixirAST>, attrs: Array<EAttribute>): Array<ElixirAST> {
        var defpNames = new StringMap<Bool>();
        for (s in stmts) switch (s.def) {
            case EDefp(name, _, _, _): defpNames.set(name, true);
            default:
        }
        if (defpNames.keys().hasNext() == false) return stmts; // nothing to prune

        var used = new StringMap<Bool>();
        // Respect compile nowarn list for defp names
        var nowarn = collectNowarnNames(attrs);
        if (nowarn != null) for (k in nowarn.keys()) used.set(k, true);

        var moduleAlias = moduleName;
        if (moduleAlias != null && moduleAlias.indexOf(".") != -1) {
            moduleAlias = moduleAlias.substr(moduleAlias.lastIndexOf(".") + 1);
        }

        function isSelfModuleExpr(tgt: ElixirAST): Bool {
            if (tgt == null || tgt.def == null) return false;
            return switch (tgt.def) {
                case EVar(v): v == moduleName || v == moduleAlias;
                default: false;
            };
        }
        // Prepare name candidates for robust matching (snake/camel variants)
        function toSnake(n:String):String {
            var b = new StringBuf();
            for (i in 0...n.length) {
                var ch = n.charAt(i);
                var isUpper = ch.toUpperCase() == ch && ch.toLowerCase() != ch;
                if (isUpper && i > 0) b.add("_");
                b.add(ch.toLowerCase());
            }
            return b.toString();
        }
        function toCamel(n:String):String {
            var parts = n.split("_");
            if (parts.length == 0) return n;
            var out = new StringBuf();
            out.add(parts[0]);
            for (i in 1...parts.length) if (parts[i].length > 0) {
                out.add(parts[i].charAt(0).toUpperCase());
                out.add(parts[i].substr(1));
            }
            return out.toString();
        }
        // Build a map of defp name -> candidate spellings to detect usage in ERaw
        var candidates = new StringMap<Array<String>>();
        for (k in defpNames.keys()) {
            var list = new Array<String>();
            list.push(k);
            var snake = toSnake(k);
            var camel = toCamel(k);
            if (list.indexOf(snake) == -1) list.push(snake);
            if (list.indexOf(camel) == -1) list.push(camel);
            candidates.set(k, list);
        }
        // detect usages
        function visit(e: ElixirAST): Void {
            if (e == null || e.def == null) return;
            switch (e.def) {
                case EDef(_, _, _, body):
                    visit(body);
                case EDefp(_, _, _, body):
                    visit(body);
                case EUnary(_, expr):
                    visit(expr);
                case EPipe(left, right):
                    visit(left);
                    visit(right);
                case EMap(pairs):
                    for (p in pairs) { visit(p.key); visit(p.value); }
                case EKeywordList(pairs):
                    for (p in pairs) visit(p.value);
                case EList(elements):
                    for (el in elements) visit(el);
                case ETuple(elements):
                    for (el in elements) visit(el);
                case EStructUpdate(_, fields):
                    for (f in fields) visit(f.value);
                case EField(target, _):
                    visit(target);
                case EAccess(target, key):
                    visit(target);
                    visit(key);
                case ERange(start, end, _, step):
                    visit(start);
                    visit(end);
                    if (step != null) visit(step);
                case EQuote(_, expr):
                    visit(expr);
                case EParen(expr):
                    visit(expr);
                case EDo(body):
                    for (s in body) visit(s);
                case ECall(null, fname, args):
                    if (defpNames.exists(fname)) used.set(fname, true);
                    for (a in args) visit(a);
                case ECapture(inner, _):
                    switch (inner.def) {
                        case EVar(v) if (defpNames.exists(v)):
                            used.set(v, true);
                        case ECall(null, fname, _):
                            if (defpNames.exists(fname)) used.set(fname, true);
                        default:
                    }
                case ERaw(code):
                    // Conservative: if ERaw contains any candidate followed by '(', mark used
                    for (k in defpNames.keys()) {
                        if (used.exists(k)) continue;
                        var names = candidates.get(k);
                        if (names != null) {
                            for (n in names) {
                                var needle = n + "(";
                                if (code.indexOf(needle) != -1) {
                                    used.set(k, true);
                                    break;
                                }
                            }
                        }
                    }
                case ESigil(_, content, _):
                    // Same conservative scan for usage inside sigils (notably ~H templates),
                    // where helper calls appear as literal text (e.g. `icon_class(@name)`).
                    if (content != null) {
                        for (k in defpNames.keys()) {
                            if (used.exists(k)) continue;
                            var names = candidates.get(k);
                            if (names != null) {
                                for (n in names) {
                                    var callNeedle = n + "(";
                                    // Capture needles:
                                    // - local capture: &name/1
                                    // - remote capture: &Module.name/1
                                    var localCapNeedle = "&" + n + "/";
                                    var aliasCapNeedle = moduleAlias != null ? ("&" + moduleAlias + "." + n + "/") : null;
                                    var moduleCapNeedle = moduleName != null ? ("&" + moduleName + "." + n + "/") : null;
                                    if (content.indexOf(callNeedle) != -1
                                        || content.indexOf(localCapNeedle) != -1
                                        || (aliasCapNeedle != null && content.indexOf(aliasCapNeedle) != -1)
                                        || (moduleCapNeedle != null && content.indexOf(moduleCapNeedle) != -1)) {
                                        used.set(k, true);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                case EMacroCall(_, args, doBlock):
                    for (a in args) visit(a);
                    visit(doBlock);
                case EWith(clauses, doBlock, elseBlock):
                    for (c in clauses) visit(c.expr);
                    visit(doBlock);
                    if (elseBlock != null) visit(elseBlock);
                case EBlock(ss): for (s in ss) visit(s);
                case EIf(c, t, e): visit(c); visit(t); if (e != null) visit(e);
                case ECase(expr, cls):
                    visit(expr);
                    for (cl in cls) { if (cl.guard != null) visit(cl.guard); visit(cl.body); }
                case ECond(clauses):
                    for (cl in clauses) { visit(cl.condition); visit(cl.body); }
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(tgt, fname, args):
                    if (tgt != null && isSelfModuleExpr(tgt) && defpNames.exists(fname)) used.set(fname, true);
                    if (tgt != null) visit(tgt);
                    for (a in args) visit(a);
                case ERemoteCall(tgt, fname, args):
                    if (tgt != null && isSelfModuleExpr(tgt) && defpNames.exists(fname)) used.set(fname, true);
                    visit(tgt);
                    for (a in args) visit(a);
                case EFn(clauses): for (cl in clauses) visit(cl.body);
                case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
                    visit(body);
                    if (rescueClauses != null) for (cl in rescueClauses) visit(cl.body);
                    if (catchClauses != null) for (cl in catchClauses) visit(cl.body);
                    if (afterBlock != null) visit(afterBlock);
                    if (elseBlock != null) visit(elseBlock);
                case EReceive(clauses, afterClause):
                    for (cl in clauses) { if (cl.guard != null) visit(cl.guard); visit(cl.body); }
                    if (afterClause != null) { visit(afterClause.timeout); visit(afterClause.body); }
                default:
            }
        }
        for (s in stmts) visit(s);

        var out:Array<ElixirAST> = [];
        for (s in stmts) switch (s.def) {
            case EDefp(name, _, _, _) if (!used.exists(name)):
                // drop unused defp
            default:
                out.push(s);
        }
        return out;
    }

    static function collectNowarnNames(attrs: Array<EAttribute>): StringMap<Bool> {
        if (attrs == null) return null;
        var out = new StringMap<Bool>();
        for (a in attrs) if (a != null && a.name == "compile") {
            switch (a.value.def) {
                case ETuple([kind, kws]):
                    var isNowarn = switch (kind.def) { case EAtom(atom) if (atom == "nowarn_unused_function"): true; default: false; };
                    if (!isNowarn) break;
                    switch (kws.def) {
                        case EKeywordList(pairs):
                            for (p in pairs) out.set(p.key, true);
                        default:
                    }
                default:
            }
        }
        return out;
    }
}

#end
