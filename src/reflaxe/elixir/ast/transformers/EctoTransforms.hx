package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

/**
 * EctoTransforms
 *
 * WHAT
 * - Normalizes Ecto.Query usage: ensures consistent query variable binding,
 *   qualifies from/in atoms to schema modules, and rewrites Repo.all/where
 *   to use the canonical query variable.
 *
 * WHY
 * - Generated code may drift between different query var names and rely on
 *   atoms for table names. Normalization improves correctness and readability.
 *
 * HOW
 * - Track first query var and rewrite subsequent calls to use it.
 * - Convert ERaw from/in :table to <App>.Schema in both ERaw and AST forms.
 *
 * EXAMPLES
 * Before: from u in :user |> where([t], t.id == ^id) |> Repo.all()
 * After:  from u in App.User |> where([u], u.id == ^id) |> Repo.all()
 */
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * EctoTransforms: Normalize Ecto query variable usage within function scope.
 *
 * WHY: Generated code for dynamic Ecto queries may introduce temp variables
 * (e.g., `query2`, `_value`) while references in subsequent calls still use
 * base names (`query`, `value`). This leads to undefined variable errors at
 * Mix compile time.
 *
 * WHAT: Within each function (EDef/EDefp),
 * - Detect the variable bound to Ecto.Queryable.to_query/1 and consistently
 *   use it as the query arg for Ecto.Query.where/2 and Repo.all/1.
 * - If a reference to an undeclared var exists and its underscore-prefixed
 *   counterpart is declared (e.g., `empty_params` vs `_empty_params`), rewrite
 *   the reference to the declared underscore name.
 *
 * HOW: Collect declared var names from pattern bindings. Track the first
 * encountered binding of Ecto.Queryable.to_query and use that as canonical
 * query var. Rewrite relevant ERemoteCall arguments and Repo.all call sites.
 */
