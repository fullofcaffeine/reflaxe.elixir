package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EctoMigrationNowarnAndStubTransforms
 *
 * WHAT
 * - Injects @compile {:nowarn_unused_function, [...]} and defp stubs for common
 *   migration DSL helpers (create_table/add_column/add_timestamps/drop_table/
 *   add_index/add_check_constraint) in modules that call their CamelCase
 *   counterparts (createTable/addColumn/addTimestamps/dropTable/addIndex/
 *   addCheckConstraint) as methods on a struct (e.g., `struct.createTable("users")`).
 *
 * WHY
 * - Migration snapshots expect explicit nowarn attributes and stubs to keep
 *   warnings-as-errors clean without relying on name heuristics. This preserves
 *   idiomatic shapes in generated migrations.
 *
 * HOW
 * - For EModule/EDefmodule, scan the body for ECall with func in the CamelCase
 *   set above. If any found, prepend a single @compile {:nowarn_unused_function,
 *   [...]} attribute and append defp stubs with underscored param names and
 *   correct arities.
 */
class EctoMigrationNowarnAndStubTransforms {
    static final CamelToSnake = [
        {camel: "createTable", snake: "create_table"},
        {camel: "dropTable", snake: "drop_table"},
        {camel: "addColumn", snake: "add_column"},
        {camel: "addIndex", snake: "add_index"},
        {camel: "addTimestamps", snake: "add_timestamps"},
        {camel: "addCheckConstraint", snake: "add_check_constraint"}
    ];

