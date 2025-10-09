package reflaxe.elixir.ir;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.EPattern as EPat;

class ApplyNames {
    /**
     * Stateless late-naming apply. Keeps backward compatibility.
     */
    public static function apply(ast: ElixirAST): ElixirAST {
        #if enable_symbol_ir
        return renameInNode(ast, null);
        #else
        return ast;
        #end
    }

    /**
     * Context-aware late-naming apply. When provided, merges binder-derived
     * renames with CompilationContext.tempVarRenameMap so both binders and
     * body references stay aligned. Binder mapping always wins.
     */
    public static function applyWithContext(ast: ElixirAST, context: reflaxe.elixir.CompilationContext): ElixirAST {
        #if enable_symbol_ir
        return renameInNode(ast, context);
        #else
        return ast;
        #end
    }

    static function renameInNode(node: ElixirAST, context: Null<reflaxe.elixir.CompilationContext>): ElixirAST {
        if (node == null || node.def == null) return node;
        return switch (node.def) {
            case EDef(name, args, guard, body):
                var mapping = computeMappingFromPatterns(args);
                var merged = mergeWithContext(mapping, context);
                var newArgs = args.map(p -> renamePattern(p, merged));
                var newBody = renameExpr(body, merged);
                makeASTWithMeta(EDef(name, newArgs, guard, newBody), node.metadata, node.pos);
            case EDefp(name, args, guard, body):
                var mapping = computeMappingFromPatterns(args);
                var merged = mergeWithContext(mapping, context);
                var newArgs = args.map(p -> renamePattern(p, merged));
                var newBody = renameExpr(body, merged);
                makeASTWithMeta(EDefp(name, newArgs, guard, newBody), node.metadata, node.pos);
            case EFn(clauses):
                var newClauses = [];
                for (c in clauses) {
                    var mapping = computeMappingFromPatterns(c.args);
                    var merged = mergeWithContext(mapping, context);
                    newClauses.push({
                        args: c.args.map(p -> renamePattern(p, merged)),
                        guard: c.guard != null ? renameExpr(c.guard, merged) : null,
                        body: renameExpr(c.body, merged)
                    });
                }
                makeASTWithMeta(EFn(newClauses), node.metadata, node.pos);
            case ECase(expr, clauses):
                var newClauses = [];
                for (cl in clauses) {
                    var mapping = computeMappingFromPatterns([cl.pattern]);
                    var merged = mergeWithContext(mapping, context);
                    newClauses.push({
                        pattern: renamePattern(cl.pattern, merged),
                        guard: cl.guard != null ? renameExpr(cl.guard, merged) : null,
                        body: renameExpr(cl.body, merged)
                    });
                }
                makeASTWithMeta(ECase(renameInNode(expr, context), newClauses), node.metadata, node.pos);
            default:
                // Recursively process children
                reflaxe.elixir.ast.ElixirASTTransformer.transformAST(node, n -> renameInNode(n, context));
        }
    }

    static function computeMappingFromPatterns(patterns: Array<EPat>): Map<String,String> {
        var binders:Array<String> = [];
        function collect(p:EPat):Void {
            switch (p) {
                case PVar(n): binders.push(n);
                case PAlias(n, inner): binders.push(n); collect(inner);
                case PTuple(el): for (e in el) collect(e);
                case PList(el): for (e in el) collect(e);
                case PCons(h,t): collect(h); collect(t);
                case PMap(pairs): for (kv in pairs) collect(kv.value);
                case PStruct(_, fields): for (f in fields) collect(f.value);
                case PPin(inner): collect(inner);
                default:
            }
        }
        for (p in patterns) collect(p);
        // Build fake scope data for hygiene pass
        var scopeId = 1;
        var scopes = [ new Scope(scopeId, ScopeKind.Block, null) ];
        var symbols:Array<Symbol> = [];
        for (n in binders) symbols.push(new Symbol(symbols.length+1, n, scopeId, Origin.PatternBinder, true));
        var nameMap = Hygiene.computeFinalNames(symbols, scopes);
        var result = new Map<String,String>();
        var i = 0;
        for (n in binders) {
            var s = symbols[i++];
            var finalNameStr = nameMap.get(s);
            if (finalNameStr != null && finalNameStr != n) result.set(n, finalNameStr);
        }
        return result;
    }