class EctoTransforms {
    /**
     * ectoQueryableAtomToSchemaPass
     *
     * WHAT
     * - Rewrites Ecto.Queryable.to_query(:atom) to the schema module <App>.<CamelCase(atom)>
     *   so Repo and Ecto.Query APIs receive a valid queryable.
     *
     * WHY
     * - Ecto.Queryable does not accept plain atoms that are not modules. Passing :todo triggers
     *   Protocol.UndefinedError. Phoenix idiom is to use the schema module.
     *
     * HOW
     * - For any ERemoteCall(Ecto.Queryable, "to_query", [EAtom(name)]), derive <App> prefix from the
     *   enclosing module name (e.g., TodoAppWeb.* -> TodoApp) and replace the call with EVar("<App>.<CamelName>")
     *   to hand a proper queryable to downstream where/order_by/all.
     */
    public static function ectoQueryableAtomToSchemaPass(ast: ElixirAST): ElixirAST {
        inline function camelize(s: String): String {
            var parts = s.split("_");
            var out = [];
            for (p in parts) if (p.length > 0) out.push(p.charAt(0).toUpperCase() + p.substr(1));
            return out.join("");
        }
        var defaultApp = (function() {
            try {
                return reflaxe.elixir.PhoenixMapper.getAppModuleName();
            } catch (e) {
                return null;
            }
        })();
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(modAst, func, args) if (func == "to_query" && args != null && args.length == 1):
                    var modStr = switch (modAst.def) {
                        case EVar(mn): mn;
                        default: reflaxe.elixir.ast.ElixirASTPrinter.printAST(modAst);
                    };
                    if (modStr != "Ecto.Queryable") return n;
                    switch (args[0].def) {
                        case EAtom(atomName) if (defaultApp != null):
                            var newArgs = args.copy();
                            newArgs[0] = makeAST(EVar(defaultApp + "." + camelize(atomName)));
                            makeASTWithMeta(ERemoteCall(modAst, func, newArgs), n.metadata, n.pos);
                        default: n;
                    }
                default: n;
            }
        });
    }
    public static function ectoQueryVarConsistencyPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body):
                    var newBody = normalizeInBody(body);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var newBody = normalizeInBody(body);
                    makeASTWithMeta(EDefp(name, args, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function normalizeInBody(body: ElixirAST): ElixirAST {
        // Collect declared vars and pick canonical query var
        var declared = new Map<String, Bool>();
        var referenced = new Map<String, Bool>();
        var canonicalQuery: Null<String> = null;

        // Local pattern var collector (avoid external deps)
        function collectPatternVars(p: EPattern, vars: Map<String, Bool>): Void {
            switch (p) {
                case PVar(name): vars.set(name, true);
                case PTuple(es) | PList(es): for (e in es) collectPatternVars(e, vars);
                case PCons(h, t): collectPatternVars(h, vars); collectPatternVars(t, vars);
                case PMap(kvs): for (kv in kvs) collectPatternVars(kv.value, vars);
                case PStruct(_, fs): for (f in fs) collectPatternVars(f.value, vars);
                case PPin(inner): collectPatternVars(inner, vars);
                default:
            }
        }

        function collect(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(pattern, expr):
                    // Collect declared names
                    collectPatternVars(pattern, declared);
                    // Detect Ecto.Queryable.to_query binding
                    switch (expr.def) {
                        case ERemoteCall(mod, func, _):
                            if (canonicalQuery == null && func == "to_query") {
                                switch (mod.def) {
                                    case EVar(n) if (n == "Ecto.Queryable"):
                                        switch (pattern) { case PVar(v): canonicalQuery = v; default: }
                                    default:
                                }
                            }
                            // Detect Ecto.Query.from binding as canonical query as well
                            if (canonicalQuery == null && func == "from") {
                                switch (mod.def) {
                                    case EVar(nf) if (nf == "Ecto.Query"):
                                        switch (pattern) { case PVar(vf): canonicalQuery = vf; default: }
                                    default:
                                }
                            }
                        case EMatch(innerPat, innerExpr):
                            switch (innerExpr.def) {
                                case ERemoteCall(mod3, func3, _):
                                    if (canonicalQuery == null && func3 == "to_query") {
                                        switch (mod3.def) {
                                            case EVar(n3) if (n3 == "Ecto.Queryable"):
                                                switch (innerPat) { case PVar(v3): canonicalQuery = v3; default: }
                                            default:
                                        }
                                    }
                                    if (canonicalQuery == null && func3 == "from") {
                                        switch (mod3.def) {
                                            case EVar(n4) if (n4 == "Ecto.Query"):
                                                switch (innerPat) { case PVar(v4): canonicalQuery = v4; default: }
                                            default:
                                        }
                                    }
                                case ERaw(code2):
                                    if (canonicalQuery == null && code2.indexOf("Ecto.Query.from") != -1) {
                                        switch (innerPat) { case PVar(v5): canonicalQuery = v5; default: }
                                    }
                                default:
                            }
                        case ERaw(code):
                            // Detect canonical query binding from raw Ecto.Query.from
                            if (canonicalQuery == null && code.indexOf("Ecto.Query.from") != -1) {
                                switch (pattern) {
                                    case PVar(vr): canonicalQuery = vr;
                                    default:
                                }
                            }
                        default:
                    }
                case EBinary(Match, left, expr):
                    // Collect simple local assignments: name = expr
                    switch (left.def) {
                        case EVar(name):
                            declared.set(name, true);
                            // Detect Ecto.Queryable.to_query binding
                            switch (expr.def) {
                                case ERemoteCall(mod, func, _):
                                    if (canonicalQuery == null && func == "to_query") {
                                        switch (mod.def) {
                                            case EVar(n) if (n == "Ecto.Queryable"):
                                                canonicalQuery = name;
                                            default:
                                        }
                                    }
                                    // Detect Ecto.Query.from binding as canonical query as well
                                    if (canonicalQuery == null && func == "from") {
                                        switch (mod.def) {
                                            case EVar(nf) if (nf == "Ecto.Query"):
                                                canonicalQuery = name;
                                            default:
                                        }
                                    }
                                case ERaw(code):
                                    // Detect canonical query binding from raw Ecto.Query.from
                                    if (canonicalQuery == null && code.indexOf("Ecto.Query.from") != -1) {
                                        canonicalQuery = name;
                                    }
                                default:
                            }
                        default:
                    }
                default:
                    // no-op; traversal is driven by a top-level walk
            }
            // Track references
            switch (n.def) {
                case EVar(nm): referenced.set(nm, true);
                default:
            }
        }

        // Helper removed; inline checks used to avoid type issues

        // Single exhaustive walk to collect declarations and references
        ASTUtils.walk(body, collect);

        // Force canonical query var preference if 'query' exists
        if (declared.exists("query")) {
            canonicalQuery = "query";
        }

        // Build rename map for underscore/non-underscore pairs and query2→query
        var renameMap = new Map<String, String>();
        for (name in declared.keys()) {
            if (StringTools.startsWith(name, "_")) {
                var alt = name.substr(1);
                if (referenced.exists(alt) && !declared.exists(alt)) {
                    renameMap.set(name, alt);
                }
            }
        }
        // Generalize: map any queryN → query when query declared and queryN is only referenced
        for (name in referenced.keys()) {
            if (StringTools.startsWith(name, "query") && name.length > 5) {
                var rest = name.substr(5);
                var isDigits = true;
                for (i in 0...rest.length) {
                    var c = rest.charCodeAt(i);
                    if (c < '0'.code || c > '9'.code) { isDigits = false; break; }
                }
                if (isDigits && declared.exists("query") && !declared.exists(name)) {
                    renameMap.set(name, "query");
                }
            }
        }
        // Prefer canonical query var name `query` if available and conflict-free
        if (canonicalQuery != null && canonicalQuery != "query" && !declared.exists("query")) {
            renameMap.set(canonicalQuery, "query");
        }

        // Helper: pattern rename
        function renameInPattern(p: EPattern): EPattern {
            return switch (p) {
                case PVar(nm) if (renameMap.exists(nm)):
                    PVar(renameMap.get(nm));
                case PTuple(es): PTuple([for (e in es) renameInPattern(e)]);
                case PList(es): PList([for (e in es) renameInPattern(e)]);
                case PCons(h, t): PCons(renameInPattern(h), renameInPattern(t));
                case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: renameInPattern(kv.value) }]);
                case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: renameInPattern(f.value) }]);
                case PPin(inner): PPin(renameInPattern(inner));
                default: p;
            }
        }

        // Helper: apply renames to patterns and variables
        function applyRenames(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                case EVar(name) if (renameMap.exists(name)):
                    makeASTWithMeta(EVar(renameMap.get(name)), n.metadata, n.pos);
                case EMatch(pattern, expr):
                    var npat = renameInPattern(pattern);
                    // Children already transformed by transformNode; do not re-traverse expr here
                    makeASTWithMeta(EMatch(npat, expr), n.metadata, n.pos);
                default:
                    n;
            }
        }

        // Rewrite visitors
        function rewrite(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                // Rewrite raw where(query, ...) → where(canonicalQuery, ...)
                case ERaw(code) if (canonicalQuery != null):
                    var newCode = code;
                    // Only replace the first argument occurrence in where/2
                    var needle = 'Ecto.Query.where(query,';
                    var replacement = 'Ecto.Query.where(' + canonicalQuery + ',';
                    if (newCode.indexOf(needle) != -1) {
                        newCode = newCode.split(needle).join(replacement);
                    }
                    makeASTWithMeta(ERaw(newCode), n.metadata, n.pos);
                // Rewrite Repo.all(query) → Repo.all(canonicalQuery)
                case ERemoteCall(mod, func, args) if (func == "all" && args.length == 1 && canonicalQuery != null):
                    switch (mod.def) {
                        case EVar(mn) if (mn == "Repo"):
                            switch (args[0].def) {
                                case EVar(arg) if (arg != canonicalQuery):
                                    makeASTWithMeta(ERemoteCall(mod, func, [makeAST(EVar(canonicalQuery))]), n.metadata, n.pos);
                                default: n;
                            }
                        default: n;
                    }
                // Rewrite Ecto.Query.where/order_by/preload first arg to canonical query var
                // only when the referenced query var is actually undefined in this function.
                case ERemoteCall(mod2, func2, args2) if ((func2 == "where" || func2 == "order_by" || func2 == "preload") && args2.length >= 1 && canonicalQuery != null):
                    switch (mod2.def) {
                        case EVar(mn2) if (mn2 == "Ecto.Query"):
                            switch (args2[0].def) {
                                case EVar(arg0) if (arg0 != canonicalQuery && !declared.exists(arg0)):
                                    var newArgs = args2.copy();
                                    newArgs[0] = makeAST(EVar(canonicalQuery));
                                    makeASTWithMeta(ERemoteCall(mod2, func2, newArgs), n.metadata, n.pos);
                                default: n;
                            }
                        default: n;
                    }
                // If referencing an undeclared var, but declared has underscore-prefixed version, rewrite
                case EVar(name):
                    if (!declared.exists(name)) {
                        var alt = "_" + name;
                        if (declared.exists(alt)) {
                            makeASTWithMeta(EVar(alt), n.metadata, n.pos);
                        } else {
                            n;
                        }
                    } else {
                        n;
                    }
                // Other nodes: traversal handled by outer transformNode call
                default:
                    n;
            }
        }

        var step1 = ElixirASTTransformer.transformNode(body, rewrite);
        // Apply renames after structural fixes
        return ElixirASTTransformer.transformNode(step1, applyRenames);
    }
}

#end