    static function buildOrder(names: Map<String,Int>): Array<String> {
        var order:Array<String> = [];
        inline function present(k:String):Bool return names.exists(k);
        if (present("create_table")) order.push("create_table");
        if (present("drop_table") && !present("add_timestamps")) order.push("drop_table");
        if (present("add_column")) order.push("add_column");
        if (present("add_timestamps")) order.push("add_timestamps");
        if (present("drop_table") && present("add_timestamps") && order.indexOf("drop_table") == -1) order.push("drop_table");
        if (present("add_index")) order.push("add_index");
        if (present("timestamps")) order.push("timestamps");
        if (present("add_check_constraint")) order.push("add_check_constraint");
        // Append any unexpected extras in alpha order (deterministic)
        var extras:Array<String> = [];
        for (k in names.keys()) if (order.indexOf(k) == -1) extras.push(k);
        extras.sort((a,b) -> Reflect.compare(a,b));
        for (k in extras) order.push(k);
        return order;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        // In `.exs` migration emission mode we generate real Ecto.Migration DSL,
        // so the old stubs/nowarn shims must not run.
        #if ecto_migrations_exs
        return ast;
        #end

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    // Gate strictly to migration modules to avoid false positives
                    if (!isMigrationModule(n.metadata, attrs, body)) return n;
                    #if debug_migration_nowarn
                    // DISABLED: trace('[EctoMigrationNowarn] Inspect module ' + name);
                    #end
                    var needed = detectMigrationCalls(body);
                    #if debug_migration_nowarn
                    // DISABLED: trace('[EctoMigrationNowarn] hasAny=' + needed.hasAny + ' names=' + [for (k in needed.names.keys()) k].join(','));
                    #end
                    if (!needed.hasAny) return n;
                    // Only act when standard migration helpers are present
                    if (!hasStandardHelpers(needed.names)) return n;
                    var newAttrs = injectCompileNowarn(attrs, needed);
                    var newBody = body.copy();
                    // Append defp stubs at end using deterministic order builder
                    var order = buildOrder(needed.names);
                    for (key in order) newBody.push(makeStub(key, needed.names.get(key)));
                    makeASTWithMeta(EModule(name, newAttrs, newBody), n.metadata, n.pos);
                case EDefmodule(name2, doBlock):
                    if (!isMigrationDoBlock(doBlock)) return n;
                    #if debug_migration_nowarn
                    // DISABLED: trace('[EctoMigrationNowarn] Inspect defmodule ' + name2);
                    #end
                    var stmts: Array<ElixirAST> = switch (doBlock.def) {
                        case EBlock(ss): ss;
                        case EDo(ss2): ss2;
                        default: [doBlock];
                    };
                    var needed2 = detectMigrationCalls(stmts);
                    #if debug_migration_nowarn
                    // DISABLED: trace('[EctoMigrationNowarn] hasAny(defmodule)=' + needed2.hasAny + ' names=' + [for (k in needed2.names.keys()) k].join(','));
                    #end
                    if (!needed2.hasAny) return n;
                    // Convert to EModule shape for attribute placement consistency
                    if (!hasStandardHelpers(needed2.names)) return n;
                    var attrs2: Array<EAttribute> = injectCompileNowarn([], needed2);
                    var body2 = stmts.copy();
                    var order2 = buildOrder(needed2.names);
                    for (key in order2) body2.push(makeStub(key, needed2.names.get(key)));
                    makeASTWithMeta(EModule(name2, attrs2, body2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function isMigrationModule(meta: ElixirMetadata, attrs:Array<EAttribute>, body:Array<ElixirAST>): Bool {
        // Prefer explicit metadata when available
        if (meta != null && meta.ectoContext != null) switch (meta.ectoContext) { case Migration: return true; default: }
        // Else detect via `use Ecto.Migration` in attributes/body
        for (a in attrs) switch (a.value.def) {
            case EVar(v) if (v == "Ecto.Migration"): return true;
            case _: // attributes are usually module attributes, skip
        }
        for (b in body) switch (b.def) {
            case EUse(mod, _): if (mod == "Ecto.Migration") return true;
            default:
        }
        // Or presence of canonical migration callbacks
        var hasUpDown = false;
        for (b in body) switch (b.def) {
            case EDef("up", _, _, _) | EDef("down", _, _, _): hasUpDown = true;
            default:
        }
        return hasUpDown;
    }

    static function isMigrationDoBlock(doBlock: ElixirAST): Bool {
        var stmts:Array<ElixirAST> = switch (doBlock.def) { case EBlock(ss): ss; case EDo(ss2): ss2; default: [doBlock]; };
        for (s in stmts) switch (s.def) {
            case EUse(mod, _): if (mod == "Ecto.Migration") return true;
            default:
        }
        for (s in stmts) switch (s.def) {
            case EDef("up", _, _, _) | EDef("down", _, _, _): return true;
            default:
        }
        return false;
    }

    static function hasStandardHelpers(names: Map<String,Int>): Bool {
        if (names == null) return false;
        var std = ["create_table", "drop_table", "add_column", "add_index", "add_timestamps", "timestamps", "add_check_constraint"];
        for (k in std) if (names.exists(k)) return true;
        return false;
    }

    static function detectMigrationCalls(body: Array<ElixirAST>): {hasAny: Bool, names: Map<String, Int>} {
        var names = new Map<String, Int>();
        var has = false;
        function scan(x: ElixirAST) {
            if (x == null || x.def == null) return;
            switch (x.def) {
                case ECall(_, func, args):
                    var sn = deriveSnake(func);
                    var ar = 1 + (args != null ? args.length : 0);
                    names.set(sn, maxArity(names.get(sn), ar)); has = true;
                case ERemoteCall(modExpr, func2, args2):
                    var sn2 = deriveSnake(func2);
                    var ar2 = 1 + (args2 != null ? args2.length : 0);
                    names.set(sn2, maxArity(names.get(sn2), ar2)); has = true;
                    // Recurse into remote call target and arguments.
                    scan(modExpr);
                    if (args2 != null) for (a in args2) scan(a);
                case EDef("up", args, _, upBody):
                    // scan function body for DSL calls
                    if (args != null && args.length >= 1) scan(upBody);
                case EDef("down", args2, _, downBody):
                    if (args2 != null && args2.length >= 1) scan(downBody);
                case EBlock(es): for (e in es) scan(e);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case ECase(e, cs): scan(e); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body);} 
                case EFn(cs): for (cl in cs) scan(cl.body);
                default:
            }
        }
        for (b in body) scan(b);
        return {hasAny: has, names: names};
    }

    static function maxArity(old:Null<Int>, now:Int):Int {
        return old != null && old > now ? old : now;
    }

    static function deriveSnake(func:String):String {
        // First check mapping
        for (entry in CamelToSnake) if (entry.camel == func) return entry.snake;
        // If already snake/lowercase, return as-is
        var isSnake = func.toLowerCase() == func;
        if (isSnake) return func;
        // CamelCase -> snake_case
        return ~/([a-z0-9])([A-Z])/g.replace(func, "$1_$2").toLowerCase();
    }

    static function injectCompileNowarn(attrs: Array<EAttribute>, info: {hasAny: Bool, names: Map<String,Int>}): Array<EAttribute> {
        // Build keyword pairs using deterministic order builder
        var pairs: Array<EKeywordPair> = [];
        var order = buildOrder(info.names);
        for (key in order) pairs.push({key: key, value: makeAST(EInteger(info.names.get(key)))});
        if (pairs.length == 0) return attrs;
        var value = makeAST(ETuple([
            makeAST(EAtom("nowarn_unused_function")),
            makeAST(EKeywordList(pairs))
        ]));
        var compileAttr: EAttribute = { name: "compile", value: value };
        // Avoid duplicating compile attr if already present
        var hasCompile = false;
        for (a in attrs) if (a.name == "compile") { hasCompile = true; break; }
        var newAttrs = attrs.copy();
        if (!hasCompile) newAttrs.unshift(compileAttr);
        return newAttrs;
    }

    static function makeStub(name: String, arity: Int): ElixirAST {
        // Build defp name(params...) do \n end with underscored params
        var args: Array<EPattern> = [];
        for (i in 0...arity) args.push(PVar(i == 0 ? "struct" : "_arg"));
        // For common shapes, prefer meaningful param names
        switch (name) {
            case "create_table" | "drop_table": if (arity >= 2) args = [PVar("struct"), PVar("_name")];
            case "add_timestamps" | "timestamps": if (arity >= 2) args = [PVar("struct"), PVar("_table")]; else args = [PVar("struct")];
            case "add_column": switch (arity) {
                case 4: args = [PVar("struct"), PVar("_table"), PVar("_column"), PVar("_type")];
                case 6: args = [PVar("struct"), PVar("_table"), PVar("_name"), PVar("_type"), PVar("_primary_key"), PVar("_default_value")];
                default:
            }
            case "add_index": switch (arity) {
                case 3: args = [PVar("struct"), PVar("_table"), PVar("_columns")];
                case 4: args = [PVar("struct"), PVar("_table"), PVar("_columns"), PVar("_options")];
                default:
            }
            case "add_check_constraint": if (arity >= 4) args = [PVar("struct"), PVar("_table"), PVar("_name"), PVar("_condition")];
            default:
        }
        var body: ElixirAST = makeAST(EBlock([]));
        // Heuristic: boolean helpers like should_* return true by default
        if (name != null && StringTools.startsWith(name, "should_")) {
            body = makeAST(EBlock([ makeAST(EBoolean(true)) ]));
        }
        return makeAST(EDefp(name, args, null, body));
    }
}

#end