    /**
     * Merge binder-derived mapping with context tempVarRenameMap.
     * - Context entries ensure body refs like `options2` map to final `options`
     * - Binder mapping wins to preserve tuple positions and chosen final names
     */
    static function mergeWithContext(mapping: Map<String,String>, context: Null<reflaxe.elixir.CompilationContext>): Map<String,String> {
        if (context == null) return mapping;
        var out = new Map<String,String>();
        // Start with context name-based entries only (skip ID keys)
        for (k in context.tempVarRenameMap.keys()) {
            var v = context.tempVarRenameMap.get(k);
            // Heuristic: treat purely numeric keys as IDs; keep only name keys
            if (!~/^\d+$/.match(k)) {
                out.set(k, v);
            }
        }
        // Overlay binder-derived mapping (binder always wins)
        for (k in mapping.keys()) {
            out.set(k, mapping.get(k));
        }
        return out;
    }

    static function renamePattern(p:EPat, mapping: Map<String,String>): EPat {
        return switch (p) {
            case PVar(n):
                var nn = mapping.exists(n) ? mapping.get(n) : n;
                PVar(nn);
            case PAlias(n, inner):
                var nn = mapping.exists(n) ? mapping.get(n) : n;
                PAlias(nn, renamePattern(inner, mapping));
            case PTuple(el): PTuple([for (e in el) renamePattern(e, mapping)]);
            case PList(el): PList([for (e in el) renamePattern(e, mapping)]);
            case PCons(h,t): PCons(renamePattern(h,mapping), renamePattern(t,mapping));
            case PMap(pairs): PMap([for (kv in pairs) { key: kv.key, value: renamePattern(kv.value, mapping) }]);
            case PStruct(mod, fields): PStruct(mod, [for (f in fields) { key: f.key, value: renamePattern(f.value, mapping) }]);
            case PPin(inner): PPin(renamePattern(inner, mapping));
            default: p;
        }
    }

    static function renameExpr(e:ElixirAST, mapping: Map<String,String>): ElixirAST {
        if (e == null || e.def == null || mapping == null || mapping.keys().hasNext() == false) return e;
        return switch (e.def) {
            case EVar(n):
                if (mapping.exists(n)) makeASTWithMeta(EVar(mapping.get(n)), e.metadata, e.pos) else e;
            case EBinary(op, l, r):
                makeASTWithMeta(EBinary(op, renameExpr(l, mapping), renameExpr(r, mapping)), e.metadata, e.pos);
            case EUnary(op, ex):
                makeASTWithMeta(EUnary(op, renameExpr(ex, mapping)), e.metadata, e.pos);
            case ECall(t, nm, args):
                makeASTWithMeta(ECall(t != null ? renameExpr(t, mapping) : null, nm, [for (a in args) renameExpr(a, mapping)]), e.metadata, e.pos);
            case ERemoteCall(m, nm, args):
                makeASTWithMeta(ERemoteCall(renameExpr(m, mapping), nm, [for (a in args) renameExpr(a, mapping)]), e.metadata, e.pos);
            case EIf(c,t,el):
                makeASTWithMeta(EIf(renameExpr(c, mapping), renameExpr(t, mapping), el != null ? renameExpr(el, mapping) : null), e.metadata, e.pos);
            case EBlock(sts):
                makeASTWithMeta(EBlock([for (s in sts) renameExpr(s, mapping)]), e.metadata, e.pos);
            case EParen(inner):
                makeASTWithMeta(EParen(renameExpr(inner, mapping)), e.metadata, e.pos);
            case EMap(pairs):
                makeASTWithMeta(EMap([for (p in pairs) { key: p.key, value: renameExpr(p.value, mapping) }]), e.metadata, e.pos);
            case EStruct(mod, fields):
                makeASTWithMeta(EStruct(mod, [for (f in fields) { key: f.key, value: renameExpr(f.value, mapping) }]), e.metadata, e.pos);
            case EKeywordList(pairs):
                makeASTWithMeta(EKeywordList([for (p in pairs) { key: p.key, value: renameExpr(p.value, mapping) }]), e.metadata, e.pos);
            case EList(el):
                makeASTWithMeta(EList([for (x in el) renameExpr(x, mapping)]), e.metadata, e.pos);
            case EFor(gens, filters, body, into, uniq):
                makeASTWithMeta(EFor([for (g in gens) { pattern: renamePattern(g.pattern, mapping), expr: renameExpr(g.expr, mapping) }], [for (f in filters) renameExpr(f, mapping)], renameExpr(body, mapping), into != null ? renameExpr(into, mapping) : null, uniq), e.metadata, e.pos);
            default: e;
        }
    }
}

#end
